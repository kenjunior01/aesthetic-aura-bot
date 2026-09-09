/// evento_store.dart — PLANO DE EVENTO: "casamento daqui a 5 semanas" e a
/// Aura traça o plano semana a semana (pele, cabelo, roupa, corpo) até ao
/// dia. Cada tarefa feita paga XP; o dia do evento tem celebração própria.
///
/// Um evento ativo de cada vez (o foco inteiro nele). Persistido em
/// SharedPreferences; a geração segue a cadeia do app: Groq direto →
/// plano local por tipo (sempre honesto sobre a fonte).
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/groq_ai.dart';
import '../secrets.dart';

/// Uma ETAPA do plano — uma semana (ou "semana final") com foco e tarefas.
class EtapaEvento {
  const EtapaEvento({
    required this.titulo,
    required this.foco,
    required this.tarefas,
    List<bool>? feitas,
  }) : feitas = feitas ?? const [];

  final String titulo; // 'Semana 3 · Pele impecável'
  final String foco; // 1 frase do capítulo
  final List<String> tarefas; // 3-5 tarefas concretas
  final List<bool> feitas; // paralelo às tarefas

  int get total => tarefas.length;
  int get feitasCount => feitas.where((f) => f).length;
  bool get completa => total > 0 && feitasCount == total;

  Map<String, dynamic> toJson() => {
        'titulo': titulo,
        'foco': foco,
        'tarefas': tarefas,
        'feitas': feitas,
      };

  static EtapaEvento fromJson(Map<String, dynamic> j) {
    final tarefas =
        (j['tarefas'] as List?)?.map((e) => '$e').toList() ?? const [];
    final feitas = (j['feitas'] as List?)
            ?.map((e) => e == true || e == 'true')
            .toList() ??
        List<bool>.filled(tarefas.length, false);
    return EtapaEvento(
      titulo: '${j['titulo'] ?? 'Semana'}',
      foco: '${j['foco'] ?? ''}',
      tarefas: tarefas,
      feitas: List<bool>.generate(
        tarefas.length,
        (i) => i < feitas.length ? feitas[i] : false,
      ),
    );
  }

  EtapaEvento comTarefaFeita(int index, bool feita) {
    if (index < 0 || index >= total) return this;
    final novas = List<bool>.from(feitas);
    novas[index] = feita;
    return EtapaEvento(
      titulo: titulo,
      foco: foco,
      tarefas: tarefas,
      feitas: novas,
    );
  }
}

/// O EVENTO completo.
class Evento {
  const Evento({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.data, // 'YYYY-MM-DD'
    required this.resumo,
    required this.dicaChave,
    required this.etapas,
    this.fonte = 'local',
  });

  final String id; // ISO da criação
  final String nome; // 'Casamento da Ana'
  final String tipo; // casamento|entrevista|festa|encontro|formatura|viagem
  final String data; // 'YYYY-MM-DD'
  final String resumo; // o plano numa frase
  final String dicaChave; // o que mais pesa para brilhar no dia
  final List<EtapaEvento> etapas; // semanas até o dia (+ 'Dia do evento')
  final String fonte; // 'groq' | 'local'

  DateTime get dataEvento =>
      DateTime.tryParse(data) ?? DateTime.now().add(const Duration(days: 30));

  /// Dias restantes até o dia (0 = é hoje; negativo = já passou).
  int get diasRestantes {
    final hoje = DateTime.now();
    final dia = DateTime(hoje.year, hoje.month, hoje.day);
    final alvo = DateTime(
      dataEvento.year,
      dataEvento.month,
      dataEvento.day,
    );
    return alvo.difference(dia).inDays;
  }

  int get totalTarefas =>
      etapas.fold(0, (acc, e) => acc + e.total);
  int get tarefasFeitas =>
      etapas.fold(0, (acc, e) => acc + e.feitasCount);
  double get progresso =>
      totalTarefas == 0 ? 0 : (tarefasFeitas / totalTarefas).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'tipo': tipo,
        'data': data,
        'resumo': resumo,
        'dicaChave': dicaChave,
        'etapas': [for (final e in etapas) e.toJson()],
        'fonte': fonte,
      };

  static Evento fromJson(Map<String, dynamic> j) => Evento(
        id: '${j['id'] ?? ''}',
        nome: '${j['nome'] ?? 'Evento'}',
        tipo: '${j['tipo'] ?? 'festa'}',
        data: '${j['data'] ?? ''}',
        resumo: '${j['resumo'] ?? ''}',
        dicaChave: '${j['dicaChave'] ?? ''}',
        etapas: (j['etapas'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(EtapaEvento.fromJson)
                .toList() ??
            const [],
        fonte: '${j['fonte'] ?? 'local'}',
      );

  Evento comEtapa(int indice, EtapaEvento etapa) {
    if (indice < 0 || indice >= etapas.length) return this;
    final novas = [for (var i = 0; i < etapas.length; i++)
      i == indice ? etapa : etapas[i]];
    return Evento(
      id: id,
      nome: nome,
      tipo: tipo,
      data: data,
      resumo: resumo,
      dicaChave: dicaChave,
      etapas: novas,
      fonte: fonte,
    );
  }
}

class EventoStore extends ChangeNotifier {
  EventoStore();

  static const _prefsKey = 'aurastyle-evento-v1';

  /// Tipos suportados — o plano local muda de forma por tipo.
  static const tipos = <String, String>{
    'casamento': 'Casamento',
    'entrevista': 'Entrevista / trabalho',
    'festa': 'Festa',
    'encontro': 'Encontro',
    'formatura': 'Formatura',
    'viagem': 'Viagem / férias',
  };

  Evento? _evento;
  bool _loaded = false;
  bool _gerando = false;
  String? _erro;

  Evento? get evento => _evento;
  bool get loaded => _loaded;
  bool get gerando => _gerando;
  String? get erro => _erro;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw);
        if (map is Map<String, dynamic>) _evento = Evento.fromJson(map);
      } catch (_) {
        _evento = null;
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistir() async {
    final e = _evento;
    final prefs = await SharedPreferences.getInstance();
    if (e == null) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setString(_prefsKey, jsonEncode(e.toJson()));
    }
  }

  static String _dataKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Cria o evento e traça o plano. Devolve o evento (null = falhou).
  Future<Evento?> criar({
    required String nome,
    required String tipo,
    required DateTime data,
    required Map<String, dynamic> perfil,
  }) async {
    _gerando = true;
    _erro = null;
    notifyListeners();
    try {
      final semanas = data.difference(DateTime.now()).inDays;
      final plano = await _gerarPlano(
        nome: nome,
        tipo: tipo,
        dias: semanas,
        perfil: perfil,
      );
      _evento = Evento(
        id: DateTime.now().toIso8601String(),
        nome: nome.trim().isEmpty ? tipos[tipo] ?? 'Evento' : nome.trim(),
        tipo: tipo,
        data: _dataKey(data),
        resumo: plano.resumo,
        dicaChave: plano.dicaChave,
        etapas: plano.etapas,
        fonte: plano.fonte,
      );
      await _persistir();
      return _evento;
    } catch (_) {
      _erro = 'Não consegui traçar o plano agora. Tenta outra vez.';
      return null;
    } finally {
      _gerando = false;
      notifyListeners();
    }
  }

  Future<void> cancelar() async {
    _evento = null;
    await _persistir();
    notifyListeners();
  }

  /// Liga/desliga uma tarefa. Cada tarefa paga +8 XP.
  Future<void> alternarTarefa(int etapa, int tarefa) async {
    final e = _evento;
    if (e == null || etapa < 0 || etapa >= e.etapas.length) return;
    final et = e.etapas[etapa];
    if (tarefa < 0 || tarefa >= et.total) return;
    final novo = et.comTarefaFeita(tarefa, !et.feitas[tarefa]);
    _evento = e.comEtapa(etapa, novo);
    await _persistir();
    notifyListeners();
  }

  // ── Geração do plano ──────────────────────────────────────────────────────

  Future<
      ({
        String resumo,
        String dicaChave,
        List<EtapaEvento> etapas,
        String fonte,
      })>
      _gerarPlano({
    required String nome,
    required String tipo,
    required int dias,
    required Map<String, dynamic> perfil,
  }) async {
    final semanas = (dias / 7).floor().clamp(1, 8);

    // ── Camada 1 · Groq direto ────────────────────────────────────────────────
    if (AuraSecrets.temGroq) {
      final json = await GroqAi.I.chat(
        system: 'És a Aura, consultora de imagem. Traças um PLANO DE '
            'PREPARAÇÃO semana a semana até "$nome" (${tipos[tipo] ?? tipo}), '
            'em português. Cobre pele, cabelo, roupa e acabamento — coerente '
            'com o perfil. Responde SÓ JSON:\n'
            '{"resumo":"<o plano numa frase>","dicaChave":"<o que mais pesa '
            'para brilhar no dia>","etapas":[{"titulo":"Semana 1 · <foco>",'
            '"foco":"<1 frase>","tarefas":["<ação concreta>"]}]} '
            'ÚLTIMA etapa = "Dia do evento" (preparação do dia).',
        turns: [
          {
            'role': 'user',
            'content': 'Evento: $nome (${tipos[tipo] ?? tipo}) daqui a $dias '
                'dias (~$semanas semanas). Perfil: ${jsonEncode(perfil)}. '
                'Gera $semanas etapas.',
          },
        ],
        temperature: 0.7,
        maxTokens: 900,
        json: true,
      );
      final mapa = GroqAi.I.extrairJson(json);
      if (mapa != null) {
        final etapas = <EtapaEvento>[
          for (final e in (mapa['etapas'] as List? ?? const []))
            if (e is Map) _etapaDe(e),
        ].where((e) => e.total > 0).toList();
        if (etapas.length >= 2) {
          return (
            resumo: '${mapa['resumo'] ?? ''}'.trim(),
            dicaChave: '${mapa['dicaChave'] ?? ''}'.trim(),
            etapas: etapas,
            fonte: 'groq',
          );
        }
      }
    }

    // ── Camada 2 · Plano local por tipo (sempre disponível) ──────────────────
    final local = _planoLocal(tipo: tipo, semanas: semanas);
    return local;
  }

  EtapaEvento _etapaDe(Map e) {
    final tarefas = (e['tarefas'] as List?)
            ?.map((t) => '$t'.trim())
            .where((t) => t.isNotEmpty)
            .take(5)
            .toList() ??
        const [];
    return EtapaEvento(
      titulo: '${e['titulo'] ?? 'Semana'}'.trim(),
      foco: '${e['foco'] ?? ''}'.trim(),
      tarefas: tarefas,
      feitas: List<bool>.filled(tarefas.length, false),
    );
  }

  ({
    String resumo,
    String dicaChave,
    List<EtapaEvento> etapas,
    String fonte,
  }) _planoLocal({required String tipo, required int semanas}) {
    // Focos por tipo — a forma muda, a estrutura é sempre progressiva.
    final (String pele, String cabelo, String roupa, String dia) =
        switch (tipo) {
          'casamento' => (
              'pele luminosa e uniforme',
              'corte e barba a definir o rosto',
              'fato/look ajustado na alfaiataria',
              'pele hidratada, cabelo marcado e sapatos polidos'
            ),
          'entrevista' => (
              'descanso visível: sono, água e pele limpa',
              'corte curto e definido — cuidado sem exagero',
              'look sóbrio e passado, calçado impecável',
              'chegar 15 min antes, respirar e sorrir'
            ),
          'encontro' => (
              'pele fresca e hálito cuidado',
              'cabelo com movimento e definição',
              'uma peça de assinatura da tua paleta',
              'confiança: postura aberta e sorriso fácil'
            ),
          'formatura' => (
              'pele tratada sem experimentar produtos novos',
              'corte com 5+ dias de antecedência (assenta melhor)',
              'traje medido com sapatos incluídos',
              'retques finais: unhas, cheiro e energia'
            ),
          'viagem' => (
              'pele preparada para o clima do destino',
              'corte prático que aguente a viagem',
              'cápsula de peças que combinam entre si',
              'kit de manutenção na bagagem de mão'
            ),
          _ => (
              'pele descansada e luminosa',
              'corte afiado 3-7 dias antes',
              'look testado ao espelho inteiro, sapatos incluídos',
              'hidratação, cheiro bom e presença'
            ),
        };

    final etapas = <EtapaEvento>[];
    for (var s = 1; s <= semanas; s++) {
      final primeira = s == 1;
      final media = s > 1 && s < semanas;
      etapas.add(
        EtapaEvento(
          titulo: semanas == 1
              ? 'Semana do evento'
              : 'Semana $s de $semanas',
          foco: primeira
              ? 'Fundação: $pele. O que plantas agora aparece no dia.'
              : media
                  ? 'Progresso: $cabelo. Ajustes com tempo de assentar.'
                  : 'Semana final: $roupa. Nada de decisões de última hora.',
          tarefas: [
            if (primeira) ...[
              'Ritual de pele diário marcado no Ritual de Hoje (sem falhar '
                  'um dia)',
              'Agendar corte/barba para a semana $semanas - 1',
              'Escolher e provar o look principal — fotografar combinações',
            ],
            if (media) ...[
              'Manter o ritual de pele sem pular (a constância é o segredo)',
              'Ajustar o look na alfaiataria/loja se algo não assenta',
              'Dormir 7-8h: o descanso paga mais que qualquer produto',
            ],
            if (s == semanas) ...[
              'Corte/barba final — e nada de experimentos depois disto',
              'Preparar o dia: $dia',
              'Fazer o check da foto: roupa, sapatos, acessórios num só sítio',
            ],
          ],
        ),
      );
    }
    return (
      resumo: 'Plano progressivo: fundação ($pele), progresso ($cabelo) e '
          'acabamento ($roupa).',
      dicaChave: 'O que mais pesa no dia é constância — pele e descanso '
          'não se compram na véspera.',
      etapas: etapas,
      fonte: 'local',
    );
  }
}
