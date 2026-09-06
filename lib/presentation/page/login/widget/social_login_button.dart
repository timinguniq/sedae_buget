import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({super.key, required this.provider, required this.onTap});

  final AuthProvider provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (provider) {
      AuthProvider.kakao => (const Color(0xFFFEE500), const Color(0xFF191600), null),
      AuthProvider.naver => (const Color(0xFF03C75A), Colors.white, null),
      AuthProvider.google => (Colors.white, const Color(0xFF1F1F1F), const Color(0xFFDADCE0)),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        width: double.infinity, height: 52,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(CSize.card.radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(CSize.card.radius),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(CSize.card.radius),
                border: border == null ? null : Border.all(color: border)),
              child: Text('${provider.label}로 시작하기',
                style: context.typo.body1W600.copyWith(color: fg)),
            ),
          ),
        ),
      ),
    );
  }
}
