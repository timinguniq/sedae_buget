import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sedae_budget/presentation/page/setting/setting.view_model.dart';

PackageInfo _info(String version) =>
    PackageInfo(appName: 'sedae', packageName: 'com.sedae.budget', version: version, buildNumber: '1');

void main() {
  test('설치된 앱의 버전을 돌려준다', () async {
    expect(await readAppVersion(() async => _info('1.2.3')), '1.2.3');
  });

  // 빈 버전을 그대로 두면 설정 화면에 'v'만 보인다.
  test('버전이 비어 있으면 null', () async {
    expect(await readAppVersion(() async => _info('')), isNull);
  });

  // 예: 웹에서 version.json 요청이 실패할 때.
  test('플랫폼에서 읽지 못하면 null', () async {
    expect(await readAppVersion(() async => throw PlatformException(code: 'unavailable')), isNull);
  });

  // provider가 readAppVersion을 거치는지 본다. 모의값은 플랫폼을 부르지 않아 OS와 무관하다.
  test('appVersionProvider도 빈 버전을 null로 준다', () async {
    PackageInfo.setMockInitialValues(
        appName: 'sedae', packageName: 'com.sedae.budget', version: '', buildNumber: '1', buildSignature: '');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(await container.read(appVersionProvider.future), isNull);
  });
}
