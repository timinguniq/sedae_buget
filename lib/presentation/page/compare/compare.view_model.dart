import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/presentation/service/dependency_provider.dart';

/// 프로필 나이대의 또래 통계. 프로필을 읽을 때까지 기다리고, 프로필이 없으면 또래 통계도 없다(null).
final peerStatsProvider = FutureProvider<PeerStats?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;
  return (await ref.watch(peerStatsRepositoryProvider).forGroup(profile.ageGroup)).unwrap();
});

/// 세대별 월평균 지출(리포트 '세대별' 차트용).
final generationAvgProvider = FutureProvider<Map<AgeGroup, int>>(
  (ref) async => (await ref.watch(peerStatsRepositoryProvider).generationAverages()).unwrap(),
);
