import 'package:dio/dio.dart';

/// API 호출 실패. 서버 에러 바디 {code, message} 또는 전송 계층 오류.
class ApiException implements Exception {
  ApiException({required this.code, required this.message, this.statusCode});

  /// 서버 code 또는 `NETWORK_ERROR` / `TIMEOUT` / `HTTP_<status>`
  final String code;
  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isNotFound => statusCode == 404;

  static ApiException fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(code: 'TIMEOUT', message: '요청 시간이 초과되었습니다.');
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final data = e.response?.data;
        if (data is Map && data['code'] is String) {
          return ApiException(
            code: data['code'] as String,
            message: (data['message'] as String?) ?? '',
            statusCode: status,
          );
        }
        return ApiException(
          code: 'HTTP_$status',
          message: e.message ?? '',
          statusCode: status,
        );
      default:
        return ApiException(code: 'NETWORK_ERROR', message: '네트워크에 연결할 수 없습니다.');
    }
  }

  @override
  String toString() => 'ApiException($code, $statusCode, $message)';
}
