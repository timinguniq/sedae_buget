import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  test('empty() uses injected current build as releaseVersion', () {
    final info = AppInitialInfo.empty(currentBuild: 42);
    expect(info.android.releaseVersion, 42);
    expect(info.ios.releaseVersion, 42);
    expect(info.serviceStatus.available, isTrue);
  });
}
