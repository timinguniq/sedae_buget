import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';
import 'package:sedae_budget/presentation/page/onboarding/onboarding_flow.view_model.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 프로필 카드. 디자인: 46px 마스코트 + 이름 700·15 + 나이대 500·11.5 + 우측 provider 배지.
/// 세션 게이트가 로그아웃 상태에선 설정을 보여주지 않으므로, 로그아웃 직후 한 프레임은 그리지 않는다.
/// 로그아웃은 화면 하단 [LogoutButton]에서.
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user == null) return const SizedBox.shrink();
    final ageGroup = ref.watch(userProfileProvider).value?.ageGroup;
    final subtitle = ageGroup?.label ?? '${user.provider.label} 로그인';
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
      child: Row(children: [
        const MascotDongle(size: 46),
        const SizedBox(width: 13),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user.nickname,
              style: context.typo.body2W600.copyWith(fontWeight: context.typo.bold, color: context.color.label.normal)),
            const SizedBox(height: 2),
            Text(subtitle,
              style: context.typo.caption1W500.copyWith(fontSize: 11.5, color: context.color.label.assistive)),
          ])),
        ProviderBadge(provider: user.provider),
      ]),
    );
  }
}
