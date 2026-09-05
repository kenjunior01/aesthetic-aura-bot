/// cortes_screen.dart — CORTES PARA O TEU ROSTO: o formato medido no Scan
/// define 4 direções de corte com objetivo claro e FOTOS REAIS do banco de
/// imagens (Pexels/Unsplash) para cada corte. Zero texto longo: o que se vê
/// ensina mais que o que se lê.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/image_bank.dart';
import '../../core/api/visual_api.dart';
import '../../core/data/cortes_data.dart';
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

  Future<VisualResult> _fotosDe(Corte c, String genero) {
    return _fotos.putIfAbsent(
      '${c.nome}::$genero',
      () => BancoImagens.I.buscar(c.consulta(genero), count: 3),
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
          'Fotos de referência do banco de imagens. Leva as que gostares '
          'ao barbeiro/cabeleireiro — mostrar vale mais que explicar.',
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
