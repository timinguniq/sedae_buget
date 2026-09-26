import 'package:flutter_test/flutter_test.dart';

import 'contract_target.dart';

/// API 계약 v1 suite. 설명은 `docs/api-contract.md`, 기준은 이 파일이다(둘이 다르면 이 파일이 맞다).
///
/// 경로·바디는 앱 코드(`ApiPath`·DTO)를 쓰지 않고 문자열 그대로 적는다. 그래서 앱과 Stub이 같은
/// 오타를 나눠 가져도 여기서 드러난다. [target]은 테스트마다 새 서버(빈 상태)를 준다.
void apiContract(ContractTarget Function() target) {
  late ContractClient api;

  setUp(() => api = ContractClient(target()));

  const september = {'from': '2026-09-01T00:00:00.000Z', 'to': '2026-10-01T00:00:00.000Z'};

  Map<String, dynamic> expense({
    int amount = 1000,
    int categoryId = 1,
    String date = '2026-09-02T00:00:00.000Z',
    String? memo,
    String? customCategoryId,
  }) =>
      {
        'amount': amount,
        'categoryId': categoryId,
        'date': date,
        'type': 'expense',
        'memo': memo,
        'customCategoryId': customCategoryId,
      };

  group('인증', () {
    test('로그인하면 액세스 토큰과 사용자를 준다', () async {
      final res = await api.send('POST', '/v1/auth/login', body: {'provider': 'kakao', 'idToken': api.idToken});
      expect(res.status, 200);
      expect(res.json['accessToken'], isA<String>());
      final user = res.json['user'] as Map<String, dynamic>;
      expect(user['provider'], 'kakao');
      expect(user['id'], isA<String>());
      expect(user['nickname'], isA<String>());
    });

    test('idToken이 없거나 provider가 틀리면 400 VALIDATION', () async {
      expect((await api.send('POST', '/v1/auth/login', body: {'provider': 'kakao'})).code, 'VALIDATION');
      final bad = await api.send('POST', '/v1/auth/login', body: {'provider': 'line', 'idToken': 'x'});
      expect(bad.status, 400);
      expect(bad.code, 'VALIDATION');
    });

    test('/v1/me는 토큰의 사용자다', () async {
      final token = await api.login('naver');
      final me = await api.send('GET', '/v1/me', token: token);
      expect(me.status, 200);
      expect(me.json['provider'], 'naver');
    });

    test('토큰이 없거나 틀리면 401', () async {
      expect((await api.send('GET', '/v1/me')).status, 401);
      expect((await api.send('GET', '/v1/me', token: 'garbage')).status, 401);
    });

    test('로그인 뒤의 모든 경로는 토큰이 필요하다', () async {
      final unauthed = [
        ('POST', '/v1/auth/logout'),
        ('GET', '/v1/me/profile'),
        ('GET', '/v1/transactions'),
        ('PUT', '/v1/transactions/t1'),
        ('DELETE', '/v1/transactions/t1'),
        ('GET', '/v1/categories'),
        ('PUT', '/v1/categories/c1'),
        ('DELETE', '/v1/categories/c1'),
        ('GET', '/v1/peer/stats'),
        ('GET', '/v1/peer/generations'),
      ];
      for (final (method, path) in unauthed) {
        expect((await api.send(method, path)).status, 401, reason: '$method $path');
      }
    });

    test('로그아웃은 204', () async {
      final token = await api.login('kakao');
      expect((await api.send('POST', '/v1/auth/logout', token: token)).status, 204);
    });

    test('오류 바디는 {code, message}', () async {
      final res = await api.send('GET', '/v1/me');
      expect(res.json.keys, containsAll(['code', 'message']));
    });
  });

  group('프로필', () {
    late String token;
    setUp(() async => token = await api.login('kakao'));

    test('만들기 전에는 404 PROFILE_NOT_FOUND', () async {
      final res = await api.send('GET', '/v1/me/profile', token: token);
      expect(res.status, 404);
      expect(res.code, 'PROFILE_NOT_FOUND');
    });

    test('PUT한 값을 돌려주고 GET으로 읽는다', () async {
      final put = await api.send('PUT', '/v1/me/profile',
          body: {'ageGroup': 'thirties', 'monthlyIncome': 3000000}, token: token);
      expect(put.status, 200);
      expect(put.json, {'ageGroup': 'thirties', 'monthlyIncome': 3000000});
      expect((await api.send('GET', '/v1/me/profile', token: token)).json,
          {'ageGroup': 'thirties', 'monthlyIncome': 3000000});
    });

    test('월소득은 0일 수 있다', () async {
      final res = await api.send('PUT', '/v1/me/profile',
          body: {'ageGroup': 'teens', 'monthlyIncome': 0}, token: token);
      expect(res.status, 200);
    });

    test('나이대 이름·0 이상 정수 월소득이 아니면 400 VALIDATION', () async {
      final bodies = <Object?>[
        {'ageGroup': 'sixties', 'monthlyIncome': 1},
        {'monthlyIncome': 1},
        {'ageGroup': 'thirties', 'monthlyIncome': -1},
        {'ageGroup': 'thirties', 'monthlyIncome': 1.5},
        {'ageGroup': 'thirties', 'monthlyIncome': '1'},
        {'ageGroup': 'thirties'},
        null,
      ];
      for (final body in bodies) {
        final res = await api.send('PUT', '/v1/me/profile', body: body, token: token);
        expect((res.status, res.code), (400, 'VALIDATION'), reason: '$body');
      }
      expect((await api.send('GET', '/v1/me/profile', token: token)).status, 404);
    });
  });

  group('거래', () {
    late String token;
    setUp(() async => token = await api.login('kakao'));

    Future<ContractResponse> put(String id, Object? body) =>
        api.send('PUT', '/v1/transactions/$id', body: body, token: token);
    Future<List<dynamic>> list([Map<String, dynamic> range = september]) async =>
        (await api.send('GET', '/v1/transactions', query: range, token: token)).list;

    test('새 id는 201, 같은 id는 200이고 서버가 생성·수정 시각을 정한다', () async {
      final created = await put('t1', expense(memo: '점심'));
      expect(created.status, 201);
      expect(created.json['id'], 't1');
      expect(created.json['amount'], 1000);
      expect(created.json['memo'], '점심');
      expect(created.json['createdAt'], isA<String>());
      expect(created.json['updatedAt'], isA<String>());

      final updated = await put('t1', expense(amount: 2500, date: '2026-09-03T00:00:00.000Z'));
      expect(updated.status, 200);
      expect(updated.json['amount'], 2500);
      expect(updated.json['createdAt'], created.json['createdAt']);
    });

    test('기간 [from, to)의 거래를 날짜 최신순으로 준다', () async {
      await put('a', expense(date: '2026-09-01T00:00:00.000Z'));
      await put('b', expense(date: '2026-09-10T00:00:00.000Z'));
      await put('c', expense(date: '2026-10-01T00:00:00.000Z')); // to는 배타
      expect((await list()).map((e) => e['id']), ['b', 'a']);
    });

    test('from·to가 없으면 400 VALIDATION', () async {
      final res = await api.send('GET', '/v1/transactions', query: {'from': september['from']}, token: token);
      expect((res.status, res.code), (400, 'VALIDATION'));
    });

    test('지우면 204, 없는 거래는 404 NOT_FOUND', () async {
      await put('a', expense());
      expect((await api.send('DELETE', '/v1/transactions/a', token: token)).status, 204);
      expect(await list(), isEmpty);
      final again = await api.send('DELETE', '/v1/transactions/a', token: token);
      expect((again.status, again.code), (404, 'NOT_FOUND'));
    });

    // 수입은 카테고리가 없다. 앱은 categoryId를 보내지만 쓰지 않으므로 서버도 검사하지 않는다.
    test('수입의 categoryId는 아무 정수나 받는다', () async {
      final res = await put('i1', {...expense(categoryId: 0), 'type': 'income'});
      expect(res.status, 201);
    });

    test('규칙에 맞지 않는 거래는 400 VALIDATION이고 저장하지 않는다', () async {
      final bodies = <String, Object?>{
        'amount 0': expense(amount: 0),
        'amount 음수': expense(amount: -5),
        'amount 소수': {...expense(), 'amount': 1.5},
        'amount 문자열': {...expense(), 'amount': '1000'},
        'type 모름': {...expense(), 'type': 'transfer'},
        '지출 categoryId 0': expense(categoryId: 0),
        '지출 categoryId 13': expense(categoryId: 13),
        'date 형식': {...expense(), 'date': 'not-a-date'},
        'date UTC 아님': {...expense(), 'date': '2026-09-02T00:00:00.000'},
        'memo 숫자': {...expense(), 'memo': 123},
        '없는 사용자 카테고리': expense(customCategoryId: 'nope'),
        '바디 없음': null,
      };
      for (final MapEntry(key: name, value: body) in bodies.entries) {
        final res = await put('bad', body);
        expect((res.status, res.code), (400, 'VALIDATION'), reason: name);
      }
      expect(await list(), isEmpty);
    });
  });

  group('사용자 카테고리', () {
    late String token;
    setUp(() async => token = await api.login('kakao'));

    Future<ContractResponse> putCategory(String id, String name, int base) =>
        api.send('PUT', '/v1/categories/$id', body: {'name': name, 'baseCategoryId': base}, token: token);
    Future<List<dynamic>> categories() async => (await api.send('GET', '/v1/categories', token: token)).list;
    Future<Map<String, dynamic>> transaction(String id) async =>
        (await api.send('GET', '/v1/transactions', query: september, token: token))
            .list
            .cast<Map<String, dynamic>>()
            .singleWhere((t) => t['id'] == id);

    test('만든 순서대로 주고, 새 id는 201·같은 id는 200', () async {
      expect(await categories(), isEmpty);
      expect((await putCategory('c1', '반려동물', 12)).status, 201);
      expect((await putCategory('c2', '자기계발', 9)).status, 201);
      expect((await putCategory('c1', '댕댕이', 12)).status, 200);
      expect((await categories()).map((e) => e['name']), ['댕댕이', '자기계발']);
      expect((await categories()).first, {'id': 'c1', 'name': '댕댕이', 'baseCategoryId': 12});
    });

    test('이름 1~10자·상위 분류 1~12가 아니면 400 VALIDATION', () async {
      for (final (name, base) in [('   ', 12), ('가나다라마바사아자차카', 12), ('반려동물', 0), ('반려동물', 13)]) {
        final res = await putCategory('c1', name, base);
        expect((res.status, res.code), (400, 'VALIDATION'), reason: '$name/$base');
      }
    });

    test('같은 사용자 안에서 이름이 겹치면(대소문자 무시) 409 CATEGORY_DUPLICATE', () async {
      await putCategory('c1', 'Pet', 12);
      final res = await putCategory('c2', 'pet', 9);
      expect((res.status, res.code), (409, 'CATEGORY_DUPLICATE'));
      expect((await putCategory('c1', 'Pet', 9)).status, 200); // 자기 자신은 겹침이 아니다
    });

    test('숫자 id(기본 분류)는 만들거나 지울 수 없다: 403 CATEGORY_IMMUTABLE', () async {
      final put = await putCategory('12', '기타 바꾸기', 12);
      expect((put.status, put.code), (403, 'CATEGORY_IMMUTABLE'));
      final del = await api.send('DELETE', '/v1/categories/1', token: token);
      expect((del.status, del.code), (403, 'CATEGORY_IMMUTABLE'));
    });

    test('사용자 카테고리 거래의 categoryId는 그 상위 분류다', () async {
      await putCategory('c1', '반려동물', 12);
      final res = await api.send('PUT', '/v1/transactions/t1',
          body: expense(categoryId: 1, customCategoryId: 'c1'), token: token);
      expect(res.json['categoryId'], 12);
      expect((await transaction('t1'))['categoryId'], 12);
    });

    test('상위 분류를 바꾸면 그 카테고리의 거래도 옮겨진다', () async {
      await putCategory('c1', '반려동물', 12);
      await api.send('PUT', '/v1/transactions/t1', body: expense(categoryId: 12, customCategoryId: 'c1'), token: token);
      await api.send('PUT', '/v1/transactions/t2', body: expense(categoryId: 12), token: token);
      await putCategory('c1', '반려동물', 9);
      expect((await transaction('t1'))['categoryId'], 9);
      expect((await transaction('t2'))['categoryId'], 12);
    });

    test('지우면 204이고, 쓰던 거래는 상위 분류만 남는다. 없는 카테고리는 404', () async {
      await putCategory('c1', '반려동물', 12);
      await api.send('PUT', '/v1/transactions/t1', body: expense(categoryId: 12, customCategoryId: 'c1'), token: token);
      expect((await api.send('DELETE', '/v1/categories/c1', token: token)).status, 204);
      expect(await categories(), isEmpty);
      final tx = await transaction('t1');
      expect(tx['customCategoryId'], isNull);
      expect(tx['categoryId'], 12);
      final again = await api.send('DELETE', '/v1/categories/c1', token: token);
      expect((again.status, again.code), (404, 'NOT_FOUND'));
    });
  });

  group('또래 통계', () {
    late String token;
    setUp(() async => token = await api.login('kakao'));

    test('나이대의 월평균·저축률·분류별 평균·표본을 준다', () async {
      final res = await api.send('GET', '/v1/peer/stats', query: {'ageGroup': 'thirties'}, token: token);
      expect(res.status, 200);
      final s = res.json;
      expect(s['ageGroup'], 'thirties');
      expect(s['avgMonthlyExpense'], isA<int>());
      expect(s['avgSavingsRate'], isA<num>());
      final byCategory = s['avgByCategory'] as Map<String, dynamic>;
      expect(byCategory.keys.every((k) => int.parse(k) >= 1 && int.parse(k) <= 12), isTrue);
      expect(byCategory.values.every((v) => v is int), isTrue);
      final samples = (s['samples'] as List).cast<int>();
      expect(samples.length, lessThanOrEqualTo(99));
      expect(samples, orderedEquals([...samples]..sort()));
    });

    test('나이대가 없거나 모르는 값이면 400 VALIDATION', () async {
      for (final query in [<String, dynamic>{}, {'ageGroup': 'sixties'}]) {
        final res = await api.send('GET', '/v1/peer/stats', query: query, token: token);
        expect((res.status, res.code), (400, 'VALIDATION'), reason: '$query');
      }
    });

    test('세대별 월평균은 다섯 나이대를 준다', () async {
      final res = await api.send('GET', '/v1/peer/generations', token: token);
      expect(res.status, 200);
      expect(res.list.map((e) => e['ageGroup']),
          unorderedEquals(['teens', 'twenties', 'thirties', 'forties', 'fiftiesPlus']));
      expect(res.list.every((e) => e['avgMonthlyExpense'] is int), isTrue);
    });
  });

  // 프로필·거래·사용자 카테고리는 로그인한 사용자 것이다. 이름 겹침도 사용자 안에서만 본다.
  test('사용자마다 데이터가 따로다', () async {
    final kakao = await api.login('kakao');
    final google = await api.login('google');
    await api.send('PUT', '/v1/me/profile', body: {'ageGroup': 'thirties', 'monthlyIncome': 1}, token: kakao);
    await api.send('PUT', '/v1/categories/c1', body: {'name': '반려동물', 'baseCategoryId': 12}, token: kakao);
    await api.send('PUT', '/v1/transactions/t1', body: expense(), token: kakao);

    expect((await api.send('GET', '/v1/me/profile', token: google)).status, 404);
    expect((await api.send('GET', '/v1/categories', token: google)).list, isEmpty);
    expect((await api.send('GET', '/v1/transactions', query: september, token: google)).list, isEmpty);
    final sameName = await api.send('PUT', '/v1/categories/c2',
        body: {'name': '반려동물', 'baseCategoryId': 9}, token: google);
    expect(sameName.status, 201);
  });

  test('없는 경로는 404 NOT_FOUND', () async {
    final token = await api.login('kakao');
    final res = await api.send('GET', '/v1/nope', token: token);
    expect((res.status, res.code), (404, 'NOT_FOUND'));
  });
}
