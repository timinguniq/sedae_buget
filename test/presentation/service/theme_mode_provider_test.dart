import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/core/local_storage/theme_mode_store.dart';
import 'package:sedae_budget/presentation/service/theme_mode_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<ThemeModeStore> store(Map<String, Object> saved) async {
    SharedPreferences.setMockInitialValues(saved);
    return ThemeModeStore(await SharedPreferences.getInstance());
  }

  ProviderContainer container(ThemeModeStore s) {
    final c = ProviderContainer(overrides: [themeModeStoreProvider.overrideWithValue(s)]);
    addTearDown(c.dispose);
    return c;
  }

  test('고른 적이 없거나 모르는 값이면 시스템 모드', () async {
    expect(container(await store({})).read(themeModeProvider), ThemeMode.system);
    expect(container(await store({'theme_mode': 'sepia'})).read(themeModeProvider), ThemeMode.system);
  });

  // 저장된 값을 첫 read에서 바로 돌려준다(비동기로 늦게 바꾸면 시작 화면이 다른 테마로 번쩍인다).
  test('저장된 모드로 바로 시작한다', () async {
    expect(container(await store({'theme_mode': 'dark'})).read(themeModeProvider), ThemeMode.dark);
  });

  test('고르면 바로 바뀌고 다음 실행을 위해 저장한다', () async {
    final s = await store({});
    final c = container(s);
    await c.read(themeModeProvider.notifier).select(ThemeMode.light);
    expect(c.read(themeModeProvider), ThemeMode.light);
    expect(container(s).read(themeModeProvider), ThemeMode.light);
  });
}
