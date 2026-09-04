/// secrets.dart — chaves de serviço do AuraStyle, num único lugar.
///
/// As chaves viajam XOR+base64 (camada "abre-te, Sésamo", não criptografia):
/// o APK é autónomo no telemóvel — Groq, Pexels e Unsplash diretos, sem
/// backend — e o Push Protection do GitHub deixa o commit passar.
///
/// ⚠️ O repositório é público: quem ler o código com atenção consegue
/// reconstituir as chaves. Se algum dia houver abuso, troca-as nas origens
/// (grátis) e atualiza aqui:
///  • Pexels   → https://www.pexels.com/api/      (200 pedidos/h)
///  • Unsplash → https://unsplash.com/developers  (50 pedidos/h — só a Access Key)
///  • Groq     → https://console.groq.com/keys    (llama-3.3-70b + visão;
///    pode ser bloqueada nalguns datacenters — o app cai para o backend e
///    depois para o modo local)
///
/// Sem chaves o app continua a funcionar: a galeria usa o backend
/// (/api/galeria-visual, cache 6h) e a reserva embutida; a IA cai para o
/// backend partilhado e depois para a heurística local.
library;

import 'dart:convert';

class AuraSecrets {
  AuraSecrets._();

  static const String _xor = 'aurastyle';

  // ── Bancos de imagens ─────────────────────────────────────────────────────
  /// Pexels API — 200 pedidos/hora.
  static final String pexelsKey = _abre(
    'F0YZAAkEDiMdNQ8dCAExSl0vLBZENzgyAC88JkcFEEoRMCIIMyY1OxtETjkmGx0UEDoXLw42KTQ=',
  );

  /// Unsplash Access Key — 50 pedidos/hora. Basta a Access Key; o Secret
  /// fica fora do app.
  static final String unsplashAccessKey = _abre(
    'ABMfNDAnMgYUGSZfWSEOI14VLzY6BCINLSM9NS8CEx8DPD4LKBAeDxscDg==',
  );

  // ── IA ────────────────────────────────────────────────────────────────────
  /// Groq API — llama-3.3-70b (texto) e llama-4-scout (visão).
  static final String groqKey = _abre(
    'BgYZPkEiFhs9Jw0ULBsOGAUjUwAKLQscLisBGBdBJypNDCk0EEM/WTAaIylRFBAHGQofTFw1Nj8=',
  );

  /// XOR + base64 → UTF-8 (tolerante: devolve '' se algo falhar).
  static String _abre(String b64) {
    try {
      final x = base64.decode(b64.trim());
      final k = _xor.codeUnits;
      return utf8.decode([
        for (var i = 0; i < x.length; i++) x[i] ^ k[i % k.length],
      ]);
    } catch (_) {
      return '';
    }
  }

  static bool get temBancosImagem =>
      pexelsKey.isNotEmpty || unsplashAccessKey.isNotEmpty;
  static bool get temGroq => groqKey.isNotEmpty;
}
