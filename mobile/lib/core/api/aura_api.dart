/// aura_api.dart — as capacidades de IA do app, agora com cadeia tripla:
///  1. GROQ DIRETO do telemóvel (llama-3.3-70b · llama-4-scout visão)
///  2. Backend partilhado (/api/ai-chat · /api/look-alike · /api/analyze-selfie)
///  3. Heurística local — o app nunca fica mudo
library;

import 'api_client.dart';
import 'groq_ai.dart';

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

  /// Persona do Aura — a MESMA do backend (buildAuraSystemPrompt),
  /// construída em cima do mapa do perfil do app.
  static String _persona(Map<String, dynamic> p) {
    String v(Object? x) => (x == null || '$x'.isEmpty || '$x' == 'null')
        ? 'não informado'
        : '$x';
    String lista(Object? x) =>
        (x is List && x.isNotEmpty) ? x.join(', ') : 'não informado';
    final metas = (p['priorities'] is List && (p['priorities'] as List).isNotEmpty)
        ? (p['priorities'] as List).join(' > ')
        : 'não definidas';
    return [
      'Você é o Aura, o "JARVIS da beleza" do app AuraStyle — um concierge de estética e estilo premium.',
      'Estilo: sofisticado, caloroso e direto, como um consultor de um balcão de beleza de luxo. Exatamente em português.',
      'REGRAS:',
      '- Responda em no máximo 3 parágrafos curtos (ou uma lista de até 5 itens). Seja específico e prático.',
      '- Use SEMPRE os dados do perfil abaixo para personalizar. Nunca peça dados que já tem.',
      '- Adapte marcas, preços e disponibilidade à realidade local do usuário. Use a moeda local.',
      '- Quando fizer sentido, indique um recurso do app: Mercado (consultor de compras), Armário (montar looks), Atividades (desafios com XP), Espelho (identidade visual), Rotina (skincare diária).',
      '- Respeite a ordem de prioridades: o 1º objetivo domina as sugestões.',
      '- Nunca julgue a aparência. Nunca dê conselhos médicos; para doenças de pele, sugira dermatologista.',
      '- No máximo 1 emoji por resposta.',
      '',
      'PERFIL DO USUÁRIO:',
      '- nome: ${v(p['name'])} | gênero: ${v(p['gender'])} | idade: ${v(p['age'])}',
      '- localização: ${v(p['city'])}, ${v(p['country'])} | clima: ${v(p['climate'])} | região: ${v(p['region'])}',
      '- prioridades (1º → último): $metas',
      '- rosto: ${v(p['faceShape'])} | tom de pele: ${v(p['skinTone'])}/14 | subtom: ${v(p['undertone'])} | olhos: ${v(p['eyeColor'])} | pele: ${lista(p['skinTypes'])}',
      '- cabelo: ${v(p['hairType'])}, cor ${v(p['hairColor'])}, comprimento ${v(p['hairLength'])} | problemas capilares: ${lista(p['hairIssues'])}',
      '- corpo: ${v(p['bodyType'])} | altura: ${v(p['height'])}cm | estilos: ${lista(p['styles'])} | ocasiões: ${lista(p['occasions'])}',
      '- orçamento: ${v(p['budget'])} | cores favoritas: ${lista(p['colors'])} | atividade física: ${v(p['activity'])}/5 | profissão: ${v(p['profession'])}',
      '- observações: ${v(p['notes'])}',
    ].join('\n');
  }

  /// Envia mensagem de chat com o contexto do perfil.
  /// Cadeia: Groq direto → backend → resposta local (nunca lança).
  Future<ChatReply> chat({
    required String message,
    required Map<String, dynamic> profile,
    List<Map<String, String>> history = const [],
  }) async {
    // 1. Groq direto — IA completa sem backend.
    final groq = await GroqAi.I.chat(
      system: _persona(profile),
      turns: [
        ...history.take(12),
        {'role': 'user', 'content': message},
      ],
    );
    if (groq != null) return ChatReply(text: groq, source: 'groq');

    // 2. Backend partilhado (persona idêntica + heurística própria).
    try {
      final data = await ApiClient.I.post('/api/ai-chat', {
        'message': message,
        'profile': profile,
        'history': history,
      });
      return ChatReply.fromJson(data);
    } catch (_) {
      // 3. Local honesto — curto, perfil-aware, sem fingir ser IA.
      return ChatReply(text: _respostaLocal(message, profile), source: 'local');
    }
  }

  String _respostaLocal(String msg, Map<String, dynamic> p) {
    final nome = '${p['name'] ?? ''}'.trim();
    final cabelo = '${p['hairType'] ?? ''}'.trim();
    final meta = (p['priorities'] is List && (p['priorities'] as List).isNotEmpty)
        ? '${(p['priorities'] as List).first}'
        : '';
    final saudacao = nome.isEmpty ? 'Estou aqui' : 'Estou aqui, $nome';
    return '$saudacao — sem ligação à IA neste momento, mas guardo a tua aura. '
        '${cabelo.isNotEmpty ? 'Para o teu cabelo $cabelo' : 'Para o teu perfil'}'
        '${meta.isNotEmpty ? ', o foco continua em "$meta"' : ''}: '
        'hidratação consistente, proteção térmica e rotina simples vencem qualquer tendência. '
        'Explora o Mercado e o Espelho enquanto a IA volta.';
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

  /// Lê a selfie (traços + sugestões). Cadeia: Groq visão direto → backend
  /// → null (o ecrã usa as estimativas locais).
  Future<Map<String, dynamic>?> analyzeSelfie(String imageBase64) async {
    // 1. Groq direto — mesmo schema canónico do backend.
    final bruto = await GroqAi.I.vision(
      prompt: 'Analise esta selfie e estime os atributos estéticos. Responda '
          'somente com JSON no formato exato: {"skinTone": <inteiro 1-14, '
          '1=mais claro, 14=mais escuro>, "undertone": "quente"|"frio"|'
          '"neutro"|"oliva", "skinType": "oleosa"|"seca"|"mista"|'
          '"sensivel"|"normal", "faceShape": "oval"|"redondo"|"quadrado"|'
          '"retangular"|"coracao"|"diamante"|"losango", "hairColor": '
          '"loiro-claro"|"loiro-escuro"|"castanho-medio"|"castanho-escuro"|'
          '"ruivo"|"preto"|"grisalho"|"colorido", "confidence": <0-1>, '
          '"observations": "<1 frase em pt-BR>"}. Se não conseguir ver rosto, '
          'use confidence baixo e estime pelos dados visíveis.',
      imageBase64: imageBase64,
      json: true,
    );
    final direto = GroqAi.I.extrairJson(bruto);
    if (direto != null && direto.containsKey('skinTone')) {
      direto['source'] = 'groq';
      return direto;
    }

    // 2. Backend partilhado.
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
