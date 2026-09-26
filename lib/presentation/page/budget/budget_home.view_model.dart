import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/budget/ledger.view_model.dart';
import 'package:sedae_budget/presentation/page/compare/compare.view_model.dart';

/// 이달 개요([MonthOverview]). 홈·비교·내역·리포트·분석이 모두 이 값을 읽는다.
/// 이달 거래를 못 읽으면 오류, 또래 통계는 처음 한 번만 기다리고 실패하면 빼고 낸다.
final monthOverviewProvider = Provider<AsyncValue<MonthOverview>>((ref) {
  final month = ref.watch(viewedMonthProvider);
  final peer = ref.watch(peerStatsProvider);
  if (!peer.hasValue && !peer.hasError) return const AsyncLoading();
  return month.whenData((month) => MonthOverview(month: month, peer: peer.value));
});
