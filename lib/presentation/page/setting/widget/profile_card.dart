import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/login/auth_provider.dart';
import 'package:sedae_budget/presentation/page/onboarding/user_profile_provider.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 로그인 상태 인지 프로필 카드. 디자인: 46px 마스코트 + 이름 700·15 + 나이대 500·11.5 + 우측 provider 배지.
/// 게스트는 "게스트" + 로그인 액션. 로그아웃은 화면 하단 [LogoutButton]에서.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final ageGroup = ref.watch(userProfileProvider).value?.ageGroup;
    final subtitle = user == null
        ? '로그인하고 또래 비교를 시작하세요'
        : (ageGroup?.label ?? '${user.provider.label} 로그인');
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      child: Row(children: [
        const MascotDongle(size: 46),
        const SizedBox(width: 13),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user?.nickname ?? '게스트',
              style: context.typo.body2W600.copyWith(fontWeight: context.typo.bold, color: context.color.label.normal)),
            const SizedBox(height: 2),
            Text(subtitle,
              style: context.typo.caption1W500.copyWith(fontSize: 11.5, color: context.color.label.assistive)),
          ])),
        if (user == null)
          TextButton(onPressed: () => context.push(RoutePath.login.path), child: const Text('로그인'))
        else
          ProviderBadge(provider: user.provider),
      ]),
    );
  }
}
