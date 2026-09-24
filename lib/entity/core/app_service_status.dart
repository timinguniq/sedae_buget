import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'app_service_status.freezed.dart';
part 'app_service_status.g.dart';

@freezed
abstract class AppServiceStatus with _$AppServiceStatus {
  const factory AppServiceStatus({
    required bool available,
    required String noticeTitle,
    required String noticeContent,
    // ignore_for_file: invalid_annotation_target
    @JsonKey(fromJson: _formatStringToDateTime, toJson: _dateTimeToString) required DateTime expectedTimeToBeAvailable,
  }) = _AppServiceStatus;

  factory AppServiceStatus.fromJson(Map<String, dynamic> json) => _$AppServiceStatusFromJson(json);
}

const String _DATE_TIME_FORMAT = 'yyyy-MM-dd HH:mm:ss'; // 2024-04-22 23:59:59 (24시간제)

DateTime _formatStringToDateTime(String date) {
  return DateFormat(_DATE_TIME_FORMAT, 'ko-KR').parse(date);
}

String _dateTimeToString(DateTime date) {
  return DateFormat(_DATE_TIME_FORMAT, 'ko-KR').format(date);
}
