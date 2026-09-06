import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 디자인 헤더용 원형 아이콘 버튼 30px: surface 배경 + line.normal 1px 테두리 (‹ / ✕).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap, this.size = 30});

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: context.color.background.surface,
          border: Border.all(color: context.color.line.normal),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.6, color: context.color.label.normal),
      ),
    );
  }
}
