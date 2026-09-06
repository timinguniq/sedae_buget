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

  factory AppServiceStatus.empty() => AppServiceStatus(
    available: true,
    noticeTitle: 'Under Maintenance',
    noticeContent: 'Maintenance in progress.\nThank for your patience!\nWe’ll be back in 13:52 tomorrow!(KST)',
    expectedTimeToBeAvailable: DateTime.now(),
  );
}

const String _DATE_TIME_FORMAT = 'yyyy-MM-dd hh:mm:ss'; // 2024-04-22 23:59:59

DateTime _formatStringToDateTime(String date) {
  return DateFormat(_DATE_TIME_FORMAT, 'ko-KR').parse(date);
}

String _dateTimeToString(DateTime date) {
  return DateFormat(_DATE_TIME_FORMAT, 'ko-KR').format(date);
}
