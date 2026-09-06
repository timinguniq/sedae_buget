import 'package:flutter/material.dart';
import 'package:sedae_budget/entity/entity.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 프로필 카드 우측 로그인 제공자 배지 (카카오 노랑 / 네이버 초록 / 구글 흰 배경 + 테두리).
class ProviderBadge extends StatelessWidget {
  const ProviderBadge({super.key, required this.provider});

  final AuthProvider provider;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (provider) {
      AuthProvider.kakao => (const Color(0xFFFEE500), const Color(0xFF1A1700), null),
      AuthProvider.naver => (const Color(0xFF03C75A), Colors.white, null),
      AuthProvider.google => (Colors.white, Palette.labelNormal, context.color.line.normal),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CSize.pill.radius),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Text(provider.label,
        style: context.typo.caption2W600.copyWith(fontSize: 10.5, fontWeight: context.typo.bold, color: fg)),
    );
  }
}
