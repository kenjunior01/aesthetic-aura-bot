/// aura_colors.dart — identidade cromática "Platina Glacial sobre Observidana".
///
/// Tradução 1:1 dos tokens oklch do web (globals.css) para sRGB:
/// nada de azul genérico — croma baixo, matiz 242-258, superfícies frias.
library;

import 'package:flutter/material.dart';

class AuraColors {
  AuraColors._();

  // ── Observidana fria (matiz 258) ──────────────────────────────────────────
  static const Color background = Color(0xFF04060A); // oklch(0.105 0.006 258)
  static const Color backgroundDeep = Color(0xFF020306);
  static const Color card = Color(0xFF0C1015); // oklch(0.17 0.012 258)
  static const Color cardFill = Color(0x8C0C1015); // card @ 55% — vidro
  static const Color secondary = Color(0xFF14191F); // oklch(0.21 0.014 258)
  static const Color muted = Color(0xFF13161C); // oklch(0.2 0.012 258)

  // ── Texto ──────────────────────────────────────────────────────────────────
  static const Color foreground = Color(0xFFEDF2FA); // oklch(0.96 0.012 258)
  static const Color mutedForeground = Color(
    0xFF8E96A2,
  ); // oklch(0.67 0.02 258)

  // ── Platina Glacial (metais usinados, matiz 239-246) ──────────────────────
  static const Color primary = Color(0xFFB8D9F3); // oklch(0.87 0.05 242)
  static const Color onPrimary = Color(0xFF101621); // oklch(0.2 0.025 262)
  static const Color glow = Color(0xFF9FCAEE); // oklch(0.82 0.068 244)
  static const Color accent = Color(0xFF9BC3E5); // pedra-lua 0.8 0.065 245
  static const Color onAccent = Color(0xFF0C121B);
  static const Color platinaLuminosa = Color(0xFFA5D4F9); // --gold

  // ── Superfícies de vidro ──────────────────────────────────────────────────
  static const Color border = Color(0x1AEDF2FA); // foreground @ 10%
  static const Color surface = Color(0x0DEDF2FA); // foreground @ 5%
  static const Color surfaceStrong = Color(0x1AEDF2FA); // foreground @ 10%
  static const Color specular = Color(0x14F4F9FF); // linha de luz no topo @ 8%

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// Metal platina usinado — 5 stops simulam torneamento real (--gradient-aura).
  static const List<Color> auraMetal = [
    Color(0xFFA2BBD2), // oklch(0.78 0.043 246)
    Color(0xFFC3E3FB), // oklch(0.9  0.047 240)
    Color(0xFFADCFEC), // oklch(0.84 0.054 243)
    Color(0xFFCDE9FD), // oklch(0.92 0.04  239)
    Color(0xFFA4C2DC), // oklch(0.8  0.05  245)
  ];

  /// Contraste quente para leituras negativas em gráficos (--chart-4).
  static const Color chartWarm = Color(0xFFDC9B90); // oklch(0.75 0.08 30)
  static const Color chartIce = Color(0xFFA2BBD2); // oklch(0.78 0.043 246)

  // ── Sombras ───────────────────────────────────────────────────────────────
  static const Color shadowCold = Color(0xE6000102); // oklch(0.01 0.004 258)
  static const Color glowShadow = Color(0x47B8D9F3); // primary @ 28%

  /// Halos da aurora de fundo (radiais decorativas).
  static const Color auroraHalo1 = Color(0x26B8D9F3); // platina @ 15%
  static const Color auroraHalo2 = Color(0x1E9FCAEE); // ártico @ 12%
  static const Color auroraHalo3 = Color(0x16141C2A); // azul profundo
}
