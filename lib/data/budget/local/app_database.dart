import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  IntColumn get amount => integer()();
  IntColumn get categoryId => integer()();
  DateTimeColumn get date => dateTime()();
  IntColumn get type => integer()(); // TransactionType.index
  TextColumn get memo => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncStatus => integer()(); // SyncStatus.index

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Transactions], daos: [TransactionDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'sedae_budget'));

  /// 테스트용 인메모리 생성자.
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<void> upsertRow(TransactionsCompanion row) =>
      into(transactions).insertOnConflictUpdate(row);

  /// [start, end) 범위 + 미삭제만, 최신순.
  Future<List<TransactionRow>> rowsInRange(DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end) &
              t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<TransactionRow>> rowsForMonth(DateTime start, DateTime end) =>
      rowsInRange(start, end);
}
