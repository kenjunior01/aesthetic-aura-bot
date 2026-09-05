/// diario_store.dart — o Diário de Evolução: cada scan fica registado com
/// data, leituras e miniatura da foto. É a linha do tempo da tua aura:
/// como estavas, como estás. Local (SharedPreferences), máximo 12 entradas.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EntradaDiario {
  const EntradaDiario({
    required this.id,
    required this.data,
    required this.faceShape,
    required this.skinTone,
    required this.undertone,
    required this.hairColor,
    required this.fonte,
    this.thumb,
  });

  final String id; // ISO da hora de criação
  final String data; // '2026-09-05'
  final String faceShape;
  final int skinTone; // 0 = não lido
  final String undertone;
  final String hairColor;

  /// 'ai' | 'local'
  final String fonte;

  /// Miniatura JPEG base64 (sem prefixo) — opcional.
  final String? thumb;

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data,
    'faceShape': faceShape,
    'skinTone': skinTone,
    'undertone': undertone,
    'hairColor': hairColor,
    'fonte': fonte,
    'thumb': thumb,
  };

  static EntradaDiario fromJson(Map<String, dynamic> j) => EntradaDiario(
    id: '${j['id'] ?? ''}',
    data: '${j['data'] ?? ''}',
    faceShape: '${j['faceShape'] ?? ''}',
    skinTone: (j['skinTone'] as num?)?.toInt() ?? 0,
    undertone: '${j['undertone'] ?? ''}',
    hairColor: '${j['hairColor'] ?? ''}',
    fonte: '${j['fonte'] ?? 'local'}',
    thumb: j['thumb'] as String?,
  );
}

class DiarioStore extends ChangeNotifier {
  DiarioStore();

  static const _prefsKey = 'aurastyle-diario-v1';
  static const _maxEntradas = 12;

  List<EntradaDiario> _entradas = const [];
  bool _loaded = false;

  /// Da mais recente para a mais antiga.
  List<EntradaDiario> get entradas => List.unmodifiable(_entradas);
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _entradas = [
          for (final e in list)
            if (e is Map<String, dynamic>) EntradaDiario.fromJson(e),
        ];
      } catch (_) {
        _entradas = const [];
      }
    }
    _ordenar();
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode([for (final e in _entradas) e.toJson()]),
    );
  }

  void _ordenar() =>
      _entradas.sort((a, b) => b.id.compareTo(a.id)); // ISO desce no tempo

  void adicionar(EntradaDiario entrada) {
    _entradas = [
      entrada,
      ..._entradas.where((e) => e.id != entrada.id),
    ].take(_maxEntradas).toList();
    _persistir();
    notifyListeners();
  }

  void remover(String id) {
    _entradas = _entradas.where((e) => e.id != id).toList();
    _persistir();
    notifyListeners();
  }

  /// Miniatura pequena da foto do scan (largura 128, PNG) — para a timeline.
  static Future<String?> miniatura(XFile foto) async {
    try {
      final bytes = await foto.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 128,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();
      if (data == null) return null;
      return base64Encode(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }
}
