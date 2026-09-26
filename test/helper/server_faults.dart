import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 테스트가 Stub 앞에 끼우는 고장 손잡이. 서버 앞의 네트워크·서버 장애와 느린 응답을 흉내 내고,
/// 서버에 닿은 요청을 기록한다. 운영 빌드에는 들어가지 않는다.
///
/// 경로는 앞부분으로 맞춘다: `fail('GET', '/v1/peer')`는 또래 통계와 세대별 평균을 모두 실패시킨다.
class ServerFaults extends Interceptor {
  final _failures = <_Failure>[];
  final _holds = <_Hold>[];

  /// 서버에 닿은(고장 손잡이를 지난) 요청. `'GET /v1/transactions'` 모양.
  final requests = <String>[];

  /// [method] [path]로 가는 요청을 [reason]으로 실패시킨다. [times]만큼만(없으면 [heal]까지 계속).
  /// 연결·시간 초과가 아닌 이유는 서버의 500 응답이고, 바디의 문구는 [message]다.
  void fail(
    String method,
    String path, {
    FailureReason reason = FailureReason.offline,
    int? times,
    String message = '서버가 내려갔어요',
  }) =>
      _failures.add(_Failure(method, path, reason, times, message));

  /// 걸어 둔 실패를 모두 푼다.
  void heal() => _failures.clear();

  /// [method] [path]로 가는 요청을 돌려준 [Completer]가 끝날 때까지 붙잡는다(한 번).
  Completer<void> hold(String method, String path) {
    final gate = Completer<void>();
    _holds.add(_Hold(method, path, gate));
    return gate;
  }

  /// [method] [path]로 간 요청 수.
  int count(String method, String path) => requests.where((r) => r.startsWith('$method $path')).length;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final method = options.method, path = options.path;
    final hold = _holds.where((h) => h.matches(method, path)).firstOrNull;
    if (hold != null) {
      _holds.remove(hold);
      await hold.gate.future;
    }
    final failure = _failures.where((f) => f.matches(method, path)).firstOrNull;
    if (failure != null) {
      if (failure.used()) _failures.remove(failure);
      handler.reject(failure.toException(options), true);
      return;
    }
    requests.add('$method $path');
    handler.next(options);
  }
}

class _Failure {
  _Failure(this.method, this.path, this.reason, this.times, this.message);

  final String method;
  final String path;
  final FailureReason reason;
  final String message;
  int? times;

  bool matches(String m, String p) => m == method && p.startsWith(path);

  /// 한 번 썼다. 다 썼으면 true.
  bool used() {
    final left = times;
    if (left == null) return false;
    times = left - 1;
    return left <= 1;
  }

  DioException toException(RequestOptions o) => switch (reason) {
        FailureReason.offline => DioException(requestOptions: o, type: DioExceptionType.connectionError),
        FailureReason.timeout => DioException(requestOptions: o, type: DioExceptionType.receiveTimeout),
        _ => DioException(
            requestOptions: o,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: o,
              statusCode: 500,
              data: {'code': 'INTERNAL', 'message': message},
            ),
          ),
      };
}

class _Hold {
  _Hold(this.method, this.path, this.gate);

  final String method;
  final String path;
  final Completer<void> gate;

  bool matches(String m, String p) => m == method && p.startsWith(path);
}
