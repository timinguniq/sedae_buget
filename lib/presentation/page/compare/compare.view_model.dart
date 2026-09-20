import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

/// 사용자 나이대 기준 또래 통계(프로필 없으면 30대 기본).
final peerStatsProvider = FutureProvider<PeerStats>((ref) async {
  final group = ref.watch(userProfileProvider).value?.ageGroup ?? AgeGroup.thirties;
  return (await ref.watch(peerStatsRepositoryProvider).forGroup(group)).unwrap();
});

/// 세대별 월평균 지출(리포트 '세대별' 차트용).
final generationAvgProvider = FutureProvider<Map<AgeGroup, int>>(
  (ref) async => (await ref.watch(peerStatsRepositoryProvider).generationAverages()).unwrap(),
);
