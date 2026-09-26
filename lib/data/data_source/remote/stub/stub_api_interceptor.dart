import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sedae_budget/data/data_source/local/stub_state_store.dart';
import 'package:sedae_budget/data/data_source/remote/api_path.dart';
import 'package:sedae_budget/data/data_source/remote/stub/stub_api_state.dart';
import 'package:sedae_budget/data/data_source/remote/stub/stub_peer_data.dart';
import 'package:sedae_budget/data/dto/peer_stats_dto.dart';
import 'package:sedae_budget/entity/entity.dart';

typedef _Json = Map<String, dynamic>;

/// 서버 없이 계약(API 계약 v1, `docs/api-contract.md`)대로 응답하는 인프로세스 Stub. 네트워크로 나가지 않는다.
/// 계약을 지키는지는 `test/contract/`가 본다.
///
/// - 인증은 무상태: 토큰 `stub.<provider>`에서 사용자를 복원한다.
/// - 프로필·거래·사용자 카테고리는 [StubApiState]에 사용자별로 보관하고 [StubStateStore]가 있으면 영속화한다.
/// - 실제 서버 응답처럼 뒤따르는 응답·오류 인터셉터를 거친다(토큰 인터셉터가 401을 본다).
/// - 기기에 저장하지 못했거나 Stub 자신의 결함이면 500이다(앱에 '인터넷 연결 없음'으로 보이지 않게).
///   저장하지 못한 변경은 메모리에도 남기지 않는다.
/// - 요청은 온 순서대로 하나씩 처리한다. 한 요청의 변경·저장·되돌리기가 다른 요청과 섞이지 않는다.
/// - 또래 통계는 [peerStats]가 정한다. 기본은 [StubPeerData](결정적)이고, 테스트는 나이대별 값을 줄 수 있다.
class StubApiInterceptor extends Interceptor {
  StubApiInterceptor({StubStateStore? store, PeerStats Function(AgeGroup)? peerStats})
      : _store = store,
        _peerStats = peerStats ?? StubPeerData.forGroup;

  static const _tokenPrefix = 'stub.';

  final StubStateStore? _store;
  final PeerStats Function(AgeGroup) _peerStats;
  final StubApiState _state = StubApiState();

  /// 기기 저장소 읽기. 처음 온 요청이 시작하고, 읽는 동안 온 요청도 같은 읽기를 기다린다.
  Future<void>? _loading;

  /// 앞 요청의 처리. 다음 요청은 이것이 끝난 뒤에 시작한다.
  Future<void> _previous = Future.value();

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final turn = _previous.then((_) => _handle(options, handler));
    // 한 요청이 어쩌다 던져도(핸들러를 두 번 부르는 결함 등) 다음 요청들이 멈추지 않게 한다.
    _previous = turn.catchError((Object _) {});
    return turn;
  }

  /// 요청 하나를 처리한다. 모든 실패를 응답으로 바꾸므로 던지지 않는다.
  Future<void> _handle(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      await _ensureLoaded();
      final (status, body) = await _route(options);
      handler.resolve(Response(requestOptions: options, statusCode: status, data: body), true);
    } on _StubError catch (e) {
      handler.reject(_error(options, e.status, e.code, e.message), true);
    } catch (e) {
      handler.reject(_error(options, 500, 'INTERNAL', 'Stub 서버 오류: $e'), true);
    }
  }

  DioException _error(RequestOptions options, int status, String code, String message) => DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: options, statusCode: status, data: {'code': code, 'message': message}),
      );

  Future<(int, Object?)> _route(RequestOptions o) async {
    final m = o.method, p = o.path;
    if (m == 'POST' && p == ApiPath.login) return (200, _login(_bodyOf(o.data)));

    final provider = _authed(o); // 이하 전부 Bearer 필수
    final db = _state.of(provider.name); // 로그인한 사용자의 데이터만 본다
    if (m == 'POST' && p == ApiPath.logout) return (204, null);
    if (m == 'GET' && p == ApiPath.me) return (200, _user(provider));
    if (p == ApiPath.profile) return _profile(db, m, o.data);
    if (m == 'GET' && p == ApiPath.transactions) return (200, _listTx(db, o.queryParameters));
    final txId = _idAfter(ApiPath.transactions, p);
    if (txId != null) return _tx(db, m, txId, o.data);
    if (m == 'GET' && p == ApiPath.categories) return (200, _listCategories(db));
    final catId = _idAfter(ApiPath.categories, p);
    if (catId != null) return _category(db, m, catId, o.data);
    if (m == 'GET' && p == ApiPath.peerStats) {
      final g = _enumOrNull(AgeGroup.values, o.queryParameters['ageGroup']);
      if (g == null) throw _StubError(400, 'VALIDATION', 'ageGroup이 잘못되었습니다.');
      return (200, PeerStatsDto.fromEntity(_peerStats(g)).toJson());
    }
    if (m == 'GET' && p == ApiPath.peerGenerations) {
      return (
        200,
        [
          for (final g in AgeGroup.values)
            {'ageGroup': g.name, 'avgMonthlyExpense': _peerStats(g).avgMonthlyExpense},
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

  AuthProvider? _providerOrNull(String? name) => _enumOrNull(AuthProvider.values, name);

  /// [values] 중 이름이 [name]인 값. 없거나 문자열이 아니면 null.
  T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }

  _Json _user(AuthProvider p) =>
      {'id': 'stub-${p.name}', 'provider': p.name, 'nickname': '${p.label} 사용자'};

  // profile --------------------//

  Future<(int, Object?)> _profile(StubUserData db, String method, Object? body) async {
    switch (method) {
      case 'GET':
        final p = db.profile;
        if (p == null) throw _StubError(404, 'PROFILE_NOT_FOUND', '프로필이 없습니다.');
        return (200, Map<String, dynamic>.of(p));
      case 'PUT':
        final b = _bodyOf(body);
        final income = b['monthlyIncome'];
        if (_enumOrNull(AgeGroup.values, b['ageGroup']) == null) {
          throw _StubError(400, 'VALIDATION', 'ageGroup이 잘못되었습니다.');
        }
        if (income is! int || income < 0) throw _StubError(400, 'VALIDATION', 'monthlyIncome은 0 이상 정수입니다.');
        await _commit(db, () => db.profile = {'ageGroup': b['ageGroup'], 'monthlyIncome': income});
        return (200, Map<String, dynamic>.of(db.profile!));
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

  List<_Json> _listTx(StubUserData db, Map<String, dynamic> query) {
    final from = _utcOrNull(query['from']);
    final to = _utcOrNull(query['to']);
    if (from == null || to == null) throw _StubError(400, 'VALIDATION', 'from·to(UTC)가 필요합니다.');
    final rows = db.transactions.values.where((r) {
      final d = DateTime.parse(r['date'] as String);
      return !d.isBefore(from) && d.isBefore(to);
    }).toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
    return [for (final r in rows) Map<String, dynamic>.of(r)];
  }

  Future<(int, Object?)> _tx(StubUserData db, String method, String id, Object? body) async {
    switch (method) {
      case 'PUT':
        final b = _bodyOf(body);
        _validateTransaction(b);
        final existing = db.transactions[id];
        final now = DateTime.now().toUtc().toIso8601String();
        final customId = b['customCategoryId'] as String?;
        final custom = customId == null ? null : db.customCategories[customId];
        if (customId != null && custom == null) {
          throw _StubError(400, 'VALIDATION', '없는 카테고리입니다: $customId');
        }
        final row = <String, dynamic>{
          'id': id,
          'amount': b['amount'],
          // 사용자 카테고리 거래의 기본 분류는 그 카테고리의 상위 분류다(또래 비교 집계 기준).
          'categoryId': custom?['baseCategoryId'] ?? b['categoryId'],
          'date': b['date'],
          'type': b['type'],
          'memo': b['memo'],
          'customCategoryId': customId,
          'createdAt': existing?['createdAt'] ?? now,
          'updatedAt': now,
        };
        await _commit(db, () => db.transactions[id] = row);
        return (existing == null ? 201 : 200, Map<String, dynamic>.of(row));
      case 'DELETE':
        if (!db.transactions.containsKey(id)) throw _StubError(404, 'NOT_FOUND', '거래가 없습니다: $id');
        await _commit(db, () => db.transactions.remove(id));
        return (204, null);
    }
    throw _StubError(404, 'NOT_FOUND', '경로가 없습니다: $method ${ApiPath.transaction(id)}');
  }

  // categories --------------------//

  List<_Json> _listCategories(StubUserData db) =>
      [for (final r in db.customCategories.values) Map<String, dynamic>.of(r)];

  Future<(int, Object?)> _category(StubUserData db, String method, String id, Object? body) async {
    // 기본 분류(1~12)는 계약 상수 — 사용자 카테고리 경로로 만들거나 지울 수 없다.
    if (int.tryParse(id) != null) {
      throw _StubError(403, 'CATEGORY_IMMUTABLE', '기본 카테고리는 수정하거나 삭제할 수 없습니다.');
    }
    switch (method) {
      case 'PUT':
        final b = _bodyOf(body);
        final rawName = b['name'];
        final name = rawName is String ? rawName.trim() : '';
        final rawBase = b['baseCategoryId'];
        final baseId = rawBase is int ? rawBase : null;
        if (name.isEmpty || name.length > CustomCategory.maxNameLength) {
          throw _StubError(
              400, 'VALIDATION', '이름은 1~${CustomCategory.maxNameLength}자여야 합니다.');
        }
        if (baseId == null || baseId < 1 || baseId > 12) {
          throw _StubError(400, 'VALIDATION', '상위 카테고리가 잘못되었습니다.');
        }
        final duplicated = db.customCategories.entries.any(
          (e) => e.key != id && (e.value['name'] as String).toLowerCase() == name.toLowerCase(),
        );
        if (duplicated) throw _StubError(409, 'CATEGORY_DUPLICATE', '이미 있는 이름입니다: $name');
        final existing = db.customCategories[id];
        final row = <String, dynamic>{'id': id, 'name': name, 'baseCategoryId': baseId};
        await _commit(db, () {
          db.customCategories[id] = row;
          // 상위 분류를 바꾸면 이 카테고리로 기록한 거래도 새 분류로 옮긴다.
          for (final tx in db.transactions.values) {
            if (tx['customCategoryId'] == id) tx['categoryId'] = baseId;
          }
        });
        return (existing == null ? 201 : 200, Map<String, dynamic>.of(row));
      case 'DELETE':
        if (!db.customCategories.containsKey(id)) throw _StubError(404, 'NOT_FOUND', '카테고리가 없습니다: $id');
        await _commit(db, () {
          db.customCategories.remove(id);
          // 참조하던 거래는 상위 기본 분류로 되돌린다.
          for (final tx in db.transactions.values) {
            if (tx['customCategoryId'] == id) tx['customCategoryId'] = null;
          }
        });
        return (204, null);
    }
    throw _StubError(404, 'NOT_FOUND', '경로가 없습니다: $method ${ApiPath.category(id)}');
  }

  // validation --------------------//

  _Json _bodyOf(Object? body) =>
      body is _Json ? body : throw _StubError(400, 'VALIDATION', 'JSON 객체 바디가 필요합니다.');

  DateTime? _utcOrNull(Object? value) {
    final d = value is String ? DateTime.tryParse(value) : null;
    return d != null && d.isUtc ? d : null;
  }

  /// 계약의 거래 규칙. 수입은 카테고리가 없으므로 categoryId는 정수이기만 하면 된다.
  void _validateTransaction(_Json b) {
    final amount = b['amount'], categoryId = b['categoryId'], memo = b['memo'], customId = b['customCategoryId'];
    final type = _enumOrNull(TransactionType.values, b['type']);
    String? problem;
    if (amount is! int || amount < 1) {
      problem = 'amount는 1 이상 정수입니다.';
    } else if (type == null) {
      problem = 'type은 expense 또는 income입니다.';
    } else if (categoryId is! int ||
        (type == TransactionType.expense && BudgetCategory.tryFromId(categoryId) == null)) {
      problem = '지출의 categoryId는 1~12입니다.';
    } else if (_utcOrNull(b['date']) == null) {
      problem = 'date는 ISO-8601 UTC입니다.';
    } else if (memo != null && memo is! String) {
      problem = 'memo는 문자열입니다.';
    } else if (customId != null && customId is! String) {
      problem = 'customCategoryId는 문자열입니다.';
    }
    if (problem != null) throw _StubError(400, 'VALIDATION', problem);
  }

  // persistence --------------------//

  Future<void> _ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = await _store?.load();
      if (raw != null) _state.loadFrom(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _loading = null; // 다음 요청이 다시 읽는다
      rethrow;
    }
  }

  /// [db]를 [change]로 바꾸고 기기에 저장한다. 저장하지 못하면 바꾸기 전으로 되돌리고 던진다.
  Future<void> _commit(StubUserData db, void Function() change) async {
    final before = jsonEncode(db.toJson());
    change();
    try {
      await _store?.save(jsonEncode(_state.toJson()));
    } catch (_) {
      db.loadFrom(jsonDecode(before) as Map<String, dynamic>);
      rethrow;
    }
  }
}

class _StubError implements Exception {
  _StubError(this.status, this.code, this.message);

  final int status;
  final String code;
  final String message;
}
