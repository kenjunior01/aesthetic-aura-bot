/// scan_screen.dart — o ritual do Scan: escolhe a foto, o feixe varre o
/// anel de confiança em 4 etapas, e a leitura dos traços entra trait-a-trait.
/// Usa /api/analyze-selfie (a MESMA IA do web); offline, devolve leitura
/// local honesta.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/aura_api.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stagger_in.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

enum ScanPhase { pick, scanning, done }

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  ScanPhase _phase = ScanPhase.pick;
  final List<String> _steps = const [
    'A enquadrar o rosto',
    'A ler tom de pele',
    'A medir traços',
    'A afinar a aura',
  ];
  int _step = 0;
  XFile? _photo;
  Map<String, dynamic>? _reading;
  Timer? _ticker;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 86,
      );
      if (photo == null) return;
      setState(() {
        _photo = photo;
        _phase = ScanPhase.scanning;
        _step = 0;
      });
      _ticker = Timer.periodic(const Duration(milliseconds: 780), (t) {
        if (t.tick >= _steps.length) {
          t.cancel();
          _analyze();
        } else if (mounted) {
          setState(() => _step = t.tick);
        }
      });
    } catch (_) {
      // picker indisponível → segue sem foto
    }
  }

  Future<void> _analyze() async {
    final store = context.read<ProfileStore>();
    Map<String, dynamic>? reading;
    if (_photo != null) {
      final bytes = await File(_photo!.path).readAsBytes();
      reading = await AuraApi.I.analyzeSelfie(base64Encode(bytes));
    }
    if (!mounted) return;
    setState(() {
      _reading = reading;
      _phase = ScanPhase.done;
    });
    store.logEvent('scan_complete', {
      'hasPhoto': _photo != null,
      'source': reading != null ? 'ai' : 'local',
    });
    store.addXp(40);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          child: switch (_phase) {
            ScanPhase.pick => _pickView(),
            ScanPhase.scanning => _scanningView(),
            ScanPhase.done => _doneView(),
          },
        ),
      ),
    );
  }

  // ── 1 · Escolher ────────────────────────────────────────────────────────────
  Widget _pickView() => Padding(
    key: const ValueKey('pick'),
    padding: const EdgeInsets.all(22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _topBar('SCAN DE AURA'),
        const SizedBox(height: 26),
        Text(
          'Uma foto sem filtros,\npor favor.',
          style: AuraType.sectionTitle.copyWith(fontSize: 26, height: 1.14),
        ),
        const SizedBox(height: 10),
        Text(
          'Rosto de frente, luz natural, sem filtros nem óculos escuros. '
          'A leitura corre no teu backend — a foto não fica guardada sem a tua conta.',
          style: AuraType.caption.copyWith(height: 1.5),
        ),
        const Spacer(),
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
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    size: 44,
                    color: AuraColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
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
    ),
  );

  // ── 2 · A varrer ────────────────────────────────────────────────────────────
  Widget _scanningView() {
    return Padding(
      key: const ValueKey('scanning'),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: _topBar('A LER')),
          const Spacer(),
          // Anel de confiança com feixe.
          SizedBox(
            width: 190,
            height: 190,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => CustomPaint(
                painter: _ScanRingPainter(_pulse.value, _step / _steps.length),
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

  // ── 3 · Leitura ─────────────────────────────────────────────────────────────
  Widget _doneView() {
    final store = context.watch<ProfileStore>();
    final r = _reading;
    return ListView(
      key: const ValueKey('done'),
      padding: const EdgeInsets.all(22),
      children: [
        _topBar('LEITURA COMPLETA'),
        const SizedBox(height: 22),
        StaggerIn(
          index: 0,
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 18,
                      color: AuraColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text('Aura lida', style: AuraType.cardTitle),
                    const Spacer(),
                    Text(
                      r != null ? 'IA' : 'local',
                      style: AuraType.chip.copyWith(fontSize: 9),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (r != null) ..._aiReadings(r) else ..._localReadings(store),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        StaggerIn(
          index: 1,
          child: SizedBox(
            width: double.infinity,
            child: PlatinaButton(
              label: 'Concluir',
              icon: Icons.check,
              expanded: true,
              onTap: () {
                store.updateProfile(
                  (p) => p.copyWith(
                    selfie: _photo != null
                        ? base64Encode(File(_photo!.path).readAsBytesSync())
                        : null,
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _aiReadings(Map<String, dynamic> r) {
    final entries = <(String, String)>[
      ('FORMATO DO ROSTO', '${r['faceShape'] ?? r['face_shape'] ?? '—'}'),
      ('TOM DE PELE', '${r['skinTone'] ?? r['skin_tone'] ?? '—'}'),
      ('SUBTOM', '${r['undertone'] ?? '—'}'),
      ('CABELO', '${r['hairType'] ?? r['hair_type'] ?? '—'}'),
      ('OLHOS', '${r['eyeColor'] ?? r['eye_color'] ?? '—'}'),
    ];
    return [
      for (final (label, value) in entries) _readingRow(label, value),
      if (r['notes'] != null) ...[
        const SizedBox(height: 8),
        Text('${r['notes']}', style: AuraType.caption.copyWith(height: 1.5)),
      ],
    ];
  }

  List<Widget> _localReadings(ProfileStore store) {
    final p = store.profile;
    return [
      _readingRow(
        'FORMATO DO ROSTO',
        p.faceShape.isEmpty ? 'por definir' : p.faceShape,
      ),
      _readingRow(
        'TOM DE PELE',
        p.skinTone > 0 ? '${p.skinTone}/10' : 'por definir',
      ),
      _readingRow('SUBTOM', p.undertone.isEmpty ? 'por definir' : p.undertone),
      _readingRow('CABELO', p.hairType.isEmpty ? 'por definir' : p.hairType),
      const SizedBox(height: 8),
      Text(
        'Sem ligação à IA — a leitura local usa o teu perfil. '
        'Liga o backend no Perfil para a análise completa.',
        style: AuraType.caption.copyWith(height: 1.5),
      ),
    ];
  }

  Widget _readingRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Text(label, style: AuraType.eyebrow.copyWith(fontSize: 8.5)),
        const Spacer(),
        Text(value, style: AuraType.body.copyWith(fontSize: 13)),
      ],
    ),
  );

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

/// Anel de confiança — feixe platina a varrer + arco de progresso + ticks.
class _ScanRingPainter extends CustomPainter {
  _ScanRingPainter(this.t, this.progress);

  final double t; // 0..1 contínuo (rotação do feixe)
  final double progress; // 0..1 por etapas

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 10;

    // Trilho.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = AuraColors.foreground.withValues(alpha: 0.1),
    );

    // Arco de progresso.
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

    // Feixe rotativo com rastro.
    final beamAngle = t * 2 * math.pi;
    final trail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius
      ..shader = SweepGradient(
        startAngle: beamAngle - math.pi / 2,
        endAngle: beamAngle,
        colors: [
          AuraColors.primary.withValues(alpha: 0),
          AuraColors.primary.withValues(alpha: 0.16),
        ],
        tileMode: TileMode.repeated,
      ).createShader(Offset.zero & size);
    canvas.drawCircle(center, radius / 2, trail);

    // Ponto do feixe.
    final p =
        center + Offset(math.cos(beamAngle), math.sin(beamAngle)) * radius;
    canvas.drawCircle(p, 4, Paint()..color = AuraColors.primary);
    canvas.drawCircle(
      p,
      9,
      Paint()..color = AuraColors.primary.withValues(alpha: 0.25),
    );

    // Ticks internos.
    final tick = Paint()
      ..strokeWidth = 1
      ..color = AuraColors.foreground.withValues(alpha: 0.1);
    for (var i = 0; i < 24; i++) {
      final a = i * math.pi / 12;
      canvas.drawLine(
        center + Offset(math.cos(a), math.sin(a)) * (radius - 22),
        center + Offset(math.cos(a), math.sin(a)) * (radius - 18),
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(_ScanRingPainter old) =>
      old.t != t || old.progress != progress;
}
