/// guarda_roupa_test.dart — o motor de harmonia do Guarda-Roupa Vivo:
/// pares de cor, determinismo do look de hoje e XP de "vou usar isto".
library;

import 'package:aurastyle_mobile/core/data/guarda_roupa_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Peca _peca(String id, String categoria, String hex) => Peca(
      id: id,
      nome: 'Peça $id',
      categoria: categoria,
      corHex: hex,
      corNome: '',
      criadoEm: '2026-09-08T12:00:00.000',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('harmoniaEntreCores', () {
    test('análogo/monocromático batem vizinhança tensa', () {
      final analogo = harmoniaEntreCores('#3E6A96', '#3EA096'); // d ≈ 36
      final mono = harmoniaEntreCores('#3E6A96', '#9BC3E5'); // d ≈ 2
      final tenso = harmoniaEntreCores('#3E6A96', '#2E8B57'); // d ≈ 64
      expect(analogo, greaterThan(tenso));
      expect(mono, greaterThan(tenso));
    });

    test('neutro ancora cor viva melhor que duas cores tensas', () {
      final neutroComVivo = harmoniaEntreCores('#8A94A6', '#7A4A3A');
      final tenso = harmoniaEntreCores('#2E8B57', '#FF8C00');
      expect(neutroComVivo, greaterThan(tenso));
    });

    test('hex inválido não rebenta — cai no neutro', () {
      expect(harmoniaEntreCores('#XXYYZZ', '#3E6A96'), 0.6);
    });
  });

  group('PecaCategoria.normalizar', () {
    test('sinónimos caem no slot certo', () {
      expect(PecaCategoria.normalizar('Calças de ganga'), 'base');
      expect(PecaCategoria.normalizar('jeans'), 'base');
      expect(PecaCategoria.normalizar('Ténis branco'), 'pes');
      expect(PecaCategoria.normalizar('sneakers'), 'pes');
      expect(PecaCategoria.normalizar('Blazer cinzento'), 'extra');
      expect(PecaCategoria.normalizar('Boné'), 'acessorio');
      expect(PecaCategoria.normalizar('Camisa azul'), 'topo');
      expect(PecaCategoria.normalizar('??'), '');
    });
  });

  group('GuardaRoupaStore.montarLook', () {
    late GuardaRoupaStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = GuardaRoupaStore();
      await store.load();
    });

    test('sem topo+base não monta look', () {
      store.adicionar(_peca('a', PecaCategoria.topo, '#3E6A96'));
      expect(store.montarLook(), isNull);
    });

    test('monta look com as peças certas nos slots', () {
      store.adicionar(_peca('top1', PecaCategoria.topo, '#3E6A96'));
      store.adicionar(_peca('bas1', PecaCategoria.base, '#101C2C'));
      store.adicionar(_peca('pes1', PecaCategoria.pes, '#8A94A6'));

      final look = store.montarLook();
      expect(look, isNotNull);
      expect(look!.pecas.length, 3);
      expect(look.pecas[0].id, 'top1');
      expect(look.pecas[1].id, 'bas1');
      expect(look.pecas[2].id, 'pes1');
      expect(look.conceito, isNotEmpty);
      expect(look.harmonia, greaterThan(0.5));
    });

    test('determinístico: mesmo attempt = mesmo look', () {
      store.adicionar(_peca('t1', PecaCategoria.topo, '#3E6A96'));
      store.adicionar(_peca('t2', PecaCategoria.topo, '#B0714F'));
      store.adicionar(_peca('b1', PecaCategoria.base, '#101C2C'));
      store.adicionar(_peca('b2', PecaCategoria.base, '#DC9B90'));

      final l1 = store.montarLook(attempt: 0);
      final l2 = store.montarLook(attempt: 0);
      expect(l1!.pecas.map((p) => p.id).join(), l2!.pecas.map((p) => p.id).join());
    });

    test('trocar combinação roda o attempt', () {
      store.adicionar(_peca('t1', PecaCategoria.topo, '#3E6A96'));
      store.adicionar(_peca('t2', PecaCategoria.topo, '#B0714F'));
      store.adicionar(_peca('b1', PecaCategoria.base, '#101C2C'));
      store.adicionar(_peca('b2', PecaCategoria.base, '#DC9B90'));

      final l0 = store.montarLook(attempt: 0);
      final l1 = store.montarLook(attempt: 1);
      expect(l0!.pecas.map((p) => p.id).join(),
          isNot(l1!.pecas.map((p) => p.id).join()));
    });

    test('usarLook dá direito 1×/dia', () {
      expect(store.usarLook(), isTrue);
      expect(store.usarLook(), isFalse);
      expect(store.lookUsadoHoje, isTrue);
    });
  });
}
