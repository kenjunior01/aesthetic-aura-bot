/// glass_card.dart — os dois blocos de construção das superfícies:
///
///  • GlassCard     → vidro fosco de observidana, fio especular no topo,
///                    sombra de estúdio (o `.glass` do web).
///  • MachinedPanel → painel de metal platina usinado, borda gradiente de 5
///                    stops (o `.machined` do web) para CTAs e selos.
library;

import 'package:flutter/material.dart';

import '../theme/aura_colors.dart';
import '../theme/aura_decorations.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius,
    this.onTap,
    this.opacity = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? radius;
  final VoidCallback? onTap;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AuraDecor.radius;
    final body = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: AuraDecor.softGlass,
        color: AuraColors.cardFill.withValues(alpha: 0.55 * opacity),
        border: Border.all(color: AuraColors.border, width: 1),
        boxShadow: AuraDecor.cardShadow,
      ),
      // Fio especular — linha de luz de 1px colada ao topo do vidro.
      child: Stack(
        children: [
          Positioned(
            left: r * 0.35,
            right: r * 0.35,
            top: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AuraColors.specular,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
    if (onTap == null) return body;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: body,
      ),
    );
  }
}

class MachinedPanel extends StatelessWidget {
  const MachinedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
    this.radius,
    this.onTap,
    this.glow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? radius;
  final VoidCallback? onTap;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AuraDecor.radiusSmall;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: AuraDecor.auraMetal,
        boxShadow: glow ? AuraDecor.glowShadow() : AuraDecor.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.2),
        // Interior usinado: o metal fica só na borda, miolo em observidana.
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(r - 1),
            color: AuraColors.backgroundDeep,
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(r),
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Painel preenchido de platina — para o CTA primário.
class PlatinaButton extends StatelessWidget {
  const PlatinaButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final btn = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AuraDecor.radiusSmall),
        gradient: AuraDecor.auraMetal,
        boxShadow: AuraDecor.glowShadow(alpha: 0.34),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        child: Row(
          mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: AuraColors.onPrimary),
              const SizedBox(width: 8),
            ],
            Text(
              label.toUpperCase(),
              style:  TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.2,
                color: AuraColors.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AuraDecor.radiusSmall),
        onTap: onTap,
        child: btn,
      ),
    );
  }
}
