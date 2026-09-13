import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

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

  testWidgets('시스템 썸네일은 라이트/다크 반반이 썸네일 높이를 채운다', (tester) async {
    await tester.pumpWidget(_wrap(ThemeModeSelector(value: ThemeMode.light, onChanged: (_) {})));
    // 다크 썸네일 배경 + 시스템 썸네일 오른쪽 반 = darkBg ColoredBox 2개. 둘 다 높이가 0이면 안 된다.
    final darkHalves = find.byWidgetPredicate((w) => w is ColoredBox && w.color == Palette.darkBg);
    expect(darkHalves, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      expect(tester.getSize(darkHalves.at(i)).height, greaterThan(50));
    }
  });

  testWidgets('tapping a thumbnail label reports the mode', (tester) async {
    ThemeMode? picked;
    await tester.pumpWidget(_wrap(ThemeModeSelector(value: ThemeMode.system, onChanged: (m) => picked = m)));
    await tester.tap(find.text('다크'));
    expect(picked, ThemeMode.dark);
  });
}
