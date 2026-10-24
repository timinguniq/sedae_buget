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

  // 계약의 입력 오류는 400(VALIDATION)이다. 이전에는 계약 밖 422의 문구도 옮겨, 화면이 그 서버 문구를 이유로 보였다.
  test('422는 invalid지만 서버 문구를 옮기지 않는다(400은 옮긴다)', () async {
    final unprocessable =
        await _failure(FakeHttpAdapter.reply(422, errorBody('UNPROCESSABLE', 'Unprocessable Entity')));
    expect(unprocessable.reason, FailureReason.invalid);
    expect(unprocessable.message, isEmpty);
    expect(unprocessable.code, 'UNPROCESSABLE');
    final validation = await _failure(FakeHttpAdapter.reply(400, errorBody('VALIDATION', '이름은 1~10자여야 합니다.')));
    expect(validation.reason, FailureReason.invalid);
    expect(validation.message, '이름은 1~10자여야 합니다.');
  });

  // 문구를 버리는 것은 계약 밖 422뿐이다.
  test('422가 아닌 오류 응답(429·500)의 서버 문구는 옮긴다', () async {
    for (final status in [429, 500]) {
      final f = await _failure(FakeHttpAdapter.reply(status, errorBody('X', '잠시 후 다시 시도해 주세요')));
      expect(f.message, '잠시 후 다시 시도해 주세요', reason: '$status');
    }
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

  // 이전에는 연결 시간 초과도 timeout이라, 장부가 서버에 가지 않은 변경 뒤에 다시 읽어 뒤 화면까지 실패로 바꿨다.
  test('연결하지 못한 시간 초과는 offline, 연결한 뒤의 시간 초과는 timeout이다', () async {
    expect((await _failure(FakeHttpAdapter.fail(DioExceptionType.connectionTimeout))).reason,
        FailureReason.offline);
    expect((await _failure(FakeHttpAdapter.fail(DioExceptionType.sendTimeout))).reason,
        FailureReason.timeout);
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
