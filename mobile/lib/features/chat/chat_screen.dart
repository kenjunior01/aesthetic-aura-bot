/// chat_screen.dart — o chatbot da Aura: adapta-se ao teu perfil, aceita
/// FOTOS (câmara/galeria/partilha) e responde a QUALQUER dúvida — beleza,
/// estilo, ou a vida lá fora. Bolhas de vidro, digitando com aura.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/aura_api.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/sfx/aura_voz.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final List<_Msg> _messages = [];
  Uint8List? _pendente; // foto à espera de ser enviada
  bool _thinking = false;

  static const _histKey = 'aurastyle-chat-hist-v1';

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  /// O histórico SOBREVIVE ao fechar do app (últimas 40 mensagens).
  /// Imagens só nos 6 turnos mais recentes — o resto segue em texto
  /// (prefs leves, arranque rápido).
  Future<void> _carregarHistorico() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_histKey) ?? const [];
      final carregadas = <_Msg>[
        for (final linha in raw)
          if (linha.isNotEmpty)
            _Msg.fromJson((jsonDecode(linha) as Map).cast<String, dynamic>()),
      ];
      if (!mounted || carregadas.isEmpty) return;
      setState(() => _messages.addAll(carregadas));
      _bump();
    } catch (_) {
      // histórico corrompido → começa limpo
    }
  }

  Future<void> _persistirHistorico() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimas = _messages.length > 40
          ? _messages.sublist(_messages.length - 40)
          : _messages;
      final linhas = <String>[
        for (var i = 0; i < ultimas.length; i++)
          jsonEncode(ultimas[i].toJson(comImagem: i >= ultimas.length - 6)),
      ];
      await prefs.setStringList(_histKey, linhas);
    } catch (_) {
      // prefs cheias etc. — o chat continua a funcionar na sessão
    }
  }

  static const _suggestions = [
    'Que cores favorecem o meu subtom?',
    'Ideias de presente para alguém especial',
    'Corte para o meu formato de rosto?',
    'Como organizar o meu dia?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    AuraVoz.I.parar(); // sair do chat corta a voz
    super.dispose();
  }

  Future<void> _escolherFoto({required bool camera}) async {
    try {
      final x = await _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1280,
        imageQuality: 80,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _pendente = bytes);
      AuraSfx.I.camera();
    } catch (_) {
      // permissão negada etc. — segue sem foto
    }
  }

  void _menuFoto() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                iconColor: AuraColors.primary,
                title: Text('Tirar foto agora', style: AuraType.body),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _escolherFoto(camera: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                iconColor: AuraColors.primary,
                title: Text('Escolher da galeria', style: AuraType.body),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _escolherFoto(camera: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    final foto = _pendente;
    if ((text.isEmpty && foto == null) || _thinking) return;
    _input.clear();
    final historico = _messages
        .take(12)
        .map((m) => {'role': m.role, 'content': m.text})
        .toList();
    setState(() {
      _messages.add(_Msg(role: 'user', text: text, image: foto));
      _pendente = null;
      _thinking = true;
    });
    AuraSfx.I.send();
    _bump();

    try {
      final store = context.read<ProfileStore>();
      // Telemetria → alimenta a missão 'Fala com a Aura'.
      store.logEvent('chat_msg', {'tem_foto': foto != null});

      // BOLHA VIVA: entra já no ecrã e cresce com os deltas do Groq
      // (streaming SSE). Se a stream falhar, a cadeia de reserva
      // (backend → local) preenche a mesma bolha no fim.
      final live = _Msg(role: 'assistant', text: '', streaming: true);
      setState(() {
        _messages.add(live);
        _thinking = false;
      });
      _bump();

      final reply = await AuraApi.I.chat(
        message: text.isEmpty
            ? 'O que vês nesta foto e o que recomendas?'
            : text,
        profile: store.aiContext(),
        history: historico,
        imageBase64: foto == null ? null : base64Encode(foto),
        onDelta: (delta) {
          live.text += delta;
          if (mounted) {
            setState(() {});
            _bump();
          }
        },
      );
      if (!mounted) return;
      // Se a streaming não entregou nada (foto / fallback), mostra já.
      live.text = reply.text;
      live.streaming = false;
      setState(() {});
      AuraSfx.I.receive();
      await _persistirHistorico();
      // A voz da Aura: se ligada (Perfil), lê a resposta COMPLETA em voz alta.
      AuraVoz.I.falar(reply.text);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (_messages.isNotEmpty &&
            _messages.last.role == 'assistant' &&
            _messages.last.text.isEmpty) {
          _messages.removeLast();
        }
        _messages.add(
          _Msg(
            role: 'assistant',
            text:
                'A IA não respondeu neste momento — tenta de novo daqui a pouco.',
          ),
        );
        _thinking = false;
      });
      await _persistirHistorico();
    }
    _bump();
  }

  void _bump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final name = store.profile.name.isEmpty
        ? 'Aura'
        : store.profile.name.split(' ').first;

    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.cardFill,
                        border: Border.all(color: AuraColors.border),
                      ),
                      child: const Icon(Icons.arrow_back, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Avatar com aura.
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AuraDecor.auraMetal,
                      boxShadow: AuraDecor.glowShadow(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.backgroundDeep,
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 18,
                        color: AuraColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aura', style: AuraType.cardTitle),
                        Text(
                          'para $name · responde a tudo · nível ${store.level}',
                          style: AuraType.caption.copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Mensagens.
            Expanded(
              child: _messages.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      controller: _scroll,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: _messages.length + (_thinking ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i == _messages.length) return _typingBubble();
                        return _bubble(_messages[i]);
                      },
                    ),
            ),

            // Sugestões.
            if (_messages.isEmpty)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final s in _suggestions)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => _send(s),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: AuraColors.surface,
                              border: Border.all(color: AuraColors.border),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              child: Text(
                                s,
                                style: AuraType.caption.copyWith(
                                  fontSize: 11.5,
                                  color: AuraColors.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Pré-visualização da foto pendente.
            if (_pendente != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _pendente!,
                        height: 92,
                        width: 92,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => _pendente = null),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AuraColors.backgroundDeep,
                            border: Border.all(color: AuraColors.border),
                          ),
                          child: const Icon(Icons.close, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Barra de entrada — com partilha de imagem.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _menuFoto,
                    child: Container(
                      width: 44,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.surface,
                        border: Border.all(color: AuraColors.border),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 21,
                        color: AuraColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: AuraType.body,
                      decoration: InputDecoration(
                        hintText: 'Pergunta o que quiseres…',
                        filled: true,
                        fillColor: AuraColors.surface,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => _send(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AuraDecor.auraMetal,
                        boxShadow: AuraDecor.glowShadow(alpha: 0.3),
                      ),
                      child: Icon(
                        Icons.arrow_upward,
                        size: 20,
                        color: AuraColors.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AuraDecor.auraMetal,
            boxShadow: AuraDecor.glowShadow(alpha: 0.34),
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.backgroundDeep,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 30,
              color: AuraColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('A tua Aura está pronta.', style: AuraType.cardTitle),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 34),
          child: Text(
            'Conhece o teu perfil — e responde a qualquer dúvida, '
            'de beleza à vida. Manda até uma foto.',
            textAlign: TextAlign.center,
            style: AuraType.caption,
          ),
        ),
      ],
    ),
  );

  Widget _bubble(_Msg m) {
    final mine = m.role == 'user';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.fromLTRB(
          m.image == null ? 15 : 6,
          m.image == null ? 11 : 6,
          15,
          m.image == null ? 11 : 6,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 5),
            bottomRight: Radius.circular(mine ? 5 : 18),
          ),
          gradient: mine ? AuraDecor.auraMetal : null,
          color: mine ? null : AuraColors.cardFill,
          border: mine ? null : Border.all(color: AuraColors.border),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (m.image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.memory(
                    m.image!,
                    width: 190,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (m.text.isNotEmpty)
              Text(
                m.text,
                style: AuraType.body.copyWith(
                  fontSize: 13.5,
                  color: mine ? AuraColors.onPrimary : AuraColors.foreground,
                  fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            // A resposta a nascer: um fio de luz a pulsar no fim do texto.
            if (!mine && m.streaming && m.text.isNotEmpty) ...[
              const SizedBox(height: 7),
              const _FioVivo(),
            ],
            // Ouvir a resposta — o alto-falante nas bolhas da Aura.
            // (só quando a bolha terminou de nascer)
            if (!mine && !m.streaming && m.text.length > 12)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: _BotaoVoz(texto: m.text),
              ),
          ],
        ),
      ),
    );
  }

  Widget _typingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AuraColors.cardFill,
          border: Border.all(color: AuraColors.border),
        ),
        child: const _TypingDots(),
      ),
    );
  }
}

/// Alto-falante das bolhas da IA: toca/para a voz da resposta.
class _BotaoVoz extends StatelessWidget {
  const _BotaoVoz({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: AuraVoz.I.estado,
      initialData: AuraVoz.I.falando,
      builder: (context, snap) {
        final aFalar = snap.data ?? false;
        return GestureDetector(
          onTap: () {
            if (aFalar) {
              AuraVoz.I.parar();
            } else {
              AuraSfx.I.tap();
              AuraVoz.I.falar(texto);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                aFalar ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: 15,
                color: AuraColors.primary,
              ),
              const SizedBox(width: 5),
              Text(
                aFalar ? 'parar' : 'ouvir',
                style: AuraType.chip.copyWith(
                  fontSize: 9.5,
                  color: AuraColors.primary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// O fio de luz que pulsa enquanto a resposta da IA está a ser escrita.
class _FioVivo extends StatefulWidget {
  const _FioVivo();

  @override
  State<_FioVivo> createState() => _FioVivoState();
}

class _FioVivoState extends State<_FioVivo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 34,
        height: 3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: AuraDecor.auraMetal,
        ),
      ),
    );
  }
}

class _Msg {
  _Msg({
    required this.role,
    required this.text,
    this.image,
    this.streaming = false,
  });
  String role;
  String text;
  Uint8List? image;
  bool streaming; // a resposta ainda está a ser escrita (bolha viva)

  Map<String, dynamic> toJson({bool comImagem = true}) => {
    'role': role,
    'text': text,
    if (comImagem && image != null) 'image': base64Encode(image!),
  };

  factory _Msg.fromJson(Map<String, dynamic> j) => _Msg(
    role: '${j['role'] ?? 'assistant'}',
    text: '${j['text'] ?? ''}',
    image: j['image'] is String
        ? Uint8List.fromList(base64Decode(j['image'] as String))
        : null,
  );
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final phase = (_c.value * 3 - i).clamp(0.0, 1.0);
              final scale = 0.6 + 0.4 * (1 - (2 * phase - 1).abs());
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AuraColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
