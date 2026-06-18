// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_initial_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppInitialInfo _$AppInitialInfoFromJson(Map<String, dynamic> json) =>
    _AppInitialInfo(
      android: AppVersion.fromJson(json['android'] as Map<String, dynamic>),
      ios: AppVersion.fromJson(json['ios'] as Map<String, dynamic>),
      serviceStatus: AppServiceStatus.fromJson(
        json['serviceStatus'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$AppInitialInfoToJson(_AppInitialInfo instance) =>
    <String, dynamic>{
      'android': instance.android,
      'ios': instance.ios,
      'serviceStatus': instance.serviceStatus,
    };
