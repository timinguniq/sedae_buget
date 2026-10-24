import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'app_initial_info.freezed.dart';

@freezed
abstract class AppInitialInfo with _$AppInitialInfo {
  const factory AppInitialInfo({
    required AppVersion android,
    required AppVersion ios,
    required AppServiceStatus serviceStatus,
  }) = _AppInitialInfo;
}
