import 'package:sedae_budget/entity/core/app_initial_info.dart';
import 'package:sedae_budget/entity/core/app_service_status.dart';
import 'package:sedae_budget/entity/core/app_version.dart';

/// 원격 시작 정보([AppInitialInfo])로 정한 앱 이용 가능 여부.
sealed class AppStatus {
  const AppStatus();

  /// [info]가 없거나(원격 설정을 못 읽음) [build]를 모르면 쓸 수 있는 것으로 본다.
  static AppStatus of(AppInitialInfo? info, {required int? build, required bool isIOS}) {
    if (info == null) return const AppAvailable();
    if (!info.serviceStatus.available) return AppUnderMaintenance(info.serviceStatus);
    final version = isIOS ? info.ios : info.android;
    if (build == null || build >= version.releaseVersion) return const AppAvailable();
    return AppUpdateAvailable(version, forced: build < version.minimumAvailableVersion);
  }
}

final class AppAvailable extends AppStatus {
  const AppAvailable();
}

/// 서비스 점검 중. [notice]의 제목·내용을 안내한다.
final class AppUnderMaintenance extends AppStatus {
  const AppUnderMaintenance(this.notice);

  final AppServiceStatus notice;
}

/// 새 버전이 있다. [forced]면 이 빌드로는 더 쓸 수 없다.
final class AppUpdateAvailable extends AppStatus {
  const AppUpdateAvailable(this.version, {required this.forced});

  final AppVersion version;
  final bool forced;
}
