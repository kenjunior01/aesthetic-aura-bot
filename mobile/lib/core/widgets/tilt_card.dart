/// tilt_card.dart — o cartão responde à mão como um objeto físico:
/// perspectiva real (max 5°), reflexo especular holográfico que corre
/// pela superfície conforme o ângulo, e sombra que se projecta no sentido
/// oposto ao toque — profundidade de vitrine.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/aura_colors.dart';

class TiltCard extends StatefulWidget {
  const TiltCard({
    super.key,
    required this.child,
    this.maxDegrees = 5,
    this.sheen = true,
    this.depthShadow = false,
  });

  final Widget child;
  final double maxDegrees;

  /// Reflexo holográfico que segue o gesto (o "vidro da vitrine").
  final bool sheen;

  /// Sombra de profundidade que desliza contra o tilt.
  final bool depthShadow;

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> with TickerProviderStateMixin {
  late final AnimationController _anim;
  Offset _target = Offset.zero; // -1..1
  Offset _current = Offset.zero;
  bool _tocando = false;

  @override
  void initState() {
    super.initState();
    _anim =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 90),
        )..addListener(() {
          setState(() => _current = Offset.lerp(_current, _target, 0.28)!);
        });
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _update(Offset local, Size size) {
    _tocando = true;
    _target = Offset(
      ((local.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
      ((local.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
    );
    _anim.forward(from: 0);
  }

  void _reset() {
    _tocando = false;
    _target = Offset.zero;
    _anim.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final tilt = _current;
    final intensidade = math
        .sqrt((tilt.dx * tilt.dx + tilt.dy * tilt.dy).clamp(0.0, 4.0))
        .clamp(0.0, 1.4);

    Widget card = widget.child;
    if (widget.depthShadow) {
      card = AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: _tocando
              ? [
                  BoxShadow(
                    color: AuraColors.shadowCold.withValues(alpha: 0.55),
                    offset: Offset(-tilt.dx * 14, 18 + tilt.dy.abs() * 8),
                    blurRadius: 34,
                    spreadRadius: -14,
                  ),
                  BoxShadow(
                    color: AuraColors.primary.withValues(alpha: 0.10 * intensidade),
                    offset: const Offset(0, 6),
                    blurRadius: 18,
                    spreadRadius: -8,
                  ),
                ]
              : [
                  BoxShadow(
                    color: AuraColors.shadowCold.withValues(alpha: 0.4),
                    offset: const Offset(0, 14),
                    blurRadius: 28,
                    spreadRadius: -14,
                  ),
                ],
        ),
        child: card,
      );
    }

    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition, context.size ?? Size.zero),
      onPanUpdate: (d) => _update(d.localPosition, context.size ?? Size.zero),
      onPanCancel: _reset,
      onPanEnd: (_) => _reset(),
      child: Stack(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // perspectiva
              ..rotateX(tilt.dy * widget.maxDegrees * math.pi / 180)
              ..rotateY(-tilt.dx * widget.maxDegrees * math.pi / 180),
            child: card,
          ),
          // Vitrine holográfica — brilho especular que corre com o gesto.
          if (widget.sheen)
            IgnorePointer(
              child: AnimatedOpacity(
                opacity: _tocando ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CustomPaint(
                    painter: _VitrinePainter(tilt),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// O brilho: um highlight radial posicionado contra a luz + faixa diagonal
/// que atravessa o cartão conforme o ângulo.
class _VitrinePainter extends CustomPainter {
  _VitrinePainter(this.tilt);

  final Offset tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w == 0 || h == 0) return;

    // Highlight radial vindo do canto oposto ao arrasto.
    final cx = w * (0.5 - tilt.dx * 0.42);
    final cy = h * (0.5 - tilt.dy * 0.42);
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: w * 0.7));
    canvas.drawRect(Offset.zero & size, glow);

    // Faixa holográfica diagonal — desloca com o tilt horizontal.
    final faixaX = w * (0.5 + tilt.dx * 0.55);
    final faixa = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.10),
          const Color(0x1AB8D9F3),
          Colors.white.withValues(alpha: 0.10),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.42, 0.5, 0.58, 1.0],
      ).createShader(
        Rect.fromLTWH(faixaX - w * 0.5, -h * 0.2, w, h * 1.4),
      );
    canvas.save();
    canvas.transform((Matrix4.identity()..rotateZ(-0.35)).storage);
    canvas.drawRect(Rect.fromLTWH(faixaX - w * 0.7, -h * 0.3, w * 1.4, h * 1.6), faixa);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_VitrinePainter oldDelegate) => oldDelegate.tilt != tilt;
}
