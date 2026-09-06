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
    expect(find.text('›'), findsNothing); // 탭 없으면 chevron 없음
  });

  testWidgets('SettingsTile with onTap shows value and chevron, fires tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_wrap(SettingsTile(label: '카테고리 관리', value: '기본 12', onTap: () => taps++)));
    expect(find.text('기본 12'), findsOneWidget);
    expect(find.text('›'), findsOneWidget);
    await tester.tap(find.text('카테고리 관리'));
    expect(taps, 1);
  });
}
