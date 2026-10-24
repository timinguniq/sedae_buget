import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sedae_budget/core/app_config/initial_info_json.dart';
import 'package:sedae_budget/entity/entity.dart';

AppInitialInfo _parse(Map<String, dynamic> json) => initialInfoFromJson(json);

/// 원격 설정 `initialInfo` 값(JSON). [expected]는 점검 예정 시각 문자열이다.
Map<String, dynamic> _json({String expected = '2026-09-24 23:59:59'}) => {
      'android': {'releaseVersion': 20, 'minimumAvailableVersion': 15, 'link': 'android-store'},
      'ios': {'releaseVersion': 30, 'minimumAvailableVersion': 25, 'link': 'ios-store'},
      'serviceStatus': {
        'available': false,
        'noticeTitle': '점검 중',
        'noticeContent': '곧 돌아올게요',
        'expectedTimeToBeAvailable': expected,
      },
    };

void main() {
  setUpAll(initializeDateFormatting);

  test('initialInfo의 모든 필드를 읽는다', () {
    expect(
      _parse(_json()),
      AppInitialInfo(
        android: const AppVersion(releaseVersion: 20, minimumAvailableVersion: 15, link: 'android-store'),
        ios: const AppVersion(releaseVersion: 30, minimumAvailableVersion: 25, link: 'ios-store'),
        serviceStatus: AppServiceStatus(
          available: false,
          noticeTitle: '점검 중',
          noticeContent: '곧 돌아올게요',
          expectedTimeToBeAvailable: DateTime(2026, 9, 24, 23, 59, 59),
        ),
      ),
    );
  });

  // JSON 숫자는 20.0처럼 소수점을 붙여 올 수 있다.
  test('버전 번호는 실수로 와도 정수로 읽는다', () {
    final json = _json()
      ..['android'] = {'releaseVersion': 20.0, 'minimumAvailableVersion': 15.0, 'link': 'android-store'};
    expect(_parse(json).android,
        const AppVersion(releaseVersion: 20, minimumAvailableVersion: 15, link: 'android-store'));
  });

  // 12시간제 형식(hh)도 23시는 받아 주지만 12시를 0시로 읽는다. 형식은 24시간제(HH)다.
  test('점검 예정 시각은 24시간제로 읽는다', () {
    DateTime read(String s) => _parse(_json(expected: s)).serviceStatus.expectedTimeToBeAvailable;
    expect(read('2026-09-24 12:30:00'), DateTime(2026, 9, 24, 12, 30));
    expect(read('2026-09-24 23:59:59'), DateTime(2026, 9, 24, 23, 59, 59));
  });

  // 읽는 쪽(FirebaseAppStatusSource)은 던지면 형식이 잘못된 것으로 보고 판정하지 않는다.
  test('필드가 빠졌거나 날짜 형식이 다르면 던진다', () {
    expect(() => _parse({..._json(), 'ios': null}), throwsA(isA<TypeError>()));
    expect(() => _parse(_json(expected: '2026/09/24 23:59:59')), throwsFormatException);
    expect(() => _parse(_json(expected: '2026-09-24')), throwsFormatException); // 시각이 없다
    expect(() => _parse(_json(expected: '2026-09-24T23:59:59')), throwsFormatException); // ISO 8601
  });
}
