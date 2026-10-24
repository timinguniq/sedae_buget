import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:sedae_budget/core/app_config/environment_config.dart';
import 'package:sedae_budget/core/http_client/session.dart';

/// 앱이 서버에 닿는 방법. retrofit 명세(`data/data_source/remote`)가 호출할 Dio를 [env]에 맞춰 만든다.
///
/// - local이면 서버 대신 [localServer](Stub)가 답한다. 다른 환경은 그 서버 주소로 보내고,
///   주소가 비었으면 [StateError]로 멈춘다(모든 호출이 '연결 안 됨'이 되는 대신 시작할 때 드러나게).
/// - 요청에는 [session]의 토큰이 붙고, 서버가 그 토큰을 거부하면(401) 세션이 끝난다([Session]).
/// - [beforeServer]는 서버(local이면 Stub) 바로 앞에 선다. 토큰이 붙은 요청을 받는다(테스트의 고장 손잡이 자리).
/// - 요청 로그는 [requestLog]일 때만 남긴다. 앱은 release 빌드에서 끈다(로그인 idToken·거래 금액·메모가
///   기기 로그에 남지 않게, `ServerRepositories.connect`).
/// - [web]이면 연결 시간 제한을 두지 않는다. 브라우저는 연결 중인지 응답을 기다리는지 구별하지 못해,
///   응답이 늦은 것도 연결 시간 초과(요청이 서버에 가지 않음)로 알리기 때문이다. 제한이 없으면 받기 시간 초과로 알린다.
///   대신 받기 시간 제한을 30초로 둔다. 웹 어댑터는 연결+받기 시간을 요청 전체의 기한으로 쓰므로,
///   전체 기한이 앱과 같은 30초(연결 15초 + 받기 15초)로 남는다.
Dio connectToServer({
  required AppEnvironment env,
  required Session session,
  required Interceptor Function() localServer,
  List<Interceptor> beforeServer = const [],
  required bool requestLog,
  bool web = kIsWeb,
}) {
  final isLocal = env == AppEnvironment.local;
  if (!isLocal && env.server.isEmpty) {
    throw StateError('env=${env.name}의 서버 주소가 비어 있어요. environment_config.dart에 적어 주세요.');
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: env.server,
      contentType: 'application/json',
      connectTimeout: web ? null : const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: Duration(seconds: web ? 30 : 15),
    ),
  );
  dio.interceptors.addAll([
    session.interceptor,
    if (requestLog) PrettyDioLogger(requestBody: true, responseBody: false, maxWidth: 120),
    ...beforeServer,
    if (isLocal) localServer(),
  ]);
  return dio;
}
