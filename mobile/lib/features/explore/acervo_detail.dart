/// acervo_detail.dart — ficha de museu em ecrã inteiro: moldura de estúdio,
/// leituras hairline (criador, datação, cultura, material, departamento),
/// CTA para o site do Met e coração de salvar.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

import '../../core/api/acervo_api.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/shimmer_box.dart';

class AcervoDetailSheet extends StatelessWidget {
  const AcervoDetailSheet({
    super.key,
    required this.item,
    required this.saved,
    required this.onToggleSave,
  });

  final MetItem item;
  final bool saved;
  final VoidCallback onToggleSave;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Container(
        color: AuraColors.background.withValues(alpha: 0.96),
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior: fechar + salvar.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    _circleButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    Text(
                      'FICHA DE MUSEU',
                      style: AuraType.eyebrow.copyWith(fontSize: 9),
                    ),
                    const Spacer(),
                    _circleButton(
                      icon: saved ? Icons.favorite : Icons.favorite_border,
                      tint: saved ? AuraColors.primary : AuraColors.foreground,
                      onTap: onToggleSave,
                    ),
                  ],
                ),
              ),

              // Moldura de estúdio.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  child: ClipRRect(
                    borderRadius: AuraDecor.roundedLarge,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: AuraDecor.roundedLarge,
                        border: Border.all(color: AuraColors.border),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: item.image,
                        fit: BoxFit.contain,
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
                  ),
                ),
              ),

              // Leituras.
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, style: AuraType.cardTitle),
                      const SizedBox(height: 10),
                      _reading('CRIADOR', item.artist),
                      _reading('DATAÇÃO', item.date),
                      if (item.culture.isNotEmpty)
                        _reading('CULTURA', item.culture),
                      if (item.medium.isNotEmpty)
                        _reading('MATERIAL', item.medium),
                      _reading('DEPARTAMENTO', item.department),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: MachinedPanel(
                              glow: false,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              onTap: () => launcher.launchUrl(
                                Uri.parse(item.objectURL),
                                mode: launcher.LaunchMode.externalApplication,
                              ),
                              child:  Center(
                                child: Text(
                                  'VER NO MET',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 2,
                                    color: AuraColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open Access · obra em domínio público',
                        style: AuraType.caption.copyWith(fontSize: 10),
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
  }

  Widget _circleButton({
    required IconData icon,
    VoidCallback? onTap,
    Color? tint,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AuraColors.cardFill,
          border: Border.all(color: AuraColors.border),
        ),
        child: Icon(icon, size: 19, color: tint ?? AuraColors.foreground),
      ),
    );
  }

  Widget _reading(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AuraType.eyebrow.copyWith(fontSize: 8.5)),
          const SizedBox(height: 2),
          Text(value, style: AuraType.body.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          Container(height: 1, color: AuraColors.border),
        ],
      ),
    );
  }
}
