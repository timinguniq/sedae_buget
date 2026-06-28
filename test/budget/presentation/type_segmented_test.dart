import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';

void main() {
  testWidgets('tapping 수입 fires onChanged', (tester) async {
    TransactionType? picked;
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => ThemeService(),
      child: MaterialApp(home: Scaffold(body: TypeSegmented(
        value: TransactionType.expense, onChanged: (t) => picked = t))),
    ));
    await tester.tap(find.text('수입'));
    expect(picked, TransactionType.income);
  });
}
