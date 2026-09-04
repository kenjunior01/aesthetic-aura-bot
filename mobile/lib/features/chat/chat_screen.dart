/// chat_screen.dart — o chatbot da Aura: adapta-se ao teu perfil, aceita
/// FOTOS (câmara/galeria/partilha) e responde a QUALQUER dúvida — beleza,
/// estilo, ou a vida lá fora. Bolhas de vidro, digitando com aura.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/aura_api.dart';
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
      HapticFeedback.selectionClick();
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
    setState(() {
      _messages.add(_Msg(role: 'user', text: text, image: foto));
      _pendente = null;
      _thinking = true;
    });
    _bump();

    try {
      final store = context.read<ProfileStore>();
      final reply = await AuraApi.I.chat(
        message: text.isEmpty ? 'O que vês nesta foto e o que recomendas?' : text,
        profile: store.aiContext(),
        history: _messages
            .take(12)
            .map((m) => {'role': m.role, 'content': m.text})
            .toList(),
        imageBase64: foto == null ? null : base64Encode(foto),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(role: 'assistant', text: reply.text));
        _thinking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _Msg(
            role: 'assistant',
            text: 'A IA não respondeu neste momento — tenta de novo daqui a pouco.',
          ),
        );
        _thinking = false;
      });
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

class _Msg {
  const _Msg({required this.role, required this.text, this.image});
  final String role;
  final String text;
  final Uint8List? image;
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
