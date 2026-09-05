/// onboarding_screen.dart — a entrada ceremonial: 3 gestos e a tua Aura
/// sabe quem és. Nome → prioridades → convenção feita. Só aparece uma vez.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/store/profile_store.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../shell/nav_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _name = TextEditingController();
  static const _kPriorities = [
    'pele',
    'cabelo',
    'estilo',
    'corpo',
    'rotina',
    'compras',
  ];
  static const _kLabels = {
    'pele': 'Pele',
    'cabelo': 'Cabelo',
    'estilo': 'Estilo',
    'corpo': 'Corpo',
    'rotina': 'Rotina',
    'compras': 'Compras',
  };
  final Set<String> _picked = {};
  int _page = 0;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _finish() {
    final store = context.read<ProfileStore>();
    store.updateProfile(
      (p) => p.copyWith(name: _name.text.trim(), priorities: _picked.toList()),
    );
    store.addXp(20);
    store.logEvent('onboarding_complete');
    store.completeOnboarding();
    AuraSfx.I.success(); // a tua aura está pronta — conquista de entrada
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, _, _) => const NavShell(),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(anim),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuraColors.backgroundDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: Column(
            children: [
              // Indicador de passos — 3 fios usinados.
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: i <= _page
                              ? AuraColors.primary
                              : AuraColors.surfaceStrong,
                          boxShadow: i == _page
                              ? AuraDecor.glowShadow(alpha: 0.5)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: switch (_page) {
                    0 => _welcome(key: const ValueKey(0)),
                    1 => _nameStep(key: const ValueKey(1)),
                    _ => _priorities(key: const ValueKey(2)),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Passo 1 · Bem-vinda ─────────────────────────────────────────────────────
  Widget _welcome({Key? key}) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Spacer(),
      Center(
        child: Container(
          width: 108,
          height: 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AuraDecor.auraMetal,
            boxShadow: AuraDecor.glowShadow(alpha: 0.5),
          ),
          padding: const EdgeInsets.all(3.5),
          child: Container(
            decoration:  BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.backgroundDeep,
            ),
            child:  Icon(
              Icons.auto_awesome,
              size: 44,
              color: AuraColors.primary,
            ),
          ),
        ),
      ),
      const SizedBox(height: 34),
       Text('AURA STYLE', style: AuraType.eyebrow),
      const SizedBox(height: 10),
      Text(
        'A tua aura,\nesculpida em platina.',
        style: AuraType.sectionTitle.copyWith(fontSize: 32, height: 1.1),
      ),
      const SizedBox(height: 14),
      Text(
        'Um assistente de estética que lê o teu rosto, as tuas cores e o '
        'teu ritmo — e devolve conselhos honestos, feitos para ti.',
        style: AuraType.caption.copyWith(fontSize: 13.5, height: 1.55),
      ),
      const Spacer(),
      PlatinaButton(
        label: 'Começar',
        icon: Icons.arrow_forward,
        expanded: true,
        onTap: () => setState(() => _page = 1),
      ),
    ],
  );

  // ── Passo 2 · Nome ──────────────────────────────────────────────────────────
  Widget _nameStep({Key? key}) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 40),
       Text('COMO TE CHAMAS?', style: AuraType.eyebrow),
      const SizedBox(height: 10),
      Text(
        'É assim que a tua Aura vai tratar-te.',
        style: AuraType.caption.copyWith(fontSize: 13.5, height: 1.5),
      ),
      const SizedBox(height: 26),
      TextField(
        controller: _name,
        style: AuraType.machinedNumber.copyWith(fontSize: 26),
        decoration: const InputDecoration(hintText: 'O teu nome'),
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _nextIfNamed(),
      ),
      const Spacer(),
      PlatinaButton(
        label: 'Continuar',
        icon: Icons.arrow_forward,
        expanded: true,
        onTap: _nextIfNamed,
      ),
    ],
  );

  void _nextIfNamed() {
    if (_name.text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _page = 2);
  }

  // ── Passo 3 · Prioridades ───────────────────────────────────────────────────
  Widget _priorities({Key? key}) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 40),
       Text('O QUE MAIS IMPORTA?', style: AuraType.eyebrow),
      const SizedBox(height: 10),
      Text(
        'Escolhe até 3 — o teu radar vai orbitar isto.',
        style: AuraType.caption.copyWith(fontSize: 13.5, height: 1.5),
      ),
      const SizedBox(height: 26),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final p in _kPriorities)
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  if (_picked.contains(p)) {
                    _picked.remove(p);
                  } else if (_picked.length < 3) {
                    _picked.add(p);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: _picked.contains(p) ? AuraDecor.auraMetal : null,
                  color: _picked.contains(p) ? null : AuraColors.surface,
                  border: Border.all(
                    color: _picked.contains(p)
                        ? Colors.transparent
                        : AuraColors.border,
                  ),
                  boxShadow: _picked.contains(p)
                      ? AuraDecor.glowShadow(alpha: 0.25)
                      : null,
                ),
                child: Text(
                  _kLabels[p]!,
                  style: AuraType.chip.copyWith(
                    fontSize: 12.5,
                    color: _picked.contains(p)
                        ? AuraColors.onPrimary
                        : AuraColors.mutedForeground,
                  ),
                ),
              ),
            ),
        ],
      ),
      const Spacer(),
      GlassCard(
        child: Text(
          'A tua cara nunca é partilhada sem a tua conta. O banco de dados '
          'é o mesmo do web — o teu perfil sincroniza com lá.',
          style: AuraType.caption.copyWith(fontSize: 11, height: 1.5),
        ),
      ),
      const SizedBox(height: 12),
      PlatinaButton(
        label: 'Entrar na minha Aura',
        icon: Icons.auto_awesome,
        expanded: true,
        onTap: _picked.isNotEmpty ? _finish : null,
      ),
    ],
  );
}
