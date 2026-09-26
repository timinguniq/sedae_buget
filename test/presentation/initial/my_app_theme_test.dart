import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sedae_budget/core/ads/index.dart';
import 'package:sedae_budget/core/local_storage/theme_mode_store.dart';
import 'package:sedae_budget/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helper/fakes.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  // 이전에는 시스템 모드로 먼저 그린 뒤 저장된 모드를 비동기로 읽어, 시작하는 순간 다른 테마가 비쳤다.
  testWidgets('저장된 테마 모드로 첫 화면부터 그린다', (t) async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final prefs = await SharedPreferences.getInstance();
    final ads = FakeAdService();
    final container = fakeContainer(
      adService: ads,
      themeModeStore: ThemeModeStore(prefs),
      launchInterstitial: LaunchInterstitial(prefs, ads),
    );

    await t.pumpWidget(fakeScope(container, const MyApp()));

    expect(t.widget<MaterialApp>(find.byType(MaterialApp)).themeMode, ThemeMode.dark);
    await t.pump(const Duration(milliseconds: 2100)); // 스플래시 타이머를 끝낸다
    await t.settle();
  });
}
