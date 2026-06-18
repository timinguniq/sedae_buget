// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppVersion _$AppVersionFromJson(Map<String, dynamic> json) => _AppVersion(
  releaseVersion: (json['releaseVersion'] as num).toInt(),
  minimumAvailableVersion: (json['minimumAvailableVersion'] as num).toInt(),
  link: json['link'] as String,
);

Map<String, dynamic> _$AppVersionToJson(_AppVersion instance) =>
    <String, dynamic>{
      'releaseVersion': instance.releaseVersion,
      'minimumAvailableVersion': instance.minimumAvailableVersion,
      'link': instance.link,
    };
