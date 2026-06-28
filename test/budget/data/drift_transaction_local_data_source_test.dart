import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/budget/local/app_database.dart';
import 'package:sedae_budget/data/budget/transaction_local_data_source.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/transaction_type.dart';
import 'package:sedae_budget/entity/budget/sync_status.dart';

void main() {
  late AppDatabase db;
  late TransactionLocalDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = DriftTransactionLocalDataSource(db.transactionDao);
  });
  tearDown(() => db.close());

  test('upsert then getMonth maps row back to domain entity', () async {
    final tx = Transaction.create(
      amount: 3000, categoryId: 11, date: DateTime(2026, 6, 15),
      type: TransactionType.expense, memo: '점심',
    );
    await ds.upsert(tx);

    final result = await ds.getMonth(2026, 6);
    expect(result.length, 1);
    final loaded = result.single;
    expect(loaded.id, tx.id);
    expect(loaded.amount, 3000);
    expect(loaded.type, TransactionType.expense);
    expect(loaded.syncStatus, SyncStatus.pending);
    expect(loaded.memo, '점심');
  });

  test('getMonth excludes other months', () async {
    await ds.upsert(Transaction.create(
        amount: 1, categoryId: 1, date: DateTime(2026, 5, 31),
        type: TransactionType.expense));
    final june = await ds.getMonth(2026, 6);
    expect(june, isEmpty);
  });
}
