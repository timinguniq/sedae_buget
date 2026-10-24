import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_service_status.freezed.dart';

@freezed
abstract class AppServiceStatus with _$AppServiceStatus {
  const factory AppServiceStatus({
    required bool available,
    required String noticeTitle,
    required String noticeContent,
    required DateTime expectedTimeToBeAvailable,
  }) = _AppServiceStatus;
}
