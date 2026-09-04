/// section_header.dart — o "carimbo usinado" que abre cada secção:
/// eyebrow em platina espaçada + título Outfit + selo opcional à direita.
library;

import 'package:flutter/material.dart';

import '../theme/aura_colors.dart';
import '../theme/aura_typography.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(), style: AuraType.eyebrow),
                const SizedBox(height: 5),
                Text(title, style: AuraType.sectionTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: AuraType.caption),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Selo machined — pill com borda platina (nível, contadores, fontes).
class MachinedChip extends StatelessWidget {
  const MachinedChip(this.label, {super.key, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: active
            ? AuraColors.primary.withValues(alpha: 0.14)
            : AuraColors.surface,
        border: Border.all(
          color: active
              ? AuraColors.primary.withValues(alpha: 0.55)
              : AuraColors.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Text(
          label.toUpperCase(),
          style: AuraType.chip.copyWith(
            color: active ? AuraColors.primary : AuraColors.mutedForeground,
          ),
        ),
      ),
    );
  }
}
