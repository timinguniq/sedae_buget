//ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

part 'custom_button_size.dart';
part 'custom_button_type.dart';

class CButton extends StatelessWidget {
  const CButton({
    super.key,
    this.leadingIcon,
    required this.label,
    this.trailingIcon,
    this.iconSpacing,
    this.labelStyle,
    this.color,
    this.buttonColor,
    CButtonType? type,
    CButtonSize? size,
    this.onTap,
  })  : type = type ?? CButtonType.fill,
        size = size ?? CButtonSize.md;

  /// 텍스트 & 아이콘
  final Widget? leadingIcon;
  final String label;
  final Widget? trailingIcon;
  final double? iconSpacing;
  final TextStyle? labelStyle;

  /// 커스텀 색상
  final Color? color;
  final Color? buttonColor;

  /// Button 타입 & 크기
  final CButtonType type;
  final CButtonSize size;

  /// 클릭 이벤트
  final VoidCallback? onTap;

  /// 비활성화 여부
  bool get isDisabled => onTap == null;

  @override
  Widget build(BuildContext context) {
    /// 버튼 배경색
    final _buttonColor = type._getButtonColor(context, isDisabled, buttonColor);

    /// 라벨 색상 & 스타일
    final _labelColor = type._getLabelColor(context, isDisabled, color);
    final _labelStyle = (labelStyle ?? size._getLabelStyle(context)).copyWith(color: _labelColor);

    /// 버튼 스타일
    final buttonStyle = type._getButtonStyle(_labelColor, _buttonColor, buttonColor ?? color ?? _buttonColor, size);

    /// 버튼 넓이, 높이, 수직 패딩
    final width = size == CButtonSize.sm ? null : double.infinity;
    final height = size.padding.vertical + (_labelStyle.fontSize! * (_labelStyle.height ?? 1.0));

    return SizedBox(
      width: width,
      height: height,
      child: button(
        buttonStyle: buttonStyle,
        child: (leadingIcon == null && trailingIcon == null)
            ? Text(label, style: labelStyle, textAlign: TextAlign.center)
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// 리딩 아이콘
            if (leadingIcon != null)
              Padding(padding: EdgeInsets.only(right: iconSpacing ?? 10), child: leadingIcon),

            /// 라벨
            Text(label, style: labelStyle),

            /// 트레일링 아이콘
            if (trailingIcon != null)
              Padding(padding: EdgeInsets.only(left: iconSpacing ?? 10), child: trailingIcon),
          ],
        ),
      ),
    );
  }

  ButtonStyleButton button({required ButtonStyle buttonStyle, required Widget child}) {
    return switch (type) {
      CButtonType.fill => ElevatedButton(style: buttonStyle, onPressed: onTap, child: child),
      CButtonType.flat => TextButton(style: buttonStyle, onPressed: onTap, child: child),
      CButtonType.outline => OutlinedButton(style: buttonStyle, onPressed: onTap, child: child),
    };
  }
}
