/// cromatica_test.dart — o motor de estações deve ser determinístico:
/// mesmo subtom + tom + cabelo = mesma estação, sempre.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:aurastyle_mobile/core/data/cromatica.dart';
import 'package:aurastyle_mobile/core/store/profile_store.dart';

Profile _perfil({
  String undertone = 'Neutro',
  int skinTone = 5,
  String hairColor = 'Castanho',
}) => Profile(undertone: undertone, skinTone: skinTone, hairColor: hairColor);

void main() {
  group('temperatura do subtom', () {
    test('reconhece quente, frio, oliva e neutro', () {
      expect(Cromatica.temperatura('Quente'), 'quente');
      expect(Cromatica.temperatura('Dourado'), 'quente');
      expect(Cromatica.temperatura('Frio'), 'frio');
      expect(Cromatica.temperatura('Olivado'), 'neutro');
      expect(Cromatica.temperatura('Neutro'), 'neutro');
      expect(Cromatica.temperatura(''), 'neutro');
    });
  });

  group('profundidade do tom', () {
    test('faixas 1-3, 4-7, 8-10', () {
      expect(Cromatica.profundidade(1), 'clara');
      expect(Cromatica.profundidade(3), 'clara');
      expect(Cromatica.profundidade(4), 'média');
      expect(Cromatica.profundidade(7), 'média');
      expect(Cromatica.profundidade(8), 'profunda');
      expect(Cromatica.profundidade(0), 'média');
    });
  });

  group('estação por perfil', () {
    test('quente + clara → Primavera Luminosa', () {
      final e = Cromatica.analisar(
        _perfil(undertone: 'Quente', skinTone: 2, hairColor: 'Loiro'),
      );
      expect(e.id, 'primavera-luminosa');
    });

    test('quente + média + cabelo escuro → Outono Dourado', () {
      final e = Cromatica.analisar(
        _perfil(undertone: 'Quente', skinTone: 6, hairColor: 'Preto'),
      );
      expect(e.id, 'outono-dourado');
    });

    test('quente + profunda → Outono Profundo', () {
      final e = Cromatica.analisar(
        _perfil(undertone: 'Quente', skinTone: 9, hairColor: 'Preto'),
      );
      expect(e.id, 'outono-profundo');
    });

    test('frio + clara → Verão Sereno', () {
      final e = Cromatica.analisar(
        _perfil(undertone: 'Frio', skinTone: 2, hairColor: 'Loiro'),
      );
      expect(e.id, 'verao-sereno');
    });

    test('frio + profunda → Inverno Real', () {
      final e = Cromatica.analisar(
        _perfil(undertone: 'Frio', skinTone: 9, hairColor: 'Preto'),
      );
      expect(e.id, 'inverno-real');
    });

    test('neutro + média + cabelo escuro → Inverno Profundo', () {
      final e = Cromatica.analisar(
        _perfil(undertone: 'Olivado', skinTone: 6, hairColor: 'Castanho-escuro'),
      );
      expect(e.id, 'inverno-profundo');
    });

    test('neutro + média + cabelo claro → Outono Suave', () {
      final e = Cromatica.analisar(
        _perfil(undertone: 'Neutro', skinTone: 5, hairColor: 'Castanho-claro'),
      );
      expect(e.id, 'outono-suave');
    });
  });

  group('integridade das estações', () {
    test('todas têm 10 cores, 4 neutros, 3 a evitar e 3 combos', () {
      for (final e in Cromatica.todas) {
        expect(e.paleta.length, 10, reason: e.nome);
        expect(e.neutros.length, 4, reason: e.nome);
        expect(e.evitar.length, 3, reason: e.nome);
        expect(e.combos.length, 3, reason: e.nome);
        expect(e.gradiente, isNotEmpty, reason: e.nome);
        expect(e.consultas, isNotEmpty, reason: e.nome);
      }
      expect(Cromatica.todas.length, 10);
    });

    test('todos os hex são válidos', () {
      for (final e in Cromatica.todas) {
        for (final s in [...e.paleta, ...e.neutros, ...e.evitar]) {
          expect(
            RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(s.hex),
            true,
            reason: '${e.nome}: ${s.nome} ${s.hex}',
          );
        }
        for (final c in e.combos) {
          for (final hex in c.cores) {
            expect(RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex), true,
                reason: '${e.nome}: combo ${c.titulo}');
          }
        }
      }
    });
  });

  test('temDados exige subtom e tom de pele', () {
    expect(Cromatica.temDados(_perfil(undertone: 'Quente', skinTone: 5)), true);
    expect(Cromatica.temDados(_perfil(undertone: '', skinTone: 5)), false);
    expect(
      Cromatica.temDados(_perfil(undertone: 'Quente', skinTone: 0)),
      false,
    );
  });
}
