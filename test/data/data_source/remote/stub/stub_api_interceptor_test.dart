import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../../../helper/stub_server.dart';
import '../../../../helper/test_api_client.dart';

class _MemStore implements StubStateStore {
  String? saved;
  @override
  Future<String?> load() async => saved;
  @override
  Future<void> save(String json) async => saved = json;
}

const _range = {'from': '2026-09-01T00:00:00.000Z', 'to': '2026-10-01T00:00:00.000Z'};

/// [user]로 로그인한 Stub 서버의 API. 같은 [store]를 주면 앱 재시작을 흉내 낸다.
TestApiClient _client(String user, {StubStateStore? store}) =>
    (StubServer(store: store)..tokens.token = 'stub.$user').api;

void main() {
  late MemoryAuthTokenStore tokens;
  late TestApiClient api;

  setUp(() {
    final server = StubServer();
    tokens = server.tokens;
    api = server.api;
  });

  Future<void> putTx(String id, String date) => api.put<Map<String, dynamic>>(
        ApiPath.transaction(id),
        body: {'amount': 1000, 'categoryId': 1, 'date': date, 'type': 'expense', 'memo': null},
      );

  test('login → token, me → same user; me without token → 401', () async {
    expect(
      () => api.get<Map<String, dynamic>>(ApiPath.me),
      throwsA(isA<HttpFailure>().having((e) => e.statusCode, 'status', 401)),
    );
    final res = await api.post<Map<String, dynamic>>(
      ApiPath.login,
      body: {'provider': 'kakao', 'idToken': 'x'},
    );
    tokens.token = res['accessToken'] as String;
    expect((res['user'] as Map)['nickname'], '카카오 사용자');

    final me = await api.get<Map<String, dynamic>>(ApiPath.me);
    expect(me['provider'], 'kakao');
    expect(me['nickname'], '카카오 사용자');
    expect(me['id'], isNotEmpty);
  });

  test('login without idToken → 400 VALIDATION', () async {
    expect(
      () => api.post<Map<String, dynamic>>(ApiPath.login, body: {'provider': 'kakao'}),
      throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'VALIDATION')),
    );
  });

  test('garbage token → 401 AUTH_004', () async {
    tokens.token = 'garbage';
    expect(
      () => api.get<Map<String, dynamic>>(ApiPath.me),
      throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'AUTH_004')),
    );
  });

  test('logout → 204', () async {
    tokens.token = 'stub.kakao';
    await api.post<dynamic>(ApiPath.logout);
  });

  test('profile 404 → put → get', () async {
    tokens.token = 'stub.kakao';
    expect(
      () => api.get<Map<String, dynamic>>(ApiPath.profile),
      throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'PROFILE_NOT_FOUND')),
    );
    await api.put<Map<String, dynamic>>(
      ApiPath.profile,
      body: {'ageGroup': 'thirties', 'monthlyIncome': 3000000},
    );
    final got = await api.get<Map<String, dynamic>>(ApiPath.profile);
    expect(got['monthlyIncome'], 3000000);
    expect(got['ageGroup'], 'thirties');
  });

  test('transactions: put → list in range, desc → delete → empty', () async {
    tokens.token = 'stub.kakao';
    await putTx('a', '2026-09-01T00:00:00.000Z');
    await putTx('b', '2026-09-10T00:00:00.000Z');
    await putTx('c', '2026-10-01T00:00:00.000Z'); // to는 배타 → 범위 밖

    final list = await api.get<List<dynamic>>(ApiPath.transactions, query: _range);
    expect(list.map((e) => e['id']), ['b', 'a']);
    expect(list.first['createdAt'], isNotNull);
    expect(list.first['updatedAt'], isNotNull);

    await api.delete(ApiPath.transaction('a'));
    await api.delete(ApiPath.transaction('b'));
    expect(await api.get<List<dynamic>>(ApiPath.transactions, query: _range), isEmpty);
  });

  test('put keeps createdAt on update; delete unknown → 404', () async {
    tokens.token = 'stub.kakao';
    await putTx('a', '2026-09-01T00:00:00.000Z');
    final first = (await api.get<List<dynamic>>(ApiPath.transactions, query: _range)).single;
    await putTx('a', '2026-09-02T00:00:00.000Z');
    final second = (await api.get<List<dynamic>>(ApiPath.transactions, query: _range)).single;
    expect(second['createdAt'], first['createdAt']);
    expect(second['date'], '2026-09-02T00:00:00.000Z');
    expect(
      () => api.delete(ApiPath.transaction('nope')),
      throwsA(isA<HttpFailure>().having((e) => e.isNotFound, 'notFound', isTrue)),
    );
  });

  test('peer stats matches StubPeerData; generations has 5 groups', () async {
    tokens.token = 'stub.kakao';
    final json = await api.get<Map<String, dynamic>>(
      ApiPath.peerStats,
      query: {'ageGroup': 'thirties'},
    );
    final expected = StubPeerData.forGroup(AgeGroup.thirties);
    expect(json['avgMonthlyExpense'], expected.avgMonthlyExpense);
    expect((json['samples'] as List).length, expected.samples.length);

    final gens = await api.get<List<dynamic>>(ApiPath.peerGenerations);
    expect(gens.length, AgeGroup.values.length);
    expect(gens.first['ageGroup'], 'teens');
  });

  group('categories', () {
    Future<Map<String, dynamic>> putCat(String id, String name, int baseId) =>
        api.put<Map<String, dynamic>>(
          ApiPath.category(id),
          body: {'name': name, 'baseCategoryId': baseId},
        );

    setUp(() => tokens.token = 'stub.kakao');

    test('empty → put(201) → list in creation order → put(200) updates', () async {
      expect(await api.get<List<dynamic>>(ApiPath.categories), isEmpty);
      await putCat('c1', '반려동물', 12);
      await putCat('c2', '자기계발', 9);
      final list = await api.get<List<dynamic>>(ApiPath.categories);
      expect(list.map((e) => e['name']), ['반려동물', '자기계발']);
      expect(list.first['baseCategoryId'], 12);

      await putCat('c1', '댕댕이', 12);
      final after = await api.get<List<dynamic>>(ApiPath.categories);
      expect(after.map((e) => e['name']), ['댕댕이', '자기계발']);
    });

    test('기본 카테고리 id는 수정·삭제 불가 → 403 CATEGORY_IMMUTABLE', () async {
      expect(
        () => putCat('12', '기타 바꾸기', 12),
        throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'CATEGORY_IMMUTABLE')),
      );
      expect(
        () => api.delete(ApiPath.category('1')),
        throwsA(isA<HttpFailure>()
            .having((e) => e.code, 'code', 'CATEGORY_IMMUTABLE')
            .having((e) => e.statusCode, 'status', 403)),
      );
    });

    test('name/baseCategoryId validation → 400 VALIDATION', () async {
      expect(
        () => putCat('c1', '   ', 12),
        throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'VALIDATION')),
      );
      expect(
        () => putCat('c1', 'a' * (CustomCategory.maxNameLength + 1), 12),
        throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'VALIDATION')),
      );
      expect(
        () => putCat('c1', '반려동물', 13),
        throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'VALIDATION')),
      );
    });

    test('duplicate name → 409 CATEGORY_DUPLICATE (같은 id 갱신은 허용)', () async {
      await putCat('c1', '반려동물', 12);
      expect(
        () => putCat('c2', '반려동물', 9),
        throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'CATEGORY_DUPLICATE')),
      );
      await putCat('c1', '반려동물', 9); // 자기 자신은 중복이 아니다
    });

    test('transaction with unknown customCategoryId → 400', () async {
      expect(
        () => api.put<Map<String, dynamic>>(ApiPath.transaction('t1'), body: {
          'amount': 1000, 'categoryId': 12, 'date': '2026-09-02T00:00:00.000Z',
          'type': 'expense', 'memo': null, 'customCategoryId': 'nope',
        }),
        throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'VALIDATION')),
      );
    });

    test('delete → 204, 참조하던 거래는 상위 기본 분류로 되돌아간다', () async {
      await putCat('c1', '반려동물', 12);
      await api.put<Map<String, dynamic>>(ApiPath.transaction('t1'), body: {
        'amount': 1000, 'categoryId': 12, 'date': '2026-09-02T00:00:00.000Z',
        'type': 'expense', 'memo': null, 'customCategoryId': 'c1',
      });
      expect(
        (await api.get<List<dynamic>>(ApiPath.transactions, query: _range))
            .single['customCategoryId'],
        'c1',
      );

      await api.delete(ApiPath.category('c1'));
      expect(await api.get<List<dynamic>>(ApiPath.categories), isEmpty);
      final tx = (await api.get<List<dynamic>>(ApiPath.transactions, query: _range)).single;
      expect(tx['customCategoryId'], isNull);
      expect(tx['categoryId'], 12); // 상위 기본 분류는 그대로 → 또래 비교 집계 유지
      expect(
        () => api.delete(ApiPath.category('c1')),
        throwsA(isA<HttpFailure>().having((e) => e.isNotFound, 'notFound', isTrue)),
      );
    });

    test('거래를 저장하면 기본 분류를 사용자 카테고리의 상위 분류에 맞춘다', () async {
      await putCat('c1', '반려동물', 12);
      final saved = await api.put<Map<String, dynamic>>(ApiPath.transaction('t1'), body: {
        'amount': 1000, 'categoryId': 1, 'date': '2026-09-02T00:00:00.000Z',
        'type': 'expense', 'memo': null, 'customCategoryId': 'c1',
      });
      expect(saved['categoryId'], 12);
      final listed = (await api.get<List<dynamic>>(ApiPath.transactions, query: _range)).single;
      expect(listed['categoryId'], 12);
    });

    test('상위 분류를 바꾸면 그 카테고리의 거래도 새 분류로 옮겨진다', () async {
      await putCat('c1', '반려동물', 12);
      await api.put<Map<String, dynamic>>(ApiPath.transaction('t1'), body: {
        'amount': 1000, 'categoryId': 12, 'date': '2026-09-02T00:00:00.000Z',
        'type': 'expense', 'memo': null, 'customCategoryId': 'c1',
      });
      await api.put<Map<String, dynamic>>(ApiPath.transaction('t2'), body: {
        'amount': 2000, 'categoryId': 12, 'date': '2026-09-03T00:00:00.000Z',
        'type': 'expense', 'memo': null,
      });

      await putCat('c1', '반려동물', 9);

      final txs = await api.get<List<dynamic>>(ApiPath.transactions, query: _range);
      final byId = {for (final t in txs) t['id']: t};
      expect(byId['t1']['categoryId'], 9);
      expect(byId['t1']['customCategoryId'], 'c1');
      expect(byId['t2']['categoryId'], 12); // 사용자 카테고리가 아닌 거래는 그대로
    });

    test('카테고리도 StubStateStore로 영속화된다', () async {
      final store = _MemStore();
      final api1 = _client('kakao', store: store);
      await api1.put<Map<String, dynamic>>(
        ApiPath.category('c1'),
        body: {'name': '반려동물', 'baseCategoryId': 12},
      );
      final api2 = _client('kakao', store: store); // 앱 재시작 시뮬레이션
      expect((await api2.get<List<dynamic>>(ApiPath.categories)).single['name'], '반려동물');
    });
  });

  test('unknown path → 404 NOT_FOUND', () async {
    tokens.token = 'stub.kakao';
    expect(
      () => api.get<dynamic>('/v1/nope'),
      throwsA(isA<HttpFailure>().having((e) => e.code, 'code', 'NOT_FOUND')),
    );
  });

  test('state persists through StubStateStore across interceptor instances', () async {
    final store = _MemStore();
    final api1 = _client('kakao', store: store);
    await api1.put<Map<String, dynamic>>(
      ApiPath.profile,
      body: {'ageGroup': 'forties', 'monthlyIncome': 1},
    );
    await api1.put<Map<String, dynamic>>(
      ApiPath.transaction('z'),
      body: {'amount': 5, 'categoryId': 2, 'date': '2026-09-03T00:00:00.000Z', 'type': 'income', 'memo': 'm'},
    );
    expect(store.saved, isNotNull);

    final api2 = _client('kakao', store: store); // 앱 재시작 시뮬레이션
    expect((await api2.get<Map<String, dynamic>>(ApiPath.profile))['ageGroup'], 'forties');
    final list = await api2.get<List<dynamic>>(ApiPath.transactions, query: _range);
    expect(list.single['memo'], 'm');
  });

  // 계약: 프로필·거래·사용자 카테고리는 로그인한 사용자 것이다. 이름 중복도 사용자 안에서만 본다.
  test('사용자마다 데이터가 따로다', () async {
    final store = _MemStore();
    final kakao = _client('kakao', store: store);
    final google = _client('google', store: store);
    await kakao.put<Map<String, dynamic>>(
        ApiPath.profile, body: {'ageGroup': 'thirties', 'monthlyIncome': 1});
    await kakao.put<Map<String, dynamic>>(
        ApiPath.category('c1'), body: {'name': '반려동물', 'baseCategoryId': 12});
    await kakao.put<Map<String, dynamic>>(ApiPath.transaction('t1'), body: {
      'amount': 1000, 'categoryId': 1, 'date': '2026-09-02T00:00:00.000Z',
      'type': 'expense', 'memo': null,
    });

    expect(
      () => google.get<Map<String, dynamic>>(ApiPath.profile),
      throwsA(isA<HttpFailure>().having((e) => e.isNotFound, 'notFound', isTrue)),
    );
    expect(await google.get<List<dynamic>>(ApiPath.categories), isEmpty);
    expect(await google.get<List<dynamic>>(ApiPath.transactions, query: _range), isEmpty);
    // 다른 사용자의 카테고리 이름과 겹쳐도 된다.
    await google.put<Map<String, dynamic>>(
        ApiPath.category('c2'), body: {'name': '반려동물', 'baseCategoryId': 9});

    expect((await kakao.get<List<dynamic>>(ApiPath.categories)).single['id'], 'c1');
  });

  test('사용자별로 나누기 전 형식으로 저장된 상태는 버린다', () async {
    final store = _MemStore()
      ..saved = jsonEncode({
        'profile': {'ageGroup': 'forties', 'monthlyIncome': 1},
        'transactions': <String, dynamic>{},
        'customCategories': <String, dynamic>{},
      });
    expect(
      () => _client('kakao', store: store).get<Map<String, dynamic>>(ApiPath.profile),
      throwsA(isA<HttpFailure>().having((e) => e.isNotFound, 'notFound', isTrue)),
    );
  });
}
