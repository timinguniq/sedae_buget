import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/core.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

class _Tokens implements AuthTokenStore {
  String? t;
  @override
  Future<String?> read() async => t;
  @override
  Future<void> write(String token) async => t = token;
  @override
  Future<void> clear() async => t = null;
}

class _MemStore implements StubStateStore {
  String? saved;
  @override
  Future<String?> load() async => saved;
  @override
  Future<void> save(String json) async => saved = json;
}

const _range = {'from': '2026-09-01T00:00:00.000Z', 'to': '2026-10-01T00:00:00.000Z'};

ApiClient _client(_Tokens tokens, {StubStateStore? store}) => ApiClient(Dio()
  ..interceptors.add(AuthTokenInterceptor(tokens))
  ..interceptors.add(StubApiInterceptor(store: store)));

void main() {
  late _Tokens tokens;
  late ApiClient api;

  setUp(() {
    tokens = _Tokens();
    api = _client(tokens);
  });

  Future<void> putTx(String id, String date) => api.put<Map<String, dynamic>>(
        ApiPath.transaction(id),
        body: {'amount': 1000, 'categoryId': 1, 'date': date, 'type': 'expense', 'memo': null},
      );

  test('login → token, me → same user; me without token → 401', () async {
    expect(
      () => api.get<Map<String, dynamic>>(ApiPath.me),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    final res = await api.post<Map<String, dynamic>>(
      ApiPath.login,
      body: {'provider': 'kakao', 'idToken': 'x'},
    );
    tokens.t = res['accessToken'] as String;
    expect((res['user'] as Map)['nickname'], '카카오 사용자');

    final me = await api.get<Map<String, dynamic>>(ApiPath.me);
    expect(me['provider'], 'kakao');
    expect(me['nickname'], '카카오 사용자');
    expect(me['id'], isNotEmpty);
  });

  test('login without idToken → 400 VALIDATION', () async {
    expect(
      () => api.post<Map<String, dynamic>>(ApiPath.login, body: {'provider': 'kakao'}),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION')),
    );
  });

  test('garbage token → 401 AUTH_004', () async {
    tokens.t = 'garbage';
    expect(
      () => api.get<Map<String, dynamic>>(ApiPath.me),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'AUTH_004')),
    );
  });

  test('logout → 204', () async {
    tokens.t = 'stub.kakao';
    await api.post<dynamic>(ApiPath.logout);
  });

  test('profile 404 → put → get → delete → 404', () async {
    tokens.t = 'stub.kakao';
    expect(
      () => api.get<Map<String, dynamic>>(ApiPath.profile),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'PROFILE_NOT_FOUND')),
    );
    await api.put<Map<String, dynamic>>(
      ApiPath.profile,
      body: {'ageGroup': 'thirties', 'monthlyIncome': 3000000},
    );
    final got = await api.get<Map<String, dynamic>>(ApiPath.profile);
    expect(got['monthlyIncome'], 3000000);
    expect(got['ageGroup'], 'thirties');
    await api.delete(ApiPath.profile);
    expect(
      () => api.get<Map<String, dynamic>>(ApiPath.profile),
      throwsA(isA<ApiException>().having((e) => e.isNotFound, 'notFound', isTrue)),
    );
  });

  test('transactions: put → list in range, desc → delete → empty', () async {
    tokens.t = 'stub.kakao';
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
    tokens.t = 'stub.kakao';
    await putTx('a', '2026-09-01T00:00:00.000Z');
    final first = (await api.get<List<dynamic>>(ApiPath.transactions, query: _range)).single;
    await putTx('a', '2026-09-02T00:00:00.000Z');
    final second = (await api.get<List<dynamic>>(ApiPath.transactions, query: _range)).single;
    expect(second['createdAt'], first['createdAt']);
    expect(second['date'], '2026-09-02T00:00:00.000Z');
    expect(
      () => api.delete(ApiPath.transaction('nope')),
      throwsA(isA<ApiException>().having((e) => e.isNotFound, 'notFound', isTrue)),
    );
  });

  test('peer stats matches StubPeerData; generations has 5 groups', () async {
    tokens.t = 'stub.kakao';
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

  test('unknown path → 404 NOT_FOUND', () async {
    tokens.t = 'stub.kakao';
    expect(
      () => api.get<dynamic>('/v1/nope'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NOT_FOUND')),
    );
  });

  test('state persists through StubStateStore across interceptor instances', () async {
    final store = _MemStore();
    tokens.t = 'stub.kakao';
    final api1 = _client(tokens, store: store);
    await api1.put<Map<String, dynamic>>(
      ApiPath.profile,
      body: {'ageGroup': 'forties', 'monthlyIncome': 1},
    );
    await api1.put<Map<String, dynamic>>(
      ApiPath.transaction('z'),
      body: {'amount': 5, 'categoryId': 2, 'date': '2026-09-03T00:00:00.000Z', 'type': 'income', 'memo': 'm'},
    );
    expect(store.saved, isNotNull);

    final api2 = _client(tokens, store: store); // 앱 재시작 시뮬레이션
    expect((await api2.get<Map<String, dynamic>>(ApiPath.profile))['ageGroup'], 'forties');
    final list = await api2.get<List<dynamic>>(ApiPath.transactions, query: _range);
    expect(list.single['memo'], 'm');
  });
}
