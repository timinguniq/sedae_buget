import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/transaction_type.dart';
import 'package:sedae_budget/entity/budget/sync_status.dart';

void main() {
  test('create sets uuid id, timestamps and pending status', () {
    final tx = Transaction.create(
      amount: 12000,
      categoryId: 7,
      date: DateTime(2026, 6, 21),
      type: TransactionType.expense,
      memo: '버스',
    );
    expect(tx.id, isNotEmpty);
    expect(tx.amount, 12000);
    expect(tx.deletedAt, isNull);
    expect(tx.syncStatus, SyncStatus.pending);
    expect(tx.createdAt, tx.updatedAt);
  });

  test('markDeleted sets tombstone and re-flags pending', () {
    final tx = Transaction.create(
      amount: 1, categoryId: 1, date: DateTime(2026, 1, 1),
      type: TransactionType.expense,
    ).copyWith(syncStatus: SyncStatus.synced);

    final deleted = tx.markDeleted();
    expect(deleted.deletedAt, isNotNull);
    expect(deleted.syncStatus, SyncStatus.pending);
  });

  test('json round-trips', () {
    final tx = Transaction.create(
      amount: 500, categoryId: 2, date: DateTime(2026, 3, 4),
      type: TransactionType.income,
    );
    expect(Transaction.fromJson(tx.toJson()), tx);
  });
}
