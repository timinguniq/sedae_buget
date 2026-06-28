part of 'app_theme.dart';

class AppDeco {
  const AppDeco({
    required this.shadow,
    required this.cardShadow,
    required this.coralShadow,
  });

  final List<BoxShadow> shadow;
  final List<BoxShadow> cardShadow; // 0 12px 34px rgba(43,39,36,.07) / dark
  final List<BoxShadow> coralShadow; // 0 12px 26px rgba(242,96,60,.26)

  BoxDecoration cardBoxDecoration(CSize size, [Color? color]) => BoxDecoration(
        color: color ?? Palette.surface,
        borderRadius: BorderRadius.circular(size.radius),
      );
}

/// 디자인 radius 스케일 (sm12 / md18 / lg22 / pill999), 카드 20·22 포함.
enum CSize {
  sm,
  md,
  card,
  lg,
  pill;

  double get radius => switch (this) {
        CSize.sm => 12,
        CSize.md => 16,
        CSize.card => 20,
        CSize.lg => 22,
        CSize.pill => 999,
      };
}
