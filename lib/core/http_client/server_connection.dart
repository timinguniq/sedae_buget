import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:sedae_budget/core/app_config/environment_config.dart';
import 'package:sedae_budget/core/http_client/auth_token_interceptor.dart';
import 'package:sedae_budget/core/http_client/auth_token_store.dart';
import 'package:sedae_budget/core/http_client/session_expiry.dart';

/// 앱이 서버에 닿는 방법. retrofit 명세(`data/data_source/remote`)가 호출할 Dio를 [env]에 맞춰 만든다.
///
/// - local이면 서버 대신 [localServer](Stub)가 답한다. 다른 환경은 그 서버 주소로 보내고,
///   주소가 비었으면 [StateError]로 멈춘다(모든 호출이 '연결 안 됨'이 되는 대신 시작할 때 드러나게).
/// - 요청에는 저장된 토큰이 붙는다. 서버가 토큰을 거부하면(401) 토큰을 지우고 [sessionExpiry]로 알린다.
/// - 요청 로그는 [release]가 아닐 때만 남긴다. 로그인 idToken·거래 금액·메모가 기기 로그에 남지 않게.
Dio connectToServer({
  required AppEnvironment env,
  required AuthTokenStore tokenStore,
  required SessionExpiry sessionExpiry,
  required Interceptor Function() localServer,
  bool release = kReleaseMode,
}) {
  final isLocal = env == AppEnvironment.local;
  if (!isLocal && env.server.isEmpty) {
    throw StateError('env=${env.name}의 서버 주소가 비어 있어요. environment_config.dart에 적어 주세요.');
  }
  final dio = Dio(
    BaseOptions(
      baseUrl: env.server,
      contentType: 'application/json',
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  dio.interceptors.addAll([
    AuthTokenInterceptor(tokenStore, sessionExpiry),
    if (!release) PrettyDioLogger(requestBody: true, responseBody: false, maxWidth: 120),
    if (isLocal) localServer(),
  ]);
  return dio;
}
