import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedae_budget/data/budget/local/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  TransactionsCompanion row(String id, DateTime date, {DateTime? deletedAt}) {
    final now = DateTime(2026, 1, 1);
    return TransactionsCompanion.insert(
      id: id,
      amount: 1000,
      categoryId: 7,
      date: date,
      type: 0,
      createdAt: now,
      updatedAt: now,
      deletedAt: Value(deletedAt),
      syncStatus: 0,
    );
  }

  test('rowsForMonth returns only same-month, non-deleted rows', () async {
    await db.transactionDao.upsertRow(row('a', DateTime(2026, 6, 10)));
    await db.transactionDao.upsertRow(row('b', DateTime(2026, 7, 1))); // 다음 달
    await db.transactionDao
        .upsertRow(row('c', DateTime(2026, 6, 20), deletedAt: DateTime(2026, 6, 21)));

    final rows = await db.transactionDao
        .rowsForMonth(DateTime(2026, 6, 1), DateTime(2026, 7, 1));

    expect(rows.map((r) => r.id), ['a']);
  });

  test('upsertRow replaces on same id', () async {
    await db.transactionDao.upsertRow(row('a', DateTime(2026, 6, 10)));
    await db.transactionDao.upsertRow(
      row('a', DateTime(2026, 6, 10)).copyWith(amount: const Value(5000)),
    );

    final rows = await db.transactionDao
        .rowsForMonth(DateTime(2026, 6, 1), DateTime(2026, 7, 1));
    expect(rows.single.amount, 5000);
  });
}
