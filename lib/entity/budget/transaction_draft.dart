import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/budget/category_catalog.dart';
import 'package:sedae_budget/entity/budget/custom_category.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/transaction_type.dart';
import 'package:uuid/uuid.dart';

/// 입력 중인 거래. 거래 입력 화면의 규칙(카테고리 선택·저장 가능 여부·저장할 거래)을 가진다.
///
/// 카테고리는 기본 분류 하나이거나 사용자 카테고리 하나다. 사용자 카테고리를 고르면 그 상위 분류가
/// 함께 정해진다. 사용자 카테고리가 아직 있는지는 저장할 때 [toTransaction]이 목록으로 판정한다.
///
/// 초안 하나는 거래 하나다. 저장을 몇 번 시도해도(두 번 누름·시간 초과 뒤 재시도) 같은 [id]로
/// 보내므로, 클라이언트 id로 멱등인 서버에는 거래가 하나만 생긴다.
class TransactionDraft {
  const TransactionDraft._({
    required this.id,
    required this.amount,
    required this.type,
    required this.base,
    required this.customCategoryId,
    required this.date,
    required this.memo,
    required this.existing,
  });

  /// 새 거래. 지출·식비·금액 0으로 시작하고, 저장할 거래의 id를 여기서 한 번 정한다.
  TransactionDraft.create(DateTime date)
      : this._(
          id: const Uuid().v4(),
          amount: 0,
          type: TransactionType.expense,
          base: BudgetCategory.food,
          customCategoryId: null,
          date: date,
          memo: '',
          existing: null,
        );

  /// [tx]를 고친다. 카테고리는 [catalog]로 판정한다.
  factory TransactionDraft.edit(Transaction tx, CategoryCatalog catalog) => TransactionDraft._(
        id: tx.id,
        amount: tx.amount,
        type: tx.type,
        base: catalog.of(tx).base,
        customCategoryId: tx.customCategoryId,
        date: tx.date,
        memo: tx.memo ?? '',
        existing: tx,
      );

  /// 저장할 거래의 id.
  final String id;
  final int amount;
  final TransactionType type;

  /// 기본 분류. 사용자 카테고리를 골랐으면 그 상위 분류.
  final BudgetCategory base;

  /// 고른 사용자 카테고리. null이면 [base] 그대로.
  final String? customCategoryId;
  final DateTime date;

  /// 입력한 그대로의 메모. 저장할 때 다듬는다.
  final String memo;

  /// 고치는 중인 거래. 새 거래면 null.
  final Transaction? existing;

  bool get isEdit => existing != null;

  /// 금액이 0이면 저장하지 않는다.
  bool get canSave => amount > 0;

  TransactionDraft withAmount(int amount) => _copy(amount: amount);
  TransactionDraft withType(TransactionType type) => _copy(type: type);
  TransactionDraft withDate(DateTime date) => _copy(date: date);
  TransactionDraft withMemo(String memo) => _copy(memo: memo);

  TransactionDraft pickBase(BudgetCategory category) => _copy(base: category, customCategoryId: null);

  TransactionDraft pickCustom(CustomCategory category) =>
      _copy(base: category.base, customCategoryId: category.id);

  /// 화면에 보일 카테고리 이름. 목록에 아직 없는 사용자 카테고리(방금 만든 것)는 상위 분류 이름으로.
  String label(CategoryCatalog catalog) => catalog.byId(customCategoryId)?.name ?? base.label;

  /// 저장할 거래. 사용자 카테고리는 [catalog]의 현재 상위 분류를 따르고,
  /// 목록에 없으면(지워졌으면) 사용자 카테고리를 떼고 [base]로 저장한다.
  /// [catalog]가 null(목록을 읽지 못함)이면 판정하지 않고 고른 그대로 저장한다.
  Transaction toTransaction(CategoryCatalog? catalog) {
    final custom = catalog?.byId(customCategoryId);
    final customId = catalog == null ? customCategoryId : custom?.id;
    final categoryId = (custom?.base ?? base).id;
    final trimmed = memo.trim();
    final memoOrNull = trimmed.isEmpty ? null : trimmed;
    final e = existing;
    if (e == null) {
      return Transaction.create(
        id: id,
        amount: amount,
        categoryId: categoryId,
        date: date,
        type: type,
        memo: memoOrNull,
        customCategoryId: customId,
      );
    }
    return e.copyWith(
      amount: amount,
      categoryId: categoryId,
      date: date,
      type: type,
      memo: memoOrNull,
      customCategoryId: customId,
    );
  }

  static const _keep = Object();

  TransactionDraft _copy({
    int? amount,
    TransactionType? type,
    BudgetCategory? base,
    Object? customCategoryId = _keep,
    DateTime? date,
    String? memo,
  }) =>
      TransactionDraft._(
        id: id,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        base: base ?? this.base,
        customCategoryId:
            identical(customCategoryId, _keep) ? this.customCategoryId : customCategoryId as String?,
        date: date ?? this.date,
        memo: memo ?? this.memo,
        existing: existing,
      );
}
