/// explore_screen.dart — Explorar: o Acervo do The Met (mesma rota /api/acervo
/// do web) + editorial de produtos. Grade 2 colunas com ritmo quebrado
/// (index%3==1 desce), cartões com tilt e ficha de museu em ecrã inteiro.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/api/acervo_api.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/widgets/tilt_card.dart';
import 'acervo_detail.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _theme = AcervoApi.themes.first;
  late Future<AcervoResult> _future;
  final Set<int> _saved = {};

  // Busca livre — 470 mil obras respondendo ao que o utilizador escreve.
  final TextEditingController _buscaCtrl = TextEditingController();
  String? _buscaAtiva;
  Future<AcervoResult>? _buscaFuture;

  @override
  void initState() {
    super.initState();
    _future = AcervoApi.I.fetchTheme(_theme);
  }

  @override
  void dispose() {
    _buscaCtrl.dispose();
    super.dispose();
  }

  void _switchTheme(String t) {
    if (t == _theme) return;
    AuraSfx.I.tap();
    setState(() {
      _theme = t;
      _buscaAtiva = null; // trocar de tema limpa a busca
    });
    _future = AcervoApi.I.fetchTheme(t);
  }

  void _buscar() {
    final q = _buscaCtrl.text.trim();
    if (q.length < 2) return;
    AuraSfx.I.send();
    setState(() => _buscaAtiva = q);
    _buscaFuture = AcervoApi.I.buscaTexto(q);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('EXPLORAR', style: AuraType.eyebrow),
                const SizedBox(height: 6),
                 Text(
                  'Acervo — galeria do Met',
                  style: AuraType.sectionTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Open Access · domínio público · 470 mil obras',
                  style: AuraType.caption,
                ),
                const SizedBox(height: 14),
                // ── Busca livre no acervo ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: AuraColors.cardFill,
                          border: Border.all(color: AuraColors.border),
                        ),
                        child: TextField(
                          controller: _buscaCtrl,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _buscar(),
                          style: AuraType.body.copyWith(fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Pesquisar no acervo… (ex: kimono)',
                            hintStyle: AuraType.caption.copyWith(fontSize: 12),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: AuraColors.mutedForeground,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _buscar,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AuraDecor.auraMetal,
                          boxShadow: AuraDecor.glowShadow(alpha: 0.24),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AuraColors.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Chips de tema (escondidos enquanto a busca está ativa) ────
        if (_buscaAtiva == null)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                children: [
                  for (final t in AcervoApi.themes)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ThemeChipLite(
                        label: AcervoApi.themeLabel[t] ?? t,
                        active: t == _theme,
                        onTap: () => _switchTheme(t),
                      ),
                    ),
                ],
              ),
            ),
          )
        else
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 4),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      AuraSfx.I.toggle();
                      setState(() => _buscaAtiva = null);
                    },
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: AuraDecor.auraMetal,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.close,
                              size: 13,
                              color: AuraColors.onPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '“$_buscaAtiva”',
                              style: AuraType.chip.copyWith(
                                color: AuraColors.onPrimary,
                                letterSpacing: 0.8,
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
          ),

        // ── Grade ──────────────────────────────────────────────────────────
        FutureBuilder<AcervoResult>(
          future: _buscaAtiva != null ? _buscaFuture : _future,
          builder: (context, snap) {
            if (!snap.hasData) {
              return _gridSkeleton();
            }
            final result = snap.data!;
            final items = result.items;
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 110),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fonte da galeria — viva, busca ou reserva.
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: MachinedChipLite(
                        result.source == 'reserva'
                            ? (_buscaAtiva != null
                                  ? 'Sem resultados vivos · reserva'
                                  : 'Reserva offline · acervo verificado')
                            : (_buscaAtiva != null
                                  ? 'Busca viva · “$_buscaAtiva” · Met'
                                  : 'Ao vivo · collectionAPI do Met'),
                      ),
                    ),
                    // 2 colunas com ritmo quebrado — index%3==1 desce e vira 3/4.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              for (var i = 0; i < items.length; i += 2)
                                _cell(items[i], i),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            children: [
                              for (var i = 1; i < items.length; i += 2)
                                _cell(items[i], i),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _cell(MetItem item, int index) {
    final tall = index % 3 == 1;
    return Padding(
      padding: EdgeInsets.only(bottom: 12, top: tall ? 18 : 0),
      child: TiltCard(
        child: GestureDetector(
          onTap: () => _openDetail(item),
          child: ClipRRect(
            borderRadius: AuraDecor.rounded,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: AuraDecor.rounded,
                border: Border.all(color: AuraColors.border),
                color: AuraColors.card,
                boxShadow: AuraDecor.cardShadow,
              ),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: tall ? 3 / 4 : 1 / 1.02,
                    child: CachedNetworkImage(
                      imageUrl: item.image,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 420),
                      httpHeaders: const {'User-Agent': 'AuraStyle/1.0'},
                      placeholder: (_, _) => const ShimmerBox(radius: 0),
                      errorWidget: (_, _, _) => Container(
                        color: AuraColors.muted,
                        child:  Icon(
                          Icons.image_outlined,
                          color: AuraColors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                  // Legenda em gradiente de observidana.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 26, 12, 11),
                      decoration: const BoxDecoration(
                        gradient: AuraDecor.imageScrim,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AuraType.cardTitle.copyWith(fontSize: 13),
                          ),
                          Text(
                            item.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AuraType.caption.copyWith(fontSize: 10.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(MetItem item) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        opaque: false,
        pageBuilder: (_, _, _) => AcervoDetailSheet(
          item: item,
          saved: _saved.contains(item.objectID),
          onToggleSave: () {
            setState(() {
              _saved.contains(item.objectID)
                  ? _saved.remove(item.objectID)
                  : _saved.add(item.objectID);
            });
          },
        ),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Skeletons ─────────────────────────────────────────────────────────────────

Widget _gridSkeleton() => SliverPadding(
  padding: const EdgeInsets.fromLTRB(22, 16, 22, 110),
  sliver: SliverToBoxAdapter(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              ShimmerBox(height: 230, radius: 20),
              const SizedBox(height: 12),
              ShimmerBox(height: 170, radius: 20),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            children: [
              ShimmerBox(height: 170, radius: 20),
              const SizedBox(height: 12),
              ShimmerBox(height: 230, radius: 20),
            ],
          ),
        ),
      ],
    ),
  ),
);

/// Chip de tema — versão local para não importar ciclo com core/widgets.
class ThemeChipLite extends StatelessWidget {
  const ThemeChipLite({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: active ? AuraDecor.auraMetal : null,
          color: active ? null : AuraColors.surface,
          border: Border.all(
            color: active ? Colors.transparent : AuraColors.border,
          ),
          boxShadow: active ? AuraDecor.glowShadow(alpha: 0.2) : null,
        ),
        child: Text(
          label,
          style: AuraType.chip.copyWith(
            color: active ? AuraColors.onPrimary : AuraColors.mutedForeground,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}

class MachinedChipLite extends StatelessWidget {
  const MachinedChipLite(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AuraColors.surface,
        border: Border.all(color: AuraColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Text(
          label.toUpperCase(),
          style: AuraType.chip.copyWith(
            fontSize: 9,
            color: AuraColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
