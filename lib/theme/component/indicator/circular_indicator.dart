import 'package:flutter/material.dart';
import 'package:sedae_budget/presentation/presentation.dart';

class CircularIndicator extends StatelessWidget {
  const CircularIndicator({
    super.key,
    this.color,
    this.size,
    this.strokeWidth = 4.0,
  });

  final double? size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size ?? double.infinity,
      width: size ?? double.infinity,
      child: Center(
        child: CircularProgressIndicator(
          color: color ?? context.color.line.normal,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
