import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/presentation/page/login/auth_provider.dart';
import 'package:sedae_budget/presentation/page/login/widget/social_login_button.dart';
import 'package:sedae_budget/theme/theme.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> signIn(AuthProvider p) async {
      await ref.read(authProvider.notifier).signIn(p);
      // 전역 가드(refreshListenable)가 로그인 성공 후 온보딩/홈으로 라우팅한다.
    }
    return DefaultLayout(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(children: [
          const Spacer(),
          const MascotDongle(size: 88),
          const SizedBox(height: 20),
          Text('세대 가계부', style: context.typo.heading2W700.copyWith(color: context.color.label.normal)),
          const SizedBox(height: 8),
          Text('내 또래는 얼마나 쓸까?',
            style: context.typo.body1W500.copyWith(color: context.color.label.alternative)),
          const Spacer(),
          for (final p in AuthProvider.values)
            SocialLoginButton(provider: p, onTap: () => signIn(p)),
          const SizedBox(height: 8),
          Text('시작하면 이용약관 및 개인정보처리방침에 동의하게 됩니다.',
            textAlign: TextAlign.center,
            style: context.typo.caption1W400.copyWith(color: context.color.label.assistive)),
        ]),
      ),
    );
  }
}
