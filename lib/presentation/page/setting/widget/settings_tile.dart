import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/presentation.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 설정 화면용 카드형 행(라벨 + 값/트레일링 + 탭).
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
      borderRadius: BorderRadius.circular(CSize.md.radius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.color.background.surface,
          borderRadius: BorderRadius.circular(CSize.md.radius),
        ),
        child: Row(
          children: [
            Text(label, style: context.typo.body1W500.copyWith(color: context.color.label.normal)),
            const Spacer(),
            if (value != null) ...[
              Text(value!, style: context.typo.body2W400.copyWith(color: context.color.label.alternative)),
              const SizedBox(width: 6),
            ],
            trailing ??
                (onTap != null
                    ? Icon(Icons.chevron_right, color: context.color.label.assistive)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}
