import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../../../contract/contract_target.dart';

/// 계약(경로·상태코드·검증)은 `test/contract/`가 본다. 여기서는 Stub만의 성질을 본다:
/// 기기 저장(재시작), 옛 저장 형식, 저장 실패, 첫 읽기 경쟁, 테스트용 또래 통계.
class _MemStore implements StubStateStore {
  String? saved;
  Completer<void>? loadGate;
  bool failSave = false;

  /// 다음 저장 한 번만 이것을 먼저 기다린다(던지면 그 저장은 실패).
  Future<void> Function()? beforeNextSave;

  @override
  Future<String?> load() async {
    await loadGate?.future;
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

  test('또래 통계는 기본이 고정표이고, 테스트는 나이대별 값을 줄 수 있다', () async {
    final fixed = _client(StubApiInterceptor());
    final token = await fixed.login('kakao');
    final res = await fixed.send('GET', '/v1/peer/stats', query: {'ageGroup': 'thirties'}, token: token);
    expect(res.json['avgMonthlyExpense'], StubPeerData.forGroup(AgeGroup.thirties).avgMonthlyExpense);

    PeerStats flat(AgeGroup g) => PeerStats(
        ageGroup: g, avgMonthlyExpense: 0, avgSavingsRate: 0, avgByCategory: const {}, samples: const []);
    final custom = _client(StubApiInterceptor(peerStats: flat));
    final stats = await custom.send('GET', '/v1/peer/stats', query: {'ageGroup': 'thirties'}, token: token);
    expect(stats.json['avgMonthlyExpense'], 0);
    expect(stats.json['samples'], isEmpty);
    final generations = await custom.send('GET', '/v1/peer/generations', token: token);
    expect(generations.list.every((g) => g['avgMonthlyExpense'] == 0), isTrue);
  });
}
