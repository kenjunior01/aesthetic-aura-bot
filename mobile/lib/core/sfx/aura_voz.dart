/// aura_voz.dart — a VOZ da Aura: text-to-speech nativo do telemóvel
/// (flutter_tts → engine TextToSpeech do Android), afinado para português.
/// O chat fala as respostas quando a voz está ligada (Perfil → Voz da Aura);
/// qualquer bolha da IA tem o alto-falante para ouvir quando quiseres.
library;

import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

class AuraVoz {
  AuraVoz._();
  static final AuraVoz I = AuraVoz._();

  final FlutterTts _tts = FlutterTts();
  bool _pronta = false;
  bool _falando = false;
  bool _on = false;

  /// Notificado quando começa/termina de falar (para o ícone animado).
  final StreamController<bool> _estado = StreamController<bool>.broadcast();
  Stream<bool> get estado => _estado.stream;
  bool get falando => _falando;
  bool get on => _on;

  /// Configura a engine uma única vez — pt-PT com fallback pt-BR.
  Future<void> ensure() async {
    if (_pronta) return;
    _pronta = true;
    try {
      final l = List<dynamic>.from(
        (await _tts.getLanguages) as List<dynamic>? ?? <dynamic>[],
      ).map((e) => '$e').toList();
      String? lingua;
      for (final cand in const ['pt-PT', 'pt_PT', 'pt-BR', 'pt_BR', 'pt']) {
        if (l.any((x) => x.toLowerCase() == cand.toLowerCase())) {
          lingua = cand.replaceAll('_', '-');
          break;
        }
      }
      if (lingua != null) await _tts.setLanguage(lingua);
      // Voz feminina suave quando existir mais do que uma.
      await _tts.setSpeechRate(0.52); // calma e clara
      await _tts.setPitch(1.05); // ligeiramente afável
      await _tts.setVolume(1.0);
      _tts.setStartHandler(() => _setFalando(true));
      _tts.setCompletionHandler(() => _setFalando(false));
      _tts.setErrorHandler((_) => _setFalando(false));
      _tts.setCancelHandler(() => _setFalando(false));
    } catch (_) {
      // engine indisponível — a voz fica silenciosa, o app continua.
      _pronta = _pronta; // sem crash; tentativas futuras reconfiguram
    }
  }

  void _setFalando(bool v) {
    _falando = v;
    if (!_estado.isClosed) _estado.add(v);
  }

  /// Liga/desliga a voz. Ao desligar, corta o que estiver a soar.
  void setEnabled(bool on) {
    _on = on;
    if (!on) parar();
  }

  /// Fala o texto (só se a voz estiver ligada). Corta o anterior.
  Future<void> falar(String texto) async {
    if (!_on || texto.trim().isEmpty) return;
    await ensure();
    try {
      await _tts.stop();
      // Limpa markdown e emojis de símbolos que a engine leria em voz alta.
      final limpo = texto
          .replaceAll(RegExp(r'[*_`#>\[\]()]'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (limpo.isEmpty) return;
      await _tts.speak(limpo);
    } catch (_) {
      // silêncio elegante se a engine falhar
    }
  }

  Future<void> parar() async {
    if (!_falando) return;
    try {
      await _tts.stop();
    } catch (_) {}
    _setFalando(false);
  }
}
