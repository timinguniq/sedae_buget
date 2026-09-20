import 'package:dio/dio.dart';

/// 요청을 기록하고 고정 응답을 돌려주는 테스트용 인터셉터.
/// API 클래스가 계약대로(메서드·경로·쿼리·바디) 요청하는지 검증할 때 쓴다.
class RecordingInterceptor extends Interceptor {
  RecordingInterceptor({this.status = 200, this.body});

  final int status;
  final Object? body;
  final List<RequestOptions> requests = [];

  RequestOptions get single => requests.single;

  @override
  void onRequest(RequestOptions o, RequestInterceptorHandler h) {
    requests.add(o);
    h.resolve(Response(requestOptions: o, statusCode: status, data: body));
  }
}
