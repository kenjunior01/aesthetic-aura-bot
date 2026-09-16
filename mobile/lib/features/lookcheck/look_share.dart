/// look_share.dart — a NOTA DO LOOK que viaja: o veredito da Aura numa
/// imagem de estúdio que se partilha num toque. Mesma engenharia do
/// Aura Card: rota transparente, o cartão pinta FORA do ecrã, os frames
/// estabilizam, o RepaintBoundary fotografa a 3× e o PNG nasce no temp
/// e morre lá — nada de storage legado.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/api/lookcheck_api.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';

/// Ponto de entrada — partilha a LEITURA atual como imagem.
Future<void> partilharNotaLook(BuildContext context, LeituraLook leitura) async {
  final nome = context.read<ProfileStore>().profile.name.split(' ').first;
  AuraSfx.I.sparkle();
  await Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      pageBuilder: (_, _, _) =>
          _LookShareCapture(leitura: leitura, nome: nome),
      transitionsBuilder: (_, _, _, child) => child,
    ),
  );
}

class _LookShareCapture extends StatefulWidget {
  const _LookShareCapture({required this.leitura, required this.nome});

  final LeituraLook leitura;
  final String nome;

  @override
  State<_LookShareCapture> createState() => _LookShareCaptureState();
}

class _LookShareCaptureState extends State<_LookShareCapture> {
  final GlobalKey _boundary = GlobalKey();
  bool _trabalhando = true;

  @override
  void initState() {
    super.initState();
    // O cartão pinta fora do ecrã; 350ms para fonts/imagens assentarem.
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
        '${dir.path}/look-nota-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await ficheiro.writeAsBytes(bytes);

      final l = widget.leitura;
      final texto = 'A Aura deu ${l.nota}/100 ao meu look de hoje'
          ' — ${l.veredito.toLowerCase()}.'
          ' Evolução real, esculpida em platina 💎';

      if (!mounted) return;
      await Share.shareXFiles(
        [XFile(ficheiro.path, mimeType: 'image/png')],
        text:
            widget.nome.isEmpty ? texto : '$texto — ${widget.nome}',
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
          ? const Color(0xFF04060A).withValues(alpha: 0.72)
          : Colors.transparent,
      body: Stack(
        children: [
          // O CARTÃO — pintado a 10000px fora do ecrã, com pixels reais.
          Positioned(
            left: -10000,
            top: 0,
            child: RepaintBoundary(
              key: _boundary,
              child: LookNotaVisual(leitura: widget.leitura),
            ),
          ),
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFA2BBD2),
                          Color(0xFFC3E3FB),
                          Color(0xFFADCFEC),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFB8D9F3).withValues(alpha: 0.4),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2.4),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF04060A),
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
                  const Text(
                    'A REVELAR A NOTA',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: Color(0xFFEDF2FA),
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

/// O CARTÃO — 360×560, ficha de estúdio em platina sobre obsidiana.
/// Tokens fixos escuros: partilha-se igual no dia e na noite.
class LookNotaVisual extends StatelessWidget {
  const LookNotaVisual({super.key, required this.leitura});

  final LeituraLook leitura;

  @override
  Widget build(BuildContext context) {
    const fundo = Color(0xFF04060A);
    const platina = Color(0xFFB8D9F3);
    const mutado = Color(0xFF8E96A2);
    final l = leitura;

    return Container(
      width: 360,
      height: 560,
      decoration: const BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Stack(
        children: [
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho — marca.
                  const Row(
                    children: [
                      Icon(
                        Icons.checkroom_outlined,
                        size: 19,
                        color: platina,
                      ),
                      Spacer(),
                      Text(
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
                  const SizedBox(height: 22),
                  // A NOTA — o número herói.
                  Text(
                    'LOOK DO DIA',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.2,
                      color: mutado,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${l.nota}',
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 88,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          color: Color(0xFFEDF2FA),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 6, bottom: 12),
                        child: Text(
                          '/100',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: platina,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: platina.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      '${l.veredito.toUpperCase()} · '
                      '${l.fonte == 'groq' ? 'LEITURA IA' : 'LEITURA LOCAL'}',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: platina,
                      ),
                    ),
                  ),
                  // A frase da Aura.
                  if (l.mensagem.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      '“${l.mensagem}”',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12.5,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFC9D4E4),
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Os ajustes — os 3 conselhos do veredito.
                  if (l.ajustes.isNotEmpty) ...[
                    const Text(
                      'OS AJUSTES DE HOJE',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.2,
                        color: mutado,
                      ),
                    ),
                    const SizedBox(height: 9),
                    for (var i = 0; i < l.ajustes.length && i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFA2BBD2),
                                    Color(0xFFC3E3FB),
                                  ],
                                ),
                              ),
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: fundo,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${l.ajustes[i].area.toUpperCase()} — '
                                '${l.ajustes[i].texto}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10.5,
                                  height: 1.4,
                                  color: Color(0xFFC9D4E4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(color: Color(0x1AEDF2FA), height: 1),
                  const SizedBox(height: 9),
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
}
