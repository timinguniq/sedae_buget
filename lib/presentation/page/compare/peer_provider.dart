import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/core/dependency_injection/dependency_injection.dart';
import 'package:sedae_budget/domain/domain.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';

/// 사용자 나이대 기준 또래 통계(프로필 없으면 30대 기본).
final peerStatsProvider = FutureProvider<PeerStats>((ref) {
  final group = ref.watch(userProfileProvider).value?.ageGroup ?? AgeGroup.thirties;
  return locator<PeerStatsRepository>().forGroup(group);
});

/// 세대별 월평균 지출(리포트 '세대별' 차트용).
final generationAvgProvider = FutureProvider<Map<AgeGroup, int>>(
  (ref) => locator<PeerStatsRepository>().generationAverages(),
);
