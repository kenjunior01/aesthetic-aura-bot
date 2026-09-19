/// jornada_store.dart — a JORNADA DO AUGE: a rota real da tua evolução.
///
/// A partir de TUDO o que deste à plataforma (nome, idade, corpo, pele,
/// cabelo, prioridades, orçamento), a IA traça:
///  • o período estimado para SENTIR efeitos e VER mudanças
///  • as FASES até o auge (com semanas, foco, ações e imagem real)
///  • os PONTOS DE CONTROLO (check-ins) alinhados com esses períodos
///
/// Em cada check-in partilhas uma foto: a IA compara, diz se o plano está
/// a andar, se estás a seguir — e o plano e o período atualizam-se.
/// Persistido localmente (SharedPreferences), versão subiu com cada revisão.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/jornada_api.dart';

/// Uma FASE da jornada — um capítulo com semanas, foco e imagem real.
class FaseJornada {
  const FaseJornada({
    required this.nome,
    required this.semanaInicio,
    required this.semanaFim,
    required this.titulo,
    required this.foco,
    required this.acoes,
    required this.visivel,
    required this.imagemQuery,
    this.imagemUrl,
  });

  final String nome; // "Fundação"
  final int semanaInicio; // 1
  final int semanaFim; // 4
  final String titulo; // "Preparar o terreno"
  final String foco; // 1-2 frases sobre o capítulo
  final List<String> acoes; // o que fazer nesta fase
  final String visivel; // o que vais começar a notar
  final String imagemQuery; // busca em inglês nos bancos de imagem

  /// URL da imagem real carregada (cache após a 1ª busca).
  final String? imagemUrl;

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'semanaInicio': semanaInicio,
    'semanaFim': semanaFim,
    'titulo': titulo,
    'foco': foco,
    'acoes': acoes,
    'visivel': visivel,
    'imagemQuery': imagemQuery,
    if (imagemUrl != null) 'imagemUrl': imagemUrl,
  };

  static FaseJornada fromJson(Map<String, dynamic> j) => FaseJornada(
    nome: '${j['nome'] ?? 'Fase'}',
    semanaInicio: (j['semanaInicio'] as num?)?.toInt() ?? 1,
    semanaFim: (j['semanaFim'] as num?)?.toInt() ?? 4,
    titulo: '${j['titulo'] ?? ''}',
    foco: '${j['foco'] ?? ''}',
    acoes: (j['acoes'] as List?)?.map((e) => '$e').toList() ?? const <String>[],
    visivel: '${j['visivel'] ?? ''}',
    imagemQuery: '${j['imagemQuery'] ?? 'healthy skin portrait'}',
    imagemUrl: j['imagemUrl'] as String?,
  );

  FaseJornada comImagem(String url) => FaseJornada(
    nome: nome,
    semanaInicio: semanaInicio,
    semanaFim: semanaFim,
    titulo: titulo,
    foco: foco,
    acoes: acoes,
    visivel: visivel,
    imagemQuery: imagemQuery,
    imagemUrl: url,
  );
}

/// Um PONTO DE CONTROLO — a foto que partilhaste e o que a IA leu.
class CheckinJornada {
  const CheckinJornada({
    required this.id,
    required this.data,
    required this.semana,
    required this.aderencia,
    required this.veredito,
    required this.mensagem,
    required this.mudancas,
    required this.ajustes,
    this.fotoThumb,
    this.revisouPlano = false,
  });

  final String id; // ISO da hora
  final String data; // '2026-09-06'
  final int semana; // semana da jornada em que ocorreu
  final String? fotoThumb; // miniatura base64 (sem prefixo)
  final int aderencia; // 0-100 — sinal de que o plano está a andar
  final String veredito; // 'no_trilho' | 'ajustar'
  final String mensagem; // leitura honesta da IA
  final List<String> mudancas; // o que já se nota
  final List<String> ajustes; // o que afinar
  final bool revisouPlano; // o plano foi recalculado depois deste registo

  bool get noTrilho => veredito != 'ajustar';

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data,
    'semana': semana,
    'aderencia': aderencia,
    'veredito': veredito,
    'mensagem': mensagem,
    'mudancas': mudancas,
    'ajustes': ajustes,
    'fotoThumb': fotoThumb,
    'revisouPlano': revisouPlano,
  };

  static CheckinJornada fromJson(Map<String, dynamic> j) => CheckinJornada(
    id: '${j['id'] ?? ''}',
    data: '${j['data'] ?? ''}',
    semana: (j['semana'] as num?)?.toInt() ?? 1,
    aderencia: (j['aderencia'] as num?)?.toInt() ?? 50,
    veredito: '${j['veredito'] ?? 'no_trilho'}',
    mensagem: '${j['mensagem'] ?? ''}',
    mudancas: (j['mudancas'] as List?)?.map((e) => '$e').toList() ?? const [],
    ajustes: (j['ajustes'] as List?)?.map((e) => '$e').toList() ?? const [],
    fotoThumb: j['fotoThumb'] as String?,
    revisouPlano: j['revisouPlano'] == true,
  );
}

/// A JORNADA completa — rota, ritmo e pontos de controlo.
class Jornada {
  const Jornada({
    required this.criada,
    required this.atualizada,
    required this.versao,
    required this.totalSemanas,
    required this.efeitosSemanas,
    required this.mudancasSemanas,
    required this.resumo,
    required this.dicaChave,
    required this.fases,
    this.checkins = const [],
    this.fonte = 'local',
  });

  final String criada; // ISO date '2026-09-06'
  final String atualizada; // ISO date da última revisão
  final int versao; // 1 = traçada; 2+ = revista após check-ins
  final int totalSemanas; // semanas até o auge
  final int efeitosSemanas; // quando vais SENTIR os primeiros efeitos
  final int mudancasSemanas; // quando as mudanças ficam VISÍVEIS
  final String resumo; // o plano numa frase
  final String dicaChave; // o hábito que mais pesa
  final List<FaseJornada> fases;
  final List<CheckinJornada> checkins; // mais recente primeiro
  final String fonte; // 'groq' | 'local'

  Jornada comFases(
    List<FaseJornada> fases, {
    required String atualizada,
    int? versao,
    String? fonte,
    int? totalSemanas,
    int? efeitosSemanas,
    int? mudancasSemanas,
    String? resumo,
    String? dicaChave,
  }) => Jornada(
    criada: criada,
    atualizada: atualizada,
    versao: versao ?? this.versao,
    totalSemanas: totalSemanas ?? this.totalSemanas,
    efeitosSemanas: efeitosSemanas ?? this.efeitosSemanas,
    mudancasSemanas: mudancasSemanas ?? this.mudancasSemanas,
    resumo: resumo ?? this.resumo,
    dicaChave: dicaChave ?? this.dicaChave,
    fases: fases,
    checkins: checkins,
    fonte: fonte ?? this.fonte,
  );

  Jornada comCheckins(List<CheckinJornada> checkins) => Jornada(
    criada: criada,
    atualizada: atualizada,
    versao: versao,
    totalSemanas: totalSemanas,
    efeitosSemanas: efeitosSemanas,
    mudancasSemanas: mudancasSemanas,
    resumo: resumo,
    dicaChave: dicaChave,
    fases: fases,
    checkins: checkins,
    fonte: fonte,
  );

  Map<String, dynamic> toJson() => {
    'criada': criada,
    'atualizada': atualizada,
    'versao': versao,
    'totalSemanas': totalSemanas,
    'efeitosSemanas': efeitosSemanas,
    'mudancasSemanas': mudancasSemanas,
    'resumo': resumo,
    'dicaChave': dicaChave,
    'fases': [for (final f in fases) f.toJson()],
    'checkins': [for (final c in checkins) c.toJson()],
    'fonte': fonte,
  };

  static Jornada fromJson(Map<String, dynamic> j) => Jornada(
    criada: '${j['criada'] ?? ''}',
    atualizada: '${j['atualizada'] ?? j['criada'] ?? ''}',
    versao: (j['versao'] as num?)?.toInt() ?? 1,
    totalSemanas: (j['totalSemanas'] as num?)?.toInt() ?? 12,
    efeitosSemanas: (j['efeitosSemanas'] as num?)?.toInt() ?? 3,
    mudancasSemanas: (j['mudancasSemanas'] as num?)?.toInt() ?? 6,
    resumo: '${j['resumo'] ?? ''}',
    dicaChave: '${j['dicaChave'] ?? ''}',
    fases:
        (j['fases'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(FaseJornada.fromJson)
            .toList() ??
        const [],
    checkins:
        (j['checkins'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(CheckinJornada.fromJson)
            .toList() ??
        const [],
    fonte: '${j['fonte'] ?? 'local'}',
  );
}

class JornadaStore extends ChangeNotifier {
  JornadaStore();

  static const _prefsKey = 'aurastyle-jornada-v1';
  static const _maxCheckins = 12;

  Jornada? _jornada;
  bool _loaded = false;
  bool _gerando = false;
  String? _erro;

  Jornada? get jornada => _jornada;
  bool get loaded => _loaded;
  bool get gerando => _gerando;
  String? get erro => _erro;

  // ── Tempo de jornada ──────────────────────────────────────────────────────
  DateTime get _inicio {
    final j = _jornada;
    if (j == null || j.criada.isEmpty) return DateTime.now();
    return DateTime.tryParse(j.criada) ?? DateTime.now();
  }

  /// Semana atual da jornada (1-based).
  int get semanaAtual {
    final dias = DateTime.now().difference(_inicio).inDays;
    return (dias ~/ 7) + 1;
  }

  /// Progresso 0..1 até o auge.
  double get progresso {
    final j = _jornada;
    if (j == null || j.totalSemanas <= 0) return 0;
    final dias = DateTime.now().difference(_inicio).inDays;
    return (dias / (j.totalSemanas * 7)).clamp(0.0, 1.0);
  }

  /// Fase da semana dada (null se fora da rota).
  FaseJornada? faseDaSemana(int semana) {
    final j = _jornada;
    if (j == null) return null;
    for (final f in j.fases) {
      if (semana >= f.semanaInicio && semana <= f.semanaFim) return f;
    }
    if (j.fases.isNotEmpty && semana > j.totalSemanas) return j.fases.last;
    return null;
  }

  FaseJornada? get faseAtual => faseDaSemana(semanaAtual);

  // ── Pontos de controlo ────────────────────────────────────────────────────
  /// Intervalo entre check-ins: alinhado com o período de mudanças visíveis.
  int get intervaloCheckinSemanas {
    final j = _jornada;
    if (j == null) return 3;
    return (j.mudancasSemanas <= 2 ? 2 : j.mudancasSemanas).clamp(2, 6);
  }

  DateTime _dataProximoCheckin() {
    final j = _jornada!;
    if (j.checkins.isEmpty) {
      // O 1º ponto de controlo alinha com as primeiras mudanças visíveis.
      return _inicio.add(Duration(days: j.mudancasSemanas * 7));
    }
    final ultimo = DateTime.tryParse(j.checkins.first.id) ?? _inicio;
    return ultimo.add(Duration(days: intervaloCheckinSemanas * 7));
  }

  /// Dias até ao próximo check-in (negativo = está atrasado).
  int get diasParaCheckin {
    final j = _jornada;
    if (j == null) return 0;
    return _dataProximoCheckin().difference(DateTime.now()).inDays;
  }

  bool get checkinDue {
    final j = _jornada;
    if (j == null) return false;
    // Semana 0 conta como "ainda cedo" — nunca pedimos foto no 1º dia.
    return diasParaCheckin <= 0 && semanaAtual >= 1;
  }

  // ── Acções ────────────────────────────────────────────────────────────────
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw);
        if (map is Map<String, dynamic>) {
          _jornada = Jornada.fromJson(map);
        }
      } catch (_) {
        _jornada = null;
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistir() async {
    final j = _jornada;
    if (j == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(j.toJson()));
  }

  /// Traça a jornada a partir do perfil completo. Guarda e devolve.
  /// GARANTIA: devolve sempre uma jornada (IA → local determinística) —
  /// o onboarding nunca fica preso a um spinner infinito.
  Future<Jornada?> criarJornada(Map<String, dynamic> perfil) async {
    _gerando = true;
    _erro = null;
    notifyListeners();
    try {
      final j = await JornadaApi.I.gerarJornada(perfil);
      _jornada = j;
      await _persistir();
      return j;
    } catch (_) {
      // Última linha de defesa: a rota local determinística.
      try {
        final j = JornadaApi.I.jornadaLocal(perfil);
        _jornada = j;
        await _persistir();
        return j;
      } catch (e) {
        _erro = 'Não consegui traçar a rota agora. Tenta outra vez.';
        return null;
      }
    } finally {
      _gerando = false;
      notifyListeners();
    }
  }

  /// Regista um check-in com foto: a IA avalia e o registo fica na rota.
  Future<CheckinJornada?> registarCheckin({
    required Map<String, dynamic> perfil,
    required String imageBase64,
    required String? fotoThumb,
    String mimeType = 'image/jpeg',
  }) async {
    final j = _jornada;
    if (j == null) return null;
    _gerando = true;
    _erro = null;
    notifyListeners();
    try {
      final agora = DateTime.now();
      final semana = semanaAtual;
      final r = await JornadaApi.I.avaliarCheckin(
        perfil: perfil,
        jornada: j,
        imageBase64: imageBase64,
        mimeType: mimeType,
        semana: semana,
      );
      final c = CheckinJornada(
        id: agora.toIso8601String(),
        data: _dataKey(agora),
        semana: semana,
        aderencia: r.aderencia,
        veredito: r.veredito,
        mensagem: r.mensagem,
        mudancas: r.mudancas,
        ajustes: r.ajustes,
        fotoThumb: fotoThumb,
      );
      _jornada = j.comCheckins([c, ...j.checkins].take(_maxCheckins).toList());
      await _persistir();
      return c;
    } catch (_) {
      _erro = 'Não consegui ler a foto agora. Tenta outra vez.';
      return null;
    } finally {
      _gerando = false;
      notifyListeners();
    }
  }

  /// Revê o plano com base nos check-ins — o período e as fases atualizam-se.
  Future<Jornada?> revisarJornada(Map<String, dynamic> perfil) async {
    final j = _jornada;
    if (j == null) return null;
    _gerando = true;
    _erro = null;
    notifyListeners();
    try {
      final nova = await JornadaApi.I.revisarJornada(
        perfil: perfil,
        jornada: j,
        semanaAtual: semanaAtual,
      );
      // Marca o check-in mais recente como origem da revisão.
      final checkins = <CheckinJornada>[
        if (j.checkins.isNotEmpty)
          CheckinJornada(
            id: j.checkins.first.id,
            data: j.checkins.first.data,
            semana: j.checkins.first.semana,
            aderencia: j.checkins.first.aderencia,
            veredito: j.checkins.first.veredito,
            mensagem: j.checkins.first.mensagem,
            mudancas: j.checkins.first.mudancas,
            ajustes: j.checkins.first.ajustes,
            fotoThumb: j.checkins.first.fotoThumb,
            revisouPlano: true,
          ),
        ...j.checkins.skip(1),
      ];
      _jornada = nova.comCheckins(checkins);
      await _persistir();
      return nova;
    } catch (_) {
      _erro = 'Não consegui rever o plano agora. Tenta outra vez.';
      return null;
    } finally {
      _gerando = false;
      notifyListeners();
    }
  }

  /// Guarda a URL da imagem real de uma fase (cache para não voltar a buscar).
  Future<void> guardarImagemFase(int indice, String url) async {
    final j = _jornada;
    if (j == null || indice < 0 || indice >= j.fases.length) return;
    final f = j.fases[indice];
    if (f.imagemUrl == url) return;
    final fases = [
      for (var i = 0; i < j.fases.length; i++)
        i == indice ? j.fases[i].comImagem(url) : j.fases[i],
    ];
    _jornada = j.comFases(fases, atualizada: j.atualizada);
    await _persistir();
    notifyListeners();
  }

  void limpar() {
    _jornada = null;
    SharedPreferences.getInstance().then((p) => p.remove(_prefsKey));
    notifyListeners();
  }

  static String _dataKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}
