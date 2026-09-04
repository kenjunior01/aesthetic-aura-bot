/// radar_chart.dart — radar de prioridades: anéis concêntricos, eixos
/// usinados, polígonos de progresso em platina translúcida e pinos de gelo
/// nos vértices. Desenhado à mão em CustomPainter — sem dependências.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/aura_colors.dart';
import '../theme/aura_typography.dart';

class RadarPoint {
  const RadarPoint({required this.label, required this.value});
  final String label; // ex.: 'Pele', 'Cabelo'
  final double value; // 0..1
}

class RadarChart extends StatefulWidget {
  const RadarChart({super.key, required this.points, this.size = 210});

  final List<RadarPoint> points;
  final double size;

  @override
  State<RadarChart> createState() => _RadarChartState();
}

class _RadarChartState extends State<RadarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant RadarChart old) {
    super.didUpdateWidget(old);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) =>
            CustomPaint(painter: _RadarPainter(widget.points, _curve.value)),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.points, this.t);

  final List<RadarPoint> points;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 26; // espaço para as legendas
    final n = points.length;

    Offset vertex(int i, double scale) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      return center + Offset(math.cos(a), math.sin(a)) * radius * scale;
    }

    // Anéis concêntricos (4) — arcos de usinagem.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AuraColors.foreground.withValues(alpha: 0.09);
    for (var r = 1; r <= 4; r++) {
      final path = Path();
      for (var i = 0; i <= n; i++) {
        final p = vertex(i % n, r / 4);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, ring);
    }

    // Eixos.
    final axis = Paint()
      ..strokeWidth = 1
      ..color = AuraColors.foreground.withValues(alpha: 0.07);
    for (var i = 0; i < n; i++) {
      canvas.drawLine(center, vertex(i, 1), axis);
    }

    // Polígono de progresso — platina translúcida com borda luminosa.
    final fill = Path();
    for (var i = 0; i <= n; i++) {
      final p = points[i % n];
      final v = vertex(i % n, p.value.clamp(0.06, 1.0) * t);
      i == 0 ? fill.moveTo(v.dx, v.dy) : fill.lineTo(v.dx, v.dy);
    }
    fill.close();
    canvas.drawPath(
      fill,
      Paint()..color = AuraColors.primary.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      fill,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AuraColors.primary.withValues(alpha: 0.85),
    );

    // Pinos de gelo nos vértices + núcleo usinado.
    for (var i = 0; i < n; i++) {
      final p = vertex(i, points[i].value.clamp(0.06, 1.0) * t);
      canvas.drawCircle(p, 3.4, Paint()..color = AuraColors.primary);
      canvas.drawCircle(
        p,
        6.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AuraColors.primary.withValues(alpha: 0.4),
      );
    }
    canvas.drawCircle(center, 3, Paint()..color = AuraColors.accent);

    // Legendas.
    for (var i = 0; i < n; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      final p = center + Offset(math.cos(a), math.sin(a)) * (radius + 14);
      final tp = TextPainter(
        text: TextSpan(
          text: points[i].label.toUpperCase(),
          style: AuraType.eyebrow.copyWith(fontSize: 8.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t || old.points != points;
}
