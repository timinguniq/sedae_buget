import 'package:flutter/foundation.dart';
import 'package:sedae_budget/core/core.dart';

final _logger = CustomLogger.create(tag: (EnvironmentConfig).toString());

enum AppEnvironment {
  local(
    AppEndpoint(
      server: '',
    ),
  ),
  dev(
    AppEndpoint(
      server: '', // TODO: 서버 주소 확정 시 기입
    ),
  ),
  staging(
    AppEndpoint(
      server: '', // TODO: 서버 주소 확정 시 기입
    ),
  ),
  prod(
    AppEndpoint(
      server: '', // TODO: 서버 주소 확정 시 기입
    ),
  );

  const AppEnvironment(this.endpoint);

  final AppEndpoint endpoint;
}

abstract class EnvironmentConfig {
  EnvironmentConfig._();

  static AppEnvironment? _env;

  /// `local`이면 서버 대신 Stub API(인프로세스)를 쓴다.
  // TODO: 서버 준비 후 기본값을 AppEnvironment.prod로 변경
  static AppEnvironment get env => _env ?? _fromDartDefine ?? AppEnvironment.local;

  /// `--dart-define=env=dev` 처럼 빌드 시 지정한 환경. 없거나 잘못된 이름이면 null.
  static AppEnvironment? get _fromDartDefine {
    const name = String.fromEnvironment('env');
    if (name.isEmpty) return null;
    try {
      return AppEnvironment.values.byName(name);
    } catch (_) {
      _logger.e("Unknown env '$name'");
      return null;
    }
  }

  //static String get baseWebUrl => EnvironmentConfig.env.endpoint.baseWebUrl;

  static void initialize(AppEnvironment remoteSetting) {
    if (kReleaseMode) {
      _env = remoteSetting;
    } else {
      const localSetting = String.fromEnvironment('env');
      if (localSetting.isNotEmpty) {
        try {
          _env = AppEnvironment.values.byName(localSetting);
        } catch (e) {
          _logger.e("Failed to config environment from '$localSetting'!", error: e);
        }
      }
    }
    _logger.i('initialize(${remoteSetting.name}) : by ${kReleaseMode ? 'release' : 'debug'} mode. env=${env.name}');
  }
}
