import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sedae_budget/presentation/presentation.dart';

Widget _wrap(Widget child) => ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('ThemeModeSelector renders header with current value and 3 thumbnails', (tester) async {
    await tester.pumpWidget(_wrap(ThemeModeSelector(value: ThemeMode.system, onChanged: (_) {})));
    expect(find.byType(ThemeModeSelector), findsOneWidget);
    expect(find.text('테마'), findsOneWidget);
    expect(find.text('시스템'), findsNWidgets(2)); // 헤더 현재값 + 썸네일 라벨
    expect(find.text('라이트'), findsOneWidget);
    expect(find.text('다크'), findsOneWidget);
  });

  testWidgets('tapping a thumbnail label reports the mode', (tester) async {
    ThemeMode? picked;
    await tester.pumpWidget(_wrap(ThemeModeSelector(value: ThemeMode.system, onChanged: (m) => picked = m)));
    await tester.tap(find.text('다크'));
    expect(picked, ThemeMode.dark);
  });
}
