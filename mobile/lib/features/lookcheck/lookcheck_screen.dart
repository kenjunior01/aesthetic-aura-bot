/// lookcheck_screen.dart — AVALIA O MEU LOOK: a foto do look vestido e a
/// Aura responde com nota honesta 0-100, o que já está a funcionar e 3
/// ajustes rápidos para hoje. Cada leitura paga XP e fica no histórico —
/// a nota de ontem é a referência para a de hoje.
///
/// Fases: escolher → a ler (feixe + ticker) → resultado (anel de nota).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/lookcheck_api.dart';
import '../../core/data/diario_store.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stagger_in.dart';
import '../home/home_cards.dart' show MachinedChipXP;

class LookCheckScreen extends StatefulWidget {
  const LookCheckScreen({super.key});

  @override
  State<LookCheckScreen> createState() => _LookCheckScreenState();
}

enum LookPhase { pick, scanning, done }

class _LookCheckScreenState extends State<LookCheckScreen>
    with SingleTickerProviderStateMixin {
  LookPhase _phase = LookPhase.pick;
  final List<String> _steps = const [
    'A enquadrar o look',
    'A ler cores e caimento',
    'A comparar com o teu perfil',
    'A afinar o veredito',
  ];
  int _step = 0;
  int _rajada = 0;
  XFile? _foto;
  String? _fotoB64;
  String? _mimeType;
  LeituraLook? _leitura;
  List<LeituraLook> _historico = const [];
  Timer? _ticker;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  static const _histKey = 'aurastyle-lookcheck-hist-v1';

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_histKey) ?? const [];
    final lista = <LeituraLook>[];
    for (final s in raw) {
      try {
        final m = jsonDecode(s);
        if (m is Map<String, dynamic>) lista.add(LeituraLook.fromJson(m));
      } catch (_) {
        // entrada corrompida → ignora
      }
    }
    if (mounted) setState(() => _historico = lista);
  }

  Future<void> _guardarNoHistorico(LeituraLook leitura) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_histKey) ?? <String>[];
    await prefs.setStringList(_histKey, [
      jsonEncode(leitura.toJson()),
      ...raw.take(7),
    ]);
  }

  /// Escolhe a fonte: câmara ao vivo (o espelho inteiro) ou galeria.
  Future<void> _pick() async {
    final fonte = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AuraColors.cardFill,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AuraColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Text(
                'DE ONDE VEM O LOOK?',
                style: AuraType.eyebrow.copyWith(fontSize: 10),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.photo_camera_outlined,
                color: AuraColors.primary,
              ),
              title: const Text('Tirar agora (câmara)'),
              subtitle: Text(
                'Look inteiro, do espelho aos sapatos',
                style: AuraType.caption.copyWith(fontSize: 11.5),
              ),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_outlined, color: AuraColors.primary),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (fonte == null || !mounted) return;
    try {
      final foto = await ImagePicker().pickImage(
        source: fonte,
        maxWidth: 1280,
        imageQuality: 86,
      );
      if (foto == null) return;
      AuraSfx.I.camera();
      setState(() {
        _foto = foto;
        _phase = LookPhase.scanning;
        _step = 0;
      });
      _ticker = Timer.periodic(const Duration(milliseconds: 760), (t) {
        if (t.tick >= _steps.length) {
          t.cancel();
          _analisar();
        } else if (mounted) {
          setState(() => _step = t.tick);
        }
      });
    } catch (_) {
      // picker indisponível → segue sem foto
    }
  }

  Future<void> _analisar() async {
    final store = context.read<ProfileStore>();
    LeituraLook? leitura;
    if (_foto != null) {
      final bytes = await File(_foto!.path).readAsBytes();
      _fotoB64 = base64Encode(bytes);
      final mime = _mimeType ?? 'image/jpeg';
      leitura = await LookCheckApi.I.avaliar(
        imageBase64: _fotoB64!,
        mimeType: mime,
        perfil: store.aiContext(),
      );
      // Miniatura para o histórico (nunca bloqueia a leitura).
      if (leitura != null) {
        try {
          leitura = LeituraLook(
            nota: leitura.nota,
            veredito: leitura.veredito,
            fonte: leitura.fonte,
            acertos: leitura.acertos,
            ajustes: leitura.ajustes,
            mensagem: leitura.mensagem,
            thumb: await DiarioStore.miniatura(_foto!),
          );
        } catch (_) {}
      }
    }
    if (!mounted) return;
    setState(() {
      _leitura = leitura;
      _phase = LookPhase.done;
    });
    if (leitura != null) {
      AuraSfx.I.success();
      await _guardarNoHistorico(leitura);
      await _carregarHistorico();
      store.addXp(35);
      if (leitura.nota >= 85) {
        setState(() => _rajada += 1);
        store.addXp(15); // bónus de look impecável
      }
      store.logEvent('lookcheck_done', {
        'nota': leitura.nota,
        'source': leitura.fonte,
      });
    } else {
      store.logEvent('lookcheck_fail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: Stack(
        children: [
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              child: switch (_phase) {
                LookPhase.pick => _pickView(),
                LookPhase.scanning => _scanningView(),
                LookPhase.done => _doneView(),
              },
            ),
          ),
          // Explosão de platina nos looks memoráveis (nota 85+).
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

  // ── 1 · Escolher ───────────────────────────────────────────────────────────
  Widget _pickView() {
    return ListView(
      key: const ValueKey('pick'),
      padding: const EdgeInsets.all(22),
      children: [
        _topBar('AVALIA O MEU LOOK'),
        const SizedBox(height: 26),
        Text(
          'Mostra o look.\nA Aura dá-lhe nota.',
          style: AuraType.sectionTitle.copyWith(fontSize: 26, height: 1.14),
        ),
        const SizedBox(height: 10),
        Text(
          'Look completo, do espelho aos sapatos, luz natural. A nota é '
          'honesta — e os 3 ajustes são para aplicar hoje, não um dia.',
          style: AuraType.caption.copyWith(height: 1.5),
        ),
        const SizedBox(height: 22),
        // Última nota — a referência a bater.
        if (_historico.isNotEmpty)
          _ultimaNotaCard(_historico.first)
        else
          Text(
            'A tua primeira nota é a linha de partida: daqui para a frente, '
            'mede-se o progresso do estilo em números.',
            style: AuraType.caption.copyWith(
              height: 1.5,
              fontSize: 12,
              color: AuraColors.mutedForeground,
            ),
          ),
        if (_historico.length >= 2) ...[
          const SizedBox(height: 14),
          _histResumoCard(),
        ],
        const SizedBox(height: 22),
        Center(
          child: GestureDetector(
            onTap: _pick,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 1.04).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 168,
                height: 168,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AuraColors.primary.withValues(alpha: 0.4),
                  ),
                  boxShadow: AuraDecor.glowShadow(alpha: 0.25),
                ),
                padding: const EdgeInsets.all(10),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.cardFill,
                  ),
                  child: Icon(
                    Icons.checkroom_outlined,
                    size: 44,
                    color: AuraColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: PlatinaButton(
            label: 'Escolher da galeria',
            icon: Icons.photo_outlined,
            onTap: _pick,
            expanded: true,
          ),
        ),
      ],
    );
  }

  Widget _ultimaNotaCard(LeituraLook ultima) {
    return GlassCard(
      child: Row(
        children: [
          Text(
            '${ultima.nota}',
            style: AuraType.machinedNumber.copyWith(
              fontSize: 34,
              height: 1,
              color: AuraColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ÚLTIMA NOTA', style: AuraType.eyebrow),
                const SizedBox(height: 3),
                Text(
                  '${ultima.veredito} · ${ultima.fonte == 'groq' ? 'IA' : 'local'}',
                  style: AuraType.caption.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _histResumoCard() {
    // Progresso real: última nota vs. média das anteriores.
    final notas = [for (final h in _historico) h.nota];
    final ultima = notas.first;
    final anteriores = notas.skip(1).toList();
    final media = anteriores.reduce((a, b) => a + b) / anteriores.length;
    final delta = (ultima - media).round();
    return GlassCard(
      child: Row(
        children: [
          Icon(
            delta >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 18,
            color: AuraColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              delta >= 0
                  ? '$delta pontos acima da tua média de ${anteriores.length} '
                      'leitura${anteriores.length == 1 ? '' : 's'} — o estilo '
                      'está a subir.'
                  : '${delta.abs()} pontos abaixo da tua média — dia para '
                      'aplicar os ajustes.',
              style: AuraType.caption.copyWith(height: 1.5, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2 · A ler ──────────────────────────────────────────────────────────────
  Widget _scanningView() {
    return Padding(
      key: const ValueKey('scanning'),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: _topBar('A LER O LOOK')),
          const Spacer(),
          SizedBox(
            width: 190,
            height: 190,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: _NotaRingPainter(_pulse.value, _step / _steps.length),
              ),
            ),
          ),
          const SizedBox(height: 30),
          for (var i = 0; i < _steps.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    i < _step
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 15,
                    color: i < _step
                        ? AuraColors.primary
                        : AuraColors.mutedForeground,
                  ),
                  const SizedBox(width: 9),
                  Text(
                    _steps[i],
                    style: AuraType.body.copyWith(
                      fontSize: 13,
                      color: i < _step
                          ? AuraColors.foreground
                          : AuraColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── 3 · Resultado ──────────────────────────────────────────────────────────
  Widget _doneView() {
    final leitura = _leitura;
    if (leitura == null) {
      return _falhaView();
    }
    return ListView(
      key: const ValueKey('done'),
      padding: const EdgeInsets.all(22),
      children: [
        _topBar('VEREDITO'),
        const SizedBox(height: 22),
        // O anel da nota — o instrumento central.
        StaggerIn(
          index: 0,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: leitura.nota / 100),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOutCubic,
              builder: (context, valor, _) => SizedBox(
                width: 172,
                height: 172,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(172, 172),
                      painter: _NotaFinalPainter(valor),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(valor * 100).round()}',
                          style: AuraType.machinedNumber.copyWith(
                            fontSize: 46,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          leitura.veredito.toUpperCase(),
                          style: AuraType.eyebrow.copyWith(fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MachinedChipXP(leitura.fonte == 'groq' ? 'IA' : 'LEITURA LOCAL'),
            const SizedBox(width: 8),
            const MachinedChipXP('+35 XP'),
          ],
        ),
        if (leitura.mensagem.isNotEmpty) ...[
          const SizedBox(height: 18),
          StaggerIn(
            index: 1,
            child: Text(
              '“${leitura.mensagem}”',
              style: AuraType.body.copyWith(
                fontSize: 14.5,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: AuraColors.foreground.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Acertos.
        if (leitura.acertos.isNotEmpty)
          StaggerIn(
            index: 2,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('O QUE JÁ FUNCIONA', style: AuraType.eyebrow),
                  const SizedBox(height: 10),
                  for (final acerto in leitura.acertos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: AuraColors.primary,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              acerto,
                              style: AuraType.caption.copyWith(
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),
        // Os 3 ajustes.
        StaggerIn(
          index: 3,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('3 AJUSTES PARA HOJE', style: AuraType.eyebrow),
                const SizedBox(height: 10),
                for (var i = 0; i < leitura.ajustes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: AuraDecor.auraMetal,
                          ),
                          child: Text(
                            '${i + 1}',
                            style: AuraType.chip.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AuraColors.onPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                leitura.ajustes[i].area.toUpperCase(),
                                style: AuraType.eyebrow.copyWith(fontSize: 8),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                leitura.ajustes[i].texto,
                                style: AuraType.caption.copyWith(
                                  fontSize: 12.5,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        StaggerIn(
          index: 4,
          child: Row(
            children: [
              Expanded(
                child: PlatinaButton(
                  label: 'Novo look',
                  icon: Icons.add_a_photo_outlined,
                  onTap: () => setState(() {
                    _foto = null;
                    _fotoB64 = null;
                    _leitura = null;
                    _phase = LookPhase.pick;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PlatinaButton(
                  label: 'Concluir',
                  icon: Icons.check,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _falhaView() {
    return ListView(
      key: const ValueKey('falha'),
      padding: const EdgeInsets.all(22),
      children: [
        _topBar('SEM LEITURA'),
        const SizedBox(height: 26),
        GlassCard(
          child: Column(
            children: [
              Icon(
                Icons.photo_size_select_actual_outlined,
                size: 34,
                color: AuraColors.mutedForeground,
              ),
              const SizedBox(height: 12),
              Text(
                'A foto não chegou à leitura.',
                style: AuraType.cardTitle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(
                'Tenta outra vez com luz natural e o look completo na foto.',
                style: AuraType.caption.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: PlatinaButton(
            label: 'Tentar outra vez',
            icon: Icons.refresh,
            expanded: true,
            onTap: () => setState(() {
              _foto = null;
              _fotoB64 = null;
              _leitura = null;
              _phase = LookPhase.pick;
            }),
          ),
        ),
      ],
    );
  }

  Widget _topBar(String eyebrow) => Row(
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
          Text(eyebrow, style: AuraType.eyebrow),
        ],
      );
}

/// Anel da fase de leitura — feixe rotativo + arco de progresso.
class _NotaRingPainter extends CustomPainter {
  _NotaRingPainter(this.t, this.progress);

  final double t;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 10;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AuraColors.foreground.withValues(alpha: 0.1),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..shader = AuraDecor.auraMetal.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );

    final beamAngle = t * 2 * math.pi;
    final p = center + Offset(math.cos(beamAngle), math.sin(beamAngle)) * radius;
    canvas.drawCircle(p, 4, Paint()..color = AuraColors.primary);
    canvas.drawCircle(
      p,
      9,
      Paint()..color = AuraColors.primary.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(_NotaRingPainter old) => old.t != t || old.progress != progress;
}

/// Anel final da nota — trilho + arco metal + ticks usinados.
class _NotaFinalPainter extends CustomPainter {
  _NotaFinalPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 10;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..color = AuraColors.foreground.withValues(alpha: 0.08),
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..shader = AuraDecor.auraMetal.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );

    final tick = Paint()
      ..strokeWidth = 1
      ..color = AuraColors.foreground.withValues(alpha: 0.12);
    for (var i = 0; i < 36; i++) {
      final a = i * math.pi / 18;
      final dentro = i < (36 * progress);
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * (radius - 13),
        center + Offset(math.cos(a), math.sin(a)) * (radius - 10),
        tick..color = dentro
            ? AuraColors.primary.withValues(alpha: 0.5)
            : AuraColors.foreground.withValues(alpha: 0.1),
      );
    }
  }

  @override
  bool shouldRepaint(_NotaFinalPainter old) => old.progress != progress;
}
