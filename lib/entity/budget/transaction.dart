import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
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
    required DateTime createdAt, // 서버가 정함
    required DateTime updatedAt, // 서버가 정함
  }) = _Transaction;

  /// 새 거래. id는 클라이언트 UUID, 타임스탬프는 서버 응답으로 대체되는 자리표시.
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
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
