// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_service_status.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppServiceStatus _$AppServiceStatusFromJson(Map<String, dynamic> json) =>
    _AppServiceStatus(
      available: json['available'] as bool,
      noticeTitle: json['noticeTitle'] as String,
      noticeContent: json['noticeContent'] as String,
      expectedTimeToBeAvailable: _formatStringToDateTime(
        json['expectedTimeToBeAvailable'] as String,
      ),
    );

Map<String, dynamic> _$AppServiceStatusToJson(_AppServiceStatus instance) =>
    <String, dynamic>{
      'available': instance.available,
      'noticeTitle': instance.noticeTitle,
      'noticeContent': instance.noticeContent,
      'expectedTimeToBeAvailable': _dateTimeToString(
        instance.expectedTimeToBeAvailable,
      ),
    };
