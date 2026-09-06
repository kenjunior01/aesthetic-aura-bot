/// jornada_api.dart — o motor da JORNADA DO AUGE.
///
///  • gerarJornada(perfil) → Groq lê TUDO o que deste à plataforma e traça
///    o período estimado (sentir efeitos / ver mudanças / auge) + as fases
///    com buscas de imagem real adaptadas aos teus traços.
///  • avaliarCheckin(foto) → visão compara e diz se o plano está a andar.
///  • revisarJornada() → recalcula fases e períodos após os check-ins.
///
/// Toda a chamada tem reserva local determinística — a jornada nunca falha.
library;

import '../data/jornada_store.dart';
import 'groq_ai.dart';

/// Resultado da leitura de um check-in.
class LeituraCheckin {
  const LeituraCheckin({
    required this.aderencia,
    required this.veredito,
    required this.mensagem,
    required this.mudancas,
    required this.ajustes,
  });

  final int aderencia; // 0-100
  final String veredito; // 'no_trilho' | 'ajustar'
  final String mensagem;
  final List<String> mudancas;
  final List<String> ajustes;
}

class JornadaApi {
  JornadaApi._();
  static final JornadaApi I = JornadaApi._();

  final GroqAi _ia = GroqAi.I;

  // ── Gerar a jornada ───────────────────────────────────────────────────────
  Future<Jornada> gerarJornada(Map<String, dynamic> perfil) async {
    final bruto = await _ia.chat(
      system:
          'És a Aura, consultora de estética e evolução pessoal. Escreves em '
          'português (português de Angola/Moçambique, tom caloroso e direto). '
          'Responde APENAS JSON válido, sem markdown.',
      turns: [
        {
          'role': 'user',
          'content': 'Perfil completo: ${_perfilTexto(perfil)}. '
              'Traça a JORNADA REALISTA desta pessoa até o seu auge visual — '
              'o estado em que pele, cabelo e estilo estão no seu melhor com '
              'consistência. Usa ritmos científicos honestos: ciclo da pele '
              '~4 semanas, hidratação capilar 2-6 semanas, hábitos visíveis '
              'em 3-8 semanas. Nada de promessas mágicas.\n'
              'Responde APENAS JSON:\n'
              '{"totalSemanas":12,"efeitosSemanas":3,"mudancasSemanas":6,'
              '"resumo":"o plano numa frase","dicaChave":"o hábito que mais pesa",'
              '"fases":[{"nome":"Fundação","semanaInicio":1,"semanaFim":4,'
              '"titulo":"capítulo curto","foco":"1-2 frases do que muda aqui",'
              '"acoes":["3-4 ações concretas desta fase"],"visivel":"o que vai '
              'começar a notar no espelho","imagem":"busca em INGLÊS 3-5 palavras '
              'de retrato real que se assemelhe a esta pessoa NESTA fase, com os '
              'SEUS traços (tipo de cabelo, tom de pele, género)"}]}\n'
              '3 a 4 fases que cubram todas as semanas (semanaInicio=1 da 1ª, '
              'última semanaFim=totalSemanas, sem buracos). Imagem: exemplo para '
              'mulher cacheada pele morena fase 1 → "natural curly hair black '
              'woman portrait skin".',
        },
      ],
      temperature: 0.55,
      maxTokens: 1400,
      json: true,
    );
    final json = _ia.extrairJson(bruto);
    final fases = _fasesDeJson(json?['fases']);
    if (json != null && fases.isNotEmpty) {
      return Jornada(
        criada: _hoje(),
        atualizada: _hoje(),
        versao: 1,
        totalSemanas: (json['totalSemanas'] as num?)?.toInt() ?? 12,
        efeitosSemanas: (json['efeitosSemanas'] as num?)?.toInt() ?? 3,
        mudancasSemanas: (json['mudancasSemanas'] as num?)?.toInt() ?? 6,
        resumo: '${json['resumo'] ?? ''}',
        dicaChave: '${json['dicaChave'] ?? ''}',
        fases: fases,
        fonte: 'groq',
      );
    }
    return _jornadaLocal(perfil);
  }

  // ── Avaliar um check-in (foto) ────────────────────────────────────────────
  Future<LeituraCheckin> avaliarCheckin({
    required Map<String, dynamic> perfil,
    required Jornada jornada,
    required String imageBase64,
    required int semana,
    String mimeType = 'image/jpeg',
  }) async {
    final fasesFeitas = jornada.fases
        .where((f) => f.semanaInicio <= semana)
        .map((f) => '${f.nome}: ${f.acoes.take(3).join('; ')}')
        .join(' | ');
    final bruto = await _ia.vision(
      prompt: 'És a Aura, consultora de estética. Esta pessoa está na SEMANA '
          '$semana da jornada dela (${jornada.totalSemanas} semanas até o auge; '
          'mudanças esperadas a partir da semana ${jornada.mudancasSemanas}). '
          'Fases já percorridas: $fasesFeitas. Perfil: ${_perfilTexto(perfil)}. '
          'Olha a foto com honestidade e bondade: compara com o que era de '
          'esperar nesta semana. NÃO inventes mudanças que não dá para ver. '
          'Responde APENAS JSON: {"aderencia":0-100 sinal de que o plano está '
          'a andar,"veredito":"no_trilho|ajustar","mensagem":"2-3 frases em '
          'português: o que notas, o que está a funcionar ou a faltar",'
          '"mudancas":["sinais visíveis (se houver)"],"ajustes":["1-3 ajustes '
          'concretos para as próximas semanas"]}.',
      imageBase64: imageBase64,
      mimeType: mimeType,
      json: true,
      maxTokens: 700,
    );
    final json = _ia.extrairJson(bruto);
    if (json != null) {
      return LeituraCheckin(
        aderencia:
            ((json['aderencia'] as num?)?.toInt() ?? 60).clamp(0, 100),
        veredito: '${json['veredito'] ?? 'no_trilho'}' == 'ajustar'
            ? 'ajustar'
            : 'no_trilho',
        mensagem: '${json['mensagem'] ?? 'Registo guardado na tua rota.'}',
        mudancas: (json['mudancas'] as List?)
                ?.map((e) => '$e')
                .where((e) => e.trim().isNotEmpty)
                .toList() ??
            const [],
        ajustes: (json['ajustes'] as List?)
                ?.map((e) => '$e')
                .where((e) => e.trim().isNotEmpty)
                .toList() ??
            const [],
      );
    }
    return _leituraLocal(semana, jornada.mudancasSemanas);
  }

  // ── Revisar a jornada após check-ins ──────────────────────────────────────
  Future<Jornada> revisarJornada({
    required Map<String, dynamic> perfil,
    required Jornada jornada,
    required int semanaAtual,
  }) async {
    final historico = jornada.checkins
        .map((c) =>
            'semana ${c.semana}: aderência ${c.aderencia}, veredito '
            '${c.veredito}, ajustes ${c.ajustes.join('; ')}')
        .join(' | ');
    final bruto = await _ia.chat(
      system:
          'És a Aura, consultora de estética e evolução. Escreves em '
          'português. Responde APENAS JSON válido, sem markdown.',
      turns: [
        {
          'role': 'user',
          'content': 'A jornada desta pessoa precisa de REVISÃO. '
              'Perfil: ${_perfilTexto(perfil)}. '
              'Plano atual (v${jornada.versao}): ${jornada.totalSemanas} semanas, '
              'fases ${jornada.fases.map((f) => f.nome).join('→')}. '
              'Já foram $semanaAtual semanas. Check-ins: ${historico.isEmpty ? 'nenhum ainda' : historico}. '
              'Reescreve a rota A PARTIR da semana atual: as fases já vividas '
              'mantêm-se como foram, o futuro ajusta-se ao ritmo real '
              '(se a aderência foi alta e há sinais, encurta; se faltou '
              'consistência, estende e simplifica). Mesmo contrato JSON da '
              'criação: {"totalSemanas":..,"efeitosSemanas":..,"mudancasSemanas":..,'
              '"resumo":"..","dicaChave":"..","fases":[{...}]}. totalSemanas '
              'conta desde a SEMANA 1 original (mantém a escala).',
        },
      ],
      temperature: 0.5,
      maxTokens: 1400,
      json: true,
    );
    final json = _ia.extrairJson(bruto);
    final fases = _fasesDeJson(json?['fases']);
    if (json != null && fases.isNotEmpty) {
      return Jornada(
        criada: jornada.criada,
        atualizada: _hoje(),
        versao: jornada.versao + 1,
        totalSemanas: (json['totalSemanas'] as num?)?.toInt() ??
            jornada.totalSemanas,
        efeitosSemanas: (json['efeitosSemanas'] as num?)?.toInt() ??
            jornada.efeitosSemanas,
        mudancasSemanas: (json['mudancasSemanas'] as num?)?.toInt() ??
            jornada.mudancasSemanas,
        resumo: '${json['resumo'] ?? jornada.resumo}',
        dicaChave: '${json['dicaChave'] ?? jornada.dicaChave}',
        fases: fases,
        fonte: 'groq',
      );
    }
    // Reserva local: estende 2 semanas e empurra as fases futuras.
    return _revisaoLocal(jornada, semanaAtual);
  }

  // ── Reservas locais ───────────────────────────────────────────────────────
  Jornada _jornadaLocal(Map<String, dynamic> perfil) {
    final prioridades = ((perfil['priorities'] as List?) ?? const [])
        .map((e) => '$e')
        .toList();
    final pele = prioridades.contains('pele');
    final cabelo = prioridades.contains('cabelo');
    final estilo = prioridades.contains('estilo');
    final nome = '${perfil['name'] ?? ''}';
    return Jornada(
      criada: _hoje(),
      atualizada: _hoje(),
      versao: 1,
      totalSemanas: 12,
      efeitosSemanas: 3,
      mudancasSemanas: 6,
      resumo: pele
          ? 'Fundação de pele e cabelo primeiro, estilo por cima — '
              'é esta a rota honesta para ${nome.isEmpty ? 'ti' : nome}.'
          : 'Hábitos que se vêem: ritmo semanal de cuidado e escolhas '
              'que assinam o teu estilo.',
      dicaChave: pele
          ? 'Nunca dormir sem limpar e hidratar — é isto que move o ponteiro.'
          : 'Repetir pequenos gestos todos os dias vence qualquer grande esforço.',
      fases: [
        FaseJornada(
          nome: 'Fundação',
          semanaInicio: 1,
          semanaFim: 4,
          titulo: 'Preparar o terreno',
          foco: 'Limpeza, hidratação e proteção — a base que faz tudo o resto '
              'render mais.',
          acoes: [
            'Limpar o rosto de manhã e à noite',
            'Hidratante com proteção solar todos os dias',
            if (cabelo) 'Máscara capilar 1x por semana',
            'Beber água logo cedo',
          ],
          visivel: pele
              ? 'Pele mais calma e uniforme por volta da semana 3-4.'
              : 'Mais energia e constância nos gestos.',
          imagemQuery: 'fresh clean skin natural portrait',
        ),
        FaseJornada(
          nome: 'Consolidação',
          semanaInicio: 5,
          semanaFim: 8,
          titulo: 'O ritmo fica teu',
          foco: 'Os hábitos já não custam — agora afinam-se os detalhes.',
          acoes: [
            if (cabelo) 'Rotina capilar completa por tipo de cabelo',
            if (pele) 'Tratamento semanal (máscara/esfoliação suave)',
            if (estilo) 'Arrumar o armário pelas tuas cores',
            'Registo semanal no diário',
          ],
          visivel: 'As primeiras mudanças que os outros começam a notar.',
          imagemQuery: cabelo
              ? 'healthy shiny hair portrait studio'
              : 'confident natural beauty portrait',
        ),
        FaseJornada(
          nome: 'Assinatura',
          semanaInicio: 9,
          semanaFim: 12,
          titulo: 'A tua marca ao espelho',
          foco: 'Corte, cor e estilo assinados — o auge desta rota.',
          acoes: [
            if (estilo) 'Look assinado para os teus dias grandes',
            if (cabelo) 'Corte que respeita o teu tipo de cabelo',
            'Manutenção da rotina vencedora',
          ],
          visivel: 'O auge: pele, cabelo e estilo a falar a mesma língua.',
          imagemQuery: 'elegant stylish portrait golden hour',
        ),
      ],
      fonte: 'local',
    );
  }

  LeituraCheckin _leituraLocal(int semana, int mudancasSemanas) =>
      LeituraCheckin(
        aderencia: 60,
        veredito: semana >= mudancasSemanas ? 'no_trilho' : 'no_trilho',
        mensagem: semana >= mudancasSemanas
            ? 'Registo guardado na semana $semana — a rota continua. '
                'Sem leitura de IA agora, mas a constância é tua.'
            : 'Registo guardado na semana $semana. As mudanças visíveis '
                'esperam-te perto da semana $mudancasSemanas — continua.',
        mudancas: const [],
        ajustes: const [],
      );

  Jornada _revisaoLocal(Jornada j, int semanaAtual) {
    final extra = 2;
    final fases = j.fases.map((f) {
      if (f.semanaFim <= semanaAtual) return f; // passado intacto
      return FaseJornada(
        nome: f.nome,
        semanaInicio: f.semanaInicio,
        semanaFim: f.semanaFim + extra,
        titulo: f.titulo,
        foco: f.foco,
        acoes: f.acoes,
        visivel: f.visivel,
        imagemQuery: f.imagemQuery,
        imagemUrl: f.imagemUrl,
      );
    }).toList();
    return Jornada(
      criada: j.criada,
      atualizada: _hoje(),
      versao: j.versao + 1,
      totalSemanas: j.totalSemanas + extra,
      efeitosSemanas: j.efeitosSemanas,
      mudancasSemanas: (j.mudancasSemanas + extra).clamp(j.mudancasSemanas, 99),
      resumo: '${j.resumo} (revista com mais $extra semanas de respiro)',
      dicaChave: j.dicaChave,
      fases: fases,
      fonte: j.fonte,
    );
  }

  // ── Utilitários ───────────────────────────────────────────────────────────
  String _perfilTexto(Map<String, dynamic> p) {
    final parts = <String>[];
    p.forEach((k, v) {
      if (v == null) return;
      final s = '$v';
      if (s.isEmpty || s == '[]') return;
      parts.add('$k=$s');
    });
    return parts.join(', ');
  }

  List<FaseJornada> _fasesDeJson(dynamic bruto) {
    if (bruto is! List) return const [];
    final fases = <FaseJornada>[];
    for (final e in bruto) {
      if (e is! Map) continue;
      final j = e.cast<String, dynamic>();
      fases.add(
        FaseJornada(
          nome: '${j['nome'] ?? 'Fase'}',
          semanaInicio: (j['semanaInicio'] as num?)?.toInt() ?? 1,
          semanaFim: (j['semanaFim'] as num?)?.toInt() ?? 4,
          titulo: '${j['titulo'] ?? ''}',
          foco: '${j['foco'] ?? ''}',
          acoes: (j['acoes'] as List?)
                  ?.map((e) => '$e')
                  .where((e) => e.trim().isNotEmpty)
                  .take(5)
                  .toList() ??
              const [],
          visivel: '${j['visivel'] ?? ''}',
          imagemQuery: '${j['imagem'] ?? j['imagemQuery'] ?? 'natural portrait'}',
        ),
      );
    }
    return fases;
  }

  String _hoje() {
    final d = DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
