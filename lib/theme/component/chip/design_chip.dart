import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 디자인 칩 3종. 내역 필터·카테고리 선택·세대 태그 공용.
enum DesignChipStyle {
  /// 잉크 배경 + 밝은 글씨 (선택된 필터 "전체")
  ink,

  /// 흰 배경 + line.normal 테두리 + alternative 글씨 (비선택)
  outline,

  /// 코랄 배경 + 흰 글씨 (선택된 카테고리·내 세대)
  coral,
}

class DesignChip extends StatelessWidget {
  const DesignChip({
    super.key,
    required this.label,
    this.style = DesignChipStyle.outline,
    this.onTap,
    this.leading,
    this.padding = const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
  });

  final String label;
  final DesignChipStyle style;
  final VoidCallback? onTap;
  final Widget? leading;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = context.color;
    final (Color bg, Color fg, Color? border) = switch (style) {
      DesignChipStyle.ink => (c.label.normal, c.background.normal, null),
      DesignChipStyle.outline => (c.background.surface, c.label.alternative, c.line.normal),
      DesignChipStyle.coral => (c.primary.normal, c.static.white, null),
    };
    final text = Text(label, style: context.typo.caption1W600.copyWith(
      fontSize: 11.5, height: 1.2, color: fg,
      fontWeight: style == DesignChipStyle.outline ? context.typo.semiBold : context.typo.bold,
    ));
    final chip = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(CSize.pill.radius),
        border: border == null ? null : Border.all(color: border),
      ),
      child: leading == null
          ? text
          : Row(mainAxisSize: MainAxisSize.min, children: [leading!, const SizedBox(width: 4), text]),
    );
    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: chip);
  }
}
