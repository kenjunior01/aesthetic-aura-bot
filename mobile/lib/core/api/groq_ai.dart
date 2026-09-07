/// groq_ai.dart — IA ultra-rápida DIRETO do telemóvel (Groq).
///
///  • llama-3.3-70b-versatile        → texto (chat do Aura)
///  • meta-llama/llama-4-scout-17b…  → visão (selfie, foto de produtos)
///
/// A cadeia de IA do app passa a ser: Groq direto → backend partilhado →
/// heurística local. Assim o app responde com IA completa mesmo sem
/// backend ligado — e o Groq (fora de datacenters bloqueados) é o caminho
/// mais rápido que existe: ~1 s por resposta.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../secrets.dart';

class GroqAi {
  GroqAi._();
  static final GroqAi I = GroqAi._();

  static const _base = 'https://api.groq.com/openai/v1/chat/completions';
  static const _modeloTexto = 'llama-3.3-70b-versatile';
  static const _modeloVisao = 'meta-llama/llama-4-scout-17b-16e-instruct';

  final http.Client _http = http.Client();

  bool get disponivel => AuraSecrets.temGroq;

  /// Conversa de texto EM STREAMING — os tokens chegam em SSE e são
  /// entregues via onDelta à medida que o modelo escreve. Devolve o texto
  /// completo (null se o Groq não responder). A perceção de velocidade muda
  /// de "6 s a olhar pontos" para "primeiras palavras em ~300 ms".
  Future<String?> chatStream({
    required String system,
    required List<Map<String, String>> turns,
    double temperature = 0.85,
    int maxTokens = 700,
    void Function(String delta)? onDelta,
  }) async {
    if (!disponivel) return null;
    try {
      final req = http.Request('POST', Uri.parse(_base))
        ..headers.addAll({
          'Authorization': 'Bearer ${AuraSecrets.groqKey}',
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode({
          'model': _modeloTexto,
          'messages': [
            {'role': 'system', 'content': system},
            ...turns,
          ],
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': true,
        });
      final res = await _http
          .send(req)
          .timeout(const Duration(seconds: 45));
      if (res.statusCode != 200) return null;
      final completo = StringBuffer();
      await for (final linha in res.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        final l = linha.trim();
        if (!l.startsWith('data:')) continue;
        final payload = l.substring(5).trim();
        if (payload == '[DONE]') break;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          final choices = data['choices'] as List?;
          final delta = ((choices?.firstOrNull as Map<String, dynamic>?)
              ?['delta'] as Map<String, dynamic>?);
          final pedaco = '${delta?['content'] ?? ''}';
          if (pedaco.isNotEmpty) {
            completo.write(pedaco);
            onDelta?.call(pedaco);
          }
        } catch (_) {
          // linha parcial/corrompida → ignora e continua
        }
      }
      final texto = completo.toString().trim();
      return texto.isEmpty ? null : texto;
    } catch (_) {
      return null;
    }
  }

  /// Conversa de texto. Devolve null se o Groq não responder (o chamador
  /// cai para o backend/local).
  Future<String?> chat({
    required String system,
    required List<Map<String, String>> turns,
    double temperature = 0.85,
    int maxTokens = 700,
    bool json = false,
  }) async {
    if (!disponivel) return null;
    try {
      final body = <String, dynamic>{
        'model': _modeloTexto,
        'messages': [
          {'role': 'system', 'content': system},
          ...turns,
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
        if (json) 'response_format': {'type': 'json_object'},
      };
      final res = await _http
          .post(
            Uri.parse(_base),
            headers: {
              'Authorization': 'Bearer ${AuraSecrets.groqKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final escolha = ((data['choices'] as List?)?.firstOrNull
          as Map<String, dynamic>?);
      final conteudo =
          '${(escolha?['message'] as Map<String, dynamic>?)?['content'] ?? ''}';
      return conteudo.trim().isEmpty ? null : conteudo.trim();
    } catch (_) {
      return null;
    }
  }

  /// Conversa com FOTO: o histórico segue em texto e a última mensagem do
  /// utilizador leva a imagem (modelo de visão). Devolve null se o Groq
  /// não responder.
  Future<String?> chatVision({
    required String system,
    required List<Map<String, String>> turns,
    required String imageBase64,
    String mimeType = 'image/jpeg',
    double temperature = 0.7,
    int maxTokens = 700,
  }) async {
    if (!disponivel) return null;
    try {
      final mensagens = <Map<String, dynamic>>[
        {'role': 'system', 'content': system},
        // Histórico em texto (sem a última entrada, que leva a imagem).
        ...turns.take(turns.length - 1).map((t) => {
              'role': t['role'],
              'content': t['content'],
            }),
        {
          'role': 'user',
          'content': [
            {
              'type': 'text',
              'text':
                  '${turns.isEmpty ? '' : turns.last['content'] ?? ''}\n'
                      '(A imagem segue anexada a esta mensagem.)'
                      .trim(),
            },
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$imageBase64'},
            },
          ],
        },
      ];
      final body = <String, dynamic>{
        'model': _modeloVisao,
        'messages': mensagens,
        'temperature': temperature,
        'max_tokens': maxTokens,
      };
      final res = await _http
          .post(
            Uri.parse(_base),
            headers: {
              'Authorization': 'Bearer ${AuraSecrets.groqKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 45));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final escolha = ((data['choices'] as List?)?.firstOrNull
          as Map<String, dynamic>?);
      final conteudo =
          '${(escolha?['message'] as Map<String, dynamic>?)?['content'] ?? ''}';
      return conteudo.trim().isEmpty ? null : conteudo.trim();
    } catch (_) {
      return null;
    }
  }

  /// Visão: foto (base64) + pergunta → texto (ou JSON se json=true).
  Future<String?> vision({
    required String prompt,
    required String imageBase64,
    String mimeType = 'image/jpeg',
    int maxTokens = 600,
    bool json = false,
  }) async {
    if (!disponivel) return null;
    try {
      final body = <String, dynamic>{
        'model': _modeloVisao,
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mimeType;base64,$imageBase64'},
              },
            ],
          },
        ],
        'temperature': 0.3,
        'max_tokens': maxTokens,
        if (json) 'response_format': {'type': 'json_object'},
      };
      final res = await _http
          .post(
            Uri.parse(_base),
            headers: {
              'Authorization': 'Bearer ${AuraSecrets.groqKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 40));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final escolha = ((data['choices'] as List?)?.firstOrNull
          as Map<String, dynamic>?);
      final conteudo =
          '${(escolha?['message'] as Map<String, dynamic>?)?['content'] ?? ''}';
      return conteudo.trim().isEmpty ? null : conteudo.trim();
    } catch (_) {
      return null;
    }
  }

  /// Extrai o primeiro objeto JSON válido de uma resposta (tolera fences
  /// ```json e texto à volta — o LLM às vezes explica antes do JSON).
  Map<String, dynamic>? extrairJson(String? texto) {
    if (texto == null || texto.isEmpty) return null;
    var t = texto.trim();
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(t);
    if (fence != null) t = fence.group(1)!.trim();
    final inicio = t.indexOf('{');
    if (inicio < 0) return null;
    var profundidade = 0;
    for (var i = inicio; i < t.length; i++) {
      if (t[i] == '{') profundidade++;
      if (t[i] == '}') {
        profundidade--;
        if (profundidade == 0) {
          try {
            final parsed = jsonDecode(t.substring(inicio, i + 1));
            return parsed is Map<String, dynamic> ? parsed : null;
          } catch (_) {
            return null;
          }
        }
      }
    }
    return null;
  }
}
