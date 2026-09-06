import 'package:dio/dio.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';

/// 저장된 액세스 토큰이 있으면 모든 요청에 `Authorization: Bearer` 헤더를 붙인다.
class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._store);

  final AuthTokenStore _store;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _store.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
