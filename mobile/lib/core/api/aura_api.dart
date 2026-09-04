/// aura_api.dart — as capacidades de IA partilhadas com o web:
///  • /api/ai-chat        → chatbot adaptado ao perfil
///  • /api/look-alike     → "a quem a minha cara se aproxima" (Referências)
///  • /api/analyze-selfie → leitura da selfie (traços canónicos)
/// Todos com degradação graciosa: sem rede, o app continua utilizável.
library;

import 'api_client.dart';

// ── Chat ──────────────────────────────────────────────────────────────────────

class ChatReply {
  const ChatReply({required this.text, required this.source});
  final String text;
  final String source; // 'groq' | 'local' | ...

  factory ChatReply.fromJson(dynamic data) {
    if (data is Map) {
      return ChatReply(
        text: '${data['reply'] ?? data['message'] ?? data['text'] ?? '…'}',
        source: '${data['source'] ?? 'groq'}',
      );
    }
    return const ChatReply(text: '…', source: 'erro');
  }
}

// ── Referências (look-alike) ──────────────────────────────────────────────────

class LookAlikeMatch {
  const LookAlikeMatch({
    required this.slug,
    required this.name,
    required this.score,
    required this.vibe,
    required this.photo,
    required this.signatures,
    required this.upgrades,
  });

  final String slug;
  final String name;
  final int score;
  final String vibe;
  final String photo;
  final List<String> signatures;
  final List<UpgradeStep> upgrades;

  factory LookAlikeMatch.fromJson(Map<String, dynamic> j) => LookAlikeMatch(
    slug: '${j['slug'] ?? j['id'] ?? ''}',
    name: '${j['name'] ?? 'Arquétipo'}',
    score: (j['score'] as num?)?.toInt() ?? 0,
    vibe: '${j['styleVibe'] ?? j['vibe'] ?? ''}',
    photo: '${j['photo'] ?? j['image'] ?? ''}',
    signatures:
        ((j['signature'] ?? j['signatures']) as List?)
            ?.map((e) => '$e')
            .toList() ??
        const [],
    upgrades: ((j['upgrades'] ?? const []) as List)
        .whereType<Map<String, dynamic>>()
        .map(UpgradeStep.fromJson)
        .toList(),
  );
}

class UpgradeStep {
  const UpgradeStep({
    required this.area,
    required this.action,
    required this.why,
  });
  final String area;
  final String action;
  final String why;

  factory UpgradeStep.fromJson(Map<String, dynamic> j) => UpgradeStep(
    area: '${j['area'] ?? 'Geral'}',
    action: '${j['action'] ?? ''}',
    why: '${j['why'] ?? ''}',
  );
}

class LookAlikeVerdict {
  const LookAlikeVerdict({
    required this.summary,
    required this.source,
    required this.matches,
  });

  final String summary;
  final String source; // 'vision' | 'profile'
  final List<LookAlikeMatch> matches;

  factory LookAlikeVerdict.fromJson(dynamic data) {
    final map = data is Map ? data : const {};
    final List raw = (map['matches'] ?? map['ranking'] ?? const []) as List;
    return LookAlikeVerdict(
      summary: '${map['summary'] ?? map['verdict'] ?? ''}',
      source: '${map['source'] ?? 'profile'}',
      matches: raw
          .whereType<Map<String, dynamic>>()
          .map(LookAlikeMatch.fromJson)
          .toList(),
    );
  }
}

// ── Cliente ───────────────────────────────────────────────────────────────────

class AuraApi {
  AuraApi._();
  static final AuraApi I = AuraApi._();

  /// Envia mensagem de chat com o contexto do perfil (adaptado ao utilizador).
  Future<ChatReply> chat({
    required String message,
    required Map<String, dynamic> profile,
    List<Map<String, String>> history = const [],
  }) async {
    final data = await ApiClient.I.post('/api/ai-chat', {
      'message': message,
      'profile': profile,
      'history': history,
    });
    return ChatReply.fromJson(data);
  }

  /// Galeria de arquétipos do banco (Referências).
  Future<List<LookAlikeMatch>> fetchGallery() async {
    final data = await ApiClient.I.get('/api/look-alike');
    final List raw =
        (data is Map
                ? (data['items'] ?? data['gallery'] ?? data['references'])
                : data)
            as List? ??
        const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(LookAlikeMatch.fromJson)
        .toList();
  }

  /// Compara a cara (opcional) + perfil com o banco de arquétipos.
  Future<LookAlikeVerdict> compare({
    String? imageBase64,
    required Map<String, dynamic> profile,
  }) async {
    final data = await ApiClient.I.post('/api/look-alike', {
      if (imageBase64 != null && imageBase64.isNotEmpty)
        'imageBase64': imageBase64,
      'profile': profile,
    });
    return LookAlikeVerdict.fromJson(data);
  }

  /// Lê a selfie (traços + sugestões). Falha gracefully devolvendo null.
  Future<Map<String, dynamic>?> analyzeSelfie(String imageBase64) async {
    try {
      final data = await ApiClient.I.post('/api/analyze-selfie', {
        'imageBase64': imageBase64,
      });
      return data is Map<String, dynamic> ? data : null;
    } catch (_) {
      return null;
    }
  }
}
