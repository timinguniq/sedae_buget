import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 각 값의 비율만큼 라디안 스윕 각도 리스트를 반환(합 2π). total<=0이면 [].
List<double> donutSweeps(List<int> values) {
  final total = values.fold<int>(0, (s, v) => s + v);
  if (total <= 0) return const [];
  return values.map((v) => (v / total) * 2 * math.pi).toList();
}

class CategoryDonut extends StatelessWidget {
  const CategoryDonut({super.key, required this.values, required this.colors, this.size = 180, this.stroke = 26});
  final List<int> values;
  final List<Color> colors;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _DonutPainter(values, colors, stroke)));
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.values, this.colors, this.stroke);
  final List<int> values;
  final List<Color> colors;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final sweeps = donutSweeps(values);
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    var start = -math.pi / 2;
    for (var i = 0; i < sweeps.length; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweeps[i] - 0.02, false, p);
      start += sweeps[i];
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.values != values || old.colors != colors;
}
