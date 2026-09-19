/// onboarding_screen.dart — a entrada ceremonial da AuraStyle.
///
/// Quatro gestos e a tua Aura sabe quem és — e traça a tua rota:
///   0 · Bem-vinda          — a promessa honesta da plataforma
///   1 · Nome               — a tua Aura passa a saber quem a chama
///   2 · Identidade         — género + idade (o que muda ritmos reais)
///   3 · Prioridades        — o teu radar orbita isto
///   4 · A JORNADA          — a Aura calcula o período estimado até o
///                            auge e revela a barra de chegada ao vivo
///
/// O clímax é o passo 4: enquanto a IA traça a rota, a órbita da Aura
/// gira com estados vivos; quando chega, a barra de chegada preenche-se
/// com as fases e as imagens reais do teu percurso.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/data/jornada_store.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/orbita_aura.dart';
import '../../core/widgets/shimmer_box.dart';
import '../jornada/barra_chegada.dart';
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
  static const _kGeneros = {'f': 'Feminino', 'm': 'Masculino', 'o': 'Outro'};
  static const _kEstadosRota = [
    'A ler o teu perfil…',
    'A calcular ritmos de pele e cabelo…',
    'A traçar as fases até o auge…',
    'A escolher imagens que se parecem contigo…',
  ];

  final Set<String> _picked = {};
  String _genero = '';
  double _idade = 24;
  int _page = 0;
  int _estadoRota = 0;
  Timer? _ticker;
  bool _rotaIniciada = false;

  @override
  void dispose() {
    _name.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  ProfileStore get _store => context.read<ProfileStore>();

  void _salvarIdentidade() {
    _store.updateProfile(
      (p) => p.copyWith(
        name: _name.text.trim(),
        gender: _genero,
        age: _idade.round(),
        priorities: _picked.toList(),
      ),
    );
  }

  void _irPara(int pagina) {
    HapticFeedback.lightImpact();
    if (_page == 1) _salvarIdentidade(); // guarda o nome ao sair do passo 1
    if (_page == 2) _salvarIdentidade(); // guarda género/idade ao sair do 2
    if (_page == 3) _salvarIdentidade(); // guarda prioridades ao sair do 3
    setState(() => _page = pagina);
    if (pagina == 4) _iniciarRota();
  }

  void _iniciarRota() {
    if (_rotaIniciada) return;
    _rotaIniciada = true;
    _ticker = Timer.periodic(const Duration(milliseconds: 950), (t) {
      if (mounted) setState(() => _estadoRota = t.tick % _kEstadosRota.length);
    });
    AuraSfx.I.toggle();
    final jStore = context.read<JornadaStore>();
    jStore
        .criarJornada({
          'name': _store.profile.name,
          'gender': _genero,
          'age': _idade.round(),
          'priorities': _picked.toList(),
          'hairType': _store.profile.hairType,
          'skinTone': _store.profile.skinTone,
          'undertone': _store.profile.undertone,
          'faceShape': _store.profile.faceShape,
          'budget': _store.profile.budget,
          'city': _store.profile.city,
          'country': _store.profile.country,
        })
        .then((j) {
          _ticker?.cancel();
          if (!mounted) return;
          if (j != null) {
            _store.addXp(30);
            _store.logEvent('jornada_criada_onboarding', {
              'fonte': j.fonte,
              'semanas': j.totalSemanas,
            });
            AuraSfx.I.sparkle();
          }
        });
  }

  /// Tentar outra vez após um erro — recomeça a rota.
  void _tentarRotaOutraVez() {
    _rotaIniciada = false;
    _iniciarRota();
  }

  void _finish() {
    _salvarIdentidade();
    _store.addXp(20);
    _store.logEvent('onboarding_complete');
    _store.completeOnboarding();
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
              // Indicador de passos — fios usinados.
              Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 3,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: i <= _page.clamp(0, 3)
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
                    2 => _identidade(key: const ValueKey(2)),
                    3 => _prioridades(key: const ValueKey(3)),
                    _ => _jornada(key: const ValueKey(4)),
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Passo 0 · Bem-vinda ─────────────────────────────────────────────────────
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.backgroundDeep,
            ),
            child: Icon(
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
        'teu ritmo — e traça a rota real até a tua melhor versão. Com '
        'períodos, fases e provas no espelho.',
        style: AuraType.caption.copyWith(fontSize: 13.5, height: 1.55),
      ),
      const Spacer(),
      PlatinaButton(
        label: 'Começar',
        icon: Icons.arrow_forward,
        expanded: true,
        onTap: () => _irPara(1),
      ),
    ],
  );

  // ── Passo 1 · Nome ──────────────────────────────────────────────────────────
  Widget _nameStep({Key? key}) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 40),
      Text('COMO TE CHAMAS?', style: AuraType.eyebrow),
      const SizedBox(height: 10),
      Text(
        'É assim que a tua Aura vai tratar-te — e assinar a tua rota.',
        style: AuraType.caption.copyWith(fontSize: 13.5, height: 1.5),
      ),
      const SizedBox(height: 26),
      TextField(
        controller: _name,
        style: AuraType.machinedNumber.copyWith(fontSize: 26),
        decoration: const InputDecoration(hintText: 'O teu nome'),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _irPara(2),
        onChanged: (_) => setState(() {}),
      ),
      if (_name.text.trim().isNotEmpty) ...[
        const SizedBox(height: 14),
        AnimatedOpacity(
          duration: const Duration(milliseconds: 320),
          opacity: 1,
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 13, color: AuraColors.primary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${_name.text.trim().split(' ').first}, a tua jornada '
                  'vai ter o teu nome em cada fase.',
                  style: AuraType.caption.copyWith(
                    fontSize: 12,
                    height: 1.45,
                    color: AuraColors.primary.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const Spacer(),
      PlatinaButton(
        label: 'Continuar',
        icon: Icons.arrow_forward,
        expanded: true,
        onTap: _name.text.trim().isNotEmpty ? () => _irPara(2) : null,
      ),
    ],
  );

  // ── Passo 2 · Identidade ────────────────────────────────────────────────────
  Widget _identidade({Key? key}) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 40),
      Text('QUEM ÉS?', style: AuraType.eyebrow),
      const SizedBox(height: 10),
      Text(
        'Género e idade mudam os ritmos reais de pele e cabelo — é com '
        'isto que o teu período estimado sai verdadeiro.',
        style: AuraType.caption.copyWith(fontSize: 13.5, height: 1.5),
      ),
      const SizedBox(height: 26),
      Row(
        children: [
          for (final e in _kGeneros.entries) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _genero = e.key);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: _genero == e.key ? AuraDecor.auraMetal : null,
                    color: _genero == e.key ? null : AuraColors.surface,
                    border: Border.all(
                      color: _genero == e.key
                          ? Colors.transparent
                          : AuraColors.border,
                    ),
                    boxShadow: _genero == e.key
                        ? AuraDecor.glowShadow(alpha: 0.22)
                        : null,
                  ),
                  child: Text(
                    e.value,
                    textAlign: TextAlign.center,
                    style: AuraType.chip.copyWith(
                      fontSize: 12,
                      color: _genero == e.key
                          ? AuraColors.onPrimary
                          : AuraColors.mutedForeground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 30),
      Center(
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${_idade.round()}',
                style: AuraType.machinedNumber.copyWith(fontSize: 44),
              ),
              TextSpan(
                text: ' anos',
                style: AuraType.caption.copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 3,
          activeTrackColor: AuraColors.primary,
          inactiveTrackColor: AuraColors.surfaceStrong,
          thumbColor: AuraColors.platinaLuminosa,
          overlayColor: AuraColors.primary.withValues(alpha: 0.12),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        ),
        child: Slider(
          value: _idade,
          min: 14,
          max: 70,
          divisions: 56,
          onChanged: (v) => setState(() => _idade = v),
          onChangeEnd: (_) {
            HapticFeedback.selectionClick();
            AuraSfx.I.tap();
          },
        ),
      ),
      const Spacer(),
      PlatinaButton(
        label: 'Continuar',
        icon: Icons.arrow_forward,
        expanded: true,
        onTap: _genero.isNotEmpty ? () => _irPara(3) : null,
      ),
    ],
  );

  // ── Passo 3 · Prioridades ───────────────────────────────────────────────────
  Widget _prioridades({Key? key}) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 40),
      Text('O QUE MAIS IMPORTA?', style: AuraType.eyebrow),
      const SizedBox(height: 10),
      Text(
        'Escolhe até 3 — o teu radar e as tuas fases vão orbitar isto.',
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
        label: _picked.isEmpty
            ? 'Traçar com pele e cabelo'
            : 'Traçar a minha jornada',
        icon: Icons.auto_awesome,
        expanded: true,
        // Sem escolha? A Aura assume pele + cabelo — o início mais comum.
        // Nunca bloqueia o avanço: a jornada é sempre traçável.
        onTap: () {
          if (_picked.isEmpty) _picked.addAll(['pele', 'cabelo']);
          _irPara(4);
        },
      ),
      if (_picked.isEmpty) ...[
        const SizedBox(height: 10),
        Center(
          child: Text(
            'ou toca nas opções acima para escolher as tuas',
            style: AuraType.caption.copyWith(
              fontSize: 11,
              color: AuraColors.mutedForeground.withValues(alpha: 0.8),
            ),
          ),
        ),
      ],
    ],
  );

  // ── Passo 4 · A Jornada (o clímax) ──────────────────────────────────────────
  Widget _jornada({Key? key}) {
    final jStore = context.watch<JornadaStore>();
    final j = jStore.jornada;
    final pronta = j != null && !jStore.gerando;

    if (!pronta) {
      // A rota a ser traçada ao vivo — SEMPRE com saída honesta: a geração
      // tem teto de 14 s no store, e aqui há "entrar já" a qualquer momento.
      final erro = jStore.erro;
      return Column(
        key: key,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 34),
          Text('A TUA JORNADA', style: AuraType.eyebrow),
          const SizedBox(height: 8),
          Text(
            erro != null
                ? 'Não consegui traçar a rota agora — a tua Aura fica\npronta na mesma.'
                : 'A Aura está a traçar a rota real do $_nomeCurto até o auge.',
            textAlign: TextAlign.center,
            style: AuraType.caption.copyWith(fontSize: 13.5, height: 1.5),
          ),
          const Spacer(),
          if (erro == null)
            const OrbitaAura(tamanho: 96)
          else
            Icon(Icons.wifi_off, size: 44, color: AuraColors.mutedForeground),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 340),
            child: erro != null
                ? Text(
                    'Sem leitura de IA agora — tenta outra vez ou entra sem rota.',
                    key: const ValueKey('erro-rota'),
                    textAlign: TextAlign.center,
                    style: AuraType.caption.copyWith(
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  )
                : Text(
                    _kEstadosRota[_estadoRota],
                    key: ValueKey(_estadoRota),
                    textAlign: TextAlign.center,
                    style: AuraType.caption.copyWith(
                      fontSize: 12.5,
                      height: 1.5,
                    ),
                  ),
          ),
          if (erro == null) ...[
            const SizedBox(height: 8),
            Text(
              'Normalmente leva segundos — sem internet, traçamos offline.',
              textAlign: TextAlign.center,
              style: AuraType.caption.copyWith(
                fontSize: 11,
                height: 1.4,
                color: AuraColors.mutedForeground.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const ShimmerBox(width: double.infinity, height: 8),
          ),
          const SizedBox(height: 18),
          if (erro != null)
            PlatinaButton(
              label: 'Tentar outra vez',
              icon: Icons.refresh,
              expanded: true,
              onTap: _tentarRotaOutraVez,
            )
          else
            TextButton(
              onPressed: _finish,
              child: Text(
                'Não esperar — entrar já (a rota fica pronta lá dentro)',
                style: AuraType.caption.copyWith(
                  fontSize: 12,
                  color: AuraColors.primary,
                ),
              ),
            ),
          const SizedBox(height: 30),
        ],
      );
    }

    // A rota revelada.
    final total = j.totalSemanas <= 1 ? 1 : j.totalSemanas;
    final nos = [for (final f in j.fases.skip(1)) (f.semanaInicio - 1) / total];
    return SingleChildScrollView(
      key: key,
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          Center(
            child: Column(
              children: [
                Text('A TUA ROTA ESTÁ TRAÇADA', style: AuraType.eyebrow),
                const SizedBox(height: 8),
                Text(
                  '$_nomeCurto, esta é a jornada até o teu auge —\n'
                  'medida nas semanas, não em promessas.',
                  textAlign: TextAlign.center,
                  style: AuraType.sectionTitle.copyWith(
                    fontSize: 20,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BarraChegada(
                  progresso: 0,
                  totalSemanas: j.totalSemanas,
                  nos: nos,
                  semanaAtual: 1,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _marco('SENTIR', j.efeitosSemanas),
                    _fio(),
                    _marco('VER', j.mudancasSemanas),
                    _fio(),
                    _marco('AUGE', j.totalSemanas),
                  ],
                ),
                if (j.resumo.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    j.resumo,
                    style: AuraType.caption.copyWith(height: 1.5, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 15, color: AuraColors.primary),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'O primeiro ponto de controlo abre na semana '
                    '${j.mudancasSemanas} — partilhas uma foto e a rota '
                    'confirma ou ajusta-se ao teu ritmo real.',
                    style: AuraType.caption.copyWith(
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PlatinaButton(
            label: 'Entrar na minha Aura',
            icon: Icons.auto_awesome,
            expanded: true,
            onTap: _finish,
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  String get _nomeCurto {
    final n = _name.text.trim().split(' ').first;
    return n.isEmpty ? 'a tua' : n;
  }

  Widget _marco(String label, int semanas) => Expanded(
    child: Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$semanas',
                style: AuraType.machinedNumber.copyWith(fontSize: 24),
              ),
              TextSpan(
                text: ' sem',
                style: AuraType.caption.copyWith(fontSize: 10.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AuraType.eyebrow.copyWith(fontSize: 7.5, letterSpacing: 1.6),
        ),
      ],
    ),
  );

  Widget _fio() => Container(
    width: 1,
    height: 28,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: AuraColors.border,
  );
}
