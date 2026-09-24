import 'package:dio/dio.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';
import 'package:sedae_budget/core/http_client/session_expiry.dart';

/// 저장된 액세스 토큰이 있으면 모든 요청에 `Authorization: Bearer` 헤더를 붙인다.
/// 서버가 그 토큰을 거부하면(401) 토큰을 버리고 [SessionExpiry]로 알린다.
class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._store, [this._expiry]);

  final AuthTokenStore _store;
  final SessionExpiry? _expiry;

  static const _header = 'Authorization';
  static const _scheme = 'Bearer ';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _store.read();
    if (token != null && token.isNotEmpty) {
      options.headers[_header] = '$_scheme$token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final sent = err.requestOptions.headers[_header] as String?;
      // 지금 가진 토큰이 거부된 경우만 버린다. 그 사이 새로 로그인했다면 새 토큰은 그대로 둔다.
      if (sent != null && sent == '$_scheme${await _store.read()}') {
        await _store.clear();
        _expiry?.notify();
      }
    }
    handler.next(err);
  }
}
