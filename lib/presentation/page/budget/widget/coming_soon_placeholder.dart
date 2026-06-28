import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 미구현 화면용 플레이스홀더(마스코트 + '곧 제공' + 부제).
class ComingSoonPlaceholder extends StatelessWidget {
  const ComingSoonPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MascotDongle(size: 64),
          const SizedBox(height: 16),
          Text(
            '곧 제공',
            style: context.typo.title3W600.copyWith(color: context.color.label.normal),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.typo.body2W400.copyWith(color: context.color.label.alternative),
          ),
        ],
      ),
    );
  }
}
