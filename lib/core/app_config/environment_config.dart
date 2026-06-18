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
      server: 'https://api-develop.kooky.run',
    ),
  ),
  staging(
    AppEndpoint(
      server: 'https://api.staging.kooky.run',
    ),
  ),
  prod(
    AppEndpoint(
      server: 'https://api.kooky.io',
    ),
  );

  const AppEnvironment(this.endpoint);

  final AppEndpoint endpoint;
}

abstract class EnvironmentConfig {
  EnvironmentConfig._();

  static AppEnvironment? _env;

  static AppEnvironment get env => _env ?? AppEnvironment.dev;

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
