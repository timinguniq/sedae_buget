import 'dart:async';

/// 서버가 저장된 토큰을 거부했다(401)는 신호. 토큰은 [AuthTokenInterceptor]가 이미 지웠다.
class SessionExpiry {
  final _expired = StreamController<void>.broadcast();

  Stream<void> get expired => _expired.stream;

  void notify() => _expired.add(null);
}
