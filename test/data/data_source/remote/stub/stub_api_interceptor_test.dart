import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../../../contract/contract_target.dart';

/// 계약(경로·상태코드·검증)은 `test/contract/`가 본다. 여기서는 Stub만의 성질을 본다:
/// 기기 저장(재시작), 옛 저장 형식, 저장 실패, 첫 읽기 경쟁, 거래 목록 정렬, 테스트용 또래 통계.
class _MemStore implements StubStateStore {
  String? saved;
  Completer<void>? loadGate;
  bool failSave = false;

  /// 이만큼의 읽기가 던진다(기기 저장소 고장).
  int failLoads = 0;

  /// 다음 저장 한 번만 이것을 먼저 기다린다(던지면 그 저장은 실패).
  Future<void> Function()? beforeNextSave;

  @override
  Future<String?> load() async {
    await loadGate?.future;
    if (failLoads > 0) {
      failLoads--;
      throw StateError('disk read');
    }
    return saved;
  }

  @override
  Future<void> save(String json) async {
    final hook = beforeNextSave;
    beforeNextSave = null;
    await hook?.call();
    if (failSave) throw StateError('disk full');
    saved = json;
  }
}

/// [stub]을 서버로 쓰는 계약 클라이언트.
ContractClient _client(StubApiInterceptor stub) =>
    ContractClient(ContractTarget(dio: Dio(BaseOptions(contentType: 'application/json'))..interceptors.add(stub)));

const _september = {'from': '2026-09-01T00:00:00.000Z', 'to': '2026-10-01T00:00:00.000Z'};

const _tx = {
  'amount': 5, 'categoryId': 2, 'date': '2026-09-03T00:00:00.000Z', 'type': 'income', 'memo': 'm',
};

void main() {
  test('다시 켜도(같은 저장소로 새 Stub) 프로필·거래·사용자 카테고리가 남아 있다', () async {
    final store = _MemStore();
    final before = _client(StubApiInterceptor(store: store));
    final token = await before.login('kakao');
    await before.send('PUT', '/v1/me/profile', body: {'ageGroup': 'forties', 'monthlyIncome': 1}, token: token);
    await before.send('PUT', '/v1/transactions/z', body: _tx, token: token);
    await before.send('PUT', '/v1/categories/c1', body: {'name': '반려동물', 'baseCategoryId': 12}, token: token);

    final after = _client(StubApiInterceptor(store: store));
    expect((await after.send('GET', '/v1/me/profile', token: token)).json['ageGroup'], 'forties');
    expect((await after.send('GET', '/v1/transactions', query: _september, token: token)).list.single['memo'], 'm');
    expect((await after.send('GET', '/v1/categories', token: token)).list.single['name'], '반려동물');
  });

  test('로그아웃한 토큰은 다시 켜도 거부하고, 저장하지 못한 로그아웃은 500이며 토큰도 그대로다', () async {
    final store = _MemStore();
    final before = _client(StubApiInterceptor(store: store));
    final out = await before.login('kakao');
    final kept = await before.login('kakao');
    await before.send('POST', '/v1/auth/logout', token: out);

    final after = _client(StubApiInterceptor(store: store));
    expect((await after.send('GET', '/v1/me', token: out)).status, 401);
    expect((await after.send('GET', '/v1/me', token: kept)).status, 200);

    store.failSave = true;
    expect((await after.send('POST', '/v1/auth/logout', token: kept)).status, 500);
    expect((await after.send('GET', '/v1/me', token: kept)).status, 200);
  });

  // 준 토큰만 받는다. 로그인마다 새 토큰을 주기 전에 저장된 예전 형식 토큰도 준 적 없는 토큰이라, 한 번
  // 만료로 끝나고 다시 로그인하면 된다(데이터는 사용자별로 남아 있다).
  test('준 적 없는 토큰은 예전 형식(stub.<provider>)이어도 401이고, 다시 로그인하면 데이터가 그대로다', () async {
    final store = _MemStore();
    final before = _client(StubApiInterceptor(store: store));
    final token = await before.login('kakao');
    await before.send('PUT', '/v1/me/profile', body: {'ageGroup': 'forties', 'monthlyIncome': 1}, token: token);

    final after = _client(StubApiInterceptor(store: store));
    expect((await after.send('GET', '/v1/me', token: 'stub.kakao')).status, 401);
    final again = await after.login('kakao');
    expect((await after.send('GET', '/v1/me/profile', token: again)).json['ageGroup'], 'forties');
  });

  test('사용자별로 나누기 전 형식으로 저장된 상태는 버린다', () async {
    final store = _MemStore()
      ..saved = jsonEncode({
        'profile': {'ageGroup': 'forties', 'monthlyIncome': 1},
        'transactions': <String, dynamic>{},
        'customCategories': <String, dynamic>{},
      });
    final api = _client(StubApiInterceptor(store: store));
    final token = await api.login('kakao');
    expect((await api.send('GET', '/v1/me/profile', token: token)).status, 404);
  });

  group('저장 형식', () {
    Map<String, dynamic> row(String id, {String date = '2026-09-03T00:00:00.000Z'}) =>
        {..._tx, 'id': id, 'date': date, 'customCategoryId': null, 'createdAt': date, 'updatedAt': date};

    test('저장할 때 형식 버전을 적는다', () async {
      final store = _MemStore();
      await _client(StubApiInterceptor(store: store)).login('kakao');
      expect((jsonDecode(store.saved!) as Map<String, dynamic>)['version'], StubApiState.version);
    });

    test('버전을 적기 전에 저장한 지금 형식(users 있음)은 그대로 읽는다', () async {
      const token = 'stub.kakao.saved';
      final store = _MemStore()
        ..saved = jsonEncode({
          'users': {
            'kakao': {
              'profile': {'ageGroup': 'forties', 'monthlyIncome': 1},
              'transactions': {'t1': row('t1')},
              'customCategories': {
                'c1': {'id': 'c1', 'name': '반려동물', 'baseCategoryId': 12},
              },
            },
          },
          'activeTokens': [token],
        });
      final api = _client(StubApiInterceptor(store: store));
      expect((await api.send('GET', '/v1/me/profile', token: token)).json['ageGroup'], 'forties');
      expect((await api.send('GET', '/v1/transactions', query: _september, token: token)).list.single['id'], 't1');
      expect((await api.send('GET', '/v1/categories', token: token)).list.single['id'], 'c1');
    });

    test('모르는 버전은 읽지 않고 빈 상태로 시작한다', () async {
      final store = _MemStore()
        ..saved = jsonEncode({
          'version': StubApiState.version + 1,
          'users': {
            'kakao': {'profile': {'ageGroup': 'forties', 'monthlyIncome': 1}},
          },
        });
      final api = _client(StubApiInterceptor(store: store));
      final token = await api.login('kakao');
      expect((await api.send('GET', '/v1/me/profile', token: token)).status, 404);
    });

    // 이전에는 저장된 상태를 검사 없이 읽어, 형식이 한 번 어긋나면 모든 요청이 500이었다.
    // release 빌드도 Stub을 쓰므로 앱이 '연결 안 됨'에 갇히고, 다시 시도해도 같은 데이터를 다시 읽었다.
    test('JSON이 아닌 저장 상태는 빈 상태로 시작한다', () async {
      final api = _client(StubApiInterceptor(store: _MemStore()..saved = '{oops'));
      expect((await api.send('POST', '/v1/auth/login', body: {'provider': 'kakao', 'idToken': 't'})).status, 200);
    });

    test('못 읽는 부분만 버리고 나머지는 살린다', () async {
      final store = _MemStore()
        ..saved = jsonEncode({
          'version': StubApiState.version,
          'users': {
            'kakao': {
              'profile': {'ageGroup': 'forties', 'monthlyIncome': 1},
              'transactions': {'t1': row('t1'), 't2': 'oops', 't3': row('t3', date: 'yesterday')},
              'customCategories': {
                'c1': {'id': 'c1', 'name': '반려동물', 'baseCategoryId': 12},
                'c2': {'id': 'c2', 'name': 3, 'baseCategoryId': 12},
              },
            },
            'naver': {'transactions': <dynamic>[]},
            'google': 'oops',
          },
          'activeTokens': [1, 'x'],
        });
      final api = _client(StubApiInterceptor(store: store));

      final kakao = await api.login('kakao');
      expect((await api.send('GET', '/v1/me/profile', token: kakao)).json['ageGroup'], 'forties');
      expect([for (final r in (await api.send('GET', '/v1/transactions', query: _september, token: kakao)).list) r['id']],
          ['t1']);
      expect([for (final r in (await api.send('GET', '/v1/categories', token: kakao)).list) r['id']], ['c1']);

      final naver = await api.login('naver');
      expect((await api.send('GET', '/v1/transactions', query: _september, token: naver)).list, isEmpty);
      final google = await api.login('google');
      expect((await api.send('GET', '/v1/me/profile', token: google)).status, 404);
    });

    // 기기 저장소를 읽지 못한 것은 잠깐의 실패일 수 있다. 버리지 않고 다음 요청이 다시 읽는다.
    test('기기 저장소를 읽지 못하면 500이고 다음 요청이 다시 읽는다', () async {
      final store = _MemStore()
        ..saved = jsonEncode({
          'version': StubApiState.version,
          'users': {
            'kakao': {'profile': {'ageGroup': 'forties', 'monthlyIncome': 1}},
          },
        })
        ..failLoads = 1;
      final api = _client(StubApiInterceptor(store: store));
      expect((await api.send('POST', '/v1/auth/login', body: {'provider': 'kakao', 'idToken': 't'})).status, 500);

      final token = await api.login('kakao');
      expect((await api.send('GET', '/v1/me/profile', token: token)).json['ageGroup'], 'forties');
    });
  });

  // 저장에 실패했는데 목록에 남으면, 앱을 다시 켰을 때 사라지는 거래를 보여주게 된다.
  test('기기에 저장하지 못하면 500이고 바뀐 것이 없다', () async {
    final store = _MemStore();
    final api = _client(StubApiInterceptor(store: store));
    final token = await api.login('kakao');
    await api.send('PUT', '/v1/categories/c1', body: {'name': '반려동물', 'baseCategoryId': 12}, token: token);
    await api.send('PUT', '/v1/transactions/t1',
        body: {..._tx, 'type': 'expense', 'categoryId': 12, 'customCategoryId': 'c1'}, token: token);

    store.failSave = true;
    final put = await api.send('PUT', '/v1/transactions/t2', body: _tx, token: token);
    final delete = await api.send('DELETE', '/v1/categories/c1', token: token);

    expect(put.status, 500);
    expect(put.code, isNotNull);
    expect(delete.status, 500);
    final txs = (await api.send('GET', '/v1/transactions', query: _september, token: token)).list;
    expect(txs.map((t) => t['id']), ['t1']);
    expect(txs.single['customCategoryId'], 'c1'); // 삭제의 연쇄(거래에서 떼기)도 되돌린다
    expect((await api.send('GET', '/v1/categories', token: token)).list, hasLength(1));
  });

  // 쓰기 둘이 겹치면, 먼저 온 쓰기의 저장 실패가 되돌리면서 나중 쓰기의 성공까지 지우거나,
  // 늦게 끝난 저장이 더 오래된 상태로 덮어쓸 수 있었다. 요청은 하나씩 처리한다.
  test('겹친 쓰기는 하나씩 처리한다: 한 쓰기의 실패가 다른 쓰기를 지우지 않는다', () async {
    final store = _MemStore();
    final api = _client(StubApiInterceptor(store: store));
    final token = await api.login('kakao');
    final gate = Completer<void>();
    store.beforeNextSave = () async {
      await gate.future;
      throw StateError('disk full');
    };

    final first = api.send('PUT', '/v1/transactions/a', body: _tx, token: token);
    final second = api.send('PUT', '/v1/transactions/b', body: _tx, token: token);
    await Future<void>.delayed(const Duration(milliseconds: 20)); // 둘 다 Stub에 닿을 때까지
    gate.complete();

    expect((await first).status, 500);
    expect((await second).status, 201);
    final listed = await api.send('GET', '/v1/transactions', query: _september, token: token);
    expect(listed.list.map((t) => t['id']), ['b']);
    final reopened = _client(StubApiInterceptor(store: store));
    final persisted = await reopened.send('GET', '/v1/transactions', query: _september, token: token);
    expect(persisted.list.map((t) => t['id']), ['b']);
  });

  // 콜드 스타트에 요청 둘이 겹치면, 두 번째가 빈 상태를 보고 '프로필 없음'이 되거나
  // 첫 쓰기가 읽어 들인 상태에 덮여 사라졌다.
  test('기기 저장소를 읽는 중에 온 요청도 읽은 상태를 본다', () async {
    final seeded = _MemStore();
    final seed = _client(StubApiInterceptor(store: seeded));
    final token = await seed.login('kakao');
    await seed.send('PUT', '/v1/me/profile', body: {'ageGroup': 'forties', 'monthlyIncome': 1}, token: token);

    final store = _MemStore()
      ..saved = seeded.saved
      ..loadGate = Completer<void>();
    final api = _client(StubApiInterceptor(store: store));
    final first = api.send('GET', '/v1/me/profile', token: token);
    final write = api.send('PUT', '/v1/transactions/z', body: _tx, token: token);
    final second = api.send('GET', '/v1/me/profile', token: token);
    await Future<void>.delayed(const Duration(milliseconds: 20)); // 세 요청이 모두 Stub에 닿을 때까지
    store.loadGate!.complete();

    expect((await first).status, 200);
    expect((await second).status, 200);
    expect((await write).status, 201);
    final reopened = _client(StubApiInterceptor(store: store));
    expect((await reopened.send('GET', '/v1/transactions', query: _september, token: token)).list, hasLength(1));
    expect((await reopened.send('GET', '/v1/me/profile', token: token)).status, 200);
  });

  // 계약은 날짜 최신순만 정한다. Stub은 문자열이 아니라 시각으로 정렬한다(소수 초 자릿수가 달라도).
  test('거래 목록은 시각 순서다: 소수 초 자릿수가 달라도 늦은 시각이 먼저다', () async {
    final api = _client(StubApiInterceptor());
    final token = await api.login('kakao');
    await api.send('PUT', '/v1/transactions/a', body: {..._tx, 'date': '2026-09-10T00:00:00Z'}, token: token);
    await api.send('PUT', '/v1/transactions/b', body: {..._tx, 'date': '2026-09-10T00:00:00.500Z'}, token: token);
    final listed = await api.send('GET', '/v1/transactions', query: _september, token: token);
    expect(listed.list.map((t) => t['id']), ['b', 'a']);
  });

  test('또래 통계는 기본이 고정표이고, 테스트는 나이대별 값을 줄 수 있다', () async {
    final fixed = _client(StubApiInterceptor());
    final token = await fixed.login('kakao');
    final res = await fixed.send('GET', '/v1/peer/stats', query: {'ageGroup': 'thirties'}, token: token);
    expect(res.json['avgMonthlyExpense'], StubPeerData.forGroup(AgeGroup.thirties).avgMonthlyExpense);

    PeerStats flat(AgeGroup g) => PeerStats(
        ageGroup: g, avgMonthlyExpense: 0, avgSavingsRate: 0, avgByCategory: const {}, samples: const []);
    final custom = _client(StubApiInterceptor(peerStats: flat));
    final customToken = await custom.login('kakao');
    final stats = await custom.send('GET', '/v1/peer/stats', query: {'ageGroup': 'thirties'}, token: customToken);
    expect(stats.json['avgMonthlyExpense'], 0);
    expect(stats.json['samples'], isEmpty);
    final generations = await custom.send('GET', '/v1/peer/generations', token: customToken);
    expect(generations.list.every((g) => g['avgMonthlyExpense'] == 0), isTrue);
  });
}
