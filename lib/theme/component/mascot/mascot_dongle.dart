import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 코랄 원형 얼굴 마스코트 '동글이'(점선 링 + 눈 2 + 미소). [size]로 26~88px 스케일.
/// [size] >= [inkThreshold]면 디자인대로 잉크색 이목구비 + 볼터치, 작으면 흰색 이목구비.
class MascotDongle extends StatelessWidget {
  const MascotDongle({super.key, this.size = 40, this.faceColor, this.featureColor});

  final double size;
  final Color? faceColor;

  /// 눈·미소 색. null이면 크기에 따라 잉크(큰 사이즈) / 흰색(작은 사이즈).
  final Color? featureColor;

  static const double inkThreshold = 64;

  @override
  Widget build(BuildContext context) {
    final large = size >= inkThreshold;
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _DonglePainter(
        face: faceColor ?? Palette.primaryNormal,
        feature: featureColor ?? (large ? Palette.labelNormal : Palette.staticWhite),
        cheeks: large,
      )),
    );
  }
}

class _DonglePainter extends CustomPainter {
  const _DonglePainter({required this.face, required this.feature, required this.cheeks});
  final Color face;
  final Color feature;
  final bool cheeks;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, r = w / 2;
    final c = Offset(r, r);
    canvas.drawCircle(c, r, Paint()..color = face);
    _dashedRing(canvas, c, r - w * 0.11, w * 0.03);

    final eye = Paint()..color = feature;
    final er = w * 0.045;
    canvas.drawCircle(Offset(w * 0.34, w * 0.47), er, eye);
    canvas.drawCircle(Offset(w * 0.66, w * 0.47), er, eye);

    final smile = Paint()
      ..color = feature
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: Offset(r, w * 0.555), radius: w * 0.1);
    canvas.drawArc(rect, 0.2, 2.74, false, smile);

    if (cheeks) {
      final blush = Paint()..color = Palette.staticWhite.withValues(alpha: 0.4);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.28, w * 0.57), width: w * 0.125, height: w * 0.068), blush);
      canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.72, w * 0.57), width: w * 0.125, height: w * 0.068), blush);
    }
  }

  /// 흰색 65% 점선 링 (디자인 `border: dashed rgba(255,255,255,.65)`).
  void _dashedRing(Canvas canvas, Offset center, double radius, double stroke) {
    final paint = Paint()
      ..color = Palette.staticWhite.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const dashes = 22;
    const step = 2 * math.pi / dashes;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(rect, i * step, step * 0.55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DonglePainter old) =>
      old.face != face || old.feature != feature || old.cheeks != cheeks;
}
