import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/budget/category_catalog.dart';
import 'package:sedae_budget/entity/budget/custom_category.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/transaction_type.dart';
import 'package:sedae_budget/entity/budget/year_month.dart';

/// 분석 화면 한 줄. [custom]이 null이면 기본 분류 자체, 아니면 사용자 카테고리.
typedef CategoryBreakdown = ({BudgetCategory base, CustomCategory? custom, int amount});

/// 보고 있는 달의 장부. 달을 보여주는 화면(홈·비교·내역·리포트·분석·카테고리 관리)은
/// 합계·분류·소득·저축률을 모두 여기서 읽는다.
///
/// - 수입은 카테고리가 없다. 분류별 합계·건수·필터·분석에는 지출만 들어간다.
/// - 사용자 카테고리 지출은 기본 분류로 모을 때 그 카테고리의 현재 상위 분류를 따른다([CategoryCatalog]).
/// - 소득은 프로필 월소득이고, 없으면 이달 수입의 합계다. 잔액·저축률은 이 소득을 기준으로 한다.
class ViewedMonth {
  ViewedMonth({
    required this.month,
    required this.transactions,
    required CategoryCatalog catalog,
    int? profileIncome,
  })  : _catalog = catalog,
        _profileIncome = profileIncome;

  /// 보고 있는 달.
  final YearMonth month;

  /// 이달 거래(지출·수입, 최신순).
  final List<Transaction> transactions;

  final CategoryCatalog _catalog;
  final int? _profileIncome;

  late final List<Transaction> _expenses =
      transactions.where((t) => t.type == TransactionType.expense).toList();

  /// [txs] 중 지출의 합계.
  static int expenseOf(Iterable<Transaction> txs) => txs
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, t) => sum + t.amount);

  late final int expense = expenseOf(transactions);

  int get expenseCount => _expenses.length;

  /// 지출이 드는 기본 분류(사용자 카테고리면 그 현재 상위 분류). 수입은 분류가 없어 null.
  BudgetCategory? baseOf(Transaction tx) =>
      tx.type == TransactionType.income ? null : _catalog.of(tx).base;

  /// 거래의 이름. 지출은 카테고리 이름(사용자 카테고리면 그 이름), 수입은 '수입'.
  String labelOf(Transaction tx) =>
      tx.type == TransactionType.income ? '수입' : _catalog.of(tx).label;

  /// 기본 분류별 지출 합계. 사용자 카테고리 지출도 상위 분류에 합산된다(또래 비교 기준).
  late final Map<BudgetCategory, int> byCategory = () {
    final map = <BudgetCategory, int>{};
    for (final t in _expenses) {
      final c = _catalog.of(t).base;
      map[c] = (map[c] ?? 0) + t.amount;
    }
    return map;
  }();

  /// 기본 분류 [base]에 드는 지출(사용자 카테고리 지출 포함, 최신순).
  List<Transaction> inCategory(BudgetCategory base) =>
      _expenses.where((t) => _catalog.of(t).base == base).toList();

  /// 기본 분류 [base]에 바로 적힌 지출 건수. 사용자 카테고리로 뗀 지출은 빼고,
  /// 지워진 사용자 카테고리를 가리키는 지출은 기본 분류로 센다(분석 화면과 같은 기준).
  int baseOnlyCount(BudgetCategory base) => _expenses.where((t) {
        final of = _catalog.of(t);
        return of.custom == null && of.base == base;
      }).length;

  /// 지출이 많은 기본 분류 상위 [n]개(금액 내림차순).
  List<MapEntry<BudgetCategory, int>> topCategories(int n) =>
      (byCategory.entries.where((e) => e.value > 0).toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .take(n)
          .toList();

  /// 분석 화면용 항목별 지출. 사용자 카테고리 지출은 상위 기본 분류에서 떼어내 따로 낸다.
  /// 금액 내림차순. 또래 평균이 있는 항목은 [CategoryBreakdown.custom]이 null인 기본 분류뿐이다.
  late final List<CategoryBreakdown> breakdown = () {
    final base = <BudgetCategory, int>{};
    final byCustom = <String, int>{};
    for (final t in _expenses) {
      final c = _catalog.of(t);
      final custom = c.custom;
      if (custom == null) {
        base[c.base] = (base[c.base] ?? 0) + t.amount;
      } else {
        byCustom[custom.id] = (byCustom[custom.id] ?? 0) + t.amount;
      }
    }
    return <CategoryBreakdown>[
      for (final e in base.entries) (base: e.key, custom: null, amount: e.value),
      for (final c in _catalog.customs)
        if ((byCustom[c.id] ?? 0) > 0) (base: c.base, custom: c, amount: byCustom[c.id]!),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
  }();

  /// 분석 도넛의 조각: [breakdown] 상위 [n]개와 나머지 합.
  ({List<CategoryBreakdown> top, int rest}) slices(int n) => (
        top: breakdown.take(n).toList(),
        rest: breakdown.skip(n).fold(0, (sum, e) => sum + e.amount),
      );

  /// 소득. 프로필 월소득이 있으면 그것, 없으면 이달 수입의 합계. 둘 다 없으면 null.
  late final int? income = () {
    final profile = _profileIncome ?? 0;
    if (profile > 0) return profile;
    final fromTransactions = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
    return fromTransactions > 0 ? fromTransactions : null;
  }();

  /// 소득에서 지출을 뺀 값. 소득이 없으면 null.
  int? get balance => income == null ? null : income! - expense;

  /// 저축률(%) = (소득 − 지출) / 소득, 반올림. 지출이 소득보다 많으면 음수, 소득이 없으면 null.
  int? get savingsRate => income == null ? null : ((income! - expense) * 100 / income!).round();

  /// 소득 대비 지출(%). 저축률의 보수. 소득이 없으면 null.
  int? get expenseRatio => savingsRate == null ? null : 100 - savingsRate!;
}
