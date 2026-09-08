/// cortes_screen.dart — CORTES PARA O TEU ROSTO: o formato medido no Scan
/// define 4 direções de corte com objetivo claro e FOTOS REAIS do banco de
/// imagens (Pexels/Unsplash) para cada corte. Zero texto longo: o que se vê
/// ensina mais que o que se lê.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/api/image_bank.dart';
import '../../core/api/visual_api.dart';
import '../../core/data/cortes_data.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/widgets/stagger_in.dart';
import '../scan/scan_screen.dart';

class CortesScreen extends StatefulWidget {
  const CortesScreen({super.key});

  @override
  State<CortesScreen> createState() => _CortesScreenState();
}

class _CortesScreenState extends State<CortesScreen> {
  final Map<String, Future<VisualResult>> _fotos = {};
  final Map<String, Future<List<VideoItem>>> _videos = {};

  Future<VisualResult> _fotosDe(Corte c, String genero) {
    return _fotos.putIfAbsent(
      '${c.nome}::$genero',
      () => BancoImagens.I.buscar(c.consulta(genero), count: 3),
    );
  }

  /// Clipes REAIS do Pexels Videos para o corte — ver a tesoura a
  /// trabalhar vale mais que três fotos paradas.
  Future<List<VideoItem>> _videosDe(Corte c, String genero) {
    return _videos.putIfAbsent(
      '${c.nome}::$genero',
      () => BancoImagens.I.buscarVideos('${c.consulta(genero)} barbershop', count: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final forma = formaDoPerfil(store.profile.faceShape);
    final genero = store.profile.gender == 'feminino' ? 'feminino' : 'masculino';

    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: _topBar(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  forma == null ? _semForma() : _comForma(forma, genero),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Row(
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
          child: Icon(
            Icons.arrow_back,
            size: 18,
            color: AuraColors.foreground,
          ),
        ),
      ),
      const Spacer(),
      Text('CORTES & ROSTO', style: AuraType.eyebrow),
      const Spacer(),
      const SizedBox(width: 40),
    ],
  );

  List<Widget> _semForma() => [
    StaggerIn(
      index: 0,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Falta o formato do rosto',
              style: AuraType.sectionTitle,
            ),
            const SizedBox(height: 8),
            Text(
              'O Scan lê o teu formato e a lista de cortes nasce daí — '
              'cada corte com fotos reais para ver antes de sentar na cadeira.',
              style: AuraType.caption.copyWith(height: 1.5),
            ),
            const SizedBox(height: 14),
            PlatinaButton(
              label: 'Fazer scan',
              icon: Icons.center_focus_strong,
              expanded: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
            ),
          ],
        ),
      ),
    ),
    const SizedBox(height: 18),
    StaggerIn(
      index: 1,
      child: const SectionHeader(
        eyebrow: 'TODOS OS FORMATOS',
        title: 'Vê como funciona',
      ),
    ),
    const SizedBox(height: 12),
    for (final (i, f) in kFormas.indexed)
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: StaggerIn(
          index: i + 2,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AuraColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: AuraType.cardTitle.copyWith(
                        fontSize: 13,
                        color: AuraColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(f.nome, style: AuraType.cardTitle.copyWith(fontSize: 14)),
                      Text(
                        f.objetivo,
                        style: AuraType.caption.copyWith(fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
  ];

  List<Widget> _comForma(FormaRosto forma, String genero) {
    return [
      StaggerIn(
        index: 0,
        child: ClipRRect(
          borderRadius: AuraDecor.roundedLarge,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AuraDecor.auraMetal,
              borderRadius: AuraDecor.roundedLarge,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AuraDecor.radiusLarge - 2),
                color: AuraColors.backgroundDeep.withValues(alpha: 0.92),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('O TEU FORMATO', style: AuraType.eyebrow),
                          const SizedBox(height: 5),
                          Text(
                            forma.nome,
                            style: AuraType.sectionTitle.copyWith(fontSize: 22),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'objetivo: ${forma.objetivo}',
                            style: AuraType.caption.copyWith(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.face_retouching_natural,
                      size: 40,
                      color: AuraColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      for (final (i, corte) in forma.cortes.indexed) ...[
        StaggerIn(index: i + 1, child: _cartaoCorte(corte, genero)),
        const SizedBox(height: 14),
      ],
      StaggerIn(
        index: 9,
        child: Text(
          'Fotos e vídeos de referência do banco de imagens. Leva as que '
          'gostares ao barbeiro/cabeleireiro — mostrar vale mais que explicar.',
          style: AuraType.caption.copyWith(fontSize: 10.5, height: 1.5),
        ),
      ),
    ];
  }

  Widget _cartaoCorte(Corte corte, String genero) => GlassCard(
    padding: const EdgeInsets.all(0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 128,
          child: FutureBuilder<VisualResult>(
            future: _fotosDe(corte, genero),
            builder: (context, snap) {
              final items = snap.data?.items ?? const <VisualItem>[];
              if (items.isEmpty) return const ShimmerBox(radius: 0);
              return Row(
                children: [
                  for (final (i, item) in items.take(2).indexed) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: item.thumb,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const ShimmerBox(radius: 0),
                        errorWidget: (_, _, _) =>
                            Container(color: AuraColors.muted),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        // EM MOVIMENTO — clipes reais do corte (Pexels Videos).
        _VideoFaixa(videos: _videosDe(corte, genero)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 13, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(corte.nome, style: AuraType.cardTitle),
              const SizedBox(height: 5),
              Text(
                corte.porque,
                style: AuraType.caption.copyWith(
                  fontSize: 11.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.tune,
                    size: 13,
                    color: AuraColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      corte.dica,
                      style: AuraType.caption.copyWith(
                        fontSize: 10.5,
                        color: AuraColors.primary.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Faixa "EM MOVIMENTO" — clipes curtos do corte. Some completamente
/// quando não há vídeos (sem rede/chave): a ficha continua limpa.
class _VideoFaixa extends StatelessWidget {
  const _VideoFaixa({required this.videos});

  final Future<List<VideoItem>> videos;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<VideoItem>>(
      future: videos,
      builder: (context, snap) {
        final itens = snap.data ?? const <VideoItem>[];
        if (itens.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_circle_outline,
                    size: 13,
                    color: AuraColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text('EM MOVIMENTO', style: AuraType.eyebrow.copyWith(fontSize: 8)),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: itens.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final v = itens[i];
                    return GestureDetector(
                      onTap: () {
                        AuraSfx.I.tap();
                        _openVideo(context, v);
                      },
                      child: Container(
                        width: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AuraColors.border),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: v.thumb,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => const ShimmerBox(radius: 0),
                                errorWidget: (_, _, _) =>
                                    Container(color: AuraColors.muted),
                              ),
                              // Botão de play — disco de platina.
                              Center(
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AuraColors.backgroundDeep
                                        .withValues(alpha: 0.72),
                                    border: Border.all(
                                      color: AuraColors.primary,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    size: 20,
                                    color: AuraColors.primary,
                                  ),
                                ),
                              ),
                              // Duração no canto.
                              Positioned(
                                left: 5,
                                bottom: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    color: AuraColors.backgroundDeep
                                        .withValues(alpha: 0.78),
                                  ),
                                  child: Text(
                                    '${v.duracao}s',
                                    style: AuraType.chip.copyWith(fontSize: 8),
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
              ),
            ],
          ),
        );
      },
    );
  }

  void _openVideo(BuildContext context, VideoItem v) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => _VideoPlayerSheet(item: v),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(begin: 0.94, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Leitor em ecrã inteiro — loop silencioso, tap para pausar/retomar,
/// crédito do autor em baixo (regra da licença Pexels).
class _VideoPlayerSheet extends StatefulWidget {
  const _VideoPlayerSheet({required this.item});

  final VideoItem item;

  @override
  State<_VideoPlayerSheet> createState() => _VideoPlayerSheetState();
}

class _VideoPlayerSheetState extends State<_VideoPlayerSheet> {
  VideoPlayerController? _ctl;
  bool _pronto = false;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _arrancar();
  }

  Future<void> _arrancar() async {
    try {
      final ctl = VideoPlayerController.networkUrl(Uri.parse(widget.item.videoUrl));
      await ctl.initialize();
      await ctl.setLooping(true);
      await ctl.setVolume(0); // ambientes públicos — sem som surpresa
      await ctl.play();
      if (!mounted) {
        await ctl.dispose();
        return;
      }
      setState(() {
        _ctl = ctl;
        _pronto = true;
      });
    } catch (_) {
      if (mounted) setState(() => _erro = true);
    }
  }

  @override
  void dispose() {
    _ctl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _voltar,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 560, maxWidth: 340),
                  margin: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: BoxDecoration(
                    borderRadius: AuraDecor.roundedLarge,
                    border: Border.all(color: AuraColors.primary.withValues(alpha: 0.5)),
                    boxShadow: AuraDecor.glowShadow(alpha: 0.35),
                  ),
                  child: ClipRRect(
                    borderRadius: AuraDecor.roundedLarge,
                    child: AspectRatio(
                      aspectRatio: 9 / 14,
                      child: !_pronto
                          ? Container(
                              color: AuraColors.backgroundDeep,
                              child: Center(
                                child: _erro
                                    ? Icon(Icons.videocam_off_outlined,
                                        color: AuraColors.mutedForeground)
                                    : const ShimmerBox(radius: 0),
                              ),
                            )
                          : GestureDetector(
                              onTap: () async {
                                final ctl = _ctl!;
                                if (ctl.value.isPlaying) {
                                  await ctl.pause();
                                } else {
                                  await ctl.play();
                                }
                                if (mounted) setState(() {});
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.cover,
                                    child: SizedBox(
                                      width: _ctl!.value.size.width,
                                      height: _ctl!.value.size.height,
                                      child: VideoPlayer(_ctl!),
                                    ),
                                  ),
                                  if (!_ctl!.value.isPlaying)
                                    Center(
                                      child: Icon(
                                        Icons.pause_circle_outline,
                                        size: 46,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '${widget.item.autor} · Pexels',
                  style: AuraType.caption.copyWith(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _voltar() {
    AuraSfx.I.tap();
    Navigator.of(context).pop();
  }
}
