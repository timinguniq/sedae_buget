import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';

void main() {
  testWidgets('tapping 수입 fires onChanged', (tester) async {
    TransactionType? picked;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TypeSegmented(
        value: TransactionType.expense, onChanged: (t) => picked = t))));
    await tester.tap(find.text('수입'));
    expect(picked, TransactionType.income);
  });
}
