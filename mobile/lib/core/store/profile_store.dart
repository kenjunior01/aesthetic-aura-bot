/// profile_store.dart — o MESMO perfil do web, persistido localmente.
///
/// Espelha `src/lib/aura-store.ts` (chave `aurastyle-profile`, mesma forma de
/// Profile, mesma fórmula de nível floor(sqrt(xp/50))+1). Quando o sync cloud
/// do web estiver ativo, os dois clientes leem/escrevem o mesmo utilizador.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sfx/aura_sfx.dart';
import '../sfx/aura_voz.dart';
import '../theme/aura_colors.dart';

/// Títulos de nível — a escada de prestígio da AuraStyle.
/// (nível mínimo → título) — o nível sobe com floor(sqrt(xp/50))+1.
const List<({int min, String titulo})> kNivelTitulos = [
  (min: 1, titulo: 'Despertar'),
  (min: 2, titulo: 'Presença'),
  (min: 3, titulo: 'Assinatura'),
  (min: 4, titulo: 'Radiancia'),
  (min: 5, titulo: 'Ícone de Estilo'),
  (min: 7, titulo: 'Lenda Urbana'),
  (min: 10, titulo: 'Aura Suprema'),
];

/// Título do nível — o mais alto atingido pela escada.
String nivelTitulo(int nivel) {
  var titulo = kNivelTitulos.first.titulo;
  for (final t in kNivelTitulos) {
    if (nivel >= t.min) titulo = t.titulo;
  }
  return titulo;
}

class Profile {
  const Profile({
    this.name = '',
    this.email = '',
    this.gender = '',
    this.age = 0,
    this.region = '',
    this.country = '',
    this.city = '',
    this.priorities = const [],
    this.selfie,
    this.faceShape = '',
    this.skinTone = 0,
    this.undertone = '',
    this.eyeColor = '',
    this.hairType = '',
    this.hairColor = '',
    this.hairLength = '',
    this.bodyType = '',
    this.height = 0,
    this.weight = 0,
    this.styles = const [],
    this.colors = const [],
    this.budget = '',
    this.profession = '',
    this.climate = '',
    this.notes = '',
    this.espelho = const [],
  });

  final String name;
  final String email;
  final String gender;
  final int age;
  final String region;
  final String country;
  final String city;
  final List<String> priorities;
  final String? selfie; // base64 (sem prefixo data:)
  final String faceShape;
  final int skinTone; // 1-10
  final String undertone;
  final String eyeColor;
  final String hairType;
  final String hairColor;
  final String hairLength;
  final String bodyType;
  final int height;
  final int weight;
  final List<String> styles;
  final List<String> colors;
  final String budget;
  final String profession;
  final String climate;
  final String notes;

  /// Referências visuais do Espelho — imagens reais que definem a pessoa
  /// (ids/urls do banco de imagens + uploads locais).
  final List<String> espelho;

  bool get hasScan => faceShape.isNotEmpty || skinTone > 0;

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'gender': gender,
    'age': age,
    'region': region,
    'country': country,
    'city': city,
    'priorities': priorities,
    'selfie': selfie,
    'faceShape': faceShape,
    'skinTone': skinTone,
    'undertone': undertone,
    'eyeColor': eyeColor,
    'hairType': hairType,
    'hairColor': hairColor,
    'hairLength': hairLength,
    'bodyType': bodyType,
    'height': height,
    'weight': weight,
    'styles': styles,
    'colors': colors,
    'budget': budget,
    'profession': profession,
    'climate': climate,
    'notes': notes,
    'espelho': espelho,
  };

  static Profile fromJson(Map<String, dynamic> j) => Profile(
    name: '${j['name'] ?? ''}',
    email: '${j['email'] ?? ''}',
    gender: '${j['gender'] ?? ''}',
    age: (j['age'] as num?)?.toInt() ?? 0,
    region: '${j['region'] ?? ''}',
    country: '${j['country'] ?? ''}',
    city: '${j['city'] ?? ''}',
    priorities:
        (j['priorities'] as List?)?.map((e) => '$e').toList() ?? const [],
    selfie: j['selfie'] as String?,
    faceShape: '${j['faceShape'] ?? ''}',
    skinTone: (j['skinTone'] as num?)?.toInt() ?? 0,
    undertone: '${j['undertone'] ?? ''}',
    eyeColor: '${j['eyeColor'] ?? ''}',
    hairType: '${j['hairType'] ?? ''}',
    hairColor: '${j['hairColor'] ?? ''}',
    hairLength: '${j['hairLength'] ?? ''}',
    bodyType: '${j['bodyType'] ?? ''}',
    height: (j['height'] as num?)?.toInt() ?? 0,
    weight: (j['weight'] as num?)?.toInt() ?? 0,
    styles: (j['styles'] as List?)?.map((e) => '$e').toList() ?? const [],
    colors: (j['colors'] as List?)?.map((e) => '$e').toList() ?? const [],
    budget: '${j['budget'] ?? ''}',
    profession: '${j['profession'] ?? ''}',
    climate: '${j['climate'] ?? ''}',
    notes: '${j['notes'] ?? ''}',
    espelho: (j['espelho'] as List?)?.map((e) => '$e').toList() ?? const [],
  );

  Profile copyWith({
    String? name,
    String? email,
    String? gender,
    int? age,
    String? region,
    String? country,
    String? city,
    List<String>? priorities,
    String? selfie,
    String? faceShape,
    int? skinTone,
    String? undertone,
    String? eyeColor,
    String? hairType,
    String? hairColor,
    String? hairLength,
    String? bodyType,
    int? height,
    int? weight,
    List<String>? styles,
    List<String>? colors,
    String? budget,
    String? profession,
    String? climate,
    String? notes,
    List<String>? espelho,
  }) => Profile(
    name: name ?? this.name,
    email: email ?? this.email,
    gender: gender ?? this.gender,
    age: age ?? this.age,
    region: region ?? this.region,
    country: country ?? this.country,
    city: city ?? this.city,
    priorities: priorities ?? this.priorities,
    selfie: selfie ?? this.selfie,
    faceShape: faceShape ?? this.faceShape,
    skinTone: skinTone ?? this.skinTone,
    undertone: undertone ?? this.undertone,
    eyeColor: eyeColor ?? this.eyeColor,
    hairType: hairType ?? this.hairType,
    hairColor: hairColor ?? this.hairColor,
    hairLength: hairLength ?? this.hairLength,
    bodyType: bodyType ?? this.bodyType,
    height: height ?? this.height,
    weight: weight ?? this.weight,
    styles: styles ?? this.styles,
    colors: colors ?? this.colors,
    budget: budget ?? this.budget,
    profession: profession ?? this.profession,
    climate: climate ?? this.climate,
    notes: notes ?? this.notes,
    espelho: espelho ?? this.espelho,
  );
}

/// Marcos de streak — idênticos ao web (aura-store.ts).
const List<({int days, int xp, String label})> kStreakMilestones = [
  (days: 3, xp: 30, label: 'Aquecimento'),
  (days: 7, xp: 50, label: 'Semana perfeita'),
  (days: 14, xp: 75, label: 'Duas semanas'),
  (days: 30, xp: 150, label: 'Mês de ouro'),
  (days: 60, xp: 300, label: 'Lenda'),
  (days: 100, xp: 600, label: 'Ícone'),
];

int calculateLevel(int xp) {
  if (xp <= 0) return 1;
  return math.sqrt(xp / 50).floor() + 1;
}

/// Progresso dentro do nível atual (0..1) — mesma curva do web.
double computeLevelProgress(int xp) {
  final level = calculateLevel(xp);
  final cur = 50.0 * (level - 1) * (level - 1);
  final next = 50.0 * level * level;
  if (next <= cur) return 0;
  return ((xp - cur) / (next - cur)).clamp(0.0, 1.0);
}

({int days, int xp, String label})? nextStreakMilestone(int streak) {
  for (final m in kStreakMilestones) {
    if (m.days > streak) return m;
  }
  return null;
}

class ProfileStore extends ChangeNotifier {
  ProfileStore();

  static const _prefsKey = 'aurastyle-profile'; // MESMA chave do web
  static const _stateKey = 'aurastyle-profile-state';
  static const _ritualKey = 'aurastyle-ritual-v1';
  static const _onboardedKey = 'aurastyle-onboarded-v1';
  static const _modoClaroKey = 'aurastyle-modo-claro';
  static const _sfxKey = 'aurastyle-sfx-on';
  static const _vozKey = 'aurastyle-voz-on';

  /// Passos do ritual diário — idênticos ao espírito do web (5 passos,
  /// 25 XP ao completar).
  static const List<String> kRitualSteps = [
    'Beber água logo cedo',
    'Limpeza de rosto',
    'Hidratante com proteção solar',
    'Cuidado capilar',
    'Registo noturno no diário',
  ];

  Profile _profile = const Profile();
  int _xp = 0;
  int _streak = 0;
  List<String> _events = const [];
  bool _loaded = false;
  String _ritualDate = '';
  List<int> _ritualDone = const [];
  bool _onboarded = false;
  bool _modoClaro = false;
  bool _sfxOn = true;
  bool _vozOn = false;
  int? _levelUpNovo; // nível acabado de alcançar (celebração pendente)

  Profile get profile => _profile;
  int get xp => _xp;
  int get streak => _streak;
  int get level => calculateLevel(_xp);
  double get levelProgress => computeLevelProgress(_xp);
  List<String> get events => List.unmodifiable(_events);
  bool get loaded => _loaded;
  bool get onboarded => _onboarded;
  bool get modoClaro => _modoClaro;

  /// Identidade sonora do app (tap, chime, sucesso…) — o utilizador manda.
  bool get sfxOn => _sfxOn;

  /// A voz da Aura (TTS) — fala as respostas do chat. O utilizador manda.
  bool get vozOn => _vozOn;

  /// Nível recém-alcançado (overlay de celebração pendente) — null se nenhum.
  int? get levelUpNovo => _levelUpNovo;

  void clearLevelUp() => _levelUpNovo = null;

  /// Ritual de hoje: passos concluídos (recalcula se virou o dia).
  List<int> get ritualDone {
    if (_ritualDate != _todayKey()) return const [];
    return List.unmodifiable(_ritualDone);
  }

  bool get ritualComplete => ritualDone.length >= kRitualSteps.length;

  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  ({int days, int xp, String label})? get nextMilestone =>
      nextStreakMilestone(_streak);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stateKey) ?? prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final map = jsonDecode(raw);
        if (map is Map) {
          final state = map['state'] is Map ? map['state'] as Map : map;
          _profile = Profile.fromJson(
            (state['profile'] as Map?)?.cast<String, dynamic>() ?? const {},
          );
          _xp = (state['xp'] as num?)?.toInt() ?? 0;
          _streak = (state['streak'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {
        // perfil corrompido → recomeça limpo, nunca bloqueia o app
      }
    }
    _events = prefs.getStringList('aurastyle-events') ?? const [];
    _ritualDate = prefs.getString('$_ritualKey-date') ?? '';
    _ritualDone =
        prefs.getStringList('$_ritualKey-done')?.map(int.parse).toList() ??
        const [];
    _onboarded = prefs.getBool(_onboardedKey) ?? false;
    _modoClaro = prefs.getBool(_modoClaroKey) ?? false;
    _sfxOn = prefs.getBool(_sfxKey) ?? true;
    AuraSfx.I.setEnabled(_sfxOn);
    _vozOn = prefs.getBool(_vozKey) ?? false;
    AuraVoz.I.setEnabled(_vozOn);
    AuraColors.modo = _modoClaro ? ModoCromatico.alvor : ModoCromatico.noite;
    _loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _stateKey,
      jsonEncode({
        'state': {'profile': _profile.toJson(), 'xp': _xp, 'streak': _streak},
        'version': 0,
      }),
    );
  }

  void updateProfile(Profile Function(Profile) updater) {
    _profile = updater(_profile);
    save();
    notifyListeners();
  }

  void addXp(int amount) {
    final antes = calculateLevel(_xp);
    _xp = (_xp + amount).clamp(0, 1 << 31);
    // Cruzou um nível? Guarda para a celebração (o shell mostra o overlay).
    final agora = calculateLevel(_xp);
    if (agora > antes && _levelUpNovo == null) _levelUpNovo = agora;
    save();
    notifyListeners();
  }

  void bumpStreak() {
    _streak += 1;
    addXp(25); // ROUTINE_COMPLETE_XP
  }

  /// Liga/desliga um passo do ritual de hoje.
  /// Cada passo +5 XP; ao completar os 5, +25 XP de bónus e streak +1.
  void toggleRitual(int index) {
    if (index < 0 || index >= kRitualSteps.length) return;
    if (_ritualDate != _todayKey()) {
      _ritualDate = _todayKey();
      _ritualDone = const [];
    }
    final wasComplete = ritualComplete;
    _ritualDone = _ritualDone.contains(index)
        ? _ritualDone.where((i) => i != index).toList()
        : [..._ritualDone, index];
    _xp = (_xp + (_ritualDone.contains(index) ? 5 : -5)).clamp(0, 1 << 31);
    if (!wasComplete && ritualComplete) {
      addXp(25);
      _streak += 1;
    }
    SharedPreferences.getInstance().then((p) async {
      await p.setString('$_ritualKey-date', _ritualDate);
      await p.setStringList(
        '$_ritualKey-done',
        _ritualDone.map((i) => '$i').toList(),
      );
    });
    notifyListeners();
  }

  /// Marca o onboarding como concluído (não volta a mostrar).
  void completeOnboarding() {
    _onboarded = true;
    SharedPreferences.getInstance().then((p) => p.setBool(_onboardedKey, true));
    notifyListeners();
  }

  /// Alterna Noite ↔ Alvor. Persistido e aplicado aos tokens vivos;
  /// o app raiz observa e reconstrói a árvore com uma nova key.
  void setModoClaro(bool claro) {
    if (_modoClaro == claro) return;
    _modoClaro = claro;
    AuraColors.modo = claro ? ModoCromatico.alvor : ModoCromatico.noite;
    SharedPreferences.getInstance().then(
      (p) => p.setBool(_modoClaroKey, claro),
    );
    notifyListeners();
  }

  /// Liga/desliga a identidade sonora (Perfil → Sons do app).
  void setSfx(bool on) {
    _sfxOn = on;
    AuraSfx.I.setEnabled(on);
    SharedPreferences.getInstance().then((p) => p.setBool(_sfxKey, on));
    notifyListeners();
  }

  /// Liga/desliga a voz da Aura (Perfil → Voz da Aura).
  void setVoz(bool on) {
    _vozOn = on;
    AuraVoz.I.setEnabled(on);
    SharedPreferences.getInstance().then((p) => p.setBool(_vozKey, on));
    notifyListeners();
  }

  /// Telemetria local (espelha logEvent do services.ts) — últimos 100.
  void logEvent(String name, [Map<String, dynamic>? props]) {
    final entry =
        '${DateTime.now().toIso8601String()} $name'
        '${props == null ? '' : ' ${jsonEncode(props)}'}';
    _events = [..._events.take(99), entry];
    SharedPreferences.getInstance().then(
      (p) => p.setStringList('aurastyle-events', _events),
    );
    notifyListeners();
  }

  /// Contexto resumido para as rotas de IA (mesmo contrato do web).
  Map<String, dynamic> aiContext() => {
    'name': _profile.name,
    'gender': _profile.gender,
    'age': _profile.age,
    'city': _profile.city,
    'country': _profile.country,
    'faceShape': _profile.faceShape,
    'skinTone': _profile.skinTone,
    'undertone': _profile.undertone,
    'hairType': _profile.hairType,
    'hairColor': _profile.hairColor,
    'hairLength': _profile.hairLength,
    'styles': _profile.styles,
    'colors': _profile.colors,
    'priorities': _profile.priorities,
    'budget': _profile.budget,
    'level': level,
    'xp': _xp,
  };
}
