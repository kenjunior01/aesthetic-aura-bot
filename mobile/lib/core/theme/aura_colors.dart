/// aura_colors.dart — identidade cromática "Platina Glacial" em DOIS modos:
/// Observidana (noite) e Alvor (dia — gelo claro).
///
/// Tradução 1:1 dos tokens oklch do web para sRGB. Os tokens são getters
/// que leem `modo` — o app reconstroi a árvore ao alternar (key no root),
/// por isso nenhum widget precisa conhecer o modo diretamente.
library;

import 'package:flutter/material.dart';

enum ModoCromatico { noite, alvor }

class AuraColors {
  AuraColors._();

  /// Modo cromático corrente. Alterado pelo seletor no Perfil; o app raiz
  /// reconstrói com uma nova key e todo o app lê os novos tokens.
  static ModoCromatico modo = ModoCromatico.noite;
  static bool get claro => modo == ModoCromatico.alvor;

  // ── Observidana fria (noite) ───────────────────────────────────────────────
  static const Color _backgroundN = Color(0xFF04060A);
  static const Color _backgroundDeepN = Color(0xFF020306);
  static const Color _cardN = Color(0xFF0C1015);
  static const Color _cardFillN = Color(0x8C0C1015);
  static const Color _secondaryN = Color(0xFF14191F);
  static const Color _mutedN = Color(0xFF13161C);
  static const Color _foregroundN = Color(0xFFEDF2FA);
  static const Color _mutedForegroundN = Color(0xFF8E96A2);
  static const Color _primaryN = Color(0xFFB8D9F3);
  static const Color _onPrimaryN = Color(0xFF101621);
  static const Color _glowN = Color(0xFF9FCAEE);
  static const Color _accentN = Color(0xFF9BC3E5);
  static const Color _onAccentN = Color(0xFF0C121B);
  static const Color _platinaLuminosaN = Color(0xFFA5D4F9);
  static const Color _borderN = Color(0x1AEDF2FA);
  static const Color _surfaceN = Color(0x0DEDF2FA);
  static const Color _surfaceStrongN = Color(0x1AEDF2FA);
  static const Color _specularN = Color(0x14F4F9FF);
  static const Color _chartWarmN = Color(0xFFDC9B90);
  static const Color _chartIceN = Color(0xFFA2BBD2);
  static const Color _shadowColdN = Color(0xE6000102);
  static const Color _glowShadowN = Color(0x47B8D9F3);
  static const Color _halo1N = Color(0x26B8D9F3);
  static const Color _halo2N = Color(0x1E9FCAEE);
  static const Color _halo3N = Color(0x16141C2A);

  // ── Alvor Glacial (dia) — o mesmo azul-gelo visto à luz do dia ────────────
  static const Color _backgroundA = Color(0xFFEFF3FA);
  static const Color _backgroundDeepA = Color(0xFFDFE9F4);
  static const Color _cardA = Color(0xFFFFFFFF);
  static const Color _cardFillA = Color(0xF2FFFFFF);
  static const Color _secondaryA = Color(0xFFF6F9FC);
  static const Color _mutedA = Color(0xFFEEF3F9);
  static const Color _foregroundA = Color(0xFF0B1119);
  static const Color _mutedForegroundA = Color(0xFF48546E);
  static const Color _primaryA = Color(0xFF2E5F8A);
  // ON-primary ESCURO no Alvor: o metal platina continua claro nos DOIS
  // modos — texto/icones brancos em cima dele eram ilegiveis (bug do light
  // mode). Marinho escuro devolve o contraste a todos os CTAs de metal.
  static const Color _onPrimaryA = Color(0xFF12283C);
  static const Color _glowA = Color(0xFF5E97C4);
  static const Color _accentA = Color(0xFF4E86B4);
  static const Color _onAccentA = Color(0xFFF4F9FD);
  static const Color _platinaLuminosaA = Color(0xFF3D7CB3);
  static const Color _borderA = Color(0x240F1B2B);
  static const Color _surfaceA = Color(0x0A0F1B2B);
  static const Color _surfaceStrongA = Color(0x240F1B2B);
  static const Color _specularA = Color(0xD9FFFFFF);
  static const Color _chartWarmA = Color(0xFFB0574A);
  static const Color _chartIceA = Color(0xFF6E9BC0);
  static const Color _shadowColdA = Color(0x33182738);
  static const Color _glowShadowA = Color(0x3D2E5F8A);
  static const Color _halo1A = Color(0x59A9CCE0);
  static const Color _halo2A = Color(0x478FBED8);
  static const Color _halo3A = Color(0x2EC9DEF0);

  // ── Tokens vivos ───────────────────────────────────────────────────────────
  static Color get background => claro ? _backgroundA : _backgroundN;
  static Color get backgroundDeep => claro ? _backgroundDeepA : _backgroundDeepN;
  static Color get card => claro ? _cardA : _cardN;
  static Color get cardFill => claro ? _cardFillA : _cardFillN;
  static Color get secondary => claro ? _secondaryA : _secondaryN;
  static Color get muted => claro ? _mutedA : _mutedN;
  static Color get foreground => claro ? _foregroundA : _foregroundN;
  static Color get mutedForeground => claro ? _mutedForegroundA : _mutedForegroundN;
  static Color get primary => claro ? _primaryA : _primaryN;
  static Color get onPrimary => claro ? _onPrimaryA : _onPrimaryN;
  static Color get glow => claro ? _glowA : _glowN;
  static Color get accent => claro ? _accentA : _accentN;
  static Color get onAccent => claro ? _onAccentA : _onAccentN;
  static Color get platinaLuminosa => claro ? _platinaLuminosaA : _platinaLuminosaN;
  static Color get border => claro ? _borderA : _borderN;
  static Color get surface => claro ? _surfaceA : _surfaceN;
  static Color get surfaceStrong => claro ? _surfaceStrongA : _surfaceStrongN;
  static Color get specular => claro ? _specularA : _specularN;
  static Color get chartWarm => claro ? _chartWarmA : _chartWarmN;
  static Color get chartIce => claro ? _chartIceA : _chartIceN;
  static Color get shadowCold => claro ? _shadowColdA : _shadowColdN;
  static Color get glowShadowC => claro ? _glowShadowA : _glowShadowN;
  static Color get auroraHalo1 => claro ? _halo1A : _halo1N;
  static Color get auroraHalo2 => claro ? _halo2A : _halo2N;
  static Color get auroraHalo3 => claro ? _halo3A : _halo3N;

  // ── Gradients ─────────────────────────────────────────────────────────────
  /// Metal platina usinado — 5 stops simulam torneamento real (--gradient-aura).
  /// Identidade em ambos os modos: o metal é a assinatura da marca.
  static const List<Color> auraMetal = [
    Color(0xFFA2BBD2), // oklch(0.78 0.043 246)
    Color(0xFFC3E3FB), // oklch(0.9  0.047 240)
    Color(0xFFADCFEC), // oklch(0.84 0.054 243)
    Color(0xFFCDE9FD), // oklch(0.92 0.04  239)
    Color(0xFFA4C2DC), // oklch(0.8  0.05  245)
  ];
}
