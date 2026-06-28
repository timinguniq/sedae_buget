import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:sedae_budget/entity/budget/sync_status.dart';
import 'package:sedae_budget/entity/budget/transaction_type.dart';

part 'transaction.freezed.dart';
part 'transaction.g.dart';

@freezed
abstract class Transaction with _$Transaction {
  const factory Transaction({
    required String id,
    required int amount, // 원 단위 정수
    required int categoryId,
    required DateTime date,
    required TransactionType type,
    String? memo,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt, // tombstone (삭제 동기화 대비)
    required SyncStatus syncStatus,
  }) = _Transaction;

  factory Transaction.create({
    required int amount,
    required int categoryId,
    required DateTime date,
    required TransactionType type,
    String? memo,
  }) {
    final now = DateTime.now();
    return Transaction(
      id: const Uuid().v4(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      type: type,
      memo: memo,
      createdAt: now,
      updatedAt: now,
      deletedAt: null,
      syncStatus: SyncStatus.pending,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}

extension TransactionX on Transaction {
  Transaction markUpdated() =>
      copyWith(updatedAt: DateTime.now(), syncStatus: SyncStatus.pending);

  Transaction markDeleted() {
    final now = DateTime.now();
    return copyWith(
      deletedAt: now,
      updatedAt: now,
      syncStatus: SyncStatus.pending,
    );
  }
}
