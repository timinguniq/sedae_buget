import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/compare/compare.view_model.dart';

/// 보고 있는 달과 또래 통계. 홈·비교·내역·리포트·분석이 모두 이 값을 읽는다.
/// 달의 합계·분류·소득·저축률은 [month]([ViewedMonth])가, 또래와의 비교는 [peer]가 정한다.
class MonthOverview {
  const MonthOverview({required this.month, required this.peer});

  /// 또래 통계를 못 읽었을 때([peer]가 null) 보여줄 문구.
  static const peerUnavailable = '또래 통계를 불러오지 못했어요';

  /// 보고 있는 달의 장부.
  final ViewedMonth month;

  /// 또래 통계. 못 읽었으면 null이고, 내 값은 그대로 보여준다.
  final PeerStats? peer;

  /// [tx]가 속한 기본 분류에서 이달 내 지출이 또래 평균보다 많은가.
  /// 수입이거나 또래 통계·그 분류의 또래 값이 없으면 false.
  bool overPeer(Transaction tx) {
    final peer = this.peer;
    final base = month.baseOf(tx);
    if (peer == null || base == null) return false;
    return peer.compareCategory(base, month.byCategory[base] ?? 0)?.direction == PeerDirection.more;
  }
}

/// 이달 개요. 이달 거래를 못 읽으면 오류, 또래 통계는 처음 한 번만 기다리고 실패하면 빼고 낸다.
final monthOverviewProvider = Provider<AsyncValue<MonthOverview>>((ref) {
  final month = ref.watch(viewedMonthProvider);
  final peer = ref.watch(peerStatsProvider);
  if (!peer.hasValue && !peer.hasError) return const AsyncLoading();
  return month.whenData((month) => MonthOverview(month: month, peer: peer.value));
});
