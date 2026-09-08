/// guarda_roupa_api.dart — a IA lê a fotografia da tua peça e devolve o
/// ficha completa: nome, slot do look (topo/base/calçado/camada/acessório),
/// cor dominante com hex, ocasiões e estação.
///
/// Cadeia: Groq visão (llama-4-scout, JSON) → fallback manual no ecrã (o
/// utilizador confirma/ corrige tudo antes de guardar — a IA propõe, o
/// utilizador dispõe).
library;

import '../secrets.dart';
import 'groq_ai.dart';

/// Proposta da IA para uma peça fotografada.
class PecaDraft {
  const PecaDraft({
    required this.nome,
    required this.categoria,
    required this.corHex,
    required this.corNome,
    this.ocasioes = const [],
    this.estacao = 'todo o ano',
    this.fonte = 'ai',
  });

  final String nome;
  final String categoria; // já normalizada (PecaCategoria.*)
  final String corHex; // '#RRGGBB'
  final String corNome;
  final List<String> ocasioes;
  final String estacao;
  final String fonte; // 'ai' | 'manual'
}

class GuardaRoupaApi {
  GuardaRoupaApi._();

  static const _promptClassificar =
      'És a Aura, catalogadora de guarda-roupa do app AuraStyle. Recebes a '
      'fotografia de UMA peça de roupa ou calçado (pode estar em cabide, '
      'dobre, chão ou a ser usada). Responde APENAS JSON válido:\n'
      '{"nome": "<nome curto em pt: \'Camisa azul de linho\'>", '
      '"categoria": "<topo|base|pes|extra|acessorio>", '
      '"corNome": "<nome da cor dominante em pt>", '
      '"corHex": "#RRGGBB", '
      '"ocasioes": ["<casual|trabalho|festa|desporto|romance — 1 a 3>"], '
      '"estacao": "<todo o ano|verao|inverno>"}\n'
      'Regras: "topo" = camisa/t-shirt/camisola/polos; "base" = calças/'
      'jeans/shorts/saias; "pes" = ténis/sapatos/botas/sandálias; "extra" = '
      'casacos/blazers/sobretudos/hoodies de fora; "acessorio" = gorros/'
      'bonés/lenços/cintos/colares/bolsas/óculos. A cor dominante é a da '
      'PEÇA, não do fundo. Se a foto não mostrar claramente uma peça, usa '
      '{"nome":"Peça","categoria":"topo","corNome":"Indefinida",'
      '"corHex":"#8A94A6","ocasioes":["casual"],"estacao":"todo o ano"}.';

  /// Classifica a foto da peça (base64 JPEG). null = IA indisponível
  /// (o ecrã abre o formulário manual com a cor média da imagem).
  static Future<PecaDraft?> classificar(String imageBase64) async {
    if (!AuraSecrets.temGroq) return null;
    final bruto = await GroqAi.I.vision(
      prompt: _promptClassificar,
      imageBase64: imageBase64,
      json: true,
      maxTokens: 300,
    );
    final map = GroqAi.I.extrairJson(bruto);
    if (map == null) return null;

    final categoria = _categoriaValida(map['categoria']);
    final hex = _hexValido(map['corHex']) ?? '#8A94A6';
    final ocasioes = (map['ocasioes'] as List?)
        ?.map((e) => '$e'.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList() ??
        const <String>[];

    return PecaDraft(
      nome: '${map['nome'] ?? 'Peça'}'.trim(),
      categoria: categoria,
      corHex: hex,
      corNome: '${map['corNome'] ?? ''}'.trim(),
      ocasioes: ocasioes,
      estacao: _estacaoValida(map['estacao']),
      fonte: 'ai',
    );
  }

  /// Comentário curto da Aura sobre o look montado — o porquê que ensina.
  static Future<String?> comentarLook({
    required String conceito,
    required List<String> linhas,
    required Map<String, dynamic> contexto,
  }) {
    final sistema =
        'És a Aura, estilista de precisão do AuraStyle — fala português de '
        'Portugal, tom direto e quente, zero emojis, zero markdown. O '
        'utilizador montou um look do próprio guarda-roupa com conceito '
        '"$conceito". Explica em 1-2 frases (máx 220 caracteres) porque é '
        'que esta combinação funciona e dá UM conselho de acabamento '
        '(acessório, sapato, dobra, fit). Nunca inventes peças que não '
        'estão na lista.';
    final pergunta =
        'Peças do look:\n${linhas.map((l) => '- $l').join('\n')}\n'
        'Contexto: ${contexto['city'] ?? ''} '
        'estilo: ${(contexto['styles'] as List?)?.join(', ') ?? ''}. '
        'Comenta o look.';
    return GroqAi.I.chat(
      system: sistema,
      turns: [
        {'role': 'user', 'content': pergunta},
      ],
      temperature: 0.8,
      maxTokens: 140,
    );
  }

  // ── Normalização ─────────────────────────────────────────────────────────

  static String _categoriaValida(Object? bruto) {
    final v = '$bruto'.trim().toLowerCase();
    const validas = ['topo', 'base', 'pes', 'extra', 'acessorio'];
    if (validas.contains(v)) return v;
    // Tolerância a sinónimos que a IA inventa.
    if (v.contains('calçado') || v.contains('calcado') || v.contains('shoe')) {
      return 'pes';
    }
    if (v.contains('camada') || v.contains('outer') || v.contains('jacket')) {
      return 'extra';
    }
    if (v.contains('acess')) return 'acessorio';
    if (v.contains('base') || v.contains('bottom')) return 'base';
    return 'topo';
  }

  static String _estacaoValida(Object? bruto) {
    final v = '$bruto'.trim().toLowerCase();
    if (v.contains('verao') || v.contains('verão')) return 'verao';
    if (v.contains('inverno') || v.contains('winter')) return 'inverno';
    return 'todo o ano';
  }

  static String? _hexValido(Object? bruto) {
    final v = '$bruto'.replaceAll('#', '').trim().toUpperCase();
    if (v.length == 6 && int.tryParse(v, radix: 16) != null) return '#$v';
    return null;
  }
}
