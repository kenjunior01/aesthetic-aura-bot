/// diagnostico_api.dart — prova de vida: cada serviço que o app usa é
/// pingado AQUI DO PRÓPRIO TELEMÓVEL, com as mesmas chaves que o app usa.
///
/// Isto existe para responder à pergunta "está mesmo a funcionar?" com
/// números: HTTP, latência e detalhe. Nada de adivinhar.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../config.dart';
import '../secrets.dart';

class ResultadoPing {
  const ResultadoPing({
    required this.nome,
    required this.sub,
    required this.icone,
    required this.ok,
    required this.httpCode,
    required this.ms,
    required this.detalhe,
    this.semChave = false,
  });

  final String nome;
  final String sub;
  final IconData icone;
  final bool ok;
  final int httpCode; // 0 = sem resposta / exceção
  final int ms; // latência
  final String detalhe;
  final bool semChave;
}

class DiagnosticoApi {
  DiagnosticoApi._();
  static final DiagnosticoApi I = DiagnosticoApi._();

  final http.Client _http = http.Client();

  static String _mascarar(String k, String prefixo) {
    if (k.isEmpty) return 'sem chave';
    if (k.length < 8) return '$prefixo••••';
    return '$prefixo••••${k.substring(k.length - 4)}';
  }

  Future<ResultadoPing> _ping({
    required String nome,
    required String sub,
    required IconData icone,
    required Future<http.Response> Function() req,
    String Function(http.Response)? extrair,
    bool? semChave,
  }) async {
    final sw = Stopwatch()..start();
    try {
      final res = await req().timeout(const Duration(seconds: 18));
      sw.stop();
      final ok = res.statusCode == 200;
      String det = '${res.statusCode}';
      if (ok && extrair != null) {
        try {
          det = extrair(res);
        } catch (_) {}
      }
      return ResultadoPing(
        nome: nome,
        sub: sub,
        icone: icone,
        ok: ok,
        httpCode: res.statusCode,
        ms: sw.elapsedMilliseconds,
        detalhe: det,
        semChave: semChave ?? false,
      );
    } on TimeoutException {
      return ResultadoPing(
        nome: nome,
        sub: sub,
        icone: icone,
        ok: false,
        httpCode: 0,
        ms: sw.elapsedMilliseconds,
        detalhe: 'tempo esgotado',
        semChave: semChave ?? false,
      );
    } catch (e) {
      return ResultadoPing(
        nome: nome,
        sub: sub,
        icone: icone,
        ok: false,
        httpCode: 0,
        ms: sw.elapsedMilliseconds,
        detalhe: 'sem ligação',
        semChave: semChave ?? false,
      );
    }
  }

  // ── 1. Groq texto ──────────────────────────────────────────────────────────
  Future<ResultadoPing> groqTexto() {
    if (AuraSecrets.groqKey.isEmpty) {
      return Future.value(
        ResultadoPing(
          nome: 'IA — texto',
          sub: 'Groq · llama-3.3-70b',
          icone: Icons.forum_outlined,
          ok: false,
          httpCode: 0,
          ms: 0,
          detalhe: 'sem chave',
          semChave: true,
        ),
      );
    }
    return _ping(
      nome: 'IA — texto',
      sub: 'Groq · llama-3.3-70b · ${_mascarar(AuraSecrets.groqKey, 'gsk_')}',
      icone: Icons.forum_outlined,
      req: () => _http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AuraSecrets.groqKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'user', 'content': 'Diz apenas: vivo'},
          ],
          'max_tokens': 8,
          'temperature': 0,
        }),
      ),
      extrair: (res) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        final c =
            ((d['choices'] as List?)?.firstOrNull
                    as Map<String, dynamic>?)?['message']
                as Map<String, dynamic>?;
        return 'respondeu: ${(c?['content'] ?? '').toString().trim()}';
      },
    );
  }

  // ── 2. Groq visão ──────────────────────────────────────────────────────────
  Future<ResultadoPing> groqVisao() async {
    if (AuraSecrets.groqKey.isEmpty) {
      return ResultadoPing(
        nome: 'IA — visão',
        sub: 'Groq · llama-4-scout',
        icone: Icons.center_focus_strong,
        ok: false,
        httpCode: 0,
        ms: 0,
        detalhe: 'sem chave',
        semChave: true,
      );
    }
    String b64;
    try {
      final bytes = await rootBundle.load('assets/diagnostico/ping.png');
      b64 = base64Encode(bytes.buffer.asUint8List());
    } catch (_) {
      b64 = '';
    }
    return _ping(
      nome: 'IA — visão',
      sub: 'Groq · llama-4-scout · fotos do scan e do chat',
      icone: Icons.center_focus_strong,
      req: () => _http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${AuraSecrets.groqKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'meta-llama/llama-4-scout-17b-16e-instruct',
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': 'Que cor domina? 1 palavra.'},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/png;base64,$b64'},
                },
              ],
            },
          ],
          'max_tokens': 8,
          'temperature': 0,
        }),
      ),
      extrair: (res) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        final c =
            ((d['choices'] as List?)?.firstOrNull
                    as Map<String, dynamic>?)?['message']
                as Map<String, dynamic>?;
        return 'leu a imagem: ${(c?['content'] ?? '').toString().trim()}';
      },
    );
  }

  // ── 3. Pexels ──────────────────────────────────────────────────────────────
  Future<ResultadoPing> pexels() {
    if (AuraSecrets.pexelsKey.isEmpty) {
      return Future.value(
        ResultadoPing(
          nome: 'Pexels',
          sub: 'banco de imagens · 200 pedidos/h',
          icone: Icons.photo_library_outlined,
          ok: false,
          httpCode: 0,
          ms: 0,
          detalhe: 'sem chave',
          semChave: true,
        ),
      );
    }
    return _ping(
      nome: 'Pexels',
      sub: 'banco de imagens · ${_mascarar(AuraSecrets.pexelsKey, 'px_')}',
      icone: Icons.photo_library_outlined,
      req: () => _http.get(
        Uri.parse(
          'https://api.pexels.com/v1/search?query=elegant%20portrait'
          '&per_page=1&orientation=portrait',
        ),
        headers: {'Authorization': AuraSecrets.pexelsKey},
      ),
      extrair: (res) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        final f = (d['photos'] as List?)?.firstOrNull as Map<String, dynamic>?;
        return 'foto viva: ${f?['photographer'] ?? '?'}';
      },
    );
  }

  // ── 4. Unsplash ────────────────────────────────────────────────────────────
  Future<ResultadoPing> unsplash() {
    if (AuraSecrets.unsplashAccessKey.isEmpty) {
      return Future.value(
        ResultadoPing(
          nome: 'Unsplash',
          sub: 'banco de imagens · 50 pedidos/h',
          icone: Icons.photo_library_outlined,
          ok: false,
          httpCode: 0,
          ms: 0,
          detalhe: 'sem chave',
          semChave: true,
        ),
      );
    }
    return _ping(
      nome: 'Unsplash',
      sub:
          'banco de imagens · ${_mascarar(AuraSecrets.unsplashAccessKey, 'un_')}',
      icone: Icons.photo_library_outlined,
      req: () => _http.get(
        Uri.parse(
          'https://api.unsplash.com/search/photos?query=elegant%20portrait'
          '&per_page=1&orientation=portrait&content_filter=high',
        ),
        headers: {
          'Authorization': 'Client-ID ${AuraSecrets.unsplashAccessKey}',
        },
      ),
      extrair: (res) {
        final d = jsonDecode(res.body) as Map<String, dynamic>;
        final r = (d['results'] as List?)?.firstOrNull as Map<String, dynamic>?;
        final u = (r?['user'] as Map?)?.cast<String, dynamic>();
        return 'foto viva: ${u?['name'] ?? '?'}';
      },
    );
  }

  // ── 5. Acervo Met ──────────────────────────────────────────────────────────
  Future<ResultadoPing> met() => _ping(
    nome: 'Acervo — The Met',
    sub: 'coleção de moda · open access · sem chave',
    icone: Icons.museum_outlined,
    req: () => _http.get(
      Uri.parse(
        'https://collectionapi.metmuseum.org/public/collection/v1/search'
        '?q=dress&hasImages=true',
      ),
      headers: {'User-Agent': AuraConfig.browserUA},
    ),
    extrair: (res) {
      final d = jsonDecode(res.body) as Map<String, dynamic>;
      return 'obras disponíveis: ${d['total'] ?? '?'}';
    },
  );

  // ── 6. Clima ───────────────────────────────────────────────────────────────
  Future<ResultadoPing> clima() => _ping(
    nome: 'Clima ao vivo',
    sub: 'Open-Meteo · dicas de cuidado do dia',
    icone: Icons.cloud_outlined,
    req: () => _http.get(
      Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=-25.97'
        '&longitude=32.58&current=temperature_2m',
      ),
    ),
    extrair: (res) {
      final d = jsonDecode(res.body) as Map<String, dynamic>;
      final c = d['current'] as Map<String, dynamic>?;
      return 'leitura: ${c?['temperature_2m']}°C';
    },
  );

  /// Todos, em paralelo.
  Future<List<ResultadoPing>> todos() async {
    final r = await Future.wait<ResultadoPing>([
      groqTexto(),
      groqVisao(),
      pexels(),
      unsplash(),
      met(),
      clima(),
    ]);
    return r;
  }
}
