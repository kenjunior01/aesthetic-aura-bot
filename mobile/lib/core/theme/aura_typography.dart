/// aura_typography.dart — as mesmas duas famílias do web:
/// Outfit para display (títulos, números usinados) e Manrope para texto.
/// Estilos são getters: herdam os tokens vivos do modo cromático.
library;

import 'package:flutter/material.dart';

import 'aura_colors.dart';

class AuraType {
  AuraType._();

  static const String display = 'Outfit';
  static const String sans = 'Manrope';

  /// Eyebrow — o "carimbo usinado" que abre cada secção.
  static TextStyle get eyebrow => TextStyle(
    fontFamily: sans,
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 3.2,
    height: 1.2,
    color: AuraColors.primary,
  );

  static TextStyle get sectionTitle => TextStyle(
    fontFamily: display,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.15,
    color: AuraColors.foreground,
  );

  static TextStyle get cardTitle => TextStyle(
    fontFamily: display,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.2,
    color: AuraColors.foreground,
  );

  static TextStyle get body => TextStyle(
    fontFamily: sans,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AuraColors.foreground,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: sans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.45,
    color: AuraColors.mutedForeground,
  );

  /// Números de instrumento — o mostrador do gauge, contadores de streak.
  static TextStyle get machinedNumber => TextStyle(
    fontFamily: display,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.0,
    color: AuraColors.foreground,
  );

  static TextStyle get chip => TextStyle(
    fontFamily: sans,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: AuraColors.primary,
  );
}
