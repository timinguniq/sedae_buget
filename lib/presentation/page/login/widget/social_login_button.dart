import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 디자인 소셜 로그인 버튼: h54 / r14 / 좌측 SVG 로고 + 중앙 라벨 700·15.
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({super.key, required this.provider, required this.onTap});

  final AuthProvider provider;
  final VoidCallback onTap;

  static const double height = 54;
  static const double radius = 14;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border, asset, logoSize) = switch (provider) {
      AuthProvider.kakao => (const Color(0xFFFEE500), const Color(0xFF1A1700), null, 'kakao', 22.0),
      AuthProvider.naver => (const Color(0xFF03C75A), Colors.white, null, 'naver', 18.0),
      AuthProvider.google => (Colors.white, Palette.labelNormal, const Color(0xFFE6E0D6), 'google', 20.0),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: SizedBox(
        width: double.infinity, height: height,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: border == null ? null : Border.all(color: border, width: 1.5)),
              child: Stack(alignment: Alignment.center, children: [
                Positioned(
                  left: 19,
                  child: SvgPicture.asset('asset/icon/social/$asset.svg', width: logoSize, height: logoSize),
                ),
                Text('${provider.label}로 시작하기',
                  style: context.typo.body2W600.copyWith(fontWeight: context.typo.bold, color: fg)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
