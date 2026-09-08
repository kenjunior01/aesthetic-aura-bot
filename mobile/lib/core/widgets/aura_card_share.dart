/// aura_card_share.dart — o AURA CARD: a tua presença resumida numa
/// imagem que se partilha. Nível, XP, streak e a posição na Jornada do
/// Auge, compostos como uma ficha de estúdio em platina.
///
/// Fluxo: a rota transparente renderiza o cartão FORA do ecrã (mas
/// pintado — RepaintBoundary só captura o que foi pintado), espera os
/// frames estabilizarem, fotografa a 3× e entrega o PNG ao share sheet
/// do sistema. Sem storage legado: o ficheiro nasce no temp e morre lá.
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/jornada_store.dart';
import '../sfx/aura_sfx.dart';
import '../store/profile_store.dart';
import '../theme/aura_colors.dart';
import '../theme/aura_decorations.dart';
import '../theme/aura_typography.dart';

/// Ponto de entrada — partilha o card com o estado ATUAL do utilizador.
Future<void> partilharAuraCard(BuildContext context) async {
  final store = context.read<ProfileStore>();
  final jStore = context.read<JornadaStore>();
  AuraSfx.I.sparkle();
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) => _AuraCardCapture(store: store, jStore: jStore),
      transitionsBuilder: (_, _, _, child) => child,
    ),
  );
}

class _AuraCardCapture extends StatefulWidget {
  const _AuraCardCapture({required this.store, required this.jStore});

  final ProfileStore store;
  final JornadaStore jStore;

  @override
  State<_AuraCardCapture> createState() => _AuraCardCaptureState();
}

class _AuraCardCaptureState extends State<_AuraCardCapture> {
  final GlobalKey _boundary = GlobalKey();
  bool _trabalhando = true;

  @override
  void initState() {
    super.initState();
    // Pinta o cartão fora do ecrã, espera 2 frames (fonts/imagens) e fotografa.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 350), _capturarEPartilhar);
    });
  }

  Future<void> _capturarEPartilhar() async {
    try {
      final boundary =
          _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return _fechar();
      final ui.Image imagem = await boundary.toImage(pixelRatio: 3.0);
      final bytes = (await imagem.toByteData(format: ui.ImageByteFormat.png))
          ?.buffer
          .asUint8List();
      if (bytes == null) return _fechar();

      final dir = await getTemporaryDirectory();
      final ficheiro = File(
        '${dir.path}/aura-card-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await ficheiro.writeAsBytes(bytes);

      final nome = widget.store.profile.name.split(' ').first;
      final texto = widget.jStore.jornada == null
          ? 'A minha aura no nível ${widget.store.level} — '
              'esculpida em platina no AuraStyle 💎'
          : 'Nível ${widget.store.level} · semana '
              '${widget.jStore.semanaAtual} da minha Jornada do Auge — '
              'evolução real, esculpida em platina 💎';

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(ficheiro.path, mimeType: 'image/png')],
        text: nome.isEmpty ? texto : '$texto — $nome',
      );
      _fechar();
    } catch (_) {
      _fechar();
    }
  }

  void _fechar() {
    if (!mounted) return;
    setState(() => _trabalhando = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _trabalhando
          ? AuraColors.backgroundDeep.withValues(alpha: 0.72)
          : Colors.transparent,
      body: Stack(
        children: [
          // O CARTÃO — pintado a 10000px fora do ecrã (nunca visível,
          // mas o RepaintBoundary tem pixels reais para fotografar).
          Positioned(
            left: -10000,
            top: 0,
            child: RepaintBoundary(
              key: _boundary,
              child: AuraCardVisual(store: widget.store, jStore: widget.jStore),
            ),
          ),
          // Cortina de espera.
          Center(
            child: AnimatedOpacity(
              opacity: _trabalhando ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AuraDecor.auraMetal,
                      boxShadow: AuraDecor.glowShadow(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.all(2.4),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.backgroundDeep,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFB8D9F3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'A REVELAR O TEU CARD',
                    style: AuraType.eyebrow.copyWith(
                      fontSize: 9,
                      color: AuraColors.foreground,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// O CARTÃO em si — 360×560, ficha de estúdio em platina sobre observidana.
/// Decorado só com tokens fixos escuros: partilha-se igual no dia e na noite.
class AuraCardVisual extends StatelessWidget {
  const AuraCardVisual({super.key, required this.store, required this.jStore});

  final ProfileStore store;
  final JornadaStore jStore;

  @override
  Widget build(BuildContext context) {
    const fundo = Color(0xFF04060A);
    const platina = Color(0xFFB8D9F3);
    const mutado = Color(0xFF8E96A2);
    final j = jStore.jornada;

    return Container(
      width: 360,
      height: 560,
      decoration: const BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Halos aurora decorativos.
          Positioned(
            right: -70,
            top: -60,
            child: _halo(190, const Color(0x33B8D9F3)),
          ),
          Positioned(
            left: -90,
            bottom: -80,
            child: _halo(230, const Color(0x249FCAEE)),
          ),
          // Moldura metálica.
          Container(
            margin: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFA2BBD2),
                  Color(0xFFC3E3FB),
                  Color(0xFFADCFEC),
                  Color(0xFFCDE9FD),
                  Color(0xFFA4C2DC),
                ],
              ),
            ),
            padding: const EdgeInsets.all(1.6),
            child: Container(
              decoration: BoxDecoration(
                color: fundo,
                borderRadius: BorderRadius.circular(21),
              ),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho — marca + anel.
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFA2BBD2),
                              Color(0xFFC3E3FB),
                              Color(0xFFADCFEC),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: fundo,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 19,
                            color: platina,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'AURA STYLE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 5.2,
                          color: platina,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  // Nível — o número herói.
                  Text(
                    'NÍVEL ${store.level}',
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                      color: Color(0xFFEDF2FA),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    nivelTitulo(store.level).toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.4,
                      color: platina,
                    ),
                  ),
                  const SizedBox(height: 22),
                  // Barra de nível do XP.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 5,
                      color: const Color(0x1AEDF2FA),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: math.max(0.04, store.levelProgress),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFA2BBD2),
                                Color(0xFFC3E3FB),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${store.xp} XP acumulado',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 10.5,
                      color: mutado,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats — streak e fases.
                  Row(
                    children: [
                      _stat('STREAK', '${store.streak} dias', platina, mutado),
                      const SizedBox(width: 22),
                      _stat(
                        'JORNADA',
                        j == null ? 'a traçar' : 'semana ${jStore.semanaAtual}',
                        platina,
                        mutado,
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Barra de chegada ao auge — cores fixas (o card partilha
                  // igual no dia e na noite, sem depender do modo vivo).
                  if (j != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 7,
                        color: const Color(0x1AEDF2FA),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: math.max(0.03, jStore.progresso),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFA2BBD2),
                                  Color(0xFFCDE9FD),
                                ],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x47B8D9F3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Text(
                          jStore.faseAtual?.nome ?? 'a caminho do auge',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: platina,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'de ${j.totalSemanas} semanas',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            color: mutado,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      'A rota até o auge começa no próximo scan.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        color: mutado,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  const Divider(color: Color(0x1AEDF2FA), height: 1),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 13,
                        color: platina,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'evolução real · esculpida em platina',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: mutado,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _halo(double size, Color cor) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [cor, cor.withValues(alpha: 0)],
      ),
    ),
  );

  Widget _stat(String label, String valor, Color cor, Color mutado) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 2.4,
          color: mutado,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        valor,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: cor,
        ),
      ),
    ],
  );
}
