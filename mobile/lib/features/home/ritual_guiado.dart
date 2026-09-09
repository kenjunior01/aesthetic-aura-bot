/// ritual_guiado.dart — MODO GUIADO do Ritual de Hoje: um passo de cada vez,
/// cronómetro a correr, som a marcar cada conclusão e a próxima etapa à
/// vista. Cada passo concluído marca o Ritual de Hoje (o XP segue pela rota
/// normal do store) — o ritual deixa de ser lista e vira experiência.
///
/// Durações por passo (editáveis no código, honestas para o uso real):
///   água 30s · limpeza 60s · hidratante 45s · capilar 90s · diário 120s.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/glass_card.dart';

/// Duração guiada de cada passo do ritual (segundos).
const List<int> kDuracaoPassos = [30, 60, 45, 90, 120];

class RitualGuiadoScreen extends StatefulWidget {
  const RitualGuiadoScreen({super.key});

  @override
  State<RitualGuiadoScreen> createState() => _RitualGuiadoScreenState();
}

class _RitualGuiadoScreenState extends State<RitualGuiadoScreen>
    with SingleTickerProviderStateMixin {
  int _passo = 0;
  int _restante = kDuracaoPassos.first;
  bool _correndo = true;
  bool _terminado = false;
  int _rajada = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _arrancarTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _arrancarTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tique());
  }

  void _tique() {
    if (!mounted || !_correndo || _terminado) return;
    if (_restante > 1) {
      setState(() => _restante -= 1);
      // Últimos 3 segundos: o tique-tique do instrumento.
      if (_restante <= 3) AuraSfx.I.tick();
      return;
    }
    // Passo concluído pelo tempo.
    _concluirPasso();
  }

  void _concluirPasso() {
    final store = context.read<ProfileStore>();
    if (!_storeDone(store, _passo)) {
      AuraSfx.I.complete();
      store.toggleRitual(_passo);
    }
    if (_passo >= ProfileStore.kRitualSteps.length - 1) {
      // Fim da linha: o acorde inteiro + confetti.
      setState(() {
        _terminado = true;
        _rajada += 1;
      });
      AuraSfx.I.success();
      return;
    }
    setState(() {
      _passo += 1;
      _restante = kDuracaoPassos[_passo.clamp(0, kDuracaoPassos.length - 1)];
    });
    AuraSfx.I.chime();
  }

  bool _storeDone(ProfileStore store, int i) => store.ritualDone.contains(i);

  void _saltar() {
    AuraSfx.I.toggle();
    _concluirPasso();
  }

  void _anterior() {
    if (_passo == 0) return;
    AuraSfx.I.tap();
    setState(() {
      _passo -= 1;
      _restante = kDuracaoPassos[_passo];
      _terminado = false;
      _correndo = true;
    });
    _arrancarTimer();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final total = ProfileStore.kRitualSteps.length;
    final duracao = kDuracaoPassos[_passo.clamp(0, kDuracaoPassos.length - 1)];

    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: Stack(
        children: [
          SafeArea(
            child: _terminado
                ? _fimView(store, total)
                : _passoView(store, total, duracao),
          ),
          if (_rajada > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiBurst(key: ValueKey('confetti-$_rajada')),
              ),
            ),
        ],
      ),
    );
  }

  // ── Vista do passo ─────────────────────────────────────────────────────────
  Widget _passoView(ProfileStore store, int total, int duracao) {
    final step = ProfileStore.kRitualSteps[_passo];
    final proximo = _passo + 1 < total ? ProfileStore.kRitualSteps[_passo + 1] : null;
    final progresso = 1 - _restante / duracao;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          // Topo: fechar + indicador de passos.
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.cardFill,
                    border: Border.all(color: AuraColors.border),
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Text('RITUAL GUIADO', style: AuraType.eyebrow),
              const Spacer(),
              Text(
                '${_passo + 1} de $total',
                style: AuraType.caption.copyWith(
                  fontSize: 12,
                  color: AuraColors.mutedForeground,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Micro-barra de progresso do conjunto.
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 3,
              color: AuraColors.surface,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _passo / total,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AuraDecor.auraMetal,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          // O cronómetro — o instrumento central.
          GestureDetector(
            onTap: () {
              setState(() => _correndo = !_correndo);
              AuraSfx.I.tap();
            },
            child: SizedBox(
              width: 236,
              height: 236,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim(),
                    builder: (context, _) => CustomPaint(
                      size: const Size(236, 236),
                      painter: _TimerPainter(
                        progresso: progresso.clamp(0.0, 1.0),
                        correndo: _correndo,
                        t: _pulse.value,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_restante ~/ 60}:${(_restante % 60).toString().padLeft(2, '0')}',
                        style: AuraType.machinedNumber.copyWith(
                          fontSize: 52,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _correndo ? 'A CORRER' : 'EM PAUSA',
                        style: AuraType.eyebrow.copyWith(
                          fontSize: 8,
                          color: _correndo
                              ? AuraColors.primary
                              : AuraColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            step,
            style: AuraType.sectionTitle.copyWith(
              fontSize: 21,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _dicaDoPasso(_passo),
            style: AuraType.caption.copyWith(
              fontSize: 12.5,
              height: 1.5,
              color: AuraColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          // Próximo passo à vista.
          if (proximo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'A SEGUIR',
                    style: AuraType.eyebrow.copyWith(fontSize: 8),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      proximo,
                      style: AuraType.caption.copyWith(
                        fontSize: 11.5,
                        color: AuraColors.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // Controles.
          Row(
            children: [
              Expanded(
                child: _ControleButton(
                  icon: Icons.skip_previous,
                  label: 'Voltar',
                  onTap: _passo == 0 ? null : _anterior,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ControleButton(
                  icon: _correndo ? Icons.pause : Icons.play_arrow,
                  label: _correndo ? 'Pausar' : 'Retomar',
                  destaque: true,
                  onTap: () {
                    setState(() => _correndo = !_correndo);
                    AuraSfx.I.tap();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ControleButton(
                  icon: Icons.check,
                  label: 'Feito',
                  onTap: _saltar,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Vista final ────────────────────────────────────────────────────────────
  Widget _fimView(ProfileStore store, int total) {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AuraColors.cardFill,
                      border: Border.all(color: AuraColors.border),
                    ),
                    child: const Icon(Icons.close, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Text('RITUAL COMPLETA', style: AuraType.eyebrow),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AuraDecor.auraMetal,
              boxShadow: AuraDecor.glowShadow(alpha: 0.35),
            ),
            child: Icon(Icons.check, size: 44, color: AuraColors.onPrimary),
          ),
          const SizedBox(height: 22),
          Text(
            'Feito como mandas.',
            style: AuraType.sectionTitle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 10),
          Text(
            'Os $total passos de hoje ficaram marcados — streak '
            '${store.streak} dias. O ritual de amanhã renova-se ao acordar.',
            style: AuraType.caption.copyWith(height: 1.55, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: PlatinaButton(
              label: 'Concluir',
              icon: Icons.check,
              expanded: true,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // O pulso do anel (a mesma cadência em todo o app).
  AnimationController get _pulse => _pulseController;
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  Animation<double> _pulseAnim() => _pulseController;
}

class _ControleButton extends StatelessWidget {
  const _ControleButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destaque = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.35 : 1,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: destaque ? AuraDecor.auraMetal : null,
            color: destaque ? null : AuraColors.cardFill,
            border: Border.all(
              color: destaque ? Colors.transparent : AuraColors.border,
            ),
            boxShadow: destaque ? AuraDecor.glowShadow(alpha: 0.25) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: destaque
                    ? AuraColors.onPrimary
                    : AuraColors.foreground.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AuraType.body.copyWith(
                  fontSize: 13,
                  fontWeight: destaque ? FontWeight.w700 : FontWeight.w500,
                  color: destaque
                      ? AuraColors.onPrimary
                      : AuraColors.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Anel do cronómetro — trilho, arco de tempo, ticks e pulso vivo.
class _TimerPainter extends CustomPainter {
  _TimerPainter({
    required this.progresso,
    required this.correndo,
    required this.t,
  });

  final double progresso;
  final bool correndo;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 12;

    // Trilho.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = AuraColors.foreground.withValues(alpha: 0.08),
    );

    // Arco do tempo restante.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progresso,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..shader = AuraDecor.auraMetal.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );

    // Ticks usinados.
    final tick = Paint()..strokeWidth = 1;
    for (var i = 0; i < 60; i++) {
      final a = i * math.pi / 30;
      final dentro = i < (60 * progresso);
      tick.color = dentro
          ? AuraColors.primary.withValues(alpha: 0.45)
          : AuraColors.foreground.withValues(alpha: 0.08);
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * (radius - 14),
        center + Offset(math.cos(a), math.sin(a)) * (radius - 10),
        tick,
      );
    }

    // Pulso no bico do arco — vivo só quando corre.
    if (correndo) {
      final a = -math.pi / 2 + 2 * math.pi * progresso;
      final p = center + Offset(math.cos(a), math.sin(a)) * radius;
      final alpha = 0.18 + 0.14 * math.sin(t * 2 * math.pi);
      canvas.drawCircle(p, 7, Paint()..color = AuraColors.primary);
      canvas.drawCircle(
        p,
        14,
        Paint()..color = AuraColors.primary.withValues(alpha: alpha),
      );
    }
  }

  @override
  bool shouldRepaint(_TimerPainter old) =>
      old.progresso != progresso ||
      old.correndo != correndo ||
      old.t != t;
}

/// Dica concreta por passo — muda com o índice, nunca com a sorte.
String _dicaDoPasso(int passo) {
  return switch (passo) {
    0 => 'Um copo inteiro, sem pressa — a pele agradece antes de qualquer '
        'produto.',
    1 => 'Água tépida e movimentos circulares: 60 segundos bastam para '
        'limpar sem agredir.',
    2 => 'Cobre o rosto todo e o pescoço — o protetor solar esquece-se '
        'exatamente onde o sol chega.',
    3 => 'Do meio para as pontas no comprimento; no couro, toque leve.',
    4 => 'Três linhas chegam: como o dia foi, o que notaste, o que amanhã '
        'pode melhorar.',
    _ => '',
  };
}
