/// theme_chip.dart — pílulas de tema da galeria Acervo (idênticas ao web):
/// inativas em vidro, ativa com preenchimento bg-aura (metal platina).
library;

import 'package:flutter/material.dart';

import '../theme/aura_colors.dart';
import '../theme/aura_decorations.dart';
import '../theme/aura_typography.dart';

class ThemeChip extends StatelessWidget {
  const ThemeChip({
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
        curve: Curves.easeOut,
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
