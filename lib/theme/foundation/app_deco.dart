part of 'app_theme.dart';

class AppDeco {
  const AppDeco({
    required this.shadow,
  });

  /// Shadow
  final List<BoxShadow> shadow;

  BoxDecoration cardBoxDecoration(CSize size, [Color? color]) {
    return BoxDecoration(
      color: color ?? Palette.fillBlack,
      borderRadius: BorderRadius.circular(size.radius),
    );
  }
}

/// 버튼 크기
enum CSize {
  // xs,
  sm,
  md,
  lg,
  xl;

  double get radius => switch (this) {
  // CSize.xs => 4,
    CSize.sm => 8,
    CSize.md => 10,
    CSize.lg => 15,
    CSize.xl => 20,
  };
}
