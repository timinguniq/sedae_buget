import 'package:flutter/material.dart';
import 'package:sedae_budget/theme/theme.dart';

/// 코랄 원형 얼굴 마스코트(눈 2 + 미소). [size]로 26~88px 스케일.
class MascotDongle extends StatelessWidget {
  const MascotDongle({super.key, this.size = 40, this.faceColor});

  final double size;
  final Color? faceColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size, height: size,
      child: CustomPaint(painter: _DonglePainter(faceColor ?? Palette.primaryNormal)),
    );
  }
}

class _DonglePainter extends CustomPainter {
  const _DonglePainter(this.face);
  final Color face;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, r = w / 2;
    final c = Offset(r, r);
    canvas.drawCircle(c, r, Paint()..color = face);
    final eye = Paint()..color = Palette.staticWhite;
    final er = w * 0.05;
    canvas.drawCircle(Offset(w * 0.38, w * 0.42), er, eye);
    canvas.drawCircle(Offset(w * 0.62, w * 0.42), er, eye);
    final smile = Paint()
      ..color = Palette.staticWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: Offset(r, w * 0.52), radius: w * 0.12);
    canvas.drawArc(rect, 0.2, 2.74, false, smile);
  }

  @override
  bool shouldRepaint(_DonglePainter old) => old.face != face;
}
