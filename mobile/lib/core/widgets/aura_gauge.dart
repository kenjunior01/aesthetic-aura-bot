/// aura_gauge.dart — o mostrador do nível: coroa usinada com arco de
/// progresso em platina, ticks de precisão e glow ártico. Relógio, não "IA
/// brilhante" — a mesma linguagem do gauge do web.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/aura_colors.dart';
import '../theme/aura_decorations.dart';
import '../theme/aura_typography.dart';

class AuraGauge extends StatefulWidget {
  const AuraGauge({
    super.key,
    required this.progress,
    required this.level,
    required this.xp,
    this.size = 168,
  });

  final double progress; // 0..1
  final int level;
  final int xp;
  final double size;

  @override
  State<AuraGauge> createState() => _AuraGaugeState();
}

class _AuraGaugeState extends State<AuraGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _curve = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    _c.forward();
  }

  @override
  void didUpdateWidget(covariant AuraGauge old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) _c.forward(from: 0);
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
        builder: (context, _) => CustomPaint(
          painter: _GaugePainter(widget.progress * _curve.value),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('NÍVEL', style: AuraType.eyebrow.copyWith(fontSize: 9)),
                const SizedBox(height: 2),
                ShaderMask(
                  shaderCallback: (b) => AuraDecor.auraMetal.createShader(
                    Rect.fromLTWH(0, 0, b.width, b.height),
                  ),
                  child: Text(
                    '${widget.level}',
                    style: AuraType.machinedNumber.copyWith(
                      fontSize: widget.size * 0.22,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.xp} XP',
                  style: AuraType.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Coroa exterior — arco de fundo frio.
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: 2.6,
        endAngle: 7.0,
        colors: [Color(0x14EDF2FA), Color(0x05EDF2FA)],
      ).createShader(rect);
    canvas.drawArc(rect, 2.55, 1.83 * math.pi, false, bgPaint);

    // Arco de progresso em metal platina + glow.
    if (progress > 0) {
      final progRect = Rect.fromCircle(center: center, radius: radius - 3);
      final glow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = AuraColors.primary.withValues(alpha: 0.35);
      final prog = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..shader = AuraDecor.auraMetal.createShader(progRect);

      final start = 2.55 * math.pi;
      final sweep = 1.83 * math.pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(progRect, start, sweep, false, glow);
      canvas.drawArc(progRect, start, sweep, false, prog);
    }

    // Ticks de usinagem — 36 marcas finas na circunferência interna.
    final tick = Paint()
      ..strokeWidth = 1
      ..color = AuraColors.foreground.withValues(alpha: 0.12);
    final inner = radius - 16;
    for (var i = 0; i < 36; i++) {
      final a = i * math.pi / 18;
      final p1 = center + Offset(math.cos(a), math.sin(a)) * (inner - 3);
      final p2 = center + Offset(math.cos(a), math.sin(a)) * inner;
      canvas.drawLine(p1, p2, tick);
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.progress != progress;
}
