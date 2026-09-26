import 'package:dio/dio.dart';

/// 서버(Stub)가 돌려준 오류 응답. 계약을 HTTP 수준(상태코드·오류 코드)으로 검증할 때 쓴다.
class HttpFailure implements Exception {
  HttpFailure(DioException e)
      : statusCode = e.response?.statusCode,
        code = _body(e)?['code'] as String?,
        message = _body(e)?['message'] as String?;

  final int? statusCode;
  final String? code;
  final String? message;

  bool get isNotFound => statusCode == 404;

  static Map<dynamic, dynamic>? _body(DioException e) {
    final data = e.response?.data;
    return data is Map ? data : null;
  }

  @override
  String toString() => 'HttpFailure($statusCode, $code, $message)';
}

/// 경로를 직접 지정해 호출하는 테스트용 HTTP 클라이언트. 오류 응답은 [HttpFailure]로 던진다.
/// retrofit 명세를 거치지 않고 서버(Stub) 계약을 경로·바디 단위로 검증할 때 쓴다.
class TestApiClient {
  TestApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _call(() async => (await _dio.get<T>(path, queryParameters: query)).data as T);

  Future<T> post<T>(String path, {Object? body}) =>
      _call(() async => (await _dio.post<T>(path, data: body)).data as T);

  Future<T> put<T>(String path, {Object? body}) =>
      _call(() async => (await _dio.put<T>(path, data: body)).data as T);

  /// 바디 없는 삭제(204).
  Future<void> delete(String path) => _call(() => _dio.delete<void>(path));

  Future<T> _call<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw HttpFailure(e);
    }
  }
}
