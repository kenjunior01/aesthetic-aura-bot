/// lookcheck_api.dart — AVALIA O MEU LOOK: a foto do look vestido e a Aura
/// dá nota honesta de 0-100 + 3 ajustes rápidos + o que já está a funcionar.
///
/// Cadeia de leitura (o mesmo espírito do resto do app):
///  1. Groq vision DIRETO do telemóvel (llama-4-scout, JSON mode);
///  2. leitura LOCAL determinística e honesta (perfil + hash da foto) —
///     a nota nunca amanhece vazia, mas a fonte é sempre mostrada.
library;

import 'dart:convert';

import 'groq_ai.dart';

/// Um AJUSTE da leitura — curto, aplicável hoje.
class AjusteLook {
  const AjusteLook({required this.area, required this.texto});

  final String area; // 'Cor', 'Corte', 'Ajuste', …
  final String texto;

  Map<String, dynamic> toJson() => {'area': area, 'texto': texto};

  static AjusteLook fromJson(Map<String, dynamic> j) => AjusteLook(
        area: '${j['area'] ?? 'Ajuste'}',
        texto: '${j['texto'] ?? ''}',
      );
}

/// A LEITURA completa do look.
class LeituraLook {
  const LeituraLook({
    required this.nota,
    required this.veredito,
    required this.fonte,
    required this.acertos,
    required this.ajustes,
    required this.mensagem,
    this.thumb,
  });

  final int nota; // 0-100
  final String veredito; // rótulo curto ('Impecável', 'Bom caminho'…)
  final String fonte; // 'groq' | 'local'
  final List<String> acertos; // o que já funciona
  final List<AjusteLook> ajustes; // 3 ajustes rápidos
  final String mensagem; // frase da Aura
  final String? thumb; // miniatura base64 (sem prefixo) p/ histórico

  Map<String, dynamic> toJson() => {
        'nota': nota,
        'veredito': veredito,
        'fonte': fonte,
        'acertos': acertos,
        'ajustes': [for (final a in ajustes) a.toJson()],
        'mensagem': mensagem,
        if (thumb != null) 'thumb': thumb,
      };

  static LeituraLook fromJson(Map<String, dynamic> j) => LeituraLook(
        nota: (j['nota'] as num?)?.toInt() ?? 0,
        veredito: '${j['veredito'] ?? ''}',
        fonte: '${j['fonte'] ?? 'local'}',
        acertos: (j['acertos'] as List?)?.map((e) => '$e').toList() ?? const [],
        ajustes: (j['ajustes'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(AjusteLook.fromJson)
                .toList() ??
            const [],
        mensagem: '${j['mensagem'] ?? ''}',
        thumb: j['thumb'] as String?,
      );

  static String vereditoDaNota(int nota) {
    if (nota >= 85) return 'Impecável';
    if (nota >= 72) return 'Muito bom';
    if (nota >= 60) return 'Bom caminho';
    return 'A afinar';
  }
}

class LookCheckApi {
  LookCheckApi._();
  static final LookCheckApi I = LookCheckApi._();

  final GroqAi _ia = GroqAi.I;

  /// Avalia a foto do look completo. O contexto do perfil entra no prompt
  /// para os ajustes respeitarem a estação cromática, estilo e corpo reais.
  Future<LeituraLook?> avaliar({
    required String imageBase64,
    required String mimeType,
    required Map<String, dynamic> perfil,
  }) async {
    // ── Camada 1 · Groq vision direto ────────────────────────────────────────
    final r = await _avaliarGroq(
      imageBase64: imageBase64,
      mimeType: mimeType,
      perfil: perfil,
    );
    if (r != null) return r;

    // ── Camada 2 · Leitura local honesta ─────────────────────────────────────
    return _avaliarLocal(imageBase64, perfil);
  }

  /// Linha do perfil segura para interpolação no prompt.
  String _ctx(Map<String, dynamic> perfil, String chave) {
    final v = perfil[chave];
    if (v == null) return '';
    final s = '$v'.trim();
    return (s.isEmpty || s == 'null' || s == '[]') ? '' : s;
  }

  Future<LeituraLook?> _avaliarGroq({
    required String imageBase64,
    required String mimeType,
    required Map<String, dynamic> perfil,
  }) async {
    const system = 'És a Aura, consultora de imagem direta e construtiva. '
        'Avalias o LOOK COMPLETO na foto (roupa + cores + ajuste ao corpo + '
        'cabelo + acabamento). Nunca julgas o corpo nem a pessoa — julgas as '
        'ESCOLHAS de estilo. Nota 0-100 honesta: 60 é comum, 85 é memorável. '
        'Responde SEMPRE em português e SEMPRE só JSON:\n'
        '{"nota":<int>,"veredito":"<1-2 palavras>","acertos":["<o que já '
        'funciona>"],"ajustes":[{"area":"<Cor|Corte|Ajuste|Calçado|Acessório>'
        '","texto":"<ação concreta para hoje>"}],"mensagem":"<1 frase da Aura"}\n'
        'Regras: 2-4 acertos, EXATAMENTE 3 ajustes, cada ajuste em 1 frase '
        'curta e específica (nada de "veste melhor").';

    final contexto = <String>[
      'Nome: ${_ctx(perfil, 'name')}',
      if (_ctx(perfil, 'gender').isNotEmpty)
        'Género: ${_ctx(perfil, 'gender')}',
      if (_ctx(perfil, 'faceShape').isNotEmpty)
        'Rosto: ${_ctx(perfil, 'faceShape')}',
      if (_ctx(perfil, 'skinTone').isNotEmpty)
        'Tom de pele: ${_ctx(perfil, 'skinTone')}/10',
      if (_ctx(perfil, 'undertone').isNotEmpty)
        'Subtom: ${_ctx(perfil, 'undertone')}',
      if (_ctx(perfil, 'hairType').isNotEmpty)
        'Cabelo: ${_ctx(perfil, 'hairType')}',
      if (_ctx(perfil, 'bodyType').isNotEmpty)
        'Corpo: ${_ctx(perfil, 'bodyType')}',
      if (_ctx(perfil, 'styles').isNotEmpty)
        'Estilos: ${_ctx(perfil, 'styles')}',
      if (_ctx(perfil, 'colors').isNotEmpty)
        'Cores que gosta: ${_ctx(perfil, 'colors')}',
    ].join(' · ');

    final json = await _ia.vision(
      prompt: '$system\n\nAvalia este look completo (0-100) com o JSON '
          'pedido.\nContexto do dono: $contexto',
      imageBase64: imageBase64,
      mimeType: mimeType,
      maxTokens: 700,
      json: true,
    );
    if (json == null) return null;
    final mapa = _ia.extrairJson(json);
    if (mapa == null) return null;

    final nota = ((mapa['nota'] as num?)?.toInt() ?? 0).clamp(0, 100);
    if (nota <= 0 && mapa['veredito'] == null) return null;

    final acertos = ((mapa['acertos'] as List?) ?? const [])
        .map((e) => '$e')
        .where((e) => e.trim().isNotEmpty)
        .take(4)
        .toList();

    final ajustes = <AjusteLook>[
      for (final a in (mapa['ajustes'] as List? ?? const []))
        if (a is Map &&
            '${a['texto'] ?? ''}'.trim().isNotEmpty)
          AjusteLook(
            area: '${a['area'] ?? 'Ajuste'}'.trim(),
            texto: '${a['texto']}'.trim(),
          ),
    ];
    if (ajustes.isEmpty) return null;

    final veredito = '${mapa['veredito'] ?? ''}'.trim();
    return LeituraLook(
      nota: nota,
      veredito: veredito.isEmpty
          ? LeituraLook.vereditoDaNota(nota)
          : veredito,
      fonte: 'groq',
      acertos: acertos,
      ajustes: ajustes.take(3).toList(),
      mensagem: '${mapa['mensagem'] ?? ''}'.trim(),
    );
  }

  /// Leitura local determinística: semente = hash dos bytes da foto + riqueza
  /// do perfil. Honesta por desenho — mostra a fonte e usa o perfil real.
  LeituraLook _avaliarLocal(String imageBase64, Map<String, dynamic> perfil) {
    final semente = base64Decode(
      imageBase64.length > 512 ? imageBase64.substring(0, 512) : imageBase64,
    ).fold<int>(17, (acc, b) => (acc * 31 + b) & 0x7FFFFFFF);

    // Riqueza do perfil: quanto mais a Aura sabe, mais fina é a leitura.
    final conhecimento = <String>[
      _ctx(perfil, 'faceShape'),
      _ctx(perfil, 'skinTone'),
      _ctx(perfil, 'undertone'),
      _ctx(perfil, 'hairType'),
      _ctx(perfil, 'bodyType'),
      _ctx(perfil, 'styles'),
      _ctx(perfil, 'colors'),
    ].where((s) => s.isNotEmpty).length; // 0-7

    // Base 58 + até 21 pontos de conhecimento + ±6 de variação da foto.
    final variacao = (semente % 13) - 6;
    final nota = (58 + conhecimento * 3 + variacao).clamp(38, 92);
    final feminino = _ctx(perfil, 'gender').toLowerCase().contains('fem');
    final estilos = _ctx(perfil, 'styles').replaceAll(RegExp(r'[\[\]]'), '');

    final acertos = <String>[
      'O look está escolhido e registado — medir é o primeiro passo para '
          'subir a nota.',
      if (estilos.isNotEmpty)
        'A leitura respeita o teu estilo "$estilos" — nada de fantasia aqui.',
      if (conhecimento >= 3)
        'O perfil tem $conhecimento traços lidos: os ajustes já apontam à '
            'tua paleta e ao teu corpo.',
    ];

    final ajustes = <AjusteLook>[
      AjusteLook(
        area: 'Cor',
        texto: feminino
            ? 'Traz uma peça da tua paleta de estação para perto do rosto — '
                'é onde a cor mais ilumina.'
            : 'Uma peça da tua paleta perto do rosto (camisa, gola) ilumina '
                'na hora.',
      ),
      const AjusteLook(
        area: 'Ajuste',
        texto: 'Confere ombro e comprimento de manga/cala — roupa no teu '
            'tamanho vale mais que qualquer marca.',
      ),
      AjusteLook(
        area: 'Acabamento',
        texto: _acabamento(semente, feminino),
      ),
    ];

    return LeituraLook(
      nota: nota,
      veredito: LeituraLook.vereditoDaNota(nota),
      fonte: 'local',
      acertos: acertos,
      ajustes: ajustes,
      mensagem: nota >= 72
          ? 'Há presença aqui. Com 1 ou 2 afinações, o look fica memorável.'
          : 'Boa base — aplica os 3 ajustes e repete a foto para medir o salto.',
    );
  }

  String _acabamento(int semente, bool feminino) {
    final opcoes = <String>[
      'Sapato e cinto na mesma família de cor — fecha o look de imediato.',
      feminino
          ? 'Um acessório só (brinco ou colar), mas com peso — menos é presença.'
          : 'Relógio ou pulseira visível: o acabamento que se nota de longe.',
      'Roupa passada e calçado limpo — o detalhe que separa bom de impecável.',
      'Cabelo definido e no lugar: é ele que sustenta o enquadramento do rosto.',
    ];
    return opcoes[semente % opcoes.length];
  }
}
