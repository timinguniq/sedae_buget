import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/core/local_storage/theme_mode_store.dart';

/// 테마 모드 저장소. DI에 등록된 [ThemeModeStore]를 넘긴다.
final themeModeStoreProvider = Provider<ThemeModeStore>((_) => locator<ThemeModeStore>());

/// 앱 테마 모드(시스템·라이트·다크). 저장된 값을 동기로 읽어 시작 화면부터 맞는 테마로 그린다.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeModeStore get _store => ref.read(themeModeStoreProvider);

  @override
  ThemeMode build() => _store.read();

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await _store.write(mode);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
