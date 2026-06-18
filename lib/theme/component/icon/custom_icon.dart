import 'package:sedae_budget/theme/theme.dart';
import 'package:flutter/material.dart';

part 'custom_icon_data.dart';
part 'custom_icon_size.dart';

class CIcon extends StatelessWidget {
  const CIcon({
    super.key,
    this.icon,
    this.iconName,
    this.color,
    this.size = IconSize.md,
  }) : assert(icon != null || iconName != null, 'icon or iconName must be provided');

  final IconData? icon;
  final String? iconName;
  final IconSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return icon == null
        ? ImageAsset(
      iconName!,
      color: color,
      size: size.getIconSize(),
    )
        : Icon(
      icon,
      color: color ?? Theme.of(context).iconTheme.color,
      size: size.getIconSize(),
    );
  }
}