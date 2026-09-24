import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_version.freezed.dart';
part 'app_version.g.dart';

@freezed
abstract class AppVersion with _$AppVersion {
  const factory AppVersion({
    required int releaseVersion,
    required int minimumAvailableVersion,
    required String link,
  }) = _AppVersion;

  factory AppVersion.fromJson(Map<String, dynamic> json) => _$AppVersionFromJson(json);
}
