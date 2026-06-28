import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sedae_budget/presentation/presentation.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'sedae', packageName: 'com.sedae.budget',
      version: '1.0.0', buildNumber: '1', buildSignature: '');
  });

  testWidgets('renders and dark chip switches theme mode', (tester) async {
    final service = ThemeService();
    await tester.pumpWidget(ProviderScope(
      child: provider.ChangeNotifierProvider<ThemeService>.value(
        value: service,
        child: const MaterialApp(home: SettingPage()),
      ),
    ));
    await tester.pump();

    expect(find.text('설정'), findsOneWidget);
    expect(find.byType(ThemeModeSelector), findsOneWidget);

    await tester.tap(find.text('다크'));
    await tester.pump();
    expect(service.themeMode, ThemeMode.dark);
  });
}
