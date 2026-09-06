/// barra_chegada.dart — a BARRA DE CHEGADA: a linha de meta da tua jornada.
///
/// CustomPainter próprio: trilho usinado, preenchimento em metal platina
/// com glow, nós de fase (passado cheio, futuro oco) e a bandeira do AUGE
/// no fim. Anima o preenchimento ao entrar.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';

/// Estado de um nó da barra.
enum _NoEstado { passado, futuro }

class BarraChegada extends StatefulWidget {
  const BarraChegada({
    super.key,
    required this.progresso,
    required this.totalSemanas,
    this.nos = const [],
    this.semanaAtual,
    this.compact = false,
    this.animar = true,
  });

  /// 0..1 — distância percorrida até o auge.
  final double progresso;

  final int totalSemanas;

  /// Nós das fases: fração 0..1 da posição.
  final List<double> nos;

  /// Semana atual (para o selo "SEM X").
  final int? semanaAtual;

  /// Compacto (cartões do início/diário): sem etiquetas nem bandeira.
  final bool compact;

  final bool animar;

  @override
  State<BarraChegada> createState() => _BarraChegadaState();
}

class _BarraChegadaState extends State<BarraChegada>
    with TickerProviderStateMixin {
  late final AnimationController _preench = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void initState() {
    super.initState();
    if (widget.animar) {
      _preench.forward();
    } else {
      _preench.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant BarraChegada old) {
    super.didUpdateWidget(old);
    if (old.progresso != widget.progresso) {
      _preench.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _preench.dispose();
    _pulso.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_preench, _pulso]),
      builder: (context, _) => CustomPaint(
        size: Size.fromHeight(widget.compact ? 54 : 92),
        painter: _BarraPainter(
          progresso: widget.progresso * _preench.value,
          nos: widget.nos,
          pulso: _pulso.value,
          compact: widget.compact,
        ),
        child: _etiquetas(),
      ),
    );
  }

  Widget _etiquetas() {
    if (widget.compact) return const SizedBox.expand();
    return SizedBox.expand(
      child: Row(
        children: [
          Text(
            'SEM 1',
            style: AuraType.eyebrow.copyWith(fontSize: 8, letterSpacing: 1.4),
          ),
          const Spacer(),
          if (widget.semanaAtual != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: AuraDecor.auraMetal,
                boxShadow: AuraDecor.glowShadow(alpha: 0.3),
              ),
              child: Text(
                'SEM ${widget.semanaAtual}',
                style: AuraType.chip.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AuraColors.onPrimary,
                ),
              ),
            ),
          const Spacer(),
          Text(
            'AUGE · SEM ${widget.totalSemanas}',
            style: AuraType.eyebrow.copyWith(fontSize: 8, letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BarraPainter extends CustomPainter {
  _BarraPainter({
    required this.progresso,
    required this.nos,
    required this.pulso,
    required this.compact,
  });

  final double progresso; // 0..1
  final List<double> nos; // posições 0..1
  final double pulso; // 0..1 contínuo
  final bool compact;

  static const _altTrilho = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final margem = compact ? 6.0 : 14.0;
    final y = compact ? size.height * 0.5 : size.height * 0.55;
    final largura = size.width - margem * 2;
    final r = Radius.circular(_altTrilho / 2);

    // ── Trilho (fundo) ──────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(margem, y - _altTrilho / 2, largura, _altTrilho),
        topLeft: r,
        topRight: r,
        bottomLeft: r,
        bottomRight: r,
      ),
      Paint()..color = AuraColors.surfaceStrong,
    );

    // ── Preenchimento com metal + glow ──────────────────────────────────
    final frac = progresso.clamp(0.0, 1.0);
    if (frac > 0.001) {
      final rectFill = Rect.fromLTWH(
        margem,
        y - _altTrilho / 2,
        largura * frac,
        _altTrilho,
      );
      final rrectFill = RRect.fromRectAndCorners(
        rectFill,
        topLeft: r,
        bottomLeft: r,
        topRight: frac > 0.995 ? r : Radius.circular(0),
        bottomRight: frac > 0.995 ? r : Radius.circular(0),
      );
      // Glow por baixo.
      canvas.drawRRect(
        rrectFill.inflate(3),
        Paint()
          ..color = AuraColors.primary.withValues(
            alpha: 0.18 + 0.1 * math.sin(pulso * math.pi * 2).abs(),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      // Metal.
      canvas.drawRRect(
        rrectFill,
        Paint()
          ..shader = AuraDecor.auraMetal.createShader(
            Rect.fromLTWH(margem, y - _altTrilho / 2, largura, _altTrilho),
          ),
      );
      // Cabeça de luz no ponteiro.
      final cabeca = Offset(margem + largura * frac, y);
      canvas.drawCircle(
        cabeca,
        compact ? 4.5 : 5.5,
        Paint()..color = AuraColors.platinaLuminosa,
      );
      canvas.drawCircle(
        cabeca,
        compact ? 8.5 : 10.5,
        Paint()
          ..color = AuraColors.primary.withValues(
            alpha: 0.22 + 0.14 * math.sin(pulso * math.pi * 2).abs(),
          )
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }

    // ── Nós das fases ───────────────────────────────────────────────────
    for (final n in nos) {
      final f = n.clamp(0.0, 1.0);
      final centro = Offset(margem + largura * f, y);
      final estado = f <= frac ? _NoEstado.passado : _NoEstado.futuro;
      final raio = compact ? 4.0 : 5.0;
      if (estado == _NoEstado.passado) {
        canvas.drawCircle(centro, raio, Paint()..color = AuraColors.primary);
      } else {
        canvas.drawCircle(
          centro,
          raio,
          Paint()..color = AuraColors.backgroundDeep,
        );
        canvas.drawCircle(
          centro,
          raio,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = AuraColors.mutedForeground,
        );
      }
    }

    if (compact) return;

    // ── Bandeira do AUGE (fim) ──────────────────────────────────────────
    final fim = Offset(margem + largura, y - _altTrilho / 2);
    final chegou = frac > 0.995;
    final cor = chegou ? AuraColors.primary : AuraColors.mutedForeground;
    // Mastro.
    canvas.drawLine(
      fim,
      Offset(fim.dx, fim.dy - 16),
      Paint()
        ..strokeWidth = 1.6
        ..color = cor,
    );
    // Bandeira triangular.
    final path = Path()
      ..moveTo(fim.dx, fim.dy - 16)
      ..lineTo(fim.dx + 11, fim.dy - 12)
      ..lineTo(fim.dx, fim.dy - 8)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = chegou
            ? AuraColors.primary
            : AuraColors.mutedForeground.withValues(alpha: 0.55),
    );
    if (chegou) {
      canvas.drawCircle(
        fim,
        12,
        Paint()
          ..color = AuraColors.primary.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarraPainter old) =>
      old.progresso != progresso ||
      old.pulso != pulso ||
      old.nos.length != nos.length ||
      old.compact != compact;
}

/// Mini barra para cartões (home, diário) — sem etiquetas.
class BarraChegadaCompacta extends StatelessWidget {
  const BarraChegadaCompacta({
    super.key,
    required this.progresso,
    required this.totalSemanas,
    this.nos = const [],
  });

  final double progresso;
  final int totalSemanas;
  final List<double> nos;

  @override
  Widget build(BuildContext context) {
    return BarraChegada(
      progresso: progresso,
      totalSemanas: totalSemanas,
      nos: nos,
      compact: true,
      animar: false,
    );
  }
}
