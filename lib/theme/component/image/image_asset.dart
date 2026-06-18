import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ImageAsset extends StatelessWidget {
  const ImageAsset(
      this.assetName, {
        super.key,
        this.color,
        this.size,
        this.alignment = Alignment.center,
      });

  final String assetName;
  final Color? color;
  final double? size;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return assetName.split('.').last == 'svg'
        ? SvgPicture.asset(
      assetName,
      width: size,
      height: size,
      colorFilter: color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
      alignment: alignment,
    )
        : Image.asset(
      assetName,
      height: size,
      width: size,
      color: color,
      alignment: alignment,
    );
  }
}
