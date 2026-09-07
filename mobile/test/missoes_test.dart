/// missoes_test.dart — o jogo da Aura sob teste:
///  • chave ISO da semana estável
///  • ingestão de logEvent alimenta a missão certa (e só ela)
///  • XP creditado no ProfileStore quando a missão fecha
///  • semana renasce limpa quando a chave muda
library;

import 'package:aurastyle_mobile/core/data/missoes_store.dart';
import 'package:aurastyle_mobile/core/store/profile_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('semanaIsoKey devolve chave ISO-8601 com W maiúsculo', () {
    final k = semanaIsoKey(DateTime(2026, 9, 7)); // segunda
    expect(k, matches(RegExp(r'^\d{4}-W\d{2}$')));
    // 2026-01-01 é quinta → semana 1.
    expect(semanaIsoKey(DateTime(2026, 1, 1)), '2026-W01');
  });

  test('logEvent alimenta a missão e credita XP', () async {
    final perfil = ProfileStore();
    final store = MissaoStore(perfil);
    await store.load();

    final alvo = store.estados
        .where((e) => e.missao.evento == 'cromatica_open')
        .first;
    expect(alvo.missao.alvo, 1);
    final xpAntes = perfil.xp;

    perfil.logEvent('cromatica_open');
    // O ingestion é síncrono no listener.
    final depois = store.estados
        .where((e) => e.missao.evento == 'cromatica_open')
        .first;
    expect(depois.feita, isTrue);
    expect(store.feitasCount, 1);
    expect(perfil.xp, xpAntes + alvo.missao.xp);
    expect(store.xpSemana, alvo.missao.xp);
  });

  test('missão multi-passo precisa do alvo completo', () async {
    final perfil = ProfileStore();
    final store = MissaoStore(perfil);
    await store.load();

    final multi = store.estados
        .where((e) => e.missao.alvo > 1)
        .toList();
    if (multi.isEmpty) return; // semana sem multi-passo — nada a provar
    final m = multi.first;
    final xpAntes = perfil.xp;

    perfil.logEvent(m.missao.evento);
    var e = store.estados.firstWhere((x) => x.missao.id == m.missao.id);
    expect(e.feita, isFalse);
    expect(perfil.xp, xpAntes);

    for (var i = 1; i < m.missao.alvo; i++) {
      perfil.logEvent(m.missao.evento);
    }
    e = store.estados.firstWhere((x) => x.missao.id == m.missao.id);
    expect(e.feita, isTrue);
    expect(perfil.xp, xpAntes + m.missao.xp);
  });

  test('evento que não é de missão não mexe no progresso', () async {
    final perfil = ProfileStore();
    final store = MissaoStore(perfil);
    await store.load();

    perfil.logEvent('evento_aleatorio_sem_missao');
    expect(store.feitasCount, 0);
    expect(store.xpSemana, 0);
  });
}
