import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 나 vs 또래 가로 막대 카드 (시안 A "이번 달 지출 비교" 18px / "소득 대비 저축률" 16px).
class VersusBarCard extends StatelessWidget {
  const VersusBarCard({
    super.key,
    required this.title,
    required this.mineFraction,
    required this.peerFraction,
    required this.mineText,
    required this.peerText,
    this.barHeight = 18,
    this.footer,
  });

  final String title;
  final double mineFraction;
  final double peerFraction;
  final String mineText;
  final String peerText;
  final double barHeight;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: context.typo.sectionTitle.copyWith(color: context.color.label.normal)),
        const SizedBox(height: 14),
        _row(context, '나', mineFraction, mineText, me: true),
        const SizedBox(height: 11),
        _row(context, '또래', peerFraction, peerText, me: false),
        if (footer != null) ...[
          const SizedBox(height: 12),
          Align(alignment: Alignment.centerRight, child: footer),
        ],
      ]),
    );
  }

  Widget _row(BuildContext context, String label, double fraction, String value, {required bool me}) {
    final dark = context.theme.brightness == Brightness.dark;
    final fill = me
        ? context.color.primary.normal
        : (dark ? context.color.label.disable : Palette.neutral400);
    final labelStyle = context.typo.caption1W600.copyWith(
      fontSize: 11.5,
      fontWeight: me ? context.typo.bold : context.typo.semiBold,
      color: me ? context.color.label.normal : context.color.label.alternative,
    );
    final valueStyle = labelStyle.copyWith(fontWeight: me ? context.typo.extraBold : context.typo.bold);
    return Row(children: [
      SizedBox(width: 32, child: Text(label, style: labelStyle)),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: context.color.background.alternative, borderRadius: BorderRadius.circular(5)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction.clamp(0.0, 1.0),
            child: DecoratedBox(
              decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(5))),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(width: 62, child: Text(value, textAlign: TextAlign.right, style: valueStyle)),
    ]);
  }
}
