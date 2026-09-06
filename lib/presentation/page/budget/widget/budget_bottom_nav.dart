import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 하단 4탭 + 탭1·탭2 사이 중앙 코랄 원형 FAB 커스텀 바.
/// 디자인: h64 / 배경 bg + 상단 1px 라인 / FAB 48px가 탭보다 8px 위로 떠 있고 코랄 그림자 /
/// 비활성 아이콘 `#C2BAB2`·라벨 assistive / 활성 아이콘 코랄 + 라벨 잉크 700.
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

  static const double barHeight = 64;
  static const double fabSize = 48;
  static const Color _inactiveIconLight = Color(0xFFC2BAB2);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.color.background.normal,
        border: Border(top: BorderSide(color: context.color.line.normal)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: barHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 9, 6, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tab(context, 0, Icons.home_rounded, '홈'),
                _tab(context, 1, Icons.bar_chart_rounded, '비교'),
                _fab(context),
                _tab(context, 2, Icons.receipt_long_outlined, '내역'),
                _tab(context, 3, Icons.data_usage_rounded, '리포트'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index, IconData icon, String label) {
    final selected = index == currentIndex;
    final dark = context.theme.brightness == Brightness.dark;
    final iconColor = selected
        ? context.color.primary.normal
        : (dark ? context.color.label.disable : _inactiveIconLight);
    final labelStyle = selected
        ? context.typo.caption2W600.copyWith(fontWeight: context.typo.bold, color: context.color.label.normal)
        : context.typo.caption2W600.copyWith(color: context.color.label.assistive);
    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(label, style: labelStyle),
          ],
        ),
      ),
    );
  }

  Widget _fab(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -8),
      child: GestureDetector(
        onTap: onFabTap,
        child: Container(
          width: fabSize,
          height: fabSize,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: context.color.primary.normal,
            shape: BoxShape.circle,
            boxShadow: context.deco.coralShadow,
          ),
          child: Icon(Icons.add, color: context.color.static.white, size: 24),
        ),
      ),
    );
  }
}
