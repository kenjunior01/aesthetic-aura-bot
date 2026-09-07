/// antes_depois.dart — ANTES & AGORA: o comparador deslizante da evolução.
///
///  • A fotografia mais antiga e a mais recente do diário, costuradas na
///    mesma moldura — arrasta o fio de platina e vês a tua estrada.
///  • A abertura é cinematográfica: o fio varre o retrato e assenta a meio.
///  • Abaixo, as leituras que mudaram entre os dois scans (tom, rosto,
///    cabelo) — a evolução medida, não prometida.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/data/diario_store.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';

class AntesDepoisCard extends StatefulWidget {
  const AntesDepoisCard({super.key, required this.entradas});

  /// Linha do tempo em ordem descrescente (mais recente primeiro).
  final List<EntradaDiario> entradas;

  @override
  State<AntesDepoisCard> createState() => _AntesDepoisCardState();
}

class _AntesDepoisCardState extends State<AntesDepoisCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _varredura;
  double _split = 0.14;
  bool _arrastou = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _varredura = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.addListener(() {
      if (!_arrastou && mounted) {
        setState(() => _split = 0.14 + (0.5 - 0.14) * _varredura.value);
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _mover(Offset local, double largura) {
    setState(() {
      _arrastou = true;
      _split = (local.dx / largura).clamp(0.08, 0.92);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mais recente com foto vs mais antiga com foto.
    EntradaDiario? agora;
    EntradaDiario? antes;
    for (final e in widget.entradas) {
      if (e.thumb == null) continue;
      agora ??= e;
      antes = e;
    }
    if (agora == null || antes == null || identical(agora, antes)) {
      return const SizedBox.shrink();
    }

    final dias = _diasEntre(antes.data, agora.data);
    final leituras = _leiturasDiferentes(antes, agora);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.compare_outlined,
                size: 15,
                color: AuraColors.primary,
              ),
              const SizedBox(width: 7),
              Text('ANTES & AGORA', style: AuraType.eyebrow),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: AuraColors.primary.withValues(alpha: 0.12),
                ),
                child: Text(
                  dias == 1 ? '1 dia' : '$dias dias',
                  style: AuraType.chip.copyWith(
                    fontSize: 9.5,
                    color: AuraColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // O comparador — arrasta o fio.
          LayoutBuilder(
            builder: (context, box) {
              final largura = box.maxWidth;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (d) =>
                    _mover(d.localPosition, largura),
                onHorizontalDragEnd: (_) => AuraSfx.I.tap(),
                onTapDown: (d) => _mover(d.localPosition, largura),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 216,
                    width: largura,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Base — o ANTES (mais antigo).
                        Image.memory(
                          base64Decode(antes!.thumb!),
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                        // Máscara — o AGORA (mais recente) até ao fio.
                        ClipRect(
                          clipper: _FioClipper(_split),
                          child: Image.memory(
                            base64Decode(agora!.thumb!),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                        // Etiquetas.
                        Positioned(
                          top: 10,
                          left: 10,
                          child: _etiqueta(
                            'ANTES · ${_dataCurta(antes.data)}',
                            base: true,
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: _etiqueta(
                            'AGORA · ${_dataCurta(agora.data)}',
                          ),
                        ),
                        // O fio de platina + pega.
                        Positioned(
                          left: largura * _split - 1,
                          top: 28,
                          bottom: 28,
                          width: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(alpha: 0.92),
                                  Colors.white.withValues(alpha: 0.92),
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: largura * _split - 17,
                          top: 216 / 2 - 17,
                          width: 34,
                          height: 34,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.96),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chevron_left,
                                  size: 16,
                                  color: Colors.black87,
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 16,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Leituras que mudaram entre os dois scans.
          if (leituras.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AuraColors.border),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final l in leituras) _chipLeitura(l),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              'as leituras continuam fiéis — a estrada é longa, continua',
              style: AuraType.caption.copyWith(fontSize: 10.5),
            ),
          ],
        ],
      ),
    );
  }

  Widget _etiqueta(String texto, {bool base = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        texto,
        style: AuraType.chip.copyWith(
          fontSize: 8.5,
          letterSpacing: 1.1,
          color: base ? Colors.white70 : AuraColors.primary,
        ),
      ),
    );
  }

  Widget _chipLeitura((String, String) l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AuraColors.primary.withValues(alpha: 0.12),
      ),
      child: Text(
        '${l.$1} ${l.$2}',
        style: AuraType.chip.copyWith(
          fontSize: 9.5,
          letterSpacing: 0.5,
          color: AuraColors.primary,
        ),
      ),
    );
  }

  /// Leituras com diferença entre o antes e o agora.
  List<(String, String)> _leiturasDiferentes(
    EntradaDiario antes,
    EntradaDiario agora,
  ) {
    final out = <(String, String)>[];
    if (antes.skinTone > 0 && agora.skinTone > 0) {
      final d = agora.skinTone - antes.skinTone;
      if (d != 0) out.add(('TOM', d > 0 ? '+$d' : '$d'));
    }
    if (antes.faceShape.isNotEmpty &&
        agora.faceShape.isNotEmpty &&
        !_mesmoRosto(antes.faceShape, agora.faceShape)) {
      out.add(('ROSTO', agora.faceShape));
    }
    if (antes.hairColor.isNotEmpty &&
        agora.hairColor.isNotEmpty &&
        antes.hairColor.toLowerCase() != agora.hairColor.toLowerCase()) {
      out.add(('CABELO', agora.hairColor));
    }
    if (antes.undertone.isNotEmpty &&
        agora.undertone.isNotEmpty &&
        antes.undertone.toLowerCase() != agora.undertone.toLowerCase()) {
      out.add(('SUBTOM', agora.undertone));
    }
    return out;
  }

  bool _mesmoRosto(String a, String b) =>
      a.toLowerCase().trim() == b.toLowerCase().trim();

  int _diasEntre(String isoA, String isoB) {
    final a = DateTime.tryParse(isoA);
    final b = DateTime.tryParse(isoB);
    if (a == null || b == null) return 0;
    return b.difference(a).inDays.abs();
  }

  String _dataCurta(String iso) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    final p = iso.split('-');
    if (p.length < 3) return iso;
    return '${p[2]} ${meses[(int.tryParse(p[1]) ?? 1) - 1]}';
  }
}

/// Corta a imagem do AGORA até à posição do fio.
class _FioClipper extends CustomClipper<Rect> {
  const _FioClipper(this.fracao);
  final double fracao;
  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fracao, size.height);
  @override
  bool shouldReclip(_FioClipper old) => old.fracao != fracao;
}
