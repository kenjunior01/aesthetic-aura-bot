/// guarda_roupa_store.dart — o Guarda-Roupa Vivo: as tuas peças REAIS,
/// fotografadas e catalogadas. Cada peça guarda a miniatura, a categoria
/// (slot do look), a cor dominante, as ocasiões e a estação.
///
/// O Look de Hoje nasce daqui: um motor de harmonia cromática combina as
/// tuas próprias peças em pares análogos/monocromáticos/complementares,
/// determinístico por dia — o mesmo dia devolve o mesmo look, o botão
/// "trocar combinação" avança para a alternativa seguinte.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:shared_preferences/shared_preferences.dart';

/// Slots do look — cada categoria de peça cabe num deles.
class PecaCategoria {
  PecaCategoria._();

  static const topo = 'topo';
  static const base = 'base';
  static const pes = 'pes';
  static const extra = 'extra';
  static const acessorio = 'acessorio';

  static const all = <String>[topo, base, pes, extra, acessorio];

  static const Map<String, String> label = {
    topo: 'Topo',
    base: 'Base',
    pes: 'Calçado',
    extra: 'Camada',
    acessorio: 'Acessório',
  };

  static const Map<String, IconData> icon = {
    topo: Icons.checkroom,
    base: Icons.square_foot,
    pes: Icons.ice_skating,
    extra: Icons.layers,
    acessorio: Icons.diamond_outlined,
  };

  /// Normaliza o que a IA (ou o dedo do utilizador) escolher.
  static String normalizar(String? bruto) {
    final v = (bruto ?? '').trim().toLowerCase();
    if (v.contains('cal') || v.contains('jeans') || v.contains('pant') ||
        v.contains('saia') || v.contains('short')) {
      return base;
    }
    if (v.contains('sap') || v.contains('ténis') || v.contains('tenis') ||
        v.contains('bot') || v.contains('sand') || v.contains('shoe') ||
        v.contains('sneak')) {
      return pes;
    }
    if (v.contains('casaco') || v.contains('blazer') || v.contains('sobr') ||
        v.contains('colete') || v.contains('jacket') || v.contains('coat') ||
        v.contains('hoodie') || v.contains('camada')) {
      return extra;
    }
    if (v.contains('gorro') || v.contains('boné') || v.contains('bone') ||
        v.contains('lenço') || v.contains('lenco') || v.contains('cinto') ||
        v.contains('colar') || v.contains('acess') || v.contains('óculos') ||
        v.contains('oculos') || v.contains('relógio') ||
        v.contains('relogio') || v.contains('bag') || v.contains('bols')) {
      return acessorio;
    }
    if (v.contains('camisa') || v.contains('shirt') || v.contains('top') ||
        v.contains('blusa') || v.contains('camisola') ||
        v.contains('sweat') || v.contains('polo') || v.contains('t-shirt') ||
        v.contains('tshirt')) {
      return topo;
    }
    return '';
  }
}

/// Uma peça real do guarda-roupa do utilizador.
class Peca {
  const Peca({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.corHex,
    this.corNome = '',
    this.ocasioes = const [],
    this.estacao = 'todo o ano',
    this.fonte = 'ai',
    this.thumb,
    required this.criadoEm,
  });

  final String id;
  final String nome;
  final String categoria; // PecaCategoria.*
  final String corHex; // '#RRGGBB'
  final String corNome;
  final List<String> ocasioes;
  final String estacao; // 'todo o ano' | 'verao' | 'inverno' | ...
  final String fonte; // 'ai' | 'manual'
  final String? thumb; // JPEG base64 (sem prefixo)
  final String criadoEm; // ISO

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'categoria': categoria,
    'corHex': corHex,
    'corNome': corNome,
    'ocasioes': ocasioes,
    'estacao': estacao,
    'fonte': fonte,
    'thumb': thumb,
    'criadoEm': criadoEm,
  };

  static Peca fromJson(Map<String, dynamic> j) => Peca(
    id: '${j['id'] ?? ''}',
    nome: '${j['nome'] ?? 'Peça'}',
    categoria: '${j['categoria'] ?? ''}',
    corHex: '${j['corHex'] ?? '#8A94A6'}',
    corNome: '${j['corNome'] ?? ''}',
    ocasioes:
        (j['ocasioes'] as List?)?.map((e) => '$e').toList() ?? const [],
    estacao: '${j['estacao'] ?? 'todo o ano'}',
    fonte: '${j['fonte'] ?? 'ai'}',
    thumb: j['thumb'] as String?,
    criadoEm: '${j['criadoEm'] ?? ''}',
  );
}

/// Um look completo montado pelo motor de harmonia.
class LookMontado {
  const LookMontado({
    required this.pecas,
    required this.conceito,
    required this.harmonia,
    required this.attempt,
  });

  final List<Peca> pecas; // topo, base, calçado, (camada)
  final String conceito; // 'Análogo Sereno', 'Monocromático'…
  final double harmonia; // 0..1
  final int attempt;
}

/// Motor de harmonia cromática — como duas cores conversam.
double harmoniaEntreCores(String hexA, String hexB) {
  final a = _hexParaCor(hexA);
  final b = _hexParaCor(hexB);
  if (a == null || b == null) return 0.6;
  final hslA = HSLColor.fromColor(a);
  final hslB = HSLColor.fromColor(b);
  final neutraA =
      hslA.saturation < 0.14 || hslA.lightness < 0.09 || hslA.lightness > 0.92;
  final neutraB =
      hslB.saturation < 0.14 || hslB.lightness < 0.09 || hslB.lightness > 0.92;
  if (neutraA && neutraB) return 0.85; // tonal sobre tonal
  if (neutraA || neutraB) return 0.84; // o neutro ancora o vivo
  var d = (hslA.hue - hslB.hue).abs();
  if (d > 180) d = 360 - d;
  if (d < 14) return 0.87; // monocromático
  if (d < 38) return 0.93; // análogo — o mais elegante
  if (d >= 148) return 0.89; // complementar controlado
  return 0.55 + (1 - d / 150) * 0.08; // vizinhança tensa
}

Color? _hexParaCor(String hex) {
  final limpo = hex.replaceAll('#', '').trim();
  if (limpo.length != 6) return null;
  final v = int.tryParse(limpo, radix: 16);
  if (v == null) return null;
  return Color(0xFF000000 | v);
}

Color? corDaPeca(Peca p) => _hexParaCor(p.corHex);

class GuardaRoupaStore extends ChangeNotifier {
  GuardaRoupaStore();

  static const _prefsKey = 'aurastyle-guarda-roupa-v1';
  static const _lookDiaKey = 'aurastyle-look-usado';
  static const _maxPecas = 40;
  static const xpPorPeca = 5;
  static const xpPorLook = 15;

  List<Peca> _pecas = const [];
  bool _loaded = false;
  String _lookUsadoDate = '';

  /// Da mais recente para a mais antiga.
  List<Peca> get pecas => List.unmodifiable(_pecas);
  bool get loaded => _loaded;

  bool get lookUsadoHoje => _lookUsadoDate == _todayKey();

  bool get temTopo => _pecas.any((p) => p.categoria == PecaCategoria.topo);
  bool get temBase => _pecas.any((p) => p.categoria == PecaCategoria.base);

  /// Pode montar um look? Precisa de topo + base no mínimo.
  bool get podeMontarLook => temTopo && temBase;

  int countCategoria(String c) =>
      _pecas.where((p) => p.categoria == c).length;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _pecas = [
          for (final e in list)
            if (e is Map<String, dynamic>) Peca.fromJson(e),
        ];
      } catch (_) {
        _pecas = const [];
      }
    }
    _lookUsadoDate = prefs.getString('$_lookDiaKey-date') ?? '';
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final p in _pecas) p.toJson()]),
    );
  }

  void adicionar(Peca peca) {
    _pecas = [peca, ..._pecas].take(_maxPecas).toList();
    _persistir();
    notifyListeners();
  }

  void remover(String id) {
    _pecas = _pecas.where((p) => p.id != id).toList();
    _persistir();
    notifyListeners();
  }

  // ── Look de Hoje ─────────────────────────────────────────────────────────

  /// Monta o look do dia. Determinístico: mesmo dia + mesmo attempt =
  /// mesmo look. O attempt avança com "trocar combinação".
  LookMontado? montarLook({int attempt = 0}) {
    if (!podeMontarLook) return null;

    final topos = _pecas.where((p) => p.categoria == PecaCategoria.topo);
    final bases = _pecas.where((p) => p.categoria == PecaCategoria.base);
    final pes = _pecas.where((p) => p.categoria == PecaCategoria.pes);
    final extras = _pecas.where((p) => p.categoria == PecaCategoria.extra);

    // Ranqueia todos os pares topo×base pela harmonia com tie-break
    // determinístico (dia + attempt), para variar dentro dos melhores.
    final hoje = _todayKey();
    final mes = DateTime.now().month;
    final pares = <({Peca topo, Peca base, double score})>[];
    for (final t in topos) {
      for (final b in bases) {
        var score = harmoniaEntreCores(t.corHex, b.corHex);
        // Estação: peça fora de estação perde pontos.
        if (!_estacaoOk(t.estacao, mes)) score -= 0.12;
        if (!_estacaoOk(b.estacao, mes)) score -= 0.12;
        pares.add((topo: t, base: b, score: score));
      }
    }
    pares.sort((x, y) {
      final cmp = y.score.compareTo(x.score);
      if (cmp != 0) return cmp;
      final hx = '${x.topo.id}${x.base.id}$hoje$attempt'.hashCode;
      final hy = '${y.topo.id}${y.base.id}$hoje$attempt'.hashCode;
      return hx.compareTo(hy);
    });

    // Escolhe entre os melhores (respeita o attempt como rotação).
    final janela = pares.take(6).toList();
    if (janela.isEmpty) return null;
    final par = janela[attempt % janela.length];

    // Calçado: o que conversa melhor com o par.
    Peca? calcado;
    double melhor = -1;
    for (final p in pes) {
      final s = (harmoniaEntreCores(p.corHex, par.topo.corHex) +
              harmoniaEntreCores(p.corHex, par.base.corHex)) /
          2;
      if (s > melhor) {
        melhor = s;
        calcado = p;
      }
    }

    // Camada: só se conversa bem (>= 0.8) com o look.
    Peca? camada;
    if (extras.isNotEmpty) {
      for (final p in extras) {
        final s = (harmoniaEntreCores(p.corHex, par.topo.corHex) +
                harmoniaEntreCores(p.corHex, par.base.corHex)) /
            2;
        if (s >= 0.8 && (camada == null || s > melhor)) camada = p;
      }
    }

    final pecasLook = <Peca>[
      par.topo,
      par.base,
      ?calcado,
      ?camada,
    ];
    final harmoniaMedia =
        pecasLook.isEmpty ? par.score : par.score.clamp(0.0, 1.0);

    return LookMontado(
      pecas: pecasLook,
      conceito: _conceito(par.topo.corHex, par.base.corHex),
      harmonia: harmoniaMedia,
      attempt: attempt,
    );
  }

  /// Confirma "vou usar este look" — +15 XP uma vez por dia.
  /// A partir do 2.º look do dia não volta a dar XP (o botão fica "em uso").
  bool usarLook() {
    if (lookUsadoHoje) return false;
    _lookUsadoDate = _todayKey();
    SharedPreferences.getInstance().then(
      (p) => p.setString('$_lookDiaKey-date', _lookUsadoDate),
    );
    notifyListeners();
    return true;
  }

  String _conceito(String hexA, String hexB) {
    final a = _hexParaCor(hexA);
    final b = _hexParaCor(hexB);
    if (a == null || b == null) return 'Contraste Urbano';
    final hslA = HSLColor.fromColor(a);
    final hslB = HSLColor.fromColor(b);
    final neutraA = hslA.saturation < 0.14 ||
        hslA.lightness < 0.09 ||
        hslA.lightness > 0.92;
    final neutraB = hslB.saturation < 0.14 ||
        hslB.lightness < 0.09 ||
        hslB.lightness > 0.92;
    if (neutraA && neutraB) return 'Total Neutral';
    if (neutraA || neutraB) return 'Neutro de Base';
    var d = (hslA.hue - hslB.hue).abs();
    if (d > 180) d = 360 - d;
    if (d < 14) return 'Monocromático';
    if (d < 38) return 'Análogo Sereno';
    if (d >= 148) return 'Complementar';
    return 'Contraste Urbano';
  }

  bool _estacaoOk(String estacao, int mes) {
    final e = estacao.toLowerCase();
    if (e.contains('todo')) return true;
    // Hemisfério sul por defeito (base de utilizadores pt) — invernos 6-8.
    final verao = mes >= 12 || mes <= 2;
    final inverno = mes >= 6 && mes <= 8;
    final meia = mes == 3 || mes == 4 || mes == 5 || mes == 9 ||
        mes == 10 || mes == 11;
    if (e.contains('verao') || e.contains('verão')) return verao || meia;
    if (e.contains('inverno')) return inverno || meia;
    return true;
  }

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  // ── Imagem: miniatura + cor média (pure Dart, sem NDK) ──────────────────

  /// Processa a foto da peça fora da UI thread (isolate):
  /// devolve (jpegBase64 420px, cor média '#RRGGBB').
  static Future<(String, String)> processarFoto(Uint8List bytes) =>
      compute(_processar, bytes);

  static (String, String) _processar(Uint8List bytes) {
    try {
      final decodificada = imglib.decodeImage(bytes);
      if (decodificada == null) return ('', '#8A94A6');

      // Cor média — amostra 1 em cada 6 px do original.
      var r = 0, g = 0, b = 0, n = 0;
      for (var y = 0; y < decodificada.height; y += 6) {
        for (var x = 0; x < decodificada.width; x += 6) {
          final px = decodificada.getPixel(x, y);
          r += px.r.toInt();
          g += px.g.toInt();
          b += px.b.toInt();
          n++;
        }
      }
      if (n == 0) n = 1;
      String canal(int v) =>
          v.clamp(0, 255).toRadixString(16).padLeft(2, '0').toUpperCase();
      final cor =
          '#${canal((r / n).round())}${canal((g / n).round())}${canal((b / n).round())}';

      // Miniatura JPEG 420px — leve para o SharedPreferences, nítida na grelha.
      final alvo = decodificada.width > decodificada.height
          ? imglib.copyResize(decodificada, width: 420)
          : imglib.copyResize(decodificada, height: 420);
      final jpg = imglib.encodeJpg(alvo, quality: 72);
      return (base64Encode(jpg), cor);
    } catch (_) {
      return ('', '#8A94A6');
    }
  }
}
