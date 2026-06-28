import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sedae_budget/presentation/presentation.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('SettingsTile renders', (tester) async {
    await tester.pumpWidget(_wrap(const SettingsTile(label: '버전')));
    expect(find.byType(SettingsTile), findsOneWidget);
  });
}
