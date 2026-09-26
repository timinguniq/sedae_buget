import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 네트워크 대신 정해 둔 응답을 돌려주는 HTTP adapter.
///
/// 인터셉터로 가짜 응답을 끼우면 Dio 자체의 응답 처리(상태 검사·본문 해석·오류 문구)를 건너뛴다.
/// 이 adapter는 그 처리를 실제와 같이 거친다.
class FakeHttpAdapter implements HttpClientAdapter {
  /// [status]와 [body]로 답한다.
  FakeHttpAdapter.reply(int status, String body, {String contentType = Headers.jsonContentType})
      : _reply = ((status: status, body: body, contentType: contentType)),
        _fail = null;

  /// 응답을 받기 전에 [type]으로 실패한다(시간 초과·연결 안 됨).
  FakeHttpAdapter.fail(DioExceptionType type)
      : _reply = null,
        _fail = type;

  final ({int status, String body, String contentType})? _reply;
  final DioExceptionType? _fail;

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? _, Future<void>? _) async {
    final fail = _fail;
    if (fail != null) throw DioException(requestOptions: o, type: fail);
    final r = _reply!;
    return ResponseBody.fromString(r.body, r.status, headers: {
      Headers.contentTypeHeader: [r.contentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

/// 서버 오류 바디 `{code, message}`.
String errorBody(String code, [String message = '']) =>
    jsonEncode({'code': code, 'message': message});

/// [adapter]로 답하는 Dio.
Dio fakeDio(HttpClientAdapter adapter) => Dio()..httpClientAdapter = adapter;
