import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 하단 4탭 + 탭1·탭2 사이 중앙 코랄 원형 FAB 커스텀 바.
class BudgetBottomNav extends StatelessWidget {
  const BudgetBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onFabTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.background.surface,
        border: Border(top: BorderSide(color: context.color.line.normal)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _tab(context, 0, Icons.home_rounded, '홈'),
              _tab(context, 1, Icons.people_alt_outlined, '비교'),
              _fab(context),
              _tab(context, 2, Icons.receipt_long_outlined, '내역'),
              _tab(context, 3, Icons.insights_rounded, '리포트'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, IconData icon, String label) {
    final selected = index == currentIndex;
    final color = selected ? context.color.primary.normal : Palette.labelDisable;
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(label, style: context.typo.caption2W500.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Widget _fab(BuildContext context) {
    return GestureDetector(
      onTap: onFabTap,
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.color.primary.normal,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: context.color.label.white, size: 28),
      ),
    );
  }
}
