import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieAsset extends StatelessWidget {
  const LottieAsset(
      this.url, {
        super.key,
        this.height = 100,
        this.width,
        this.repeat = true,
        this.fit = BoxFit.fitHeight,
        this.animate,
      });

  final String url;
  final double? height;
  final double? width;
  final bool? repeat;
  final BoxFit? fit;
  final bool? animate;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      url,
      height: height,
      width: width,
      repeat: repeat,
      fit: fit,
      frameRate: FrameRate.max,
      animate: animate,
    );
  }
}
