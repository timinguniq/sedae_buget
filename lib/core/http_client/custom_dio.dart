part of 'custom_http_client.dart';

class _CustomInterceptor extends PrettyDioLogger {
  _CustomInterceptor()
      : super(
    // request: false,
    // requestHeader: true,
    requestBody: true,
    // responseHeader: false,
    responseBody: false,
    // error: false,
    maxWidth: 120,
    // compact: false,
  );

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.headers['withJwt'] == true) {
      options.headers.remove('withJwt');
      /*
      final jwtToken = locator<AuthTokenManager>().token;
      if (jwtToken != '') {
        options.headers.addAll({'X-AUTH-TOKEN': jwtToken});
      }
       */
    }

    if (options.headers['withKookyUserAgent'] == true) {
      options.headers.remove('User-Agent');
      // TODO: User-Agent 생성 유틸리티 필요
      options.headers.addAll({'User-Agent': 'kooky/1.0/io.kooky.kooky/6/android/29'});
    }

    return super.onRequest(options, handler);
  }
}
