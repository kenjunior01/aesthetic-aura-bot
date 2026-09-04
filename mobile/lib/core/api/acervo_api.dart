/// acervo_api.dart — galeria Acervo (The Met) via rota /api/acervo partilhada.
///
/// Resiliência em 2 camadas no cliente (o servidor já tem 3):
///  1. chamada viva à rota Next.js (que por sua vez fala com o Met);
///  2. reserva embutida (kMetReserva) — a galeria nunca amanhece vazia.
library;

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

  /// Busca obras de um tema. count limitado a 6-24 pela rota.
  Future<AcervoResult> fetchTheme(String theme, {int count = 12}) async {
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
      if (items.isEmpty) throw ApiException('resposta vazia');
      final src = data is Map ? '${data['source'] ?? 'met'}' : 'met';
      return AcervoResult(items: items, source: src);
    } catch (_) {
      // Camada 2: reserva embutida — mesma filosofia do web.
      return AcervoResult(
        items: kMetReserva[theme] ?? const [],
        source: 'reserva',
      );
    }
  }
}
