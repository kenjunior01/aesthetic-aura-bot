/// image_bank.dart — bancos de imagens REAIS direto do telemóvel.
///
/// DOIS bancos em paralelo, intercalados na mesma grelha:
///  • Pexels   (200 req/h) — fotografia de pessoas, luz e moda
///  • Unsplash (50 req/h)  — editorial e retrato de estúdio
///
/// Cadeia de fonte: bancos diretos → backend partilhado (/api/galeria-visual)
/// → reserva embutida. O app nunca fica sem grelha visual.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../secrets.dart';
import 'api_client.dart';
import 'visual_api.dart';

class BancoImagens {
  BancoImagens._();
  static final BancoImagens I = BancoImagens._();

  final http.Client _http = http.Client();
  final Map<String, (List<VisualItem>, DateTime)> _cache = {};
  static const _ttl = Duration(hours: 6);

  /// Busca intercalando Pexels + Unsplash (metade de cada), com fallback.
  Future<VisualResult> buscar(String query, {int count = 6}) async {
    final chave = '$query::$count';
    final hit = _cache[chave];
    if (hit != null && hit.$2.isAfter(DateTime.now())) {
      return VisualResult(items: hit.$1, source: hit.$1.first.fonte.isEmpty ? 'reserva' : hit.$1.map((e) => e.fonte).toSet().join('+'));
    }

    final n = count.clamp(2, 12);
    final metade = (n / 2).ceil();

    // Os dois bancos em paralelo — quem falhar, devolve vazio.
    final resultados = await Future.wait<List<VisualItem>>([
      _pexels(query, metade + 1),
      _unsplash(query, metade + 1),
    ]);
    var items = _intercalar(resultados[0], resultados[1]).take(n).toList();

    String fonte;
    if (items.isNotEmpty) {
      fonte = items.map((e) => e.fonte).toSet().join('+');
    } else {
      // 2ª camada: backend partilhado (pode ter chave própria + cache 6h).
      final r = await _viaBackend(query, count);
      items = r.items;
      fonte = r.source;
      if (items.isEmpty) {
        items = _reserva(query);
        fonte = 'reserva';
      }
    }

    _cache[chave] = (items, DateTime.now().add(_ttl));
    return VisualResult(items: items, source: fonte);
  }

  // ── Pexels ────────────────────────────────────────────────────────────────
  Future<List<VisualItem>> _pexels(String query, int perPage) async {
    if (AuraSecrets.pexelsKey.isEmpty) return const [];
    try {
      final uri = Uri.parse(
        'https://api.pexels.com/v1/search?query=${Uri.encodeComponent(query)}'
        '&per_page=$perPage&orientation=portrait',
      );
      final res = await _http
          .get(uri, headers: {'Authorization': AuraSecrets.pexelsKey})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final fotos = (jsonDecode(res.body)['photos'] as List?) ?? const [];
      return fotos
          .whereType<Map<String, dynamic>>()
          .map((p) {
            final src = (p['src'] as Map?)?.cast<String, dynamic>() ?? const {};
            return VisualItem(
              id: 'px-${p['id']}',
              url: '${src['large2x'] ?? src['large'] ?? ''}',
              thumb: '${src['medium'] ?? src['small'] ?? ''}',
              alt: '${p['alt'] ?? ''}',
              autor: '${p['photographer'] ?? 'Pexels'}',
              fonte: 'pexels',
            );
          })
          .where((i) => i.url.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ── Unsplash ──────────────────────────────────────────────────────────────
  Future<List<VisualItem>> _unsplash(String query, int perPage) async {
    if (AuraSecrets.unsplashAccessKey.isEmpty) return const [];
    try {
      final uri = Uri.parse(
        'https://api.unsplash.com/search/photos?query=${Uri.encodeComponent(query)}'
        '&per_page=$perPage&orientation=portrait&content_filter=high',
      );
      final res = await _http.get(uri, headers: {
        'Authorization': 'Client-ID ${AuraSecrets.unsplashAccessKey}',
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return const [];
      final fotos =
          (jsonDecode(res.body)['results'] as List?) ?? const [];
      return fotos
          .whereType<Map<String, dynamic>>()
          .map((p) {
            final urls = (p['urls'] as Map?)?.cast<String, dynamic>() ?? const {};
            final user = (p['user'] as Map?)?.cast<String, dynamic>() ?? const {};
            return VisualItem(
              id: 'un-${p['id']}',
              url: '${urls['regular'] ?? ''}',
              thumb: '${urls['small'] ?? ''}',
              alt: '${p['alt_description'] ?? p['description'] ?? ''}',
              autor: '${user['name'] ?? 'Unsplash'}',
              fonte: 'unsplash',
            );
          })
          .where((i) => i.url.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ── Backend partilhado (2ª camada) ────────────────────────────────────────
  Future<VisualResult> _viaBackend(String query, int count) async {
    try {
      final data = await ApiClient.I.get(
        '/api/galeria-visual',
        query: {'q': query, 'count': '$count'},
      ).timeout(const Duration(seconds: 6));
      final fonte = (data['fonte'] as String?) ?? 'backend';
      final items = (data['items'] as List?)
              ?.map((e) => VisualItem.fromJson((e as Map).cast<String, dynamic>()))
              .toList() ??
          const <VisualItem>[];
      return VisualResult(items: items, source: fonte);
    } catch (_) {
      return const VisualResult(items: [], source: 'offline');
    }
  }

  /// Intercala pexels/unsplash preservando ordem de relevância de cada banco.
  List<VisualItem> _intercalar(List<VisualItem> a, List<VisualItem> b) {
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    final out = <VisualItem>[];
    final maxLen = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < maxLen; i++) {
      if (i < a.length) out.add(a[i]);
      if (i < b.length) out.add(b[i]);
    }
    return out;
  }

  // ── Reserva embutida (última camada — nunca falha) ────────────────────────
  static const List<VisualItem> _reservaFotos = [
    VisualItem(
      id: 'reserva-cacheados',
      url: 'https://images.pexels.com/photos/2709388/pexels-photo-2709388.jpeg?auto=compress&cs=tinysrgb&w=800',
      thumb: 'https://images.pexels.com/photos/2709388/pexels-photo-2709388.jpeg?auto=compress&cs=tinysrgb&w=300',
      alt: 'Cabelos cacheados ao sol',
      autor: 'Pexels',
      fonte: 'reserva',
    ),
    VisualItem(
      id: 'reserva-ondulado',
      url: 'https://images.pexels.com/photos/3034705/pexels-photo-3034705.jpeg?auto=compress&cs=tinysrgb&w=800',
      thumb: 'https://images.pexels.com/photos/3034705/pexels-photo-3034705.jpeg?auto=compress&cs=tinysrgb&w=300',
      alt: 'Ondas naturais',
      autor: 'Pexels',
      fonte: 'reserva',
    ),
    VisualItem(
      id: 'reserva-liso',
      url: 'https://images.pexels.com/photos/3993449/pexels-photo-3993449.jpeg?auto=compress&cs=tinysrgb&w=800',
      thumb: 'https://images.pexels.com/photos/3993449/pexels-photo-3993449.jpeg?auto=compress&cs=tinysrgb&w=300',
      alt: 'Liso espelhado',
      autor: 'Pexels',
      fonte: 'reserva',
    ),
    VisualItem(
      id: 'reserva-trancas',
      url: 'https://images.pexels.com/photos/2065195/pexels-photo-2065195.jpeg?auto=compress&cs=tinysrgb&w=800',
      thumb: 'https://images.pexels.com/photos/2065195/pexels-photo-2065195.jpeg?auto=compress&cs=tinysrgb&w=300',
      alt: 'Tranças clássicas',
      autor: 'Pexels',
      fonte: 'reserva',
    ),
    VisualItem(
      id: 'reserva-fade',
      url: 'https://images.pexels.com/photos/2061820/pexels-photo-2061820.jpeg?auto=compress&cs=tinysrgb&w=800',
      thumb: 'https://images.pexels.com/photos/2061820/pexels-photo-2061820.jpeg?auto=compress&cs=tinysrgb&w=300',
      alt: 'Corte deprecado',
      autor: 'Pexels',
      fonte: 'reserva',
    ),
    VisualItem(
      id: 'reserva-editorial',
      url: 'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=800',
      thumb: 'https://images.pexels.com/photos/1043474/pexels-photo-1043474.jpeg?auto=compress&cs=tinysrgb&w=300',
      alt: 'Editorial de moda',
      autor: 'Pexels',
      fonte: 'reserva',
    ),
  ];

  /// Reserva determinística por query (varia a ordem p/ não repetir tile).
  List<VisualItem> _reserva(String query) {
    final rot = query.hashCode.clamp(0, _reservaFotos.length - 1);
    return [..._reservaFotos.sublist(rot), ..._reservaFotos.sublist(0, rot)];
  }
}
