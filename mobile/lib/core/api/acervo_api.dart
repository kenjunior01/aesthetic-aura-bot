/// acervo_api.dart — galeria Acervo (The Met) DIRETO do telemóvel + rota
/// /api/acervo partilhada como 2ª camada.
///
/// Resiliência em 3 camadas no cliente:
///  1. chamada VIVA ao Met collectionAPI (grátis, sem chave, UA de navegador);
///  2. rota Next.js /api/acervo (o MESMO backend do web);
///  3. reserva embutida (kMetReserva) — a galeria nunca amanhece vazia.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../data/met_reserva.dart';
import 'api_client.dart';

class MetItem {
  const MetItem({
    required this.objectID,
    required this.title,
    required this.artist,
    required this.date,
    required this.culture,
    required this.medium,
    required this.department,
    required this.image,
    required this.objectURL,
  });

  final int objectID;
  final String title;
  final String artist;
  final String date;
  final String culture;
  final String medium;
  final String department;
  final String image;
  final String objectURL;

  factory MetItem.fromJson(Map<String, dynamic> j) => MetItem(
    objectID: (j['objectID'] as num?)?.toInt() ?? 0,
    title: (j['title'] as String?) ?? 'Sem título',
    artist: (j['artist'] as String?) ?? 'Anónimo',
    date: (j['date'] as String?) ?? '',
    culture: (j['culture'] as String?) ?? '',
    medium: (j['medium'] as String?) ?? '',
    department: (j['department'] as String?) ?? '',
    image: (j['image'] as String?) ?? '',
    objectURL: (j['objectURL'] as String?) ?? '',
  );
}

class AcervoResult {
  const AcervoResult({required this.items, required this.source});
  final List<MetItem> items;
  final String source; // 'met' | 'reserva'
}

class AcervoApi {
  AcervoApi._();
  static final AcervoApi I = AcervoApi._();

  final http.Client _http = http.Client();
  final Map<String, AcervoResult> _cacheVivo = {};

  static const List<String> themes = [
    'vestidos',
    'padroes',
    'joalharia',
    'armaduras',
    'retratos',
    'fotografias',
  ];

  static const Map<String, String> themeLabel = {
    'vestidos': 'Vestidos',
    'padroes': 'Padrões',
    'joalharia': 'Joalharia',
    'armaduras': 'Armaduras',
    'retratos': 'Retratos',
    'fotografias': 'Fotografia',
  };

  /// Termos EN de busca no Met + departamento (mesma curadoria do web).
  static const Map<String, String> _temaTermo = {
    'vestidos': 'dress',
    'padroes': 'textile',
    'joalharia': 'jewelry',
    'armaduras': 'armor',
    'retratos': 'portrait',
    'fotografias': 'photograph',
  };
  static const Map<String, int> _temaDepto = {
    'vestidos': 8,
    'padroes': 8,
    'joalharia': 8,
    'armaduras': 4,
    'retratos': 11,
    'fotografias': 19,
  };

  /// Busca obras de um tema. count limitado a 6-24 pela rota.
  Future<AcervoResult> fetchTheme(String theme, {int count = 12}) async {
    // 1. DIRETO do telemóvel — Met collectionAPI (grátis, sem chave).
    final termo = _temaTermo[theme] ?? 'fashion';
    final depto = _temaDepto[theme];
    final direto = await _pipelineMet(
      termo,
      depto,
      count,
      cacheKey: '$theme::$count',
    );
    if (direto != null && direto.items.isNotEmpty) return direto;

    // 2. Backend partilhado (cache 6h no servidor).
    try {
      final data = await ApiClient.I.get(
        '/api/acervo',
        query: {'theme': theme, 'count': '$count'},
      );
      final List raw =
          (data is Map ? data['items'] : data) as List? ?? const [];
      final items = raw
          .whereType<Map<String, dynamic>>()
          .map(MetItem.fromJson)
          .where((m) => m.image.isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        final src = data is Map ? '${data['source'] ?? 'met'}' : 'met';
        return AcervoResult(items: items, source: src);
      }
    } catch (_) {
      // cai para a reserva
    }

    // 3. Reserva embutida — mesma filosofia do web.
    return AcervoResult(
      items: kMetReserva[theme] ?? const [],
      source: 'reserva',
    );
  }

  // ── Camada 1: Met direto ────────────────────────────────────────────────────
  static const _metBase = 'https://collectionapi.metmuseum.org/public/collection/v1';

  /// BUSCA LIVRE por texto no acervo inteiro do Met — 470 mil obras
  /// respondendo à palavra que o utilizador escreveu. Sem departamento:
  /// a palavra manda. Reserva como último recurso.
  Future<AcervoResult> buscaTexto(String query, {int count = 12}) async {
    final q = query.trim();
    if (q.isEmpty) return fetchTheme(themes.first, count: count);
    final direto = await _pipelineMet(
      q,
      null,
      count,
      cacheKey: 'livre::$q::$count',
    );
    if (direto != null && direto.items.isNotEmpty) return direto;
    return AcervoResult(
      items: kMetReserva['vestidos'] ?? const [],
      source: 'reserva',
    );
  }

  /// Pipeline comum: search por termo (+depto opcional) → objetos com
  /// imagem de domínio público. Cache por chave; null se o vivo falhar.
  Future<AcervoResult?> _pipelineMet(
    String termo,
    int? depto,
    int count, {
    required String cacheKey,
  }) async {
    final hit = _cacheVivo[cacheKey];
    if (hit != null && hit.items.isNotEmpty) return hit;
    try {
      final searchUri = Uri.parse('$_metBase/search').replace(queryParameters: {
        'q': termo,
        'hasImages': 'true',
        if (depto != null) 'departmentId': '$depto',
      });
      final searchRes = await _http
          .get(searchUri, headers: {'User-Agent': AuraConfig.browserUA})
          .timeout(const Duration(seconds: 9));
      if (searchRes.statusCode != 200) return null;
      final ids = ((jsonDecode(searchRes.body)['objectIDs'] as List?) ?? const [])
          .whereType<num>()
          .map((e) => e.toInt())
          .take(30)
          .toList();
      if (ids.isEmpty) return null;

      // objectIDs → objetos com imagem de domínio público (concorrência 5).
      final items = <MetItem>[];
      for (var i = 0; i < ids.length && items.length < count; i += 5) {
        final lote = ids.skip(i).take(5).toList();
        final objetos = await Future.wait(
          lote.map((id) => _objetoMet(id)),
        );
        for (final o in objetos) {
          if (o != null && items.length < count) items.add(o);
        }
      }
      if (items.isEmpty) return null;
      final result = AcervoResult(items: items, source: 'met');
      _cacheVivo[cacheKey] = result;
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<MetItem?> _objetoMet(int id) async {
    try {
      final res = await _http
          .get(
            Uri.parse('$_metBase/objects/$id'),
            headers: {'User-Agent': AuraConfig.browserUA},
          )
          .timeout(const Duration(seconds: 9));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body);
      if (j is! Map) return null;
      final imagem = '${j['primaryImage'] ?? ''}';
      final dominio = j['isPublicDomain'] == true;
      if (imagem.isEmpty || !dominio) return null;
      return MetItem(
        objectID: id,
        title: (j['title'] as String?) ?? 'Sem título',
        artist: (j['artistDisplayName'] as String?)?.isEmpty == false
            ? j['artistDisplayName'] as String
            : 'Anónimo',
        date: (j['objectDate'] as String?) ?? '',
        culture: (j['culture'] as String?) ?? '',
        medium: (j['medium'] as String?) ?? '',
        department: (j['department'] as String?) ?? '',
        image: imagem,
        objectURL: (j['objectURL'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}
