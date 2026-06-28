import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/budget/local/app_database.dart';
import 'package:sedae_budget/data/budget/transaction_local_data_source.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/transaction_type.dart';

void main() {
  late AppDatabase db;
  late TransactionLocalDataSource ds;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    ds = DriftTransactionLocalDataSource(db.transactionDao);
  });
  tearDown(() => db.close());

  test('getRange returns only non-deleted txs in [start, end)', () async {
    // April tx — outside range (before start)
    await ds.upsert(Transaction.create(
      amount: 10000, categoryId: 1, date: DateTime(2026, 4, 15),
      type: TransactionType.expense,
    ));

    // May tx — inside range
    final mayTx = Transaction.create(
      amount: 20000, categoryId: 7, date: DateTime(2026, 5, 10),
      type: TransactionType.expense,
    );
    await ds.upsert(mayTx);

    // June tx — inside range
    final juneTx = Transaction.create(
      amount: 30000, categoryId: 11, date: DateTime(2026, 6, 20),
      type: TransactionType.expense,
    );
    await ds.upsert(juneTx);

    // Soft-deleted tx inside range — must be excluded
    final deletedTx = Transaction.create(
      amount: 99000, categoryId: 3, date: DateTime(2026, 5, 25),
      type: TransactionType.expense,
    );
    await ds.upsert(deletedTx.markDeleted());

    final result = await ds.getRange(DateTime(2026, 5), DateTime(2026, 7));

    expect(result.length, 2);
    final ids = result.map((t) => t.id).toSet();
    expect(ids.contains(mayTx.id), isTrue);
    expect(ids.contains(juneTx.id), isTrue);
    // April and deleted must not appear
    expect(result.any((t) => t.amount == 10000), isFalse);
    expect(result.any((t) => t.amount == 99000), isFalse);
  });
}
