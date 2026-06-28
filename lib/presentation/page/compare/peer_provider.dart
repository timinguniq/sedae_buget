import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/data/peer/mock_peer_stats_source.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';

final mockPeerStatsSourceProvider =
    Provider<MockPeerStatsSource>((_) => MockPeerStatsSource());

/// 사용자 나이대 기준 또래 통계(프로필 없으면 30대 기본).
final peerStatsProvider = Provider<PeerStats>((ref) {
  final group = ref.watch(userProfileProvider).value?.ageGroup ?? AgeGroup.thirties;
  return ref.read(mockPeerStatsSourceProvider).forGroup(group);
});
