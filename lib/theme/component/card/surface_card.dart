import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 디자인 기본 카드: surface 배경 + line.normal 1px + r20.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(17, 16, 17, 16),
    this.radius,
    this.onTap,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? radius;
  final VoidCallback? onTap;

  /// 워터마크 등 카드 밖으로 나가는 자식을 잘라낼지.
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      padding: padding,
      decoration: BoxDecoration(
        color: context.color.background.surface,
        borderRadius: BorderRadius.circular(radius ?? CSize.card.radius),
        border: Border.all(color: context.color.line.normal),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: card);
  }
}

/// 잉크(`#2B2724`) 배경 카드 — 리포트 "이달의 발견", 인사이트 배너용. r22, 자식 클립.
class InkCard extends StatelessWidget {
  const InkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(18, 19, 18, 19),
    this.radius,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? radius;

  /// 밝기별 잉크 카드 배경(다크에선 sunken surface).
  static Color colorOf(BuildContext context) =>
      context.theme.brightness == Brightness.dark ? Palette.darkSurfaceSunken : Palette.labelNormal;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: padding,
      decoration: BoxDecoration(
        color: colorOf(context),
        borderRadius: BorderRadius.circular(radius ?? CSize.lg.radius),
      ),
      child: child,
    );
  }
}
