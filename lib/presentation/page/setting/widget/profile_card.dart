import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/login/auth_provider.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 로그인 상태 인지 프로필 카드(게스트 ↔ 로그인 + 로그아웃).
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.background.surface,
        borderRadius: BorderRadius.circular(CSize.card.radius)),
      child: Row(children: [
        const MascotDongle(size: 48),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(user?.nickname ?? '게스트',
              style: context.typo.body1W600.copyWith(color: context.color.label.normal)),
            Text(user == null ? '로그인하고 또래 비교를 시작하세요' : '${user.provider.label} 로그인',
              style: context.typo.caption1W400.copyWith(color: context.color.label.alternative)),
          ])),
        if (user == null)
          TextButton(onPressed: () => context.push(RoutePath.login.path), child: const Text('로그인'))
        else
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: Text('로그아웃', style: context.typo.label2W600.copyWith(color: context.color.label.alternative))),
      ]),
    );
  }
}
