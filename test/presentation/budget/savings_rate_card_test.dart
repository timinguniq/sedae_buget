import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/widget/savings_rate_card.dart';
import 'package:sedae_budget/theme/theme.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child), theme: materialTheme(LightTheme()));

void main() {
  testWidgets('shows rate, peer rate and encouragement when below peer', (t) async {
    await t.pumpWidget(_wrap(const SavingsRateCard(label: '이번 달', rate: 18, peer: SavingsComparison(mine: 18, peer: 23))));
    await t.pump();
    expect(find.text('이번 달 저축률 18%'), findsOneWidget);
    expect(find.text('18%'), findsOneWidget); // 도넛 중앙
    expect(find.text('또래 평균 23% · 조금 더 모아볼까요?'), findsOneWidget);
    expect(find.byType(CategoryDonut), findsOneWidget);
  });

  testWidgets('praises when at or above peer', (t) async {
    await t.pumpWidget(_wrap(const SavingsRateCard(label: '이번 달', rate: 30, peer: SavingsComparison(mine: 30, peer: 23))));
    await t.pump();
    expect(find.text('이번 달 저축률 30%'), findsOneWidget);
    expect(find.text('또래 평균 23% · 잘 모으고 있어요'), findsOneWidget);
  });

  // 이전에는 홈만 0%로 잘라, 비교·리포트의 -20%와 달랐다. 도넛만 0에서 멈춘다.
  testWidgets('지출이 소득보다 많으면 음수 저축률을 그대로 보인다', (t) async {
    await t.pumpWidget(_wrap(const SavingsRateCard(label: '8월', rate: -20, peer: SavingsComparison(mine: -20, peer: 23))));
    await t.pump();
    expect(find.text('8월 저축률 -20%'), findsOneWidget);
    expect(find.text('-20%'), findsOneWidget); // 도넛 중앙
    final donut = t.widget<CategoryDonut>(find.byType(CategoryDonut));
    expect(donut.values, [0, 100]);
  });
}
