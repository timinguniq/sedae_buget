import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

import '../../helper/fake_http_adapter.dart';

/// retrofit 명세를 거친 실제 호출 경로로 검증한다.
Future<Result<AuthUserDto>> _me(HttpClientAdapter server) =>
    guardApi(() => AuthApi(fakeDio(server)).me());

Future<ErrorResult> _failure(HttpClientAdapter server) async => (await _me(server)).failureOrNull!;

void main() {
  test('성공 응답은 값이다', () async {
    final res = await _me(FakeHttpAdapter.reply(200, jsonEncode({'provider': 'kakao', 'nickname': 'n'})));
    expect(res.unwrap().nickname, 'n');
  });

  test('서버 오류 바디의 코드와 문구를 옮긴다', () async {
    final f = await _failure(
        FakeHttpAdapter.reply(409, errorBody('CATEGORY_DUPLICATE', '같은 이름의 카테고리가 있어요')));
    expect(f.reason, FailureReason.conflict);
    expect(f.code, 'CATEGORY_DUPLICATE');
    expect(f.message, '같은 이름의 카테고리가 있어요');
  });

  test('상태코드를 도메인 분류로 바꾼다', () async {
    const table = [
      (400, FailureReason.invalid),
      (401, FailureReason.unauthorized),
      (403, FailureReason.forbidden),
      (404, FailureReason.notFound),
      (409, FailureReason.conflict),
      (422, FailureReason.invalid),
      (418, FailureReason.unknown),
      (500, FailureReason.server),
      (503, FailureReason.server),
    ];
    for (final (status, reason) in table) {
      expect((await _failure(FakeHttpAdapter.reply(status, errorBody('X')))).reason, reason,
          reason: '$status');
    }
  });

  // 이전에는 Dio의 영어 개발자 문장("This exception was thrown because ...")이 문구로 담겨 화면까지 갔다.
  test('알아볼 수 없는 오류 본문(프록시의 HTML 502)은 문구 없는 server 실패다', () async {
    final f = await _failure(
        FakeHttpAdapter.reply(502, '<html>Bad Gateway</html>', contentType: 'text/html'));
    expect(f.reason, FailureReason.server);
    expect(f.message, isEmpty);
    expect(f.code, isNull);
  });

  // 이전에는 DTO 변환 오류(TypeError)가 Result 계약 밖으로 던져져, 화면이 실패를 몰랐다.
  test('해석할 수 없는 성공 응답은 던지지 않고 server 실패다', () async {
    final missingField = FakeHttpAdapter.reply(200, jsonEncode({'provider': 'kakao'}));
    expect((await _failure(missingField)).reason, FailureReason.server);
    expect((await _failure(FakeHttpAdapter.reply(200, ''))).reason, FailureReason.server);
  });

  test('응답을 못 받으면 문구 없는 timeout·offline이다', () async {
    final timeout = await _failure(FakeHttpAdapter.fail(DioExceptionType.receiveTimeout));
    expect(timeout.reason, FailureReason.timeout);
    expect(timeout.message, isEmpty);
    final offline = await _failure(FakeHttpAdapter.fail(DioExceptionType.connectionError));
    expect(offline.reason, FailureReason.offline);
    expect(offline.message, isEmpty);
  });

  test('HTTP·전송 계층 사정은 domain seam을 넘지 않는다(서버 도메인 코드만 남는다)', () async {
    expect((await _failure(FakeHttpAdapter.reply(500, '<html>', contentType: 'text/html'))).code,
        isNull);
    expect((await _failure(FakeHttpAdapter.fail(DioExceptionType.connectionTimeout))).code, isNull);
    expect((await _failure(FakeHttpAdapter.reply(418, errorBody('TEAPOT')))).code, 'TEAPOT');
  });

  group('실패를 값으로 바꾸기', () {
    Future<Result<String?>> profile(HttpClientAdapter server) => guardApi<String?>(
          () async => (await fakeDio(server).get<Map<String, dynamic>>('/v1/me/profile'))
              .data!['ageGroup'] as String,
          recover: (f) => f.code == 'PROFILE_NOT_FOUND' ? const Result.success(null) : null,
        );

    test('고른 실패는 그 값으로 성공한다', () async {
      expect((await profile(FakeHttpAdapter.reply(404, errorBody('PROFILE_NOT_FOUND')))).unwrap(),
          isNull);
    });

    test('고르지 않은 실패는 그대로 실패다', () async {
      expect((await profile(FakeHttpAdapter.reply(404, errorBody('NOT_FOUND')))).failureOrNull?.reason,
          FailureReason.notFound);
    });
  });
}
