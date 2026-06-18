part of 'custom_http_client.dart';

class HttpException {
  HttpException._();

  static Future<ResponseWrapper<T>> handleHttpException<T>(DioException e) async {
    _logger.w('handleHttpException : e.response=${e.response})');
    if (e.type == DioExceptionType.connectionTimeout) {
      return ResponseCode.HTTP_CONNECT_TIMEOUT.toResponseWrapper();
    }

    if (e.type == DioExceptionType.sendTimeout) {
      return ResponseCode.HTTP_SEND_TIMEOUT.toResponseWrapper();
    }

    if (e.type == DioExceptionType.receiveTimeout) {
      return ResponseCode.HTTP_RECEIVE_TIMEOUT.toResponseWrapper();
    }

    if (e.response == null) {
      return ResponseCode.DATA_NULL.toResponseWrapper();
    }

    ResponseWrapper<T> responseWrapper;
    final code = (e.response?.data as Map<String, dynamic>)['code'] as int;
    final message = (e.response?.data as Map<String, dynamic>)['message'] as String;
    if (code != 0) {
      if (code == 100 && message == 'Need to login') {
        /*
        await locator<AuthTokenManager>().deleteToken();
         */
        responseWrapper = ResponseCode.AUTH_TOKEN_INVALIDED.toResponseWrapper();
      } else if (message == 'Parameter is invalid.') {
        responseWrapper = ResponseCode.INVALID_PARAMETER.toResponseWrapper();
      } else if (message == 'Already signed up with Social Media') {
        responseWrapper = ResponseCode.SIGN_IN_WITH_OTHER_SOCIAL_LOGIN.toResponseWrapper();
      } else if (message == 'Need Sign Up') {
        responseWrapper = ResponseCode.AUTH_OAUTH_SIGN_UP_REQUIRED_ACCOUNT.toResponseWrapper();
      } else if (message == 'Not found') {
        responseWrapper = ResponseCode.NOT_FOUND.toResponseWrapper();
      } else if (message == 'Please confirm your email or password') {
        responseWrapper = ResponseCode.AUTH_EMAIL_OR_PASSWORD_INVALIDED.toResponseWrapper();
      } else {
        _logger.e('unhandled error : e.response=${e.response})');
        responseWrapper = ResponseCode.UNDEFINED.toResponseWrapper();
      }
    } else {
      final statusCode = e.response?.statusCode;
      if (e.error is SocketException) {
        responseWrapper = ResponseCode.HTTP_SOCKET_EXCEPTION.toResponseWrapper();
      } else if (statusCode != null && statusCode >= 500 && statusCode < 600) {
        responseWrapper = ResponseCode.HTTP_500_INTERNAL_SERVER_ERROR.toResponseWrapper();
        _recordError(e, responseWrapper);
      } else {
        _logger.e('unhandled exception : e.message=${e.message})');
        responseWrapper = ResponseCode.UNKNOWN.toResponseWrapper();
      }
    }
    return responseWrapper;
  }

  static void _recordError(DioException err, ResponseWrapper responseWrapper) {
    final params = err.requestOptions.data;
    unawaited(
      FirebaseCrashlytics.instance.recordError(
        err,
        err.stackTrace,
        reason: {
          'errorMessage': err.message ?? err.toString(),
          'path': err.requestOptions.path,
          'resultCode': responseWrapper.resultCode,
          'logMessage': responseWrapper.message,
          if (params != null) 'params': params,
        },
        fatal: true,
        printDetails: true,
      ),
    );
  }
}
