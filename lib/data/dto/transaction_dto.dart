import 'package:json_annotation/json_annotation.dart';
import 'package:sedae_budget/entity/entity.dart';

part 'transaction_dto.g.dart';

/// `/v1/transactions` 응답 한 건. 일시는 서버가 UTC로 준다.
@JsonSerializable(createToJson: false)
class TransactionDto {
  const TransactionDto({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.type,
    this.memo,
    this.customCategoryId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionDto.fromJson(Map<String, dynamic> json) => _$TransactionDtoFromJson(json);

  final String id;
  final int amount;
  final int categoryId;
  final DateTime date;
  final TransactionType type;
  final String? memo;
  final String? customCategoryId;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// 서버 응답(UTC) → 엔티티(로컬 시각).
  Transaction toEntity() => Transaction(
        id: id,
        amount: amount,
        categoryId: categoryId,
        date: date.toLocal(),
        type: type,
        memo: memo,
        customCategoryId: customCategoryId,
        createdAt: createdAt.toLocal(),
        updatedAt: updatedAt.toLocal(),
      );
}

/// PUT 바디. id/createdAt/updatedAt은 서버 소관이라 보내지 않는다.
@JsonSerializable(createFactory: false)
class TransactionBodyDto {
  const TransactionBodyDto({
    required this.amount,
    required this.categoryId,
    required this.date,
    required this.type,
    this.memo,
    this.customCategoryId,
  });

  /// 일시는 UTC로 보낸다.
  factory TransactionBodyDto.fromEntity(Transaction t) => TransactionBodyDto(
        amount: t.amount,
        categoryId: t.categoryId,
        date: t.date.toUtc(),
        type: t.type,
        memo: t.memo,
        customCategoryId: t.customCategoryId,
      );

  final int amount;
  final int categoryId;
  final DateTime date;
  final TransactionType type;
  final String? memo;
  final String? customCategoryId;

  Map<String, dynamic> toJson() => _$TransactionBodyDtoToJson(this);
}

/// 기간 조회 쿼리 값(UTC ISO-8601).
String utcQuery(DateTime local) => local.toUtc().toIso8601String();
