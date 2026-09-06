import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 시안 B 하단 잉크색 인사이트 배너: 26px 마스코트 + 강조어(코랄 소프트) 포함 한 줄.
class InsightBanner extends StatelessWidget {
  const InsightBanner({super.key, required this.prefix, required this.highlight, required this.suffix});
  final String prefix;
  final String highlight;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    final base = context.typo.caption1W600.copyWith(
      fontSize: 11.5, height: 1.45, color: context.color.static.white);
    return InkCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      child: Row(children: [
        const MascotDongle(size: 26, ring: false),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(TextSpan(style: base, children: [
            TextSpan(text: prefix),
            TextSpan(text: highlight, style: base.copyWith(fontWeight: context.typo.bold, color: Palette.coralSoft)),
            TextSpan(text: suffix),
          ])),
        ),
      ]),
    );
  }
}
