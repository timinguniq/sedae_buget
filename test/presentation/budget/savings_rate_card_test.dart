import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as provider;
import 'package:sedae_budget/presentation/page/budget/widget/savings_rate_card.dart';
import 'package:sedae_budget/presentation/service/theme_service.dart';
import 'package:sedae_budget/theme/theme.dart';

Widget _wrap(Widget child) => provider.ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp(home: Scaffold(body: child), theme: ThemeService().lightThemeData()));

void main() {
  testWidgets('shows rate, peer rate and encouragement when below peer', (t) async {
    await t.pumpWidget(_wrap(const SavingsRateCard(rate: 18, peerRate: 23)));
    await t.pump();
    expect(find.text('이번 달 저축률 18%'), findsOneWidget);
    expect(find.text('18%'), findsOneWidget); // 도넛 중앙
    expect(find.text('또래 평균 23% · 조금 더 모아볼까요?'), findsOneWidget);
    expect(find.byType(CategoryDonut), findsOneWidget);
  });

  testWidgets('praises when at or above peer and clamps rate', (t) async {
    await t.pumpWidget(_wrap(const SavingsRateCard(rate: 130, peerRate: 23)));
    await t.pump();
    expect(find.text('이번 달 저축률 100%'), findsOneWidget);
    expect(find.text('또래 평균 23% · 잘 모으고 있어요'), findsOneWidget);
  });
}
