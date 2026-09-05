/// confetti_burst.dart — explosão de partículas de platina, desenhada à mão
/// (CustomPainter, zero dependências). Dispara quando o Ritual fica completa
/// e quando um novo nível é alcançado — o momento merece ser visto.
///
/// Uso: ConfettiBurst(key: ValueKey(disparo)) dentro de um Stack — cada key
/// nova dispara uma nova rajada; sozinho quando o controller termina.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../store/profile_store.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_decorations.dart';

class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.duracaoMs = 1900, this.pouco = false});

  final int duracaoMs;

  /// Modo discreto (para dentro do cartão do Ritual) — menos partículas.
  final bool pouco;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.duracaoMs),
  )..forward();

  late final List<_Particula> _particulas;

  @override
  void initState() {
    super.initState();
    final rng = math.Random();
    final n = widget.pouco ? 26 : 58;
    // Cores da casa + um toque de gelo: a explosão é da identidade, não de
    // um arco-íris genérico.
    final cores = [
      const Color(0xFFE8F4FB), // platina claro
      const Color(0xFFBFD9EA), // gelo médio
      AuraColors.primary,
      AuraColors.secondary,
      const Color(0xFFF5E9D7), // champanhe rara
    ];
    _particulas = List.generate(n, (i) {
      // Dois canhões: cantos inferiores esquerdo/direito apontando ao centro.
      final esquerda = i.isEven;
      final ang = (esquerda ? -0.15 : math.pi + 0.15) +
          (rng.nextDouble() - 0.5) * 1.1;
      final vel = 0.55 + rng.nextDouble() * 0.75;
      return _Particula(
        x0: esquerda ? 0.04 : 0.96,
        y0: 0.86,
        vx: math.cos(ang) * vel,
        vy: math.sin(ang) * vel * 1.35,
        tamanho: 4.0 + rng.nextDouble() * 5.5,
        cor: cores[rng.nextInt(cores.length)],
        rot: rng.nextDouble() * math.pi * 2,
        vRot: (rng.nextDouble() - 0.5) * 12,
        atraso: rng.nextDouble() * 0.12,
        formato: rng.nextBool()
            ? _Formato.retangulo
            : (rng.nextBool() ? _Formato.disco : _Formato.fita),
      );
    });
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        // Fica invisível ao terminar — o pai remove com um setState.
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_c.isAnimating && _c.isCompleted) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _ConfettiPainter(_c.value, _particulas),
        size: Size.infinite,
      ),
    );
  }
}

enum _Formato { retangulo, disco, fita }

class _Particula {
  const _Particula({
    required this.x0,
    required this.y0,
    required this.vx,
    required this.vy,
    required this.tamanho,
    required this.cor,
    required this.rot,
    required this.vRot,
    required this.atraso,
    required this.formato,
  });

  final double x0, y0, vx, vy, tamanho, rot, vRot, atraso;
  final Color cor;
  final _Formato formato;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, this.particulas);

  final double t;
  final List<_Particula> particulas;

  @override
  void paint(Canvas canvas, Size size) {
    final gravidade = size.height * 1.15;
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in particulas) {
      final tt = t - p.atraso;
      if (tt <= 0) continue;
      // Física simples: velocidade decaindo + gravidade + arrasto do ar.
      final x = (p.x0 + p.vx * tt * 0.9) * size.width;
      final y = (p.y0 +
              p.vy * tt * 0.9 +
              0.5 * tt * tt * (gravidade / size.height) * 0.55) *
          size.height;
      if (y > size.height + 20) continue;
      final fade = (1.0 - (tt / 1.0).clamp(0.0, 1.0)).clamp(0.0, 1.0);
      if (fade <= 0.02) continue;
      final ang = p.rot + p.vRot * tt;
      final s = p.tamanho;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(ang);
      paint.color = p.cor.withValues(alpha: fade);
      switch (p.formato) {
        case _Formato.retangulo:
          // Brilho especular no retângulo — o toque "usinado".
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: s,
              height: s * 0.62,
            ),
            paint,
          );
          break;
        case _Formato.disco:
          canvas.drawCircle(Offset.zero, s * 0.42, paint);
          break;
        case _Formato.fita:
          // Fita ondulada: largura respira com a rotação.
          final ond = (math.sin(ang * 3) * 0.5 + 0.5).clamp(0.35, 1.0);
          final path = Path()
            ..addRRect(
              RRect.fromRectAndRadius(
                Rect.fromCenter(
                  center: Offset.zero,
                  width: s * 2.1,
                  height: s * 0.5 * ond,
                ),
                const Radius.circular(3),
              ),
            );
          canvas.drawPath(path, paint);
          break;
      }
      canvas.restore();
    }

    // Pó de brilho: pontinhos que fazem "twinkle" no pico da rajada.
    final rng = math.Random(20260906);
    for (var i = 0; i < 14; i++) {
      final fx = rng.nextDouble();
      final fy = rng.nextDouble() * 0.7;
      final fase = (t * 3 - rng.nextDouble()).clamp(0.0, 1.0);
      final brilho = (1 - (2 * fase - 1).abs()) * (1 - t);
      if (brilho <= 0.05) continue;
      paint.color = AuraColors.primary.withValues(alpha: brilho * 0.8);
      canvas.drawCircle(
        Offset(fx * size.width, fy * size.height),
        1.6 + brilho,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.particulas != particulas;
}

/// Overlay de LEVEL-UP — ecrã inteiro: disco usinado a ascender, novo nível
/// e título, confetti atrás. Auto-fecha (ou ao tocar).
class LevelUpOverlay extends StatefulWidget {
  const LevelUpOverlay({super.key, required this.nivel});

  final int nivel;

  @override
  State<LevelUpOverlay> createState() => _LevelUpOverlayState();
}

class _LevelUpOverlayState extends State<LevelUpOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void initState() {
    super.initState();
    // Some sozinho após a celebração.
    Future.delayed(const Duration(milliseconds: 2900), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titulo = nivelTitulo(widget.nivel);
    return GestureDetector(
      onTap: () => Navigator.of(context).maybePop(),
      child: Material(
        color: AuraColors.backgroundDeep.withValues(alpha: 0.72),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ConfettiBurst(),
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: _c,
                  curve: Curves.easeOutBack,
                ).drive(Tween(begin: 0.55, end: 1.0)),
                child: FadeTransition(
                  opacity: _c,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'NÍVEL ALCANÇADO',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          letterSpacing: 4.5,
                          color: AuraColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AuraDecor.auraMetal,
                          boxShadow: AuraDecor.glowShadow(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AuraColors.backgroundDeep,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${widget.nivel}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              color: AuraColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        titulo,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AuraColors.foreground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'a tua aura está a subir — continua',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: AuraColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
