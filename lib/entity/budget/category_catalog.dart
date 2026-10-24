import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/budget/custom_category.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';

/// 거래 하나가 속한 카테고리. 화면에는 [label]로 보이고, 또래 비교 집계는 언제나 [base]로 한다.
class TransactionCategory {
  const TransactionCategory(this.base, [this.custom]);

  final BudgetCategory base;

  /// 사용자 카테고리. null이면 기본 분류 그대로.
  final CustomCategory? custom;

  String get label => custom?.name ?? base.label;
}

/// 기본 분류와 사용자 카테고리를 함께 아는 목록. 거래의 카테고리는 여기서만 판정한다.
class CategoryCatalog {
  /// 다 읽은 사용자 카테고리 목록([customs]). 여기 없는 사용자 카테고리는 지워진 것이다.
  const CategoryCatalog([this.customs = const []]) : isComplete = true;

  /// 사용자 카테고리 목록을 모른다(읽는 중이거나 읽지 못했다). 사용자 카테고리를 가리키는 거래는
  /// 적힌 기본 분류로 보이고, 그 카테고리가 지워졌는지는 판정하지 않는다.
  const CategoryCatalog.unknown()
      : customs = const [],
        isComplete = false;

  final List<CustomCategory> customs;

  /// 사용자 카테고리 목록을 다 읽었는가. false면 목록에 없는 사용자 카테고리가 지워졌는지 알 수 없다.
  final bool isComplete;

  /// [tx]의 카테고리.
  ///
  /// 사용자 카테고리를 가리키면 그 카테고리의 현재 상위 분류를 따른다(거래에 적힌 기본 분류가 낡았을 수 있다).
  /// 지워졌거나 모르는 사용자 카테고리를 가리키면 거래에 적힌 기본 분류로 돌아간다.
  TransactionCategory of(Transaction tx) {
    final custom = byId(tx.customCategoryId);
    return TransactionCategory(custom?.base ?? tx.base, custom);
  }

  /// id로 찾기. [id]가 null이거나 없는 id면 null.
  CustomCategory? byId(String? id) {
    if (id == null) return null;
    for (final c in customs) {
      if (c.id == id) return c;
    }
    return null;
  }
}
