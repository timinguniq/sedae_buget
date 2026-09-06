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
        padding: const EdgeInsets.fromLTRB(26, 0, 26, 32),
        child: Column(children: [
          Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const MascotDongle(size: 88),
              const SizedBox(height: 22),
              Text('세대 가계부',
                style: context.typo.titleW700.copyWith(
                  fontWeight: context.typo.extraBold, letterSpacing: -0.7, color: context.color.label.normal)),
              const SizedBox(height: 9),
              Text('내 또래는 얼마나 쓸까?',
                style: context.typo.label2W600.copyWith(
                  fontWeight: context.typo.bold, color: context.color.primary.normal)),
              const SizedBox(height: 8),
              Text('또래·세대 평균과 내 소비를\n나란히 비교하는 가계부',
                textAlign: TextAlign.center,
                style: context.typo.caption1W500.copyWith(
                  fontSize: 12.5, height: 1.55, color: context.color.label.assistive)),
            ]),
          ),
          for (final p in AuthProvider.values)
            SocialLoginButton(provider: p, onTap: () => signIn(p)),
          const SizedBox(height: 7),
          const _TermsNotice(),
        ]),
      ),
    );
  }
}

/// "로그인 시 이용약관 및 개인정보처리방침에 / 동의하는 것으로 간주됩니다." (강조 2곳 600·alternative)
class _TermsNotice extends StatelessWidget {
  const _TermsNotice();

  @override
  Widget build(BuildContext context) {
    final emphasis = TextStyle(fontWeight: context.typo.semiBold, color: context.color.label.alternative);
    return Text.rich(
      TextSpan(
        style: context.typo.caption2W500.copyWith(fontSize: 10.5, height: 1.55, color: context.color.label.disable),
        children: [
          const TextSpan(text: '로그인 시 '),
          TextSpan(text: '이용약관', style: emphasis),
          const TextSpan(text: ' 및 '),
          TextSpan(text: '개인정보처리방침', style: emphasis),
          const TextSpan(text: '에\n동의하는 것으로 간주됩니다.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
