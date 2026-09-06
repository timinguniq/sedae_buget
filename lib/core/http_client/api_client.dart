import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:sedae_budget/core/http_client/api_exception.dart';
import 'package:sedae_budget/core/http_client/auth_token_interceptor.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';

/// 서버 API용 Dio 래퍼. 응답 바디를 그대로 돌려주고 실패는 [ApiException]으로 통일한다.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  /// [extra]는 토큰·로거 뒤에 붙는다(Stub 인터셉터 자리).
  factory ApiClient.create({
    required String baseUrl,
    required AuthTokenStore tokenStore,
    List<Interceptor> extra = const [],
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        contentType: 'application/json',
        connectTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    dio.interceptors
      ..add(AuthTokenInterceptor(tokenStore))
      ..add(PrettyDioLogger(requestBody: true, responseBody: false, maxWidth: 120))
      ..addAll(extra);
    return ApiClient(dio);
  }

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _run(() => _dio.get<T>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? body}) =>
      _run(() => _dio.post<T>(path, data: body));

  Future<T> put<T>(String path, {Object? body}) =>
      _run(() => _dio.put<T>(path, data: body));

  Future<void> delete(String path) => _run(() => _dio.delete<void>(path));

  Future<T> _run<T>(Future<Response<T>> Function() call) async {
    try {
      return (await call()).data as T;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
