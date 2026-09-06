import 'package:sedae_budget/entity/entity.dart';

/// 서버 응답(UTC) → 엔티티(로컬 시각).
Transaction transactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      categoryId: (json['categoryId'] as num).toInt(),
      date: DateTime.parse(json['date'] as String).toLocal(),
      type: TransactionType.values.byName(json['type'] as String),
      memo: json['memo'] as String?,
      customCategoryId: json['customCategoryId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
    );

/// PUT 바디. id/createdAt/updatedAt은 서버 소관이라 보내지 않는다.
Map<String, dynamic> transactionToBody(Transaction t) => {
      'amount': t.amount,
      'categoryId': t.categoryId,
      'date': t.date.toUtc().toIso8601String(),
      'type': t.type.name,
      'memo': t.memo,
      'customCategoryId': t.customCategoryId,
    };

/// 기간 조회 쿼리 값(UTC ISO-8601).
String utcQuery(DateTime local) => local.toUtc().toIso8601String();
