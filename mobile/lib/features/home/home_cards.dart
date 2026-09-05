/// home_cards.dart — os cartões vivos do painel:
///  • RitualCard → IMAGENS REAIS que se encaixam em quem tu és (esquerda,
///    a trocar sozinhas com crossfade + zoom) + as metas de hoje (direita)
///  • ClimaCard  → clima REAL da tua cidade (Open-Meteo direto do telemóvel)
///                 com dicas de cuidado adaptadas.
library;

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/clima_api.dart';
import '../../core/api/image_bank.dart';
import '../../core/api/visual_api.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/shimmer_box.dart';

/// RITUAL DE HOJE — o cartão-motivação: à esquerda, pessoas reais (Pexels +
/// Unsplash) escolhidas pela Aura para o teu género, estilo e metas; à
/// direita, os passos de hoje. As imagens trocam sozinhas a cada ~4,6s com
/// crossfade e zoom lento (Ken Burns) — ver, não ler.
class RitualCard extends StatefulWidget {
  const RitualCard({super.key});

  @override
  State<RitualCard> createState() => _RitualCardState();
}

class _RitualCardState extends State<RitualCard> {
  List<VisualItem> _fotos = const [];
  int _idx = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Consulta personalizada: quem tu és + o que queres ser.
  String _queryPerfil(ProfileStore store) {
    final p = store.profile;
    final g = p.gender.toLowerCase();
    final sujeito = g.contains('fem')
        ? 'mulher elegante'
        : (g.contains('masc') || g.contains('homem')
              ? 'homem elegante'
              : 'pessoa elegante');
    final estilo = p.styles.isNotEmpty
        ? p.styles.first.toLowerCase()
        : 'fashion';
    return '$sujeito $estilo style portrait';
  }

  Future<void> _carregar() async {
    final store = context.read<ProfileStore>();
    final r = await BancoImagens.I.buscar(_queryPerfil(store), count: 6);
    if (!mounted) return;
    setState(() => _fotos = r.items);
    if (_fotos.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 4600), (_) {
        if (!mounted) return;
        setState(() => _idx = (_idx + 1) % _fotos.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final done = store.ritualDone;
    final progress = done.length / ProfileStore.kRitualSteps.length;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('RITUAL DE HOJE', style: AuraType.eyebrow),
              const Spacer(),
              MachinedChipXP(
                store.ritualComplete
                    ? 'completa +25 XP'
                    : '${done.length}/5 passos',
              ),
            ],
          ),
          const SizedBox(height: 12),
          // IMAGENS (esquerda) + METAS (direita) no mesmo cartão. O
          // IntrinsicHeight faz o trilho esticar até à altura real dos
          // passos (mesmo com fontes do sistema maiores — sem overflow).
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 178),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _trilhoImagens(),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        // Barra de progresso compacta sobre a coluna de metas.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            height: 4,
                            color: AuraColors.surface,
                            child: AnimatedFractionallySizedBox(
                              duration: const Duration(milliseconds: 420),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: AuraDecor.auraMetal,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (
                          var i = 0;
                          i < ProfileStore.kRitualSteps.length;
                          i++
                        )
                          _RitualRow(index: i, done: done.contains(i)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (store.ritualComplete)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 15,
                    color: AuraColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ritual completa · streak ${store.streak} dias',
                    style: AuraType.caption.copyWith(
                      fontSize: 11,
                      color: AuraColors.primary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Trilho de imagens — troca automática com crossfade + Ken Burns ────────
  Widget _trilhoImagens() {
    const largura = 118.0;

    Widget corpo;
    if (_fotos.isEmpty) {
      corpo = const ShimmerBox(radius: 0);
    } else {
      final foto = _fotos[_idx % _fotos.length];
      corpo = ClipRRect(
        borderRadius: AuraDecor.rounded,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Crossfade entre fotos.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 760),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween(begin: 1.04, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(foto.url),
                child: TweenAnimationBuilder<double>(
                  // Ken Burns — zoom lento contínuo dentro de cada foto.
                  tween: Tween(begin: 1.0, end: 1.09),
                  duration: const Duration(milliseconds: 5200),
                  curve: Curves.linear,
                  builder: (context, escala, filho) =>
                      Transform.scale(scale: escala, child: filho),
                  child: CachedNetworkImage(
                    imageUrl: foto.url,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                    placeholder: (_, _) => const ShimmerBox(radius: 0),
                    errorWidget: (_, _, _) => _gradienteReserva(),
                  ),
                ),
              ),
            ),
            // Base de vidro para os pontos.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                height: 34,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x0004060A), Color(0x9904060A)],
                  ),
                ),
              ),
            ),
            // Pontos de fase.
            Positioned(
              left: 0,
              right: 0,
              bottom: 7,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var d = 0; d < _fotos.length.clamp(2, 6); d++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: d == _idx % _fotos.length ? 7 : 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: d == _idx % _fotos.length
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.38),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: largura,
      decoration: BoxDecoration(
        borderRadius: AuraDecor.rounded,
        boxShadow: [
          ...AuraDecor.glowShadow(alpha: 0.24),
          BoxShadow(
            color: AuraColors.shadowCold.withValues(alpha: 0.5),
            offset: const Offset(0, 12),
            blurRadius: 26,
            spreadRadius: -12,
          ),
        ],
      ),
      child: corpo,
    );
  }

  Widget _gradienteReserva() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AuraColors.surface, AuraColors.secondary],
      ),
    ),
    child: Icon(
      Icons.auto_awesome,
      color: AuraColors.primary.withValues(alpha: 0.6),
      size: 28,
    ),
  );
}

class _RitualRow extends StatelessWidget {
  const _RitualRow({required this.index, required this.done});

  final int index;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final step = ProfileStore.kRitualSteps[index];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final store = context.read<ProfileStore>();
        final eraCompleta = store.ritualComplete;
        if (done) {
          AuraSfx.I.toggle();
        } else {
          AuraSfx.I.complete();
        }
        store.toggleRitual(index);
        // Os 5 passos completos: a conquista merece o acorde inteiro.
        if (!eraCompleta && store.ritualComplete) {
          Future.delayed(const Duration(milliseconds: 420), () {
            AuraSfx.I.success();
          });
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: done ? AuraDecor.auraMetal : null,
                color: done ? null : AuraColors.surface,
                border: done ? null : Border.all(color: AuraColors.border),
                boxShadow: done ? AuraDecor.glowShadow(alpha: 0.3) : null,
              ),
              child: done
                  ? Icon(Icons.check, size: 13, color: AuraColors.onPrimary)
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                style: AuraType.body.copyWith(
                  fontSize: 13,
                  color: done
                      ? AuraColors.mutedForeground
                      : AuraColors.foreground,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: AuraColors.mutedForeground,
                ),
                child: Text(step),
              ),
            ),
            Text(
              done ? '+5' : '+5 XP',
              style: AuraType.chip.copyWith(
                fontSize: 9,
                color: done ? AuraColors.primary : AuraColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MachinedChipXP extends StatelessWidget {
  const MachinedChipXP(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AuraColors.primary.withValues(alpha: 0.12),
        border: Border.all(color: AuraColors.primary.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label.toUpperCase(),
          style: AuraType.chip.copyWith(fontSize: 9),
        ),
      ),
    );
  }
}

class ClimaCard extends StatefulWidget {
  const ClimaCard({super.key});

  @override
  State<ClimaCard> createState() => _ClimaCardState();
}

class _ClimaCardState extends State<ClimaCard> {
  Clima? _clima;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    ClimaApi.I.load().then((c) {
      if (mounted) {
        setState(() {
          _clima = c;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ShimmerBox(height: 118, radius: 20);
    }
    final c = _clima;
    if (c == null) return const SizedBox.shrink(); // offline → silêncio

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('CLIMA AO VIVO', style: AuraType.eyebrow),
              const Spacer(),
              Text(
                '${c.city}${c.country.isEmpty ? '' : ' · ${c.country}'}',
                style: AuraType.caption.copyWith(fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(c.emoji, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 13),
              Text(
                '${c.temp.round()}°C',
                style: AuraType.machinedNumber.copyWith(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.label,
                  style: AuraType.caption.copyWith(fontSize: 12),
                ),
              ),
            ],
          ),
          if (c.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(height: 1, color: AuraColors.border),
            const SizedBox(height: 10),
            for (final tip in c.tips.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(top: 7, right: 9),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AuraColors.primary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: AuraType.caption.copyWith(
                          fontSize: 11.5,
                          height: 1.45,
                          color: AuraColors.foreground.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
