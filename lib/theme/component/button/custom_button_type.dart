part of 'custom_button.dart';

/// 버튼 타입
enum CButtonType {
  fill,
  flat,
  outline,
  ;

  /// 텍스트 & 아이콘 색상
  Color _getLabelColor(
      BuildContext context,
      bool isDisabled, [
        Color? color,
      ]) {
    switch (this) {
      case CButtonType.fill:
        return color ?? context.color.fill.white;
      case CButtonType.flat:
        return isDisabled ? context.color.fill.grey : color ?? context.color.primary.strong;
      case CButtonType.outline:
        return isDisabled ? context.color.line.normal : color ?? context.color.primary.strong;
    }
  }

  /// 버튼 색상
  Color _getButtonColor(
      BuildContext context,
      bool isDisabled, [
        Color? color,
      ]) {
    switch (this) {
      case CButtonType.fill:
        return isDisabled ? context.color.fill.grey : color ?? context.color.primary.strong;
      case CButtonType.flat:
        return Colors.transparent;
      case CButtonType.outline:
        return isDisabled ? context.color.fill.grey : color ?? context.color.primary.strong;
    }
  }

  /// 버튼 스타일
  ButtonStyle _getButtonStyle(
      Color labelColor,
      Color buttonColor,
      Color borderColor,
      CButtonSize size,
      ) {
    switch (this) {
      case CButtonType.fill:
        return ElevatedButton.styleFrom(
          foregroundColor: labelColor,
          backgroundColor: buttonColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          padding: size.padding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size.radius)),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.transparent;
            }
            return labelColor.withAlpha(25);
          }),
        );
      case CButtonType.flat:
        return TextButton.styleFrom(
          padding: size.padding.copyWith(left: 0, right: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size.radius)),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.transparent;
            }
            return labelColor.withAlpha(25);
          }),
        );
      case CButtonType.outline:
        return OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          surfaceTintColor: Colors.green,
          shadowColor: Colors.green,
          side: BorderSide(color: borderColor),
          elevation: 0,
          padding: size.padding,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(size.radius)),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.transparent;
            }
            return labelColor.withAlpha(25);
          }),
        );
    }
  }
}
