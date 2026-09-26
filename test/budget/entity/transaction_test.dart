import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/transaction_type.dart';

void main() {
  test('create sets uuid id and placeholder timestamps', () {
    final tx = Transaction.create(
      amount: 12000,
      categoryId: 7,
      date: DateTime(2026, 6, 21),
      type: TransactionType.expense,
      memo: '버스',
    );
    expect(tx.id, isNotEmpty);
    expect(tx.amount, 12000);
    expect(tx.createdAt, tx.updatedAt);
  });
}
