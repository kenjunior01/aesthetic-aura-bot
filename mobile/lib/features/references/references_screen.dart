/// references_screen.dart — Referências: "a quem a minha cara se aproxima?"
/// Galeria do banco de arquétipos (GET /api/look-alike) + comparação com a
/// tua foto/perfil (POST). Pódio com anel de proximidade, leitura trait a
/// trait e plano de upgrade — a MESMA IA do web.
library;

import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/aura_api.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/widgets/stagger_in.dart';

class ReferencesScreen extends StatefulWidget {
  const ReferencesScreen({super.key});

  @override
  State<ReferencesScreen> createState() => _ReferencesScreenState();
}

class _ReferencesScreenState extends State<ReferencesScreen> {
  List<LookAlikeMatch> _gallery = const [];
  bool _loadingGallery = true;
  bool _comparing = false;
  LookAlikeVerdict? _verdict;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  Future<void> _loadGallery() async {
    try {
      final g = await AuraApi.I.fetchGallery();
      if (mounted) setState(() => _gallery = g);
    } catch (_) {
      // sem banco — a comparação continua disponível via perfil
    } finally {
      if (mounted) setState(() => _loadingGallery = false);
    }
  }

  Future<void> _compare() async {
    final store = context.read<ProfileStore>();
    setState(() => _comparing = true);
    try {
      String? base64Image;
      if (_photoPath != null) {
        final bytes = await File(_photoPath!).readAsBytes();
        base64Image = base64Encode(bytes);
      }
      final v = await AuraApi.I.compare(
        imageBase64: base64Image,
        profile: store.aiContext(),
      );
      if (!mounted) return;
      setState(() => _verdict = v);
      store.logEvent('lookalike_compare', {
        'source': v.source,
        'matches': v.matches.length,
      });
      store.addXp(30);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sem ligação ao banco de referências.')),
      );
    } finally {
      if (mounted) setState(() => _comparing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(22),
          children: [
            // Cabeçalho.
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
                    child: const Icon(Icons.arrow_back, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REFERÊNCIAS', style: AuraType.eyebrow),
                    Text('A quem te aproximas?', style: AuraType.cardTitle),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Foto + comparar.
            StaggerIn(
              index: 0,
              child: GlassCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Visor da foto.
                        GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              borderRadius: AuraDecor.roundedSmall,
                              color: AuraColors.surface,
                              border: Border.all(
                                color: AuraColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                            ),
                            child: _photoPath != null
                                ? ClipRRect(
                                    borderRadius: AuraDecor.roundedSmall,
                                    child: Image.file(
                                      File(_photoPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                :  Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 22,
                                    color: AuraColors.primary,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Envia uma foto sem filtros (ou segue só com o perfil) '
                            'e a IA mede 8 traços contra o banco de arquétipos.',
                            style: AuraType.caption.copyWith(
                              fontSize: 11.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: PlatinaButton(
                        label: _comparing ? 'A comparar…' : 'Comparar agora',
                        icon: Icons.compare_outlined,
                        expanded: true,
                        onTap: _comparing ? null : _compare,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Veredito.
            if (_verdict != null) ...[
              StaggerIn(
                index: 1,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        eyebrow: 'VEREDITO',
                        title: 'A tua aura mais próxima',
                      ),
                      if (_verdict!.summary.isNotEmpty)
                        Text(
                          _verdict!.summary,
                          style: AuraType.body.copyWith(height: 1.5),
                        ),
                      const SizedBox(height: 14),
                      for (var i = 0; i < _verdict!.matches.length; i++)
                        _matchRow(_verdict!.matches[i], i + 1),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Galeria do banco.
            StaggerIn(
              index: 2,
              child: const SectionHeader(
                eyebrow: 'BANCO DE ARQUÉTIPOS',
                title: 'Originais de estúdio',
                subtitle: 'Arquétipos gerados — não pessoas reais.',
              ),
            ),
            if (_loadingGallery)
              Row(
                children: [
                  Expanded(child: ShimmerBox(height: 150)),
                  const SizedBox(width: 12),
                  Expanded(child: ShimmerBox(height: 150)),
                ],
              )
            else if (_gallery.isEmpty)
              GlassCard(
                child: Text(
                  'Sem banco ligado. Configura a Ligação no Perfil para carregar '
                  'os 8 arquétipos e comparar trait a trait.',
                  style: AuraType.caption.copyWith(height: 1.5),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: _gallery.length,
                itemBuilder: (context, i) =>
                    StaggerIn(index: i % 6, child: _galleryCard(_gallery[i])),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _galleryCard(LookAlikeMatch m) {
    return ClipRRect(
      borderRadius: AuraDecor.rounded,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AuraDecor.rounded,
          border: Border.all(color: AuraColors.border),
          color: AuraColors.card,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: m.photo,
              fit: BoxFit.cover,
              placeholder: (_, _) => const ShimmerBox(radius: 0),
              errorWidget: (_, _, _) => Container(
                color: AuraColors.muted,
                child:  Icon(
                  Icons.person_outline,
                  color: AuraColors.mutedForeground,
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(11, 22, 11, 10),
                decoration: const BoxDecoration(gradient: AuraDecor.imageScrim),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AuraType.cardTitle.copyWith(fontSize: 12.5),
                    ),
                    if (m.vibe.isNotEmpty)
                      Text(
                        m.vibe,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AuraType.caption.copyWith(fontSize: 10),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _matchRow(LookAlikeMatch m, int place) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text('$placeº', style: AuraType.chip.copyWith(fontSize: 11)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${m.name} · ${m.score}%',
                  style: AuraType.body.copyWith(fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 4,
                    color: AuraColors.surface,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: (m.score / 100).clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: AuraDecor.auraMetal,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final photo = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 86,
      );
      if (photo == null) return;
      setState(() {
        _photoPath = photo.path;
        _verdict = null;
      });
    } catch (_) {
      // picker indisponível
    }
  }
}
