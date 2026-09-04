/// chat_screen.dart — o chatbot da Aura, adaptado ao teu perfil: envia o
/// contexto completo (traços, cores, prioridades, nível) para /api/ai-chat —
/// a MESMA personalidade do web. Bolhas de vidro, digitando com aura.
library;

import 'package:flutter/material.dart';
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
  final List<_Msg> _messages = [];
  bool _thinking = false;

  static const _suggestions = [
    'Que cores favorecem o meu subtom?',
    'Corte para o meu formato de rosto?',
    'Constrói-me uma rotina de hoje',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty || _thinking) return;
    _input.clear();
    setState(() {
      _messages.add(_Msg(role: 'user', text: text));
      _thinking = true;
    });
    _bump();

    try {
      final store = context.read<ProfileStore>();
      final reply = await AuraApi.I.chat(
        message: text,
        profile: store.aiContext(),
        history: _messages
            .take(12)
            .map((m) => {'role': m.role, 'content': m.text})
            .toList(),
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
            text:
                'Não cheguei ao backend. Liga a API no Perfil → Ligação, '
                'e volto a responder com a tua aura completa.',
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
                      decoration:  BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.backgroundDeep,
                      ),
                      child:  Icon(
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
                          'adaptada a $name · nível ${store.level}',
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

            // Barra de entrada.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      style: AuraType.body,
                      decoration: InputDecoration(
                        hintText: 'Pede conselho à tua Aura…',
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
                      child:  Icon(
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
            decoration:  BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.backgroundDeep,
            ),
            child:  Icon(
              Icons.auto_awesome,
              size: 30,
              color: AuraColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('A tua Aura está pronta.', style: AuraType.cardTitle),
        const SizedBox(height: 6),
        Text(
          'Conhece o teu perfil, as tuas cores e o teu ritmo.',
          style: AuraType.caption,
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
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
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
        child: Text(
          m.text,
          style: AuraType.body.copyWith(
            fontSize: 13.5,
            color: mine ? AuraColors.onPrimary : AuraColors.foreground,
            fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
          ),
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
  const _Msg({required this.role, required this.text});
  final String role;
  final String text;
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
                    decoration:  BoxDecoration(
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
