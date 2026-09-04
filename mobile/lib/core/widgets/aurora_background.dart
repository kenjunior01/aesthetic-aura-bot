/// aurora_background.dart — a observidana respira: halos de aurora platina
/// derivam lentamente atrás de todo o app (float-slow do web).
///
/// O tick vive no painter (AnimationController → repaint), nunca reconstrói
/// a árvore de conteúdo — 60fps no halo, custo zero no resto do app.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/aura_colors.dart';

class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, this.child});

  final Widget? child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AuraColors.background),
        CustomPaint(
          painter: _AuroraPainter(drift: _controller),
          size: Size.infinite,
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter({required Animation<double> drift})
    : _driftAnim = drift,
      super(repaint: drift);

  final Animation<double> _driftAnim;

  // Deriva lenta e orgânica — cada halo com fase própria.
  static double _drift(double t, double speed, double phase, double amp) =>
      math.sin(t * speed + phase) * amp;

  @override
  void paint(Canvas canvas, Size size) {
    // Uma volta completa de deriva por ciclo do controller (24s).
    final t = _driftAnim.value * 2 * math.pi;
    final w = size.width;
    final h = size.height;

    void halo(Offset c, double r, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(colors: [color, color.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    // Halo principal — platina no topo-esquerda.
    halo(
      Offset(
        w * 0.18 + _drift(t, 1.0, 0, w * 0.045),
        h * 0.08 + _drift(t, 1.3, 1.2, h * 0.028),
      ),
      w * 0.9,
      AuraColors.auroraHalo1,
    );
    // Halo ártico — direita, mais profundo.
    halo(
      Offset(
        w * 0.95 + _drift(t, 0.8, 2.1, w * 0.055),
        h * 0.42 + _drift(t, 1.1, 0.4, h * 0.038),
      ),
      w * 0.75,
      AuraColors.auroraHalo2,
    );
    // Azul profundo — base.
    halo(
      Offset(w * 0.4 + _drift(t, 0.7, 4.0, w * 0.07), h * 1.02),
      w * 0.85,
      AuraColors.auroraHalo3,
    );

    // Véu vertical de observidana — garante contraste do conteúdo.
    final veil = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x0004060A), Color(0x9904060A), Color(0xE604060A)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, veil);
  }

  @override
  bool shouldRepaint(_AuroraPainter oldDelegate) => false;
}
