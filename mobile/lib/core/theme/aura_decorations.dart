/// aura_decorations.dart — a gramática visual do "metal usinado e vidro frio":
/// gradientes de platina, bordas especulares, sombras de estúdio e halos de aurora.
/// Todos os compostos são getters: leem o modo cromático a cada build.
library;

import 'package:flutter/material.dart';

import 'aura_colors.dart';

class AuraDecor {
  AuraDecor._();

  /// Metal platina usinado em 5 stops (105° no web → Begin/End alinhado).
  /// Identidade constante nos dois modos.
  static const LinearGradient auraMetal = LinearGradient(
    begin: Alignment(-1, -0.35),
    end: Alignment(1, 0.35),
    colors: AuraColors.auraMetal,
    stops: [0.0, 0.22, 0.45, 0.68, 1.0],
  );

  /// Vidro fosco — fumado na noite, branco leitoso no alvor.
  static LinearGradient get softGlass => AuraColors.claro
      ? const LinearGradient(
          begin: Alignment(-0.4, -1),
          end: Alignment(0.4, 1),
          colors: [Color(0xCCFFFFFF), Color(0x8CF2F7FC)],
          stops: [0.0, 0.55],
        )
      : const LinearGradient(
          begin: Alignment(-0.4, -1),
          end: Alignment(0.4, 1),
          colors: [Color(0x17494D54), Color(0x0A2B2E33)],
          stops: [0.0, 0.55],
        );

  /// Legenda sobre imagem — observidana a derreter para baixo.
  static const LinearGradient imageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.45, 1.0],
    colors: [Color(0x0004060A), Color(0xF204060A)],
  );

  /// Borda de vidro: especular no topo, sombra em baixo (2 stops).
  static LinearGradient get glassBorder => AuraColors.claro
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0x140D131C)],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x2EF4F9FF), Color(0x0AEDF2FA)],
        );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AuraColors.shadowCold.withValues(alpha: AuraColors.claro ? 0.5 : 0.85),
      offset: const Offset(0, 22),
      blurRadius: 44,
      spreadRadius: -24,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: AuraColors.shadowCold.withValues(alpha: AuraColors.claro ? 0.55 : 0.9),
      offset: const Offset(0, 32),
      blurRadius: 64,
      spreadRadius: -28,
    ),
    BoxShadow(
      color: AuraColors.shadowCold.withValues(alpha: AuraColors.claro ? 0.35 : 0.6),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: -6,
    ),
  ];

  static List<BoxShadow> glowShadow({double alpha = 0.28}) => [
    BoxShadow(
      color: AuraColors.primary.withValues(alpha: alpha),
      offset: const Offset(0, 10),
      blurRadius: 32,
      spreadRadius: -14,
    ),
  ];

  /// Raio de canto padrão — --radius 1.25rem no web.
  static const double radius = 20;
  static const double radiusLarge = 26;
  static const double radiusSmall = 14;

  static BorderRadius get rounded => BorderRadius.circular(radius);
  static BorderRadius get roundedLarge => BorderRadius.circular(radiusLarge);
  static BorderRadius get roundedSmall => BorderRadius.circular(radiusSmall);
}
