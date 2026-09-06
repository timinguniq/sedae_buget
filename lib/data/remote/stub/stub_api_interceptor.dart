import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sedae_budget/data/peer/peer_stats_json.dart';
import 'package:sedae_budget/data/remote/api_path.dart';
import 'package:sedae_budget/data/remote/stub/stub_api_state.dart';
import 'package:sedae_budget/data/remote/stub/stub_peer_data.dart';
import 'package:sedae_budget/entity/entity.dart';

typedef _Json = Map<String, dynamic>;

/// 서버 없이 계약(API 계약 v1)대로 응답하는 인프로세스 Stub. 네트워크로 나가지 않는다.
///
/// - 인증은 무상태: 토큰 `stub.<provider>`에서 사용자를 복원한다.
/// - 프로필·거래·사용자 카테고리는 [StubApiState]에 보관하고 [StubStateStore]가 있으면 영속화한다.
/// - 또래 통계는 [StubPeerData](결정적).
class StubApiInterceptor extends Interceptor {
  StubApiInterceptor({StubStateStore? store}) : _store = store;

  static const _tokenPrefix = 'stub.';

  final StubStateStore? _store;
  final StubApiState _state = StubApiState();
  bool _loaded = false;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await _ensureLoaded();
    try {
      final (status, body) = await _route(options);
      handler.resolve(Response(requestOptions: options, statusCode: status, data: body));
    } on _StubError catch (e) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: options,
            statusCode: e.status,
            data: {'code': e.code, 'message': e.message},
          ),
        ),
      );
    }
  }

  Future<(int, Object?)> _route(RequestOptions o) async {
    final m = o.method, p = o.path;
    if (m == 'POST' && p == ApiPath.login) return (200, _login(o.data as _Json));

    final provider = _authed(o); // 이하 전부 Bearer 필수
    if (m == 'POST' && p == ApiPath.logout) return (204, null);
    if (m == 'GET' && p == ApiPath.me) return (200, _user(provider));
    if (p == ApiPath.profile) return _profile(m, o.data);
    if (m == 'GET' && p == ApiPath.transactions) return (200, _listTx(o.queryParameters));
    final txId = _idAfter(ApiPath.transactions, p);
    if (txId != null) return _tx(m, txId, o.data);
    if (m == 'GET' && p == ApiPath.categories) return (200, _listCategories());
    final catId = _idAfter(ApiPath.categories, p);
    if (catId != null) return _category(m, catId, o.data);
    if (m == 'GET' && p == ApiPath.peerStats) {
      final g = AgeGroup.values.byName(o.queryParameters['ageGroup'] as String);
      return (200, peerStatsToJson(StubPeerData.forGroup(g)));
    }
    if (m == 'GET' && p == ApiPath.peerGenerations) {
      return (
        200,
        [
          for (final g in AgeGroup.values)
            {'ageGroup': g.name, 'avgMonthlyExpense': StubPeerData.forGroup(g).avgMonthlyExpense},
        ],
      );
    }
    throw _StubError(404, 'NOT_FOUND', '경로가 없습니다: $m $p');
  }

  // auth --------------------//

  _Json _login(_Json body) {
    final idToken = body['idToken'];
    if (idToken is! String || idToken.isEmpty) {
      throw _StubError(400, 'VALIDATION', 'idToken이 필요합니다.');
    }
    final provider = _providerOrNull(body['provider'] as String?);
    if (provider == null) throw _StubError(400, 'VALIDATION', 'provider가 잘못되었습니다.');
    return {'accessToken': '$_tokenPrefix${provider.name}', 'user': _user(provider)};
  }

  AuthProvider _authed(RequestOptions o) {
    final header = o.headers['Authorization'] as String?;
    if (header == null || !header.startsWith('Bearer ')) {
      throw _StubError(401, 'AUTH_002', '로그인이 필요합니다.');
    }
    final token = header.substring('Bearer '.length);
    final provider = token.startsWith(_tokenPrefix)
        ? _providerOrNull(token.substring(_tokenPrefix.length))
        : null;
    if (provider == null) throw _StubError(401, 'AUTH_004', '잘못된 토큰입니다.');
    return provider;
  }

  AuthProvider? _providerOrNull(String? name) {
    if (name == null) return null;
    try {
      return AuthProvider.values.byName(name);
    } catch (_) {
      return null;
    }
  }

  _Json _user(AuthProvider p) =>
      {'id': 'stub-${p.name}', 'provider': p.name, 'nickname': '${p.label} 사용자'};

  // profile --------------------//

  Future<(int, Object?)> _profile(String method, Object? body) async {
    switch (method) {
      case 'GET':
        final p = _state.profile;
        if (p == null) throw _StubError(404, 'PROFILE_NOT_FOUND', '프로필이 없습니다.');
        return (200, Map<String, dynamic>.of(p));
      case 'PUT':
        final b = body as _Json;
        _state.profile = {'ageGroup': b['ageGroup'], 'monthlyIncome': b['monthlyIncome']};
        await _persist();
        return (200, Map<String, dynamic>.of(_state.profile!));
      case 'DELETE':
        _state.profile = null;
        await _persist();
        return (204, null);
    }
    throw _StubError(404, 'NOT_FOUND', '경로가 없습니다: $method ${ApiPath.profile}');
  }

  // transactions --------------------//

  /// `/v1/things/{id}` 형태 경로에서 id를 뽑는다. 모양이 다르면 null.
  String? _idAfter(String collection, String path) {
    final prefix = '$collection/';
    if (!path.startsWith(prefix)) return null;
    final id = path.substring(prefix.length);
    return id.isEmpty ? null : id;
  }

  List<_Json> _listTx(Map<String, dynamic> query) {
    final from = DateTime.parse(query['from'] as String);
    final to = DateTime.parse(query['to'] as String);
    final rows = _state.transactions.values.where((r) {
      final d = DateTime.parse(r['date'] as String);
      return !d.isBefore(from) && d.isBefore(to);
    }).toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return [for (final r in rows) Map<String, dynamic>.of(r)];
  }

  Future<(int, Object?)> _tx(String method, String id, Object? body) async {
    switch (method) {
      case 'PUT':
        final b = body as _Json;
        final existing = _state.transactions[id];
        final now = DateTime.now().toUtc().toIso8601String();
        final customId = b['customCategoryId'] as String?;
        if (customId != null && !_state.customCategories.containsKey(customId)) {
          throw _StubError(400, 'VALIDATION', '없는 카테고리입니다: $customId');
        }
        final row = <String, dynamic>{
          'id': id,
          'amount': b['amount'],
          'categoryId': b['categoryId'],
          'date': b['date'],
          'type': b['type'],
          'memo': b['memo'],
          'customCategoryId': customId,
          'createdAt': existing?['createdAt'] ?? now,
          'updatedAt': now,
        };
        _state.transactions[id] = row;
        await _persist();
        return (existing == null ? 201 : 200, Map<String, dynamic>.of(row));
      case 'DELETE':
        if (_state.transactions.remove(id) == null) {
          throw _StubError(404, 'NOT_FOUND', '거래가 없습니다: $id');
        }
        await _persist();
        return (204, null);
    }
    throw _StubError(404, 'NOT_FOUND', '경로가 없습니다: $method ${ApiPath.transaction(id)}');
  }

  // categories --------------------//

  List<_Json> _listCategories() =>
      [for (final r in _state.customCategories.values) Map<String, dynamic>.of(r)];

  Future<(int, Object?)> _category(String method, String id, Object? body) async {
    // 기본 분류(1~12)는 계약 상수 — 사용자 카테고리 경로로 만들거나 지울 수 없다.
    if (int.tryParse(id) != null) {
      throw _StubError(403, 'CATEGORY_IMMUTABLE', '기본 카테고리는 수정하거나 삭제할 수 없습니다.');
    }
    switch (method) {
      case 'PUT':
        final b = body as _Json;
        final name = (b['name'] as String?)?.trim() ?? '';
        final baseId = (b['baseCategoryId'] as num?)?.toInt();
        if (name.isEmpty || name.length > CustomCategory.maxNameLength) {
          throw _StubError(
              400, 'VALIDATION', '이름은 1~${CustomCategory.maxNameLength}자여야 합니다.');
        }
        if (baseId == null || baseId < 1 || baseId > 12) {
          throw _StubError(400, 'VALIDATION', '상위 카테고리가 잘못되었습니다.');
        }
        final duplicated = _state.customCategories.entries.any(
          (e) => e.key != id && (e.value['name'] as String).toLowerCase() == name.toLowerCase(),
        );
        if (duplicated) throw _StubError(409, 'CATEGORY_DUPLICATE', '이미 있는 이름입니다: $name');
        final existing = _state.customCategories[id];
        final row = <String, dynamic>{'id': id, 'name': name, 'baseCategoryId': baseId};
        _state.customCategories[id] = row;
        await _persist();
        return (existing == null ? 201 : 200, Map<String, dynamic>.of(row));
      case 'DELETE':
        if (_state.customCategories.remove(id) == null) {
          throw _StubError(404, 'NOT_FOUND', '카테고리가 없습니다: $id');
        }
        // 참조하던 거래는 상위 기본 분류로 되돌린다.
        for (final tx in _state.transactions.values) {
          if (tx['customCategoryId'] == id) tx['customCategoryId'] = null;
        }
        await _persist();
        return (204, null);
    }
    throw _StubError(404, 'NOT_FOUND', '경로가 없습니다: $method ${ApiPath.category(id)}');
  }

  // persistence --------------------//

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final raw = await _store?.load();
    if (raw != null) _state.loadFrom(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _persist() async => _store?.save(jsonEncode(_state.toJson()));
}

class _StubError implements Exception {
  _StubError(this.status, this.code, this.message);

  final int status;
  final String code;
  final String message;
}
