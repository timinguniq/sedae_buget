import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'app_initial_info.freezed.dart';
part 'app_initial_info.g.dart';

@freezed
abstract class AppInitialInfo with _$AppInitialInfo {
  const factory AppInitialInfo({
    required AppVersion android,
    required AppVersion ios,
    required AppServiceStatus serviceStatus,
  }) = _AppInitialInfo;

  factory AppInitialInfo.fromJson(Map<String, dynamic> json) => _$AppInitialInfoFromJson(json);

  factory AppInitialInfo.empty() => AppInitialInfo(
    android: AppVersion.empty(),
    ios: AppVersion.empty(),
    serviceStatus: AppServiceStatus.empty(),
  );
}
