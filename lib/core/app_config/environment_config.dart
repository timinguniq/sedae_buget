import 'package:sedae_budget/core/util/logger/custom_logger.dart';

final _logger = CustomLogger.create(tag: 'AppEnvironment');

/// 앱이 붙는 서버 환경. local은 서버 대신 앱 안의 Stub이 답한다.
enum AppEnvironment {
  local(''),
  dev(''), // TODO: 서버 주소 확정 시 기입
  staging(''), // TODO: 서버 주소 확정 시 기입
  prod(''); // TODO: 서버 주소 확정 시 기입

  const AppEnvironment(this.server);

  /// 서버 주소. local은 쓰지 않는다.
  final String server;

  /// 빌드할 때 지정한 환경(`--dart-define=env=dev`). 지정하지 않았으면 local이다(release 빌드도).
  // TODO: 서버 준비 후 기본값을 prod로 변경
  static AppEnvironment get current => parse(const String.fromEnvironment('env'));

  /// 환경 이름을 읽는다. 비었거나 모르는 이름이면 local.
  static AppEnvironment parse(String name) {
    if (name.isEmpty) return local;
    for (final env in values) {
      if (env.name == name) return env;
    }
    _logger.e("Unknown env '$name'");
    return local;
  }
}
