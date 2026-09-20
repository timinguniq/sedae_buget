import 'package:dio/dio.dart';
import 'package:sedae_budget/data/repository_impl/api_call.dart';

/// 경로를 직접 지정해 호출하는 테스트용 HTTP 클라이언트. 실패는 앱과 같이 `ApiException`으로 통일된다.
/// retrofit 명세를 거치지 않고 서버(Stub) 계약을 경로·바디 단위로 검증할 때 쓴다.
class TestApiClient {
  TestApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      callApi(() async => (await _dio.get<T>(path, queryParameters: query)).data as T);

  Future<T> post<T>(String path, {Object? body}) =>
      callApi(() async => (await _dio.post<T>(path, data: body)).data as T);

  Future<T> put<T>(String path, {Object? body}) =>
      callApi(() async => (await _dio.put<T>(path, data: body)).data as T);

  /// 바디 없는 삭제(204).
  Future<void> delete(String path) => callApi(() => _dio.delete<void>(path));
}
