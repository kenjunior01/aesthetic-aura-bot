/// home_cards.dart — os cartões vivos do painel:
///  • RitualCard → os 5 passos de hoje com XP e streak (toca para cumprir)
///  • ClimaCard  → clima REAL da tua cidade via /api/geo → /api/weather
///                 (o MESMO backend do web) com dicas de cuidado adaptadas.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api/clima_api.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/shimmer_box.dart';

class RitualCard extends StatelessWidget {
  const RitualCard({super.key});

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
              const Text('RITUAL DE HOJE', style: AuraType.eyebrow),
              const Spacer(),
              MachinedChipXP(
                store.ritualComplete
                    ? 'completa +25 XP'
                    : '${done.length}/5 passos',
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Barra de progresso do ritual.
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 5,
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
          const SizedBox(height: 8),
          // Escada de passos.
          for (var i = 0; i < ProfileStore.kRitualSteps.length; i++)
            _RitualRow(index: i, done: done.contains(i)),
          if (store.ritualComplete)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(
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
        HapticFeedback.lightImpact();
        context.read<ProfileStore>().toggleRitual(index);
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
                  ? const Icon(
                      Icons.check,
                      size: 13,
                      color: AuraColors.onPrimary,
                    )
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
              const Text('CLIMA AO VIVO', style: AuraType.eyebrow),
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
                      decoration: const BoxDecoration(
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
