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
    // 1. DIRETO do telemóvel — sem backend: geolocalização por IP
    //    (ipapi.co → ipwho.is) + Open-Meteo (grátis, sem chave).
    final direto = await _directLive();
    if (direto != null) return direto;

    // 2. Backend partilhado (mesmo do web) — quando apontado manualmente.
    return _backendLive();
  }

  /// Camada direta: ipapi.co → ipwho.is → Open-Meteo. Sem chaves, HTTPS.
  Future<Clima?> _directLive() async {
    try {
      final c = await _client;

      // Geo por IP — dois serviços gratuitos em cascata.
      String city = '', country = '';
      double? lat, lon;
      for (final host in ['https://ipapi.co/json/', 'https://ipwho.is/']) {
        try {
          final res = await c
              .get(Uri.parse(host), headers: _headers)
              .timeout(const Duration(seconds: 7));
          final j = jsonDecode(res.body);
          if (j is! Map) continue;
          lat = (j['latitude'] as num?)?.toDouble();
          lon = (j['longitude'] as num?)?.toDouble();
          city = '${j['city'] ?? ''}';
          country = '${j['country_name'] ?? j['country'] ?? ''}';
          if (lat != null && lon != null) break;
        } catch (_) {
          continue;
        }
      }
      if (lat == null || lon == null) return null;

      // Open-Meteo — tempo atual (WMO weather code).
      final wxUri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,weather_code&timezone=auto',
      );
      final wxRes = await c
          .get(wxUri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      final wx = jsonDecode(wxRes.body);
      if (wx is! Map) return null;
      final current =
          (wx['current'] as Map?)?.cast<String, dynamic>() ?? const {};
      final temp = (current['temperature_2m'] as num?)?.toDouble();
      final code = (current['weather_code'] as num?)?.toInt();
      if (temp == null || code == null) return null;

      final (label, emoji) = _wmo(code);
      return Clima(
        city: city.isEmpty ? 'Tua cidade' : city,
        country: country,
        temp: temp,
        label: label,
        emoji: emoji,
        tips: _dicas(temp, code),
        lat: lat,
        lon: lon,
      );
    } catch (_) {
      return null;
    }
  }

  /// Camada antiga — rotas /api/geo + /api/weather do backend.
  Future<Clima?> _backendLive() async {
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

  /// Código WMO → (rótulo, emoji).
  static (String, String) _wmo(int code) {
    if (code == 0) return ('Céu limpo', '☀️');
    if (code <= 2) return ('Pouco nublado', '🌤️');
    if (code == 3) return ('Encoberto', '☁️');
    if (code == 45 || code == 48) return ('Nevoeiro', '🌫️');
    if (code >= 51 && code <= 57) return ('Chuvisco', '🌦️');
    if (code >= 61 && code <= 67) return ('Chuva', '🌧️');
    if (code >= 71 && code <= 77) return ('Neve', '❄️');
    if (code >= 80 && code <= 82) return ('Pancadas', '🌦️');
    if (code == 85 || code == 86) return ('Neve a passar', '🌨️');
    if (code >= 95) return ('Trovoada', '⛈️');
    return ('Tempo instável', '🌤️');
  }

  /// 3 dicas curtas por temperatura + condição.
  static List<String> _dicas(double temp, int code) {
    final dicas = <String>[];
    if (code == 0 || code <= 2) {
      dicas.add('Sol à vera — protetor facial mesmo no trajeto curto.');
    }
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      dicas.add('Chuva no ar — leave-in com proteção e pente largo.');
    }
    if (code >= 71 && code <= 77) {
      dicas.add('Frio seco — soro antes do creme veda a hidratação.');
    }
    if (temp <= 12) {
      dicas.add('Abaixo de 12°: creme mais rico à noite e água morna na cara.');
    } else if (temp >= 28) {
      dicas.add('Calor pede gel leve de manhã e água à mão o dia todo.');
    }
    if (dicas.isEmpty) {
      dicas.add('Dia estável — o ritual de hoje mantém a tua aura intacta.');
    }
    return dicas.take(3).toList();
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
