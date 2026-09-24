import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/presentation/page/login/login.view_model.dart';
import 'package:sedae_budget/presentation/widget/index.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 세션을 확인하지 못했을 때(서버에 닿지 못함). 토큰·프로필은 그대로 두고 다시 확인하게 한다.
/// 확인이 끝나면 전역 가드가 알맞은 화면으로 옮긴다.
class UnreachablePage extends ConsumerWidget {
  const UnreachablePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultLayout(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 0, 26, 32),
        child: Column(children: [
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const MascotDongle(size: 88),
              const SizedBox(height: 22),
              Text('서버에 연결하지 못했어요',
                style: context.typo.headline2W600.copyWith(
                  fontWeight: context.typo.bold, color: context.color.label.normal)),
              const SizedBox(height: 8),
              Text('인터넷 연결을 확인하고 다시 시도해 주세요.',
                textAlign: TextAlign.center,
                style: context.typo.caption1W500.copyWith(
                  fontSize: 13, height: 1.5, color: context.color.label.assistive)),
            ]),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => ref.read(authProvider.notifier).retry(),
              child: const Text('다시 시도'),
            ),
          ),
        ]),
      ),
    );
  }
}
