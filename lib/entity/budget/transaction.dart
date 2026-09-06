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
    required int categoryId, // 통계청 12분류 id. 커스텀 카테고리면 그 상위 분류
    required DateTime date,
    required TransactionType type,
    String? memo,

    /// 사용자가 만든 카테고리(CustomCategory) id. null이면 기본 분류 그대로.
    String? customCategoryId,
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
    String? customCategoryId,
  }) {
    final now = DateTime.now();
    return Transaction(
      id: const Uuid().v4(),
      amount: amount,
      categoryId: categoryId,
      date: date,
      type: type,
      memo: memo,
      customCategoryId: customCategoryId,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);
}
