/// missoes_store.dart — MISSÕES DA SEMANA: a camada de jogo da Aura.
///
///  • 5 missões escolhidas por semana (ISO) de um convés de 7 — cada semana
///    é uma combinação nova, sem repetir a anterior.
///  • O progresso alimenta-se da telemetria que já existe: o store observa
///    o ProfileStore e ingere os logEvent novos (zero acoplamento nas
///    features — quem faz logEvent("scan_complete") já está a pontuar).
///  • Completar uma missão dá XP (via ProfileStore.addXp) e fica marcada
///    para a celebração no cartão (confetti + som).
///  • Persistido em SharedPreferences sob 'aurastyle-missoes' — quando o
///    ISO da semana muda, tudo renasce limpo.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../store/profile_store.dart';

/// Uma missão do convés — imutável, definida aqui.
class Missao {
  const Missao({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.icone,
    required this.evento,
    required this.alvo,
    required this.xp,
    required this.destino,
  });

  final String id;
  final String titulo;
  final String descricao;
  final IconData icone;
  final String evento; // nome do logEvent que alimenta o progresso
  final int alvo; // quantas vezes precisa
  final int xp;

  /// Rota a abrir quando a missão é tocada (nome simbólico — o cartão mapeia
  /// para as screens reais).
  final String destino;
}

/// O convés completo — 7 missões possíveis, 5 entram na semana.
const List<Missao> kConvesMissoes = [
  Missao(
    id: 'scan',
    titulo: 'Ler a tua aura',
    descricao: 'Faz um scan de rosto no instrumento',
    icone: Icons.center_focus_strong,
    evento: 'scan_complete',
    alvo: 1,
    xp: 40,
    destino: 'scan',
  ),
  Missao(
    id: 'checkin',
    titulo: 'Ponto de controlo',
    descricao: 'Partilha uma foto na tua Jornada do Auge',
    icone: Icons.route_outlined,
    evento: 'jornada_checkin',
    alvo: 1,
    xp: 60,
    destino: 'jornada',
  ),
  Missao(
    id: 'cromatica',
    titulo: 'Visita à estação',
    descricao: 'Volta à tua análise cromática',
    icone: Icons.palette_outlined,
    evento: 'cromatica_open',
    alvo: 1,
    xp: 20,
    destino: 'cromatica',
  ),
  Missao(
    id: 'closet',
    titulo: 'Provador',
    descricao: 'Escolhe 2 peças no teu armário',
    icone: Icons.checkroom_outlined,
    evento: 'closet_pick',
    alvo: 2,
    xp: 25,
    destino: 'closet',
  ),
  Missao(
    id: 'lookalike',
    titulo: 'Parentes de estilo',
    descricao: 'Compara a tua cara com as referências',
    icone: Icons.face_retouching_natural,
    evento: 'lookalike_compare',
    alvo: 1,
    xp: 30,
    destino: 'references',
  ),
  Missao(
    id: 'chat',
    titulo: 'Fala com a Aura',
    descricao: 'Pede 2 conselhos no chat',
    icone: Icons.chat_bubble_outline,
    evento: 'chat_msg',
    alvo: 2,
    xp: 25,
    destino: 'chat',
  ),
  Missao(
    id: 'explorar',
    titulo: 'Caça à inspiração',
    descricao: 'Visita o Ateliê e o Acervo',
    icone: Icons.explore_outlined,
    evento: 'explorar_open',
    alvo: 1,
    xp: 15,
    destino: 'explorar',
  ),
];

/// Chave ISO-8601 da semana: '2026-W36'.
String semanaIsoKey([DateTime? agora]) {
  final d = (agora ?? DateTime.now()).toLocal();
  // Quinta-feira decide o ano ISO.
  final quinta = d.add(Duration(days: 3 - ((d.weekday - DateTime.monday) % 7)));
  final primeiroJan = DateTime(quinta.year, 1, 1);
  final semana = ((quinta.difference(primeiroJan).inDays) / 7).floor() + 1;
  return '${quinta.year}-W${semana.toString().padLeft(2, '0')}';
}

class MissaoEstado {
  const MissaoEstado({
    required this.missao,
    required this.progresso,
    required this.feita,
  });

  final Missao missao;
  final int progresso;
  final bool feita;

  double get fracao =>
      missao.alvo == 0 ? 0 : (progresso / missao.alvo).clamp(0, 1).toDouble();
}

class MissaoStore extends ChangeNotifier {
  MissaoStore(this._perfil) {
    _perfil.addListener(_ingerir);
  }

  final ProfileStore _perfil;

  static const _prefsKey = 'aurastyle-missoes';

  List<Missao> _missoes = const [];
  final Map<String, int> _progresso = {};
  final Set<String> _feitas = {};
  String _semana = '';
  int _xpSemana = 0;
  int _semanasPerfeitas = 0;

  /// Missão concluída nesta sessão à espera de celebração (o cartão consome).
  Missao? _celebracao;
  bool _aProcessar = false;
  int _ultimoIndiceIngerido = -1;

  List<Missao> get missoes => List.unmodifiable(_missoes);
  String get semana => _semana;
  int get feitasCount => _feitas.length;
  int get xpSemana => _xpSemana;
  int get semanasPerfeitas => _semanasPerfeitas;
  bool get semanaPerfeita =>
      _missoes.isNotEmpty && _feitas.length == _missoes.length;
  bool get temCelebracao => _celebracao != null;
  Missao? get celebracaoPendente => _celebracao;

  List<MissaoEstado> get estados => [
    for (final m in _missoes)
      MissaoEstado(
        missao: m,
        progresso: _progresso[m.id] ?? 0,
        feita: _feitas.contains(m.id),
      ),
  ];

  /// Fracao global da semana (para o anel do cartão).
  double get fracaoSemana {
    if (_missoes.isEmpty) return 0;
    var soma = 0.0;
    for (final m in _missoes) {
      soma += _feitas.contains(m.id)
          ? 1.0
          : ((_progresso[m.id] ?? 0) / m.alvo).clamp(0, 1).toDouble();
    }
    return soma / _missoes.length;
  }

  /// Carrega do disco (ou cria a semana).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _semana = semanaIsoKey();
    final raw = prefs.getString(_prefsKey);
    if (raw != null) {
      try {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        if ((j['semana'] as String?) == _semana) {
          _missoes = _missoesDaSemana(_semana);
          final prog = (j['progresso'] as Map?)?.cast<String, dynamic>() ?? {};
          for (final e in prog.entries) {
            _progresso[e.key] = (e.value as num?)?.toInt() ?? 0;
          }
          _feitas.addAll(
            ((j['feitas'] as List?) ?? const []).cast<String>(),
          );
          _xpSemana = (j['xp'] as num?)?.toInt() ?? 0;
          _semanasPerfeitas = (j['perfeitas'] as num?)?.toInt() ?? 0;
        }
      } catch (_) {
        // estado corrompido → semana nova limpa
      }
    }
    if (_missoes.isEmpty) _renascer(_semana);
    _ultimoIndiceIngerido = _perfil.events.length - 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _perfil.removeListener(_ingerir);
    super.dispose();
  }

  /// As 5 missões desta semana: rotação determinística pelo número da semana
  /// — cada semana muda o combo e nunca repete a ordem.
  List<Missao> _missoesDaSemana(String chave) {
    final n = int.tryParse(chave.split('W').last) ?? 0;
    final offset = n % kConvesMissoes.length;
    return [
      for (var i = 0; i < 5; i++)
        kConvesMissoes[(offset + i) % kConvesMissoes.length],
    ];
  }

  void _renascer(String chave) {
    // A semana fechou completa? Sobe a chama das semanas perfeitas.
    final fechouPerfeita = _semana.isNotEmpty && semanaPerfeita;
    _semanasPerfeitas = fechouPerfeita ? _semanasPerfeitas + 1 : 0;
    _semana = chave;
    _missoes = _missoesDaSemana(chave);
    _progresso.clear();
    _feitas.clear();
    _xpSemana = 0;
    _persistir();
  }

  /// Observa o ProfileStore: cada logEvent novo alimenta a missão certa.
  void _ingerir() {
    if (_aProcessar) return;
    final eventos = _perfil.events;
    if (_ultimoIndiceIngerido >= eventos.length) {
      _ultimoIndiceIngerido = eventos.length - 1;
    }
    if (_ultimoIndiceIngerido + 1 >= eventos.length) return;
    _aProcessar = true;
    try {
      // A semana mudou enquanto o app estava vivo? (madrugada de domingo)
      final chave = semanaIsoKey();
      if (chave != _semana) _renascer(chave);
      for (var i = _ultimoIndiceIngerido + 1; i < eventos.length; i++) {
        final partes = eventos[i].split(' ');
        final nome = partes.length > 1 ? partes[1] : '';
        Missao? missao;
        for (final m in _missoes) {
          if (m.evento == nome) {
            missao = m;
            break;
          }
        }
        if (missao == null || _feitas.contains(missao.id)) continue;
        final antes = _progresso[missao.id] ?? 0;
        final agora = (antes + 1).clamp(0, missao.alvo);
        _progresso[missao.id] = agora;
        if (agora >= missao.alvo) {
          _feitas.add(missao.id);
          _celebracao = missao;
          _xpSemana += missao.xp;
          _perfil.addXp(missao.xp);
          _perfil.logEvent('missao_done', {'id': missao.id, 'xp': missao.xp});
        }
        _persistir();
      }
      _ultimoIndiceIngerido = eventos.length - 1;
    } finally {
      _aProcessar = false;
    }
    notifyListeners();
  }

  /// O cartão consome a celebração (mostra o confetti uma única vez).
  Missao? consumirCelebracao() {
    final m = _celebracao;
    _celebracao = null;
    return m;
  }

  Future<void> _persistir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'semana': _semana,
        'progresso': _progresso,
        'feitas': _feitas.toList(),
        'xp': _xpSemana,
        'perfeitas': _semanasPerfeitas,
      }),
    );
  }
}
