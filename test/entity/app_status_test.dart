import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

const _android = AppVersion(releaseVersion: 20, minimumAvailableVersion: 15, link: 'android-store');
const _ios = AppVersion(releaseVersion: 30, minimumAvailableVersion: 25, link: 'ios-store');

AppInitialInfo _info({bool available = true}) => AppInitialInfo(
      android: _android,
      ios: _ios,
      serviceStatus: AppServiceStatus(
        available: available,
        noticeTitle: '점검 중',
        noticeContent: '곧 돌아올게요',
        expectedTimeToBeAvailable: DateTime(2026, 9, 24, 23, 59, 59),
      ),
    );

AppStatus _of(AppInitialInfo? info, {int? build = 20, bool isIOS = false}) =>
    AppStatus.of(info, build: build, isIOS: isIOS);

void main() {
  test('원격 정보가 없으면(원격 설정을 못 읽음) 쓸 수 있다', () {
    expect(_of(null, build: 1), isA<AppAvailable>());
  });

  test('빌드 번호를 모르면 업데이트를 묻지 않는다', () {
    expect(_of(_info(), build: null), isA<AppAvailable>());
  });

  test('점검 중이면 빌드와 무관하게 점검 안내', () {
    final status = _of(_info(available: false), build: 99);
    expect(status, isA<AppUnderMaintenance>());
    expect((status as AppUnderMaintenance).notice.noticeTitle, '점검 중');
  });

  test('출시 버전 이상이면 쓸 수 있다', () {
    expect(_of(_info(), build: 20), isA<AppAvailable>());
    expect(_of(_info(), build: 21), isA<AppAvailable>());
  });

  test('출시 버전보다 낮지만 최소 버전 이상이면 선택 업데이트', () {
    final status = _of(_info(), build: 15);
    expect(status, isA<AppUpdateAvailable>());
    expect((status as AppUpdateAvailable).forced, isFalse);
    expect(status.version.link, 'android-store');
  });

  test('최소 버전보다 낮으면 강제 업데이트', () {
    final status = _of(_info(), build: 14) as AppUpdateAvailable;
    expect(status.forced, isTrue);
  });

  test('iOS는 iOS 버전 정보로 판정한다', () {
    final status = _of(_info(), build: 24, isIOS: true) as AppUpdateAvailable;
    expect(status.forced, isTrue);
    expect(status.version.link, 'ios-store');
  });
}
