/// clima_api.dart — Clima ao Vivo: o plano adapta-se ao clima REAL da tua
/// cidade, via as rotas /api/geo → /api/weather do MESMO backend do web.
/// Gratuito, sem chaves (Open-Meteo → wttr.in no servidor). Degradation
/// honesta: sem rede, o cartão apenas não aparece.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class Clima {
  const Clima({
    required this.city,
    required this.country,
    required this.temp,
    required this.label,
    required this.emoji,
    required this.tips,
    required this.lat,
    required this.lon,
  });

  final String city;
  final String country;
  final double temp;
  final String label;
  final String emoji;
  final List<String> tips;
  final double lat;
  final double lon;

  static Clima? fromJson(Map<String, dynamic> j) {
    final temp = (j['temp'] as num?)?.toDouble();
    final lat = (j['lat'] as num?)?.toDouble();
    final lon = (j['lon'] as num?)?.toDouble();
    if (temp == null || lat == null || lon == null) return null;
    return Clima(
      city: '${j['city'] ?? 'Tua cidade'}',
      country: '${j['country'] ?? ''}',
      temp: temp,
      label: '${j['label'] ?? ''}',
      emoji: '${j['emoji'] ?? '☀️'}',
      tips: (j['tips'] as List?)?.map((e) => '$e').toList() ?? const [],
      lat: lat,
      lon: lon,
    );
  }

  Map<String, dynamic> toJson() => {
    'city': city,
    'country': country,
    'temp': temp,
    'label': label,
    'emoji': emoji,
    'tips': tips,
    'lat': lat,
    'lon': lon,
  };
}

class ClimaApi {
  ClimaApi._();
  static final ClimaApi I = ClimaApi._();

  static const _cacheKey = 'aurastyle-clima-v1';

  http.Client? _http;
  Clima? _last;
  Timer? _stale;

  /// Último clima carregado nesta sessão (para pintar sem esperar).
  Clima? get current => _last;

  Future<http.Client> get _client async => _http ??= http.Client();

  Map<String, String> get _headers => {
    'User-Agent': AuraConfig.browserUA,
    'Accept': 'application/json',
  };

  /// Clima do dia: cache 3h em prefs → rede (geo → weather) → null.
  Future<Clima?> load() async {
    if (_last != null) return _last;

    // 1. Cache recente (3h).
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw != null) {
      try {
        final saved = jsonDecode(raw) as Map<String, dynamic>;
        final at = (saved['at'] as num?)?.toInt() ?? 0;
        if (DateTime.now().millisecondsSinceEpoch - at < 3 * 3600 * 1000) {
          final clima = Clima.fromJson(
            (saved['clima'] as Map?)?.cast<String, dynamic>() ?? const {},
          );
          if (clima != null) return _last = clima;
        }
      } catch (_) {}
    }

    // 2. Rede.
    final clima = await _fetchLive();
    if (clima != null) {
      _last = clima;
      _schedulePrefetchRefresh();
      await prefs.setString(
        _cacheKey,
        jsonEncode({
          'at': DateTime.now().millisecondsSinceEpoch,
          'clima': clima.toJson(),
        }),
      );
    }
    return clima;
  }

  Future<Clima?> _fetchLive() async {
    try {
      final c = await _client;
      final geoRes = await c
          .get(Uri.parse('${AuraConfig.apiBase}/api/geo'), headers: _headers)
          .timeout(AuraConfig.connectTimeout);
      final geo = jsonDecode(geoRes.body);
      if (geo is! Map || geo['ok'] != true) return null;
      final lat = (geo['lat'] as num?)?.toDouble();
      final lon = (geo['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) return null;

      final wxRes = await c
          .get(
            Uri.parse('${AuraConfig.apiBase}/api/weather')
                .replace(queryParameters: {'lat': '$lat', 'lon': '$lon'}),
            headers: _headers,
          )
          .timeout(AuraConfig.receiveTimeout);
      final wx = jsonDecode(wxRes.body);
      if (wx is! Map || wx['ok'] != true) return null;

      return Clima.fromJson({
        ...wx.cast<String, dynamic>(),
        'city': geo['city'],
        'country': geo['country'],
        'lat': lat,
        'lon': lon,
      });
    } catch (_) {
      return null;
    }
  }

  /// Refresco silencioso do cache a cada 3h enquanto o app vive.
  void _schedulePrefetchRefresh() {
    _stale?.cancel();
    _stale = Timer(const Duration(hours: 3), () async {
      final live = await _fetchLive();
      if (live != null) {
        _last = live;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _cacheKey,
          jsonEncode({
            'at': DateTime.now().millisecondsSinceEpoch,
            'clima': live.toJson(),
          }),
        );
      }
    });
  }

  void dispose() {
    _stale?.cancel();
    _http?.close();
  }
}
