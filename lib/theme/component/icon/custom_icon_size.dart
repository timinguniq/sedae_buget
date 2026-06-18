part of 'custom_icon.dart';

enum IconSize {
  xxs,
  xs,
  sm,
  md,
  lg,
  xl,
  xxl;

  double getIconSize() {
    return switch (this) {
      IconSize.xxs => 14,
      IconSize.xs => 16,
      IconSize.sm => 20,
      IconSize.md => 24,
      IconSize.lg => 28,
      IconSize.xl => 30,
      IconSize.xxl => 32,
    };
  }
}
