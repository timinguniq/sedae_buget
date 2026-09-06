import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 라이트/다크/시스템 테마 모드 선택 칩 3개.
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key, required this.value, required this.onChanged});

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(ThemeMode mode, String label) {
      final selected = mode == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? context.color.primary.tint : context.color.background.alternative,
              borderRadius: BorderRadius.circular(CSize.sm.radius),
            ),
            child: Text(
              label,
              style: context.typo.label2W600.copyWith(
                color: selected ? context.color.primary.normal : context.color.label.neutral,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(ThemeMode.light, '라이트'),
        const SizedBox(width: 8),
        chip(ThemeMode.dark, '다크'),
        const SizedBox(width: 8),
        chip(ThemeMode.system, '시스템'),
      ],
    );
  }
}
