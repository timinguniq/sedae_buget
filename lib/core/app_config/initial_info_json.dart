import 'package:intl/intl.dart';
import 'package:sedae_budget/entity/entity.dart';

/// 원격 설정 `initialInfo` 값(JSON)을 엔티티로 읽는다. 이 JSON 형식은 여기만 안다.
/// 필드가 빠졌거나 타입·날짜 형식이 다르면 던진다.
AppInitialInfo initialInfoFromJson(Map<String, dynamic> json) => AppInitialInfo(
      android: _version(json['android'] as Map<String, dynamic>),
      ios: _version(json['ios'] as Map<String, dynamic>),
      serviceStatus: _serviceStatus(json['serviceStatus'] as Map<String, dynamic>),
    );

AppVersion _version(Map<String, dynamic> json) => AppVersion(
      releaseVersion: (json['releaseVersion'] as num).toInt(),
      minimumAvailableVersion: (json['minimumAvailableVersion'] as num).toInt(),
      link: json['link'] as String,
    );

AppServiceStatus _serviceStatus(Map<String, dynamic> json) => AppServiceStatus(
      available: json['available'] as bool,
      noticeTitle: json['noticeTitle'] as String,
      noticeContent: json['noticeContent'] as String,
      expectedTimeToBeAvailable: _parseDateTime(json['expectedTimeToBeAvailable'] as String),
    );

const String _dateTimeFormat = 'yyyy-MM-dd HH:mm:ss'; // 2024-04-22 23:59:59 (24시간제)

DateTime _parseDateTime(String date) {
  return DateFormat(_dateTimeFormat, 'ko-KR').parse(date);
}
