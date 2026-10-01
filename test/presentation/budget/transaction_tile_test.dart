import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/widget/transaction_tile.dart';
import 'package:sedae_budget/theme/theme.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko'));

  // 이전에는 첫 글자를 UTF-16 한 단위로 잘라, 이모지로 시작하는 사용자 카테고리의 거래를 그리지 못했다.
  testWidgets('이모지로 시작하는 카테고리도 첫 글자를 그린다', (tester) async {
    final tx = Transaction.create(
        amount: 1000, categoryId: 19, date: DateTime(2026, 9, 5), type: TransactionType.expense);

    await tester.pumpWidget(MaterialApp(
      theme: materialTheme(LightTheme()),
      home: Scaffold(body: TransactionTile(tx: tx, label: '🐶간식')),
    ));

    expect(tester.takeException(), isNull);
    expect(find.text('🐶'), findsOneWidget);
  });
}
