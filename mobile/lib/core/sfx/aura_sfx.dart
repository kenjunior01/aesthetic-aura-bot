/// aura_sfx.dart — a identidade sonora do AuraStyle.
///
/// Nove timbres "platina" sintetizados de propósito para o app (cristalinos,
/// suaves, curtos — nada de buzz genérico):
///   tap · toggle · complete · success · send · receive · camera · sparkle · chime
///
/// Pré-carregados como AudioPool (latência baixa, até 3 vozes por timbre).
/// O utilizador controla em Perfil → Sons do app (persistido). Todo o motor
/// falha em silêncio: sem áudio nunca trava o app — nem em testes.
library;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum Sfx {
  tap,
  toggle,
  complete,
  success,
  send,
  receive,
  camera,
  sparkle,
  chime,
}

class AuraSfx {
  AuraSfx._();
  static final AuraSfx I = AuraSfx._();

  bool _on = true;
  bool _ready = false;
  bool _loading = false;
  final Map<Sfx, AudioPool?> _pools = {};

  static const _arquivos = <Sfx, String>{
    Sfx.tap: 'sfx/tap.wav',
    Sfx.toggle: 'sfx/toggle.wav',
    Sfx.complete: 'sfx/complete.wav',
    Sfx.success: 'sfx/success.wav',
    Sfx.send: 'sfx/send.wav',
    Sfx.receive: 'sfx/receive.wav',
    Sfx.camera: 'sfx/camera.wav',
    Sfx.sparkle: 'sfx/sparkle.wav',
    Sfx.chime: 'sfx/chime.wav',
  };

  /// Quantos timbres carregaram (para o diagnóstico mostrar).
  int get carregados => _pools.values.where((p) => p != null).length;
  bool get ativo => _on;

  void setEnabled(bool v) {
    _on = v;
  }

  /// Pré-carrega todos os pools uma única vez. Nunca lança.
  Future<void> ensure() async {
    if (_ready || _loading) return;
    _loading = true;
    try {
      for (final entry in _arquivos.entries) {
        try {
          _pools[entry.key] = await AudioPool.create(
            source: AssetSource(entry.value),
            maxPlayers: 3,
          );
        } catch (_) {
          _pools[entry.key] = null; // plataforma sem áudio → silêncio
        }
      }
      _ready = true;
    } catch (_) {
      // ambiente sem canais de áudio (testes) → o app segue mudo
    } finally {
      _loading = false;
    }
  }

  /// Toca um timbre cru. Falha em silêncio.
  Future<void> play(Sfx s, {double volume = 0.7}) async {
    if (!_on) return;
    try {
      await ensure();
      await _pools[s]?.start(volume: volume);
    } catch (_) {}
  }

  // ── Verbos semânticos — som + háptico juntos, uma só chamada ──────────────

  /// Navegação, escolhas leves.
  void tap() {
    HapticFeedback.selectionClick();
    play(Sfx.tap, volume: 0.5);
  }

  /// Interruptores (tema, som), adicionar/remover estado.
  void toggle() {
    HapticFeedback.lightImpact();
    play(Sfx.toggle, volume: 0.6);
  }

  /// Passo do ritual concluído.
  void complete() {
    HapticFeedback.lightImpact();
    play(Sfx.complete, volume: 0.75);
  }

  /// Conquista: ritual completa, onboarding termina.
  void success() {
    HapticFeedback.mediumImpact();
    play(Sfx.success, volume: 0.85);
  }

  /// Mensagem enviada no chat.
  void send() => play(Sfx.send, volume: 0.55);

  /// Resposta da Aura chegou.
  void receive() => play(Sfx.receive, volume: 0.7);

  /// Foto tirada / anexada.
  void camera() {
    HapticFeedback.lightImpact();
    play(Sfx.camera, volume: 0.7);
  }

  /// Ganho de XP especial, análise pronta.
  void sparkle() => play(Sfx.sparkle, volume: 0.6);

  /// Assinatura de arranque — a aura acende.
  void chime() => play(Sfx.chime, volume: 0.55);
}
