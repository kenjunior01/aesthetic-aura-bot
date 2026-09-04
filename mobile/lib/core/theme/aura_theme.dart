/// aura_theme.dart — ThemeData da identidade Platina Glacial, nos dois modos.
/// Tudo o que é Material (sheets, inputs, navegação) herda os tokens vivos.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'aura_colors.dart';
import 'aura_decorations.dart';
import 'aura_typography.dart';

ThemeData buildAuraTheme() {
  final claro = AuraColors.claro;
  final base = ThemeData(
    useMaterial3: true,
    brightness: claro ? Brightness.light : Brightness.dark,
    fontFamily: AuraType.sans,
    scaffoldBackgroundColor: Colors.transparent,
    colorScheme: ColorScheme(
      brightness: claro ? Brightness.light : Brightness.dark,
      primary: AuraColors.primary,
      onPrimary: AuraColors.onPrimary,
      secondary: AuraColors.accent,
      onSecondary: AuraColors.onAccent,
      surface: AuraColors.card,
      onSurface: AuraColors.foreground,
      error: AuraColors.chartWarm,
      onError: Colors.white,
      outline: AuraColors.border,
      surfaceContainerHighest: AuraColors.secondary,
      onSurfaceVariant: AuraColors.mutedForeground,
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      bodyLarge: AuraType.body,
      bodyMedium: AuraType.body,
      bodySmall: AuraType.caption,
      titleLarge: AuraType.sectionTitle,
      titleMedium: AuraType.cardTitle,
      labelSmall: AuraType.eyebrow,
    ),
    dividerTheme: DividerThemeData(
      color: AuraColors.border,
      thickness: 1,
      space: 1,
    ),
    splashColor: AuraColors.primary.withValues(alpha: 0.08),
    highlightColor: AuraColors.primary.withValues(alpha: 0.05),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: claro ? Brightness.dark : Brightness.light,
        statusBarBrightness: claro ? Brightness.light : Brightness.dark,
      ),
      titleTextStyle: AuraType.cardTitle,
      iconTheme: IconThemeData(color: AuraColors.foreground),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AuraColors.backgroundDeep,
      modalBackgroundColor: AuraColors.backgroundDeep,
      shape: RoundedRectangleBorder(borderRadius: AuraDecor.roundedLarge),
      showDragHandle: true,
      dragHandleColor: AuraColors.border,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AuraColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: AuraDecor.roundedLarge,
        side: BorderSide(color: AuraColors.border),
      ),
      titleTextStyle: AuraType.cardTitle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AuraColors.surface,
      hintStyle: AuraType.caption,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AuraDecor.roundedSmall,
        borderSide: BorderSide(color: AuraColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AuraDecor.roundedSmall,
        borderSide: BorderSide(color: AuraColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AuraDecor.roundedSmall,
        borderSide: BorderSide(color: AuraColors.primary, width: 1.2),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AuraColors.primary),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AuraColors.secondary,
      contentTextStyle: AuraType.body,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: AuraDecor.roundedSmall),
    ),
  );
}
