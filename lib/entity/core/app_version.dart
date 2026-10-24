import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version.freezed.dart';

@freezed
abstract class AppVersion with _$AppVersion {
  const factory AppVersion({
    required int releaseVersion,
    required int minimumAvailableVersion,
    required String link,
  }) = _AppVersion;
}
