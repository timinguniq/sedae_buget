import 'dart:io';

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

  factory AppVersion.empty({required int releaseVersion}) => AppVersion(
    releaseVersion: releaseVersion,
    minimumAvailableVersion: 0,
    link: Platform.isIOS
        ? 'itms-apps://apps.apple.com/kr/app/1506564650'
        : 'https://play.google.com/store/apps/details?id=io.kooky.kooky',
  );
}
