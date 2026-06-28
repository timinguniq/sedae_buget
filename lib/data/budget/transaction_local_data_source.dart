import 'package:drift/drift.dart';
import 'package:sedae_budget/data/budget/local/app_database.dart';
import 'package:sedae_budget/entity/budget/sync_status.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/transaction_type.dart';

abstract class TransactionLocalDataSource {
  Future<void> upsert(Transaction tx);
  Future<List<Transaction>> getMonth(int year, int month);
  Future<List<Transaction>> getRange(DateTime start, DateTime end);
}

class DriftTransactionLocalDataSource implements TransactionLocalDataSource {
  DriftTransactionLocalDataSource(this._dao);

  final TransactionDao _dao;

  @override
  Future<void> upsert(Transaction tx) => _dao.upsertRow(_toCompanion(tx));

  @override
  Future<List<Transaction>> getMonth(int year, int month) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1); // 12월이면 다음 해 1월로 자동 보정
    final rows = await _dao.rowsForMonth(start, end);
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<Transaction>> getRange(DateTime start, DateTime end) async {
    final rows = await _dao.rowsInRange(start, end);
    return rows.map(_toDomain).toList();
  }

  TransactionsCompanion _toCompanion(Transaction t) => TransactionsCompanion(
        id: Value(t.id),
        amount: Value(t.amount),
        categoryId: Value(t.categoryId),
        date: Value(t.date),
        type: Value(t.type.index),
        memo: Value(t.memo),
        createdAt: Value(t.createdAt),
        updatedAt: Value(t.updatedAt),
        deletedAt: Value(t.deletedAt),
        syncStatus: Value(t.syncStatus.index),
      );

  Transaction _toDomain(TransactionRow r) => Transaction(
        id: r.id,
        amount: r.amount,
        categoryId: r.categoryId,
        date: r.date,
        type: TransactionType.values[r.type],
        memo: r.memo,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
        deletedAt: r.deletedAt,
        syncStatus: SyncStatus.values[r.syncStatus],
      );
}
