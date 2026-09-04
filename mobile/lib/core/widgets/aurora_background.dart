/// aurora_background.dart — campo Interstellar: a obsidiana respira com
/// nebulosas à deriva, poeira estelar em três profundidades, constelação
/// da Aura, fitas de aurora boreal e estrelas cadentes ocasionais.
///
/// Tudo num único CustomPainter animado por um AnimationController (repaint),
/// sem reconstruir a árvore de conteúdo. Zero dependências externas.
/// Com "reduzir animações" activo nas definições, o campo pinta parado.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

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
  late final Stopwatch _clock;
  bool _reduzAnim = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );
    _clock = Stopwatch()..start();
    // Ciclo longo e contínuo — a deriva nunca salta.
    _controller.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduz = MediaQuery.disableAnimationsOf(context);
    if (reduz != _reduzAnim) {
      _reduzAnim = reduz;
      if (reduz) {
        _controller.stop();
      } else {
        _controller.repeat();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AuraColors.background),
        RepaintBoundary(
          child: CustomPaint(
            painter: _InterstellarPainter(
              drift: _controller,
              clock: _clock,
              quiet: _reduzAnim,
            ),
            size: Size.infinite,
            isComplex: true,
            willChange: !_reduzAnim,
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

/// Estrela com posição relativa (0..1), tamanho, brilho e fase própria.
class _Estrela {
  _Estrela(this.dx, this.dy, this.r, this.alpha, this.fase, this.periodo);

  final double dx;
  final double dy;
  final double r;
  final double alpha;
  final double fase;
  final double periodo;
}

class _InterstellarPainter extends CustomPainter {
  _InterstellarPainter({
    required Animation<double> drift,
    required Stopwatch clock,
    required this.quiet,
  }) : _driftAnim = drift,
       // ignore: prefer_initializing_formals
       _clock = clock,
       super(repaint: drift);

  final Animation<double> _driftAnim;
  final Stopwatch _clock;
  final bool quiet;

  // Poeira estelar determinística — a mesma semente desenha sempre o
  // mesmo céu (sem cintilar ao redimensionar).
  static final List<_Estrela> _campo = _gerarCampo();

  static List<_Estrela> _gerarCampo() {
    final rng = math.Random(20260904);
    final estrelas = <_Estrela>[];
    // Camada distante — 52 pontos de poeira fina.
    for (var i = 0; i < 52; i++) {
      estrelas.add(
        _Estrela(
          rng.nextDouble(),
          rng.nextDouble(),
          0.4 + rng.nextDouble() * 0.5,
          0.12 + rng.nextDouble() * 0.22,
          rng.nextDouble() * 2 * math.pi,
          4 + rng.nextDouble() * 6,
        ),
      );
    }
    // Camada média — 28 estrelas.
    for (var i = 0; i < 28; i++) {
      estrelas.add(
        _Estrela(
          rng.nextDouble(),
          rng.nextDouble(),
          0.8 + rng.nextDouble() * 0.6,
          0.22 + rng.nextDouble() * 0.28,
          rng.nextDouble() * 2 * math.pi,
          3 + rng.nextDouble() * 5,
        ),
      );
    }
    // Camada próxima — 12 estrelas-guia.
    for (var i = 0; i < 12; i++) {
      estrelas.add(
        _Estrela(
          rng.nextDouble(),
          rng.nextDouble() * 0.85,
          1.2 + rng.nextDouble() * 0.8,
          0.4 + rng.nextDouble() * 0.3,
          rng.nextDouble() * 2 * math.pi,
          2.5 + rng.nextDouble() * 4,
        ),
      );
    }
    return estrelas;
  }

  static double _deriva(double t, double speed, double fase, double amp) =>
      math.sin(t * speed + fase) * amp;

  /// Jitter determinístico em [0,1) a partir de um inteiro.
  static double _jitter(int i) {
    final x = math.sin(i * 127.1 + 311.7) * 43758.5453;
    return x - x.floorToDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // t ambiente: uma volta por ciclo de 60s; quiet congela num momento bonito.
    final t = quiet ? 1.7 : _driftAnim.value * 2 * math.pi;
    final secs = quiet ? 9.0 : _clock.elapsedMilliseconds / 1000.0;

    _pintarNebulosas(canvas, w, h, t);
    _pintarHalos(canvas, w, h, t);
    _pintarCampoEstelar(canvas, w, h, t, secs);
    _pintarConstelacao(canvas, w, h, t);
    _pintarFitasAurora(canvas, w, h, t);
    _pintarEstrelaCadente(canvas, w, h, secs);
    _pintarVeu(canvas, w, h, t);
  }

  void _orbe(Canvas canvas, Offset c, double r, Color cor) {
    final paint = Paint()
      ..shader = RadialGradient(colors: [cor, cor.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawCircle(c, r, paint);
  }

  void _pintarNebulosas(Canvas canvas, double w, double h, double t) {
    // Poeira cósmica — massas ultra-suaves em órbitas de Lissajous lentas.
    _orbe(
      canvas,
      Offset(
        w * 0.30 + _deriva(t, 0.9, 0.6, w * 0.08),
        h * 0.24 + _deriva(t, 1.4, 2.2, h * 0.05),
      ),
      w * 0.62,
      const Color(0x0F9FCAEE),
    );
    _orbe(
      canvas,
      Offset(
        w * 0.78 + _deriva(t, 1.2, 3.5, w * 0.06),
        h * 0.62 + _deriva(t, 0.7, 1.1, h * 0.07),
      ),
      w * 0.55,
      const Color(0x0CB8D9F3),
    );
  }

  void _pintarHalos(Canvas canvas, double w, double h, double t) {
    _orbe(
      canvas,
      Offset(
        w * 0.18 + _deriva(t, 1.0, 0, w * 0.045),
        h * 0.08 + _deriva(t, 1.3, 1.2, h * 0.028),
      ),
      w * 0.9,
      AuraColors.auroraHalo1,
    );
    _orbe(
      canvas,
      Offset(
        w * 0.95 + _deriva(t, 0.8, 2.1, w * 0.055),
        h * 0.42 + _deriva(t, 1.1, 0.4, h * 0.038),
      ),
      w * 0.75,
      AuraColors.auroraHalo2,
    );
    _orbe(
      canvas,
      Offset(w * 0.4 + _deriva(t, 0.7, 4.0, w * 0.07), h * 1.02),
      w * 0.85,
      AuraColors.auroraHalo3,
    );
  }

  void _pintarCampoEstelar(
    Canvas canvas,
    double w,
    double h,
    double t,
    double secs,
  ) {
    // Cada camada deriva a velocidade própria — paralaxe ambiente.
    for (var i = 0; i < _campo.length; i++) {
      final e = _campo[i];
      final camada = i < 52 ? 0 : (i < 80 ? 1 : 2);
      final amp = w * (0.006 + camada * 0.008);
      final dx = _deriva(t, 1.1 + camada * 0.5, e.fase, amp);
      final dy = _deriva(t, 0.8 + camada * 0.4, e.fase * 1.7, amp * 0.7);
      // Cintilação — cada estrela respira no seu ritmo.
      final pulsos = quiet
          ? 1.0
          : 0.55 + 0.45 * math.sin(secs * 2 * math.pi / e.periodo + e.fase);
      final a = (e.alpha * pulsos).clamp(0.0, 1.0);
      final cor = i.isEven
          ? const Color(0xFFF4FAFF)
          : (i % 3 == 0 ? const Color(0xFFB8D9F3) : const Color(0xFF9FCAEE));
      canvas.drawCircle(
        Offset(e.dx * w + dx, e.dy * h + dy),
        e.r,
        Paint()
          ..color = cor.withValues(alpha: a)
          ..isAntiAlias = false,
      );
      // As quatro mais brilhantes da camada próxima ganham brilho de lente.
      if (camada == 2 && i % 3 == 0) {
        final brilho = (a * 0.55).clamp(0.0, 1.0);
        final glint = Paint()
          ..color = cor.withValues(alpha: brilho)
          ..strokeWidth = 0.8
          ..isAntiAlias = false;
        canvas.drawLine(
          Offset(e.dx * w + dx - e.r * 3.2, e.dy * h + dy),
          Offset(e.dx * w + dx + e.r * 3.2, e.dy * h + dy),
          glint,
        );
        canvas.drawLine(
          Offset(e.dx * w + dx, e.dy * h + dy - e.r * 3.2),
          Offset(e.dx * w + dx, e.dy * h + dy + e.r * 3.2),
          glint,
        );
      }
    }
  }

  void _pintarConstelacao(Canvas canvas, double w, double h, double t) {
    // Mapa da Aura — sete estrelas da camada distante unidas por fios de luz.
    const indices = [3, 9, 14, 21, 27, 33, 40];
    final pontos = <Offset>[];
    for (final i in indices) {
      final e = _campo[i];
      pontos.add(
        Offset(
          e.dx * w + _deriva(t, 1.1, e.fase, w * 0.006),
          e.dy * h + _deriva(t, 0.8, e.fase * 1.7, h * 0.004),
        ),
      );
    }
    final fio = Path()..moveTo(pontos.first.dx, pontos.first.dy);
    for (var k = 1; k < pontos.length; k++) {
      fio.lineTo(pontos[k].dx, pontos[k].dy);
    }
    canvas.drawPath(
      fio,
      Paint()
        ..color = const Color(0x10B8D9F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
    // Nós da constelação — pontos um pouco mais presentes.
    for (final p in pontos) {
      canvas.drawCircle(p, 1.3, Paint()..color = const Color(0x2EB8D9F3));
    }
  }

  void _pintarFitasAurora(Canvas canvas, double w, double h, double t) {
    // Fitas boreais — seda de luz platina que ondula e respira.
    void fita(double yBase, double fase, double alpha, double espessura) {
      final path = Path();
      var primeiro = true;
      for (var passo = 0; passo <= 16; passo++) {
        final x = passo * (w / 16);
        final y =
            yBase +
            math.sin(passo * 0.34 + t * 1.1 + fase) * h * 0.030 +
            math.sin(passo * 0.13 - t * 0.5 + fase * 2.0) * h * 0.018;
        if (primeiro) {
          path.moveTo(x, y);
          primeiro = false;
        } else {
          path.lineTo(x, y);
        }
      }
      void finalPaint(Color cor, double largura, double sigma) {
        final p = Paint()
          ..color = cor
          ..style = PaintingStyle.stroke
          ..strokeWidth = largura
          ..strokeCap = StrokeCap.round
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, sigma);
        canvas.drawPath(path, p);
      }

      finalPaint(
        const Color(0x169FCAEE).withValues(alpha: alpha),
        espessura,
        16,
      );
      finalPaint(
        const Color(0x26B8D9F3).withValues(alpha: alpha * 0.85),
        espessura * 0.36,
        6,
      );
    }

    final respira = quiet ? 1.0 : 0.75 + 0.25 * math.sin(t * 1.9);
    fita(h * 0.13, 0.0, 0.34 * respira, 22);
    fita(h * 0.24, 2.4, 0.22 * respira, 15);
  }

  void _pintarEstrelaCadente(Canvas canvas, double w, double h, double secs) {
    // Agenda determinística: um desejo a cada ~11s, vida de 0.7s.
    const intervalo = 11.3;
    const vida = 0.7;
    final ciclo = secs % intervalo;
    // O primeiro segundo de cada ciclo está reservado à estrela.
    if (ciclo > vida) return;
    final slot = (secs ~/ intervalo).toInt();
    final progresso = ciclo / vida;
    final ease = Curves.easeOutCubic.transform(progresso);

    // Trajectória: nasce no terço superior, desce na diagonal.
    final startX = w * (0.18 + _jitter(slot) * 0.55);
    final startY = h * (0.06 + _jitter(slot + 7) * 0.16);
    final dist = w * 0.34;
    final dx = dist * 0.92;
    final dy = dist * 0.39;
    final caudaX = startX + dx * (ease - 0.28);
    final caudaY = startY + dy * (ease - 0.28);
    final cabecaX = startX + dx * ease;
    final cabecaY = startY + dy * ease;

    final fade = math.sin(progresso * math.pi);
    final trilho = Paint()
      ..shader = ui.Gradient.linear(
        Offset(caudaX, caudaY),
        Offset(cabecaX, cabecaY),
        [
          const Color(0xFFF4FAFF).withValues(alpha: 0),
          const Color(0xFFB8D9F3).withValues(alpha: 0.55 * fade),
          const Color(0xFFF4FAFF).withValues(alpha: 0.95 * fade),
        ],
        [0.0, 0.7, 1.0],
      )
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(caudaX, caudaY), Offset(cabecaX, cabecaY), trilho);
    _orbe(
      canvas,
      Offset(cabecaX, cabecaY),
      7,
      const Color(0x66F4FAFF).withValues(alpha: 0.7 * fade),
    );
  }

  void _pintarVeu(Canvas canvas, double w, double h, double t) {
    // Horizonte glacial — luz distante de gelo refletida, muito abaixo.
    _orbe(
      canvas,
      Offset(w * 0.5 + _deriva(t, 0.6, 1.8, w * 0.05), h * 0.9),
      w * 1.1,
      const Color(0x0A9FCAEE),
    );

    // Véu vertical de obsidiana — garante contraste do conteúdo.
    final veil = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x0004060A), Color(0x8C04060A), Color(0xE604060A)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(Offset.zero & Size(w, h));
    canvas.drawRect(Offset.zero & Size(w, h), veil);
  }

  @override
  bool shouldRepaint(_InterstellarPainter oldDelegate) => quiet != oldDelegate.quiet;
}
