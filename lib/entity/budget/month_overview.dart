import 'package:sedae_budget/entity/budget/budget_category.dart';
import 'package:sedae_budget/entity/budget/transaction.dart';
import 'package:sedae_budget/entity/budget/viewed_month.dart';
import 'package:sedae_budget/entity/peer/peer_comparison.dart';
import 'package:sedae_budget/entity/peer/peer_stats.dart';

/// 내 저축률과 또래 평균 저축률(%)의 비교.
class SavingsComparison {
  const SavingsComparison({required this.mine, required this.peer});

  /// 내 저축률. 소득이 없으면 계산할 수 없어 null.
  final int? mine;

  /// 또래 평균 저축률.
  final int peer;

  /// 또래만큼(같거나 더) 모으고 있는가. 내 저축률을 모르면 false.
  bool get atLeastPeer {
    final m = mine;
    return m != null && m >= peer;
  }
}

/// 두 막대의 길이. 큰 쪽이 1이고 음수는 0이다.
typedef BarPair = ({double mine, double peer});

/// 이달 개요: 보고 있는 달([month])을 또래([peer])와 견준 결과.
///
/// 달을 보여주는 화면(홈·비교·내역·리포트·분석)은 무엇을 또래와 견줄지, 무엇을 뺄지를 모두 여기서 읽는다.
/// - 또래 통계를 못 읽었으면([hasPeer]가 false) 비교는 모두 없다. 내 값은 [month]로 그대로 보인다.
/// - 빈 달(지출 0원, [isEmpty])은 또래와 견주지 않는다: 총지출·순위·분류별·가장 큰 차이·저축률 비교가 모두 없다.
/// - 또래 값이 없는 항목(평균 0·빠짐)은 그 비교만 없다([PeerComparison.of]).
class MonthOverview {
  const MonthOverview({required this.month, this.peer});

  /// 보고 있는 달의 장부.
  final ViewedMonth month;

  /// 또래 통계. 못 읽었으면 null. 분포 그림·나이대 표시에만 쓰고, 비교는 이 클래스의 멤버로 한다.
  final PeerStats? peer;

  bool get hasPeer => peer != null;

  /// 지출이 없는 달.
  bool get isEmpty => month.expense == 0;

  /// 견줄 또래 통계. 못 읽었거나 빈 달이면 null.
  PeerStats? get _comparable => isEmpty ? null : peer;

  /// 이달 총지출과 또래 월평균.
  PeerComparison? get total => _comparable?.compareTotal(month.expense);

  /// 또래 중 내 지출 순위. 표본이 없어도 null.
  PeerRank? get rank => _comparable?.rankOf(month.expense);

  /// [category]의 이달 지출(사용자 카테고리 포함)과 또래 평균.
  PeerComparison? category(BudgetCategory category) =>
      _comparable?.compareCategory(category, month.byCategory[category] ?? 0);

  /// 분석 화면 한 줄의 또래 비교. 또래 비교는 기본 분류로만 하므로 사용자 카테고리 행은 null이다.
  PeerComparison? row(CategoryBreakdown row) =>
      row.custom == null ? _comparable?.compareCategory(row.base, row.amount) : null;

  /// 많이 쓴 기본 분류 [n]개(금액 내림차순)와 각 분류의 또래 비교.
  List<({BudgetCategory category, int amount, PeerComparison? peer})> topCategories(int n) => [
        for (final e in month.topCategories(n)) (category: e.key, amount: e.value, peer: category(e.key)),
      ];

  /// 또래 평균과 차이가 가장 큰 기본 분류.
  ({BudgetCategory category, PeerComparison comparison})? get largestGap =>
      _comparable?.largestCategoryGap(month.byCategory);

  /// 저축률 비교.
  SavingsComparison? get savings {
    final p = _comparable;
    return p == null ? null : SavingsComparison(mine: month.savingsRate, peer: p.avgSavingsRatePercent);
  }

  /// 또래가 가장 많이 쓰는 분류(또래 평균을 가장 끌어올리는 항목).
  BudgetCategory? get peerTopCategory {
    MapEntry<BudgetCategory, int>? top;
    for (final e in peer?.avgByCategory.entries ?? const <MapEntry<BudgetCategory, int>>[]) {
      if (top == null || e.value > top.value) top = e;
    }
    return top?.key;
  }

  /// 총지출 막대. 또래 월평균이 없으면 null.
  BarPair? get totalBars {
    final t = total;
    return t == null ? null : _bars(t.mine, t.peer);
  }

  /// 저축률 막대. 내 저축률을 모르거나 음수면 내 막대는 0이다.
  BarPair? get savingsBars {
    final s = savings;
    return s == null ? null : _bars(s.mine ?? 0, s.peer);
  }

  /// [tx]가 속한 기본 분류에서 이달 내 지출이 또래 평균보다 많은가.
  /// 수입이거나 또래 통계·그 분류의 또래 값이 없으면 false.
  bool overPeer(Transaction tx) {
    final base = month.baseOf(tx);
    return base != null && category(base)?.direction == PeerDirection.more;
  }

  static BarPair _bars(int mine, int peer) {
    final m = mine < 0 ? 0 : mine;
    final p = peer < 0 ? 0 : peer;
    final max = m > p ? m : p;
    return max == 0 ? (mine: 0.0, peer: 0.0) : (mine: m / max, peer: p / max);
  }
}
