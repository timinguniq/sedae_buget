import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/data.dart';
import 'package:sedae_budget/entity/entity.dart';

void main() {
  test('toBody omits server-owned fields and sends UTC date', () {
    final tx = Transaction.create(
      amount: 12000, categoryId: 7, date: DateTime(2026, 9, 6), // 로컬 자정
      type: TransactionType.expense, memo: '버스',
    );
    final body = transactionToBody(tx);
    expect(body.keys,
        unorderedEquals(['amount', 'categoryId', 'date', 'type', 'memo', 'customCategoryId']));
    expect(body['type'], 'expense');
    expect(body['customCategoryId'], isNull);
    expect((body['date'] as String).endsWith('Z'), isTrue);
    expect(DateTime.parse(body['date'] as String), DateTime(2026, 9, 6).toUtc());
  });

  test('fromJson converts UTC strings to local DateTime', () {
    final tx = transactionFromJson({
      'id': 'x', 'amount': 500, 'categoryId': 2,
      'date': '2026-09-05T15:00:00.000Z', 'type': 'income', 'memo': null,
      'createdAt': '2026-09-06T01:02:03.000Z', 'updatedAt': '2026-09-06T01:02:04.000Z',
    });
    expect(tx.id, 'x');
    expect(tx.type, TransactionType.income);
    expect(tx.memo, isNull);
    expect(tx.date.isUtc, isFalse);
    expect(tx.date.toUtc(), DateTime.utc(2026, 9, 5, 15));
    expect(tx.createdAt.toUtc(), DateTime.utc(2026, 9, 6, 1, 2, 3));
    expect(tx.updatedAt.toUtc(), DateTime.utc(2026, 9, 6, 1, 2, 4));
    expect(tx.customCategoryId, isNull);
  });

  test('customCategoryId round-trips', () {
    final body = transactionToBody(Transaction.create(
      amount: 3000, categoryId: 12, date: DateTime(2026, 9, 6),
      type: TransactionType.expense, customCategoryId: 'cat-1',
    ));
    expect(body['customCategoryId'], 'cat-1');
    final tx = transactionFromJson({
      'id': 'x', 'amount': 3000, 'categoryId': 12,
      'date': '2026-09-05T15:00:00.000Z', 'type': 'expense', 'memo': null,
      'customCategoryId': 'cat-1',
      'createdAt': '2026-09-06T01:02:03.000Z', 'updatedAt': '2026-09-06T01:02:04.000Z',
    });
    expect(tx.customCategoryId, 'cat-1');
  });

  test('utcQuery formats a local instant as UTC ISO-8601', () {
    final q = utcQuery(DateTime(2026, 9, 1));
    expect(q.endsWith('Z'), isTrue);
    expect(DateTime.parse(q), DateTime(2026, 9, 1).toUtc());
  });
}
