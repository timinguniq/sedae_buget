part of 'custom_button.dart';

/// 버튼 크기
enum CButtonSize {
  sm,
  md,
  lg,
  xl;

  EdgeInsets get padding => switch (this) {
    CButtonSize.sm => const EdgeInsets.symmetric(horizontal: 20, vertical: 6), // h32(20+12)
    CButtonSize.md => const EdgeInsets.symmetric(horizontal: 17, vertical: 8), // h40(24+16)
    CButtonSize.lg => const EdgeInsets.symmetric(horizontal: 30, vertical: 17), // h58(24+34)
    CButtonSize.xl => EdgeInsets.zero,
  };

  double get radius => switch (this) {
    CButtonSize.sm => 5,
    CButtonSize.md => 5,
    CButtonSize.lg => 10,
    CButtonSize.xl => 10,
  };

  TextStyle _getLabelStyle(BuildContext context) {
    switch (this) {
      case CButtonSize.sm: // t20
        return context.typo.label2W400;
      case CButtonSize.md: // t24
        return context.typo.titleReadingW600;
      case CButtonSize.lg: // t24
        return context.typo.titleReadingW600;
      case CButtonSize.xl: // t24
        return context.typo.titleReadingW600;
    }
  }
}
