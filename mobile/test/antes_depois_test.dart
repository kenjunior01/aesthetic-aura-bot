/// antes_depois_test.dart — fumaço do comparador ANTES & AGORA:
///  • com <2 fotos → não rende nada
///  • com 2 fotos → rende o cartão com as etiquetas e o fio
///  • delta de tom entre os dois scans aparece no chip de leitura
library;

import 'package:aurastyle_mobile/core/data/diario_store.dart';
import 'package:aurastyle_mobile/features/evolucao/antes_depois.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _kPng1x1 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

EntradaDiario _entrada({
  required String id,
  required String data,
  int tom = 0,
  String? thumb,
}) {
  return EntradaDiario(
    id: id,
    data: data,
    faceShape: 'Oval',
    skinTone: tom,
    undertone: 'quente',
    hairColor: 'castanho-escuro',
    fonte: 'ai',
    thumb: thumb,
  );
}

Widget _envolvida(List<EntradaDiario> entradas) => MaterialApp(
  home: Scaffold(
    body: AntesDepoisCard(entradas: entradas),
  ),
);

void main() {
  testWidgets('sem duas fotos, não há comparador', (tester) async {
    await tester.pumpWidget(
      _envolvida([_entrada(id: 'a', data: '2026-09-05')]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AntesDepoisCard), findsOneWidget);
    expect(find.text('ANTES & AGORA'), findsNothing);
  });

  testWidgets('com duas fotos, o fio e as etiquetas entram em cena', (
    tester,
  ) async {
    final novas = [
      _entrada(id: '2026-09-05T10:00:00Z', data: '2026-09-05', tom: 6, thumb: _kPng1x1),
      _entrada(id: '2026-08-01T10:00:00Z', data: '2026-08-01', tom: 5, thumb: _kPng1x1),
    ];
    await tester.pumpWidget(_envolvida(novas));
    await tester.pumpAndSettle();

    expect(find.text('ANTES & AGORA'), findsOneWidget);
    expect(find.textContaining('AGORA · 05 Set'), findsOneWidget);
    expect(find.textContaining('ANTES · 01 Ago'), findsOneWidget);
    expect(find.textContaining('35 dias'), findsOneWidget);
    // Tom subiu 5 → 6.
    expect(find.textContaining('TOM +1'), findsOneWidget);
  });
}
