import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 게스트 프로필 카드(로그인은 P2라 버튼 비활성).
class GuestProfileCard extends StatelessWidget {
  const GuestProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.color.background.surface,
        borderRadius: BorderRadius.circular(CSize.card.radius),
      ),
      child: Row(
        children: [
          const MascotDongle(size: 48),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('게스트', style: context.typo.body1W600.copyWith(color: context.color.label.normal)),
              Text('로그인 준비 중', style: context.typo.caption1W400.copyWith(color: context.color.label.alternative)),
            ],
          ),
          const Spacer(),
          const TextButton(onPressed: null, child: Text('로그인')),
        ],
      ),
    );
  }
}
