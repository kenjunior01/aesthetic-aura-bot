/// config.dart — ponte entre o app Flutter e o MESMO backend do app web.
///
/// O banco de dados é o mesmo: as rotas Next.js (/api/acervo, /api/ai-chat,
/// /api/look-alike, /api/analyze-selfie) são a única fonte de verdade.
///
/// Como apontar:
///  • Emulador Android → http://10.0.2.2:3000 (localhost da máquina anfitriã)
///  • iOS Simulator    → http://localhost:3000
///  • Dispositivo real → IP da máquina na mesma rede, ou o URL de produção
///    (Vercel) depois do deploy do web.
///
/// O valor pode ser alterado em runtime no ecrã Perfil → Ligação ao backend,
/// e a escolha PERSISTE (antes resetava a cada arranque).
library;

import 'package:shared_preferences/shared_preferences.dart';

class AuraConfig {
  AuraConfig._();

  static const _prefsKey = 'aurastyle-apibase-v1';

  /// Base URL atual das rotas /api partilhadas com o web.
  static String apiBase = defaultApiBase;

  /// Valor de arranque (emulador Android é o caso mais comum).
  static const String defaultApiBase = 'http://10.0.2.2:3000';

  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 25);

  /// O Met bloqueia User-Agent não-navegador — idêntico ao web.
  static const String browserUA =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/126.0 Safari/537.36';

  /// Carrega a base URL guardada (chamar no arranque do app).
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) apiBase = saved;
  }

  /// Define e persiste a base URL do backend.
  static Future<void> setApiBase(String url) async {
    final limpo = url.trim().isEmpty ? defaultApiBase : url.trim();
    apiBase = limpo.endsWith('/') ? limpo.substring(0, limpo.length - 1) : limpo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, apiBase);
  }
}
