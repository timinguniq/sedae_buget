import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:sedae_budget/core/http_client/auth_token_interceptor.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';

/// 서버 API용 Dio 구성. retrofit 명세(`data/data_source/remote`)가 이 [dio]로 호출한다.
class ApiClient {
  ApiClient(this.dio);

  final Dio dio;

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
}
