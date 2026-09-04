/// secrets.dart — chaves de serviço do AuraStyle, num único lugar.
///
/// ⚠️ NO REPO, as chaves ficam VAZIAS por segurança (o GitHub Push
/// Protection bloqueia chaves de IA em commits públicos). O APK entregue
/// já foi compilado COM as chaves — para compilares tu mesmo:
///
///   1. Cola as tuas chaves nas 3 constantes abaixo, OU
///   2. Compila com --dart-define (se migrarmos para String.fromEnvironment).
///
/// Onde obter:
///  • Pexels   → https://www.pexels.com/api/      (200 pedidos/h, grátis)
///  • Unsplash → https://unsplash.com/developers  (50 pedidos/h, grátis —
///    só a Access Key; o Secret não é usado)
///  • Groq     → https://console.groq.com/keys    (llama-3.3-70b + visão)
///
/// Com chaves vazias o app CONTINUA A FUNCIONAR: a galeria usa o backend
/// (/api/galeria-visual, cache 6h) e a reserva embutida; a IA cai para o
/// backend partilhado e depois para a heurística local.
library;

class AuraSecrets {
  AuraSecrets._();

  // ── Bancos de imagens ─────────────────────────────────────────────────────
  /// Pexels API (https://www.pexels.com/api/) — 200 pedidos/hora.
  static const String pexelsKey = '';

  /// Unsplash Access Key (https://unsplash.com/developers) — 50 pedidos/hora.
  /// Basta a Access Key para busca pública; o Secret fica fora do app.
  static const String unsplashAccessKey = '';

  // ── IA ────────────────────────────────────────────────────────────────────
  /// Groq API (https://console.groq.com/keys) — llama-3.3-70b (texto) e
  /// llama-4-scout (visão). Pode ser bloqueada em alguns datacenters (ex. HK);
  /// nesses casos o app cai para o backend partilhado e depois para o local.
  static const String groqKey = '';

  static bool get temBancosImagem => pexelsKey.isNotEmpty || unsplashAccessKey.isNotEmpty;
  static bool get temGroq => groqKey.isNotEmpty;
}
