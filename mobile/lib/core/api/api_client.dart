/// api_client.dart — cliente HTTP único para as rotas Next.js partilhadas.
/// Timeout curto, User-Agent de navegador (o Met bloqueia clientes "nus") e
/// normalização de erros — as features nunca lançam exceptions cruas.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient._();
  static final ApiClient I = ApiClient._();

  final http.Client _http = http.Client();

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = AuraConfig.apiBase.endsWith('/')
        ? AuraConfig.apiBase.substring(0, AuraConfig.apiBase.length - 1)
        : AuraConfig.apiBase;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
    'User-Agent': AuraConfig.browserUA,
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  /// GET com retry curto (2 tentativas) e parse JSON tolerante.
  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final res = await _http
            .get(_uri(path, query), headers: _headers)
            .timeout(AuraConfig.receiveTimeout);
        if (res.statusCode >= 400) {
          throw ApiException(
            'HTTP ${res.statusCode}',
            statusCode: res.statusCode,
          );
        }
        return jsonDecode(utf8.decode(res.bodyBytes));
      } on ApiException {
        rethrow;
      } catch (e) {
        lastError = e;
        if (attempt == 0) {
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
      }
    }
    throw ApiException(
      'Sem ligação ao backend (${AuraConfig.apiBase}): $lastError',
      statusCode: 0,
    );
  }

  /// POST JSON. Devolve o corpo decodificado (Map ou List).
  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final res = await _http
          .post(_uri(path), headers: _headers, body: jsonEncode(body))
          .timeout(AuraConfig.receiveTimeout);
      if (res.statusCode >= 400) {
        throw ApiException(
          'HTTP ${res.statusCode}',
          statusCode: res.statusCode,
        );
      }
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Sem ligação ao backend (${AuraConfig.apiBase})');
    }
  }

  void dispose() => _http.close();
}
