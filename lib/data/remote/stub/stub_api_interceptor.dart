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
/// - 프로필·거래는 [StubApiState]에 보관하고 [StubStateStore]가 있으면 영속화한다.
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
    final txId = _txId(p);
    if (txId != null) return _tx(m, txId, o.data);
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

  String? _txId(String path) {
    const prefix = '${ApiPath.transactions}/';
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
        final row = <String, dynamic>{
          'id': id,
          'amount': b['amount'],
          'categoryId': b['categoryId'],
          'date': b['date'],
          'type': b['type'],
          'memo': b['memo'],
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
