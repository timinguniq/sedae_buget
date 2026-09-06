import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 설정 행(라벨 + 값/트레일링 + 탭). 카드 배경은 감싸는 쪽([SurfaceCard])이 그린다.
/// 디자인: 600·13.5 라벨 / 600·12.5 값 / `›` 700·15.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
  });

  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        child: Row(
          children: [
            Text(label, style: context.typo.label2W600.copyWith(fontSize: 13.5, color: context.color.label.normal)),
            const Spacer(),
            if (value != null) ...[
              Text(value!, style: context.typo.caption1W600.copyWith(fontSize: 12.5, color: context.color.label.assistive)),
              const SizedBox(width: 8),
            ],
            trailing ??
                (onTap != null
                    ? Text('›', style: context.typo.body2W600.copyWith(
                        fontWeight: context.typo.bold, height: 1, color: context.color.label.disable))
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
