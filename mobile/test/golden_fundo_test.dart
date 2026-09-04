/// golden_fundo_test.dart — captura o céu vivo nos DOIS modos para
/// verificação visual. Captura manual apenas:
///   CAPTURA_FUNDO=1 flutter test --update-goldens test/golden_fundo_test.dart
/// No dia-a-dia os testes passam trivialmente (o relógio real tornaria o
/// golden não-determinístico em CI).
library;

import 'dart:io';

import 'package:aurastyle_mobile/core/theme/aura_colors.dart';
import 'package:aurastyle_mobile/core/widgets/aurora_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('captura do céu — noite', (tester) async {
    if (Platform.environment['CAPTURA_FUNDO'] != '1') return;
    AuraColors.modo = ModoCromatico.noite;
    await _captura(tester, 'goldens/fundo_noite.png');
  });

  testWidgets('captura do céu — alvor', (tester) async {
    if (Platform.environment['CAPTURA_FUNDO'] != '1') return;
    AuraColors.modo = ModoCromatico.alvor;
    await _captura(tester, 'goldens/fundo_alvor.png');
    AuraColors.modo = ModoCromatico.noite; // não polui outros testes
  });
}

Future<void> _captura(WidgetTester tester, String caminho) async {
  tester.view.physicalSize = const Size(400, 820);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: AuroraBackground(child: const SizedBox.expand()),
      ),
    ),
  );
  // Avança o relógio para o céu ganhar vida.
  await tester.pump(const Duration(seconds: 6));
  await expectLater(find.byType(AuroraBackground), matchesGoldenFile(caminho));
}
