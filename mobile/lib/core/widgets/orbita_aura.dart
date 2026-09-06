/// orbita_aura.dart — a órbita da Aura: partícula de platina a girar num
/// anel usinado com núcleo que respira. É o estado "a calcular" dos
/// momentos cerimoniais (onboarding, jornada, check-ins).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/aura_colors.dart';
import '../theme/aura_decorations.dart';

class OrbitaAura extends StatefulWidget {
  const OrbitaAura({super.key, this.tamanho = 84, this.mostraNucleo = true});

  final double tamanho;
  final bool mostraNucleo;

  @override
  State<OrbitaAura> createState() => _OrbitaAuraState();
}

class _OrbitaAuraState extends State<OrbitaAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.tamanho,
      height: widget.tamanho,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _OrbitaPainter(t: _c.value, nucleo: widget.mostraNucleo),
        ),
      ),
    );
  }
}

class _OrbitaPainter extends CustomPainter {
  _OrbitaPainter({required this.t, required this.nucleo});
  final double t;
  final bool nucleo;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = size.width / 2 - 6;
    const doisPi = 2 * math.pi;

    // Anel base.
    canvas.drawCircle(
      centro,
      raio,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = AuraColors.border,
    );

    // Partícula em órbita com rastro.
    final ang = doisPi * t;
    for (var i = 5; i >= 0; i--) {
      final a = ang - i * 0.22;
      final pos = Offset(
        centro.dx + raio * math.cos(a),
        centro.dy + raio * math.sin(a),
      );
      canvas.drawCircle(
        pos,
        i == 0 ? 3.2 : 2.2 - i * 0.25,
        Paint()..color = AuraColors.platinaLuminosa.withValues(
          alpha: i == 0 ? 1 : 0.5 - i * 0.08,
        ),
      );
    }
    final pos = Offset(
      centro.dx + raio * math.cos(ang),
      centro.dy + raio * math.sin(ang),
    );
    canvas.drawCircle(
      pos,
      7,
      Paint()
        ..color = AuraColors.primary.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    if (nucleo) {
      // Núcleo que respira.
      canvas.drawCircle(
        centro,
        10 + 1.6 * math.sin(doisPi * t),
        Paint()
          ..shader = AuraDecor.auraMetal.createShader(
            Rect.fromCircle(center: centro, radius: 14),
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitaPainter old) => old.t != t;
}
