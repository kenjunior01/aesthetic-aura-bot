/// conquistas_screen.dart — a sala dos troféus: cada conquista é medida na
/// vida REAL do utilizador (scan feito, jornada em andamento, diário ativo,
/// conversas com a Aura…). Zero números decorativos: ou desbloqueaste ou não.
/// A escada de streak fecha a vista — os marcos que já conquistaste brilham.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/diario_store.dart';
import '../../core/data/jornada_store.dart';
import '../../core/data/missoes_store.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stagger_in.dart';

class ConquistasScreen extends StatelessWidget {
  const ConquistasScreen({super.key});

  int _countEvents(List<String> events, String name) => events
      .where((e) => e.contains(' $name') || e.endsWith(' $name'))
      .length;

  @override
  Widget build(BuildContext context) {
    final pStore = context.watch<ProfileStore>();
    final jStore = context.watch<JornadaStore>();
    final dStore = context.watch<DiarioStore>();
    final mStore = context.watch<MissaoStore>();
    final p = pStore.profile;
    final eventos = pStore.events;

    // ── Conquistas vivas — derivadas do estado real, sem persistência extra ──
    final conquistas = <_Trofeu>[
      _Trofeu(
        icon: Icons.center_focus_strong,
        titulo: 'Primeiro Scan',
        desc: 'Leste a tua aura pela primeira vez',
        unlocked: _countEvents(eventos, 'scan_complete') > 0,
      ),
      _Trofeu(
        icon: Icons.local_fire_department,
        titulo: 'Ritual Completo',
        desc: 'Cumpreste os 5 passos de um dia',
        unlocked: pStore.streak > 0,
      ),
      _Trofeu(
        icon: Icons.route_outlined,
        titulo: 'Jornada Traçada',
        desc: 'A rota até o auge existe no mapa',
        unlocked: jStore.jornada != null,
      ),
      _Trofeu(
        icon: Icons.photo_camera_front_outlined,
        titulo: 'Prova Real',
        desc: 'Primeiro check-in de foto na jornada',
        unlocked: (jStore.jornada?.checkins.length ?? 0) > 0,
      ),
      _Trofeu(
        icon: Icons.emoji_events_outlined,
        titulo: 'Semana Perfeita',
        desc: 'Todas as missões de uma semana',
        unlocked: mStore.semanasPerfeitas > 0,
      ),
      _Trofeu(
        icon: Icons.palette_outlined,
        titulo: 'Estação de Cores',
        desc: 'Descobriste a tua estação cromática',
        unlocked:
            _countEvents(eventos, 'cromatica_open') > 0 ||
            p.undertone.isNotEmpty,
      ),
      _Trofeu(
        icon: Icons.face_retouching_natural,
        titulo: 'Espelho Próprio',
        desc: 'Definiste a tua identidade visual',
        unlocked: p.espelho.length >= 3,
      ),
      _Trofeu(
        icon: Icons.shopping_bag_outlined,
        titulo: 'Consultor de Bolso',
        desc: 'Abriste o consultor de compras',
        unlocked: _countEvents(eventos, 'mercado_open') > 0,
      ),
      _Trofeu(
        icon: Icons.chat_bubble_outline,
        titulo: 'Conversa com a Aura',
        desc: '5 conversas com a tua IA pessoal',
        unlocked: _countEvents(eventos, 'chat_msg') >= 5,
      ),
      _Trofeu(
        icon: Icons.museum_outlined,
        titulo: 'Colecionador do Met',
        desc: '3 obras salvas no acervo',
        unlocked: _countEvents(eventos, 'acervo_save') >= 3,
      ),
      _Trofeu(
        icon: Icons.menu_book_outlined,
        titulo: 'Diário Ativo',
        desc: '3 registos na linha do tempo',
        unlocked: dStore.entradas.length >= 3,
      ),
      _Trofeu(
        icon: Icons.flag_outlined,
        titulo: 'Metade do Caminho',
        desc: '50% da jornada até o auge',
        unlocked: jStore.jornada != null && jStore.progresso >= 0.5,
      ),
    ];

    final abertas = conquistas.where((t) => t.unlocked).length;

    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
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
                    Expanded(
                      child: Text('Conquistas', style: AuraType.cardTitle),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // ── Escada de streak ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: StaggerIn(
                  index: 0,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          eyebrow: 'A CHAMA',
                          title: 'A escada de streak',
                          subtitle:
                              'dias seguidos de ritual — cada degrau paga XP',
                        ),
                        const SizedBox(height: 6),
                        ..._escadaStreak(pStore),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // ── Grelha de troféus ─────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: SectionHeader(
                  eyebrow: 'TROFÉUS',
                  title: '$abertas de ${conquistas.length} desbloqueadas',
                  subtitle: 'medidas na tua atividade real, não em sorte',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.45,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final t = conquistas[i];
                    return StaggerIn(index: i % 6, child: _TrofeuCard(t));
                  },
                  childCount: conquistas.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _escadaStreak(ProfileStore store) {
    final marcados = <Widget>[];
    for (final m in kStreakMilestones) {
      final done = store.streak >= m.days;
      final proximo = !done && store.nextMilestone?.days == m.days;
      marcados.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: done ? AuraDecor.auraMetal : null,
                  color: done ? null : AuraColors.surface,
                  border: done
                      ? null
                      : Border.all(
                          color: proximo
                              ? AuraColors.primary.withValues(alpha: 0.55)
                              : AuraColors.border,
                        ),
                  boxShadow: done ? AuraDecor.glowShadow(alpha: 0.28) : null,
                ),
                child: done
                    ? Icon(Icons.check, size: 15, color: AuraColors.onPrimary)
                    : Center(
                        child: Text(
                          '${m.days}',
                          style: AuraType.chip.copyWith(
                            fontSize: 10,
                            color: proximo
                                ? AuraColors.primary
                                : AuraColors.mutedForeground,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  done
                      ? '${m.label} · conquistado'
                      : '${m.label} · ${m.days} dias',
                  style: AuraType.body.copyWith(
                    fontSize: 12.5,
                    color: done
                        ? AuraColors.foreground
                        : AuraColors.mutedForeground,
                  ),
                ),
              ),
              Text(
                '+${m.xp} XP',
                style: AuraType.chip.copyWith(
                  fontSize: 10,
                  color: done ? AuraColors.primary : AuraColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return marcados;
  }
}

class _Trofeu {
  const _Trofeu({
    required this.icon,
    required this.titulo,
    required this.desc,
    required this.unlocked,
  });
  final IconData icon;
  final String titulo;
  final String desc;
  final bool unlocked;
}

class _TrofeuCard extends StatelessWidget {
  const _TrofeuCard(this.t);

  final _Trofeu t;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: t.unlocked ? AuraDecor.auraMetal : null,
        color: t.unlocked ? null : AuraColors.cardFill,
        border: Border.all(
          color: t.unlocked ? Colors.transparent : AuraColors.border,
        ),
        boxShadow: t.unlocked ? AuraDecor.glowShadow(alpha: 0.26) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                t.unlocked ? t.icon : Icons.lock_outline,
                size: 19,
                color: t.unlocked
                    ? AuraColors.onPrimary
                    : AuraColors.mutedForeground,
              ),
              const Spacer(),
              if (t.unlocked)
                Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: AuraColors.onPrimary.withValues(alpha: 0.8),
                ),
            ],
          ),
          const Spacer(),
          Text(
            t.titulo,
            style: AuraType.cardTitle.copyWith(
              fontSize: 12.5,
              color: t.unlocked
                  ? AuraColors.onPrimary
                  : AuraColors.mutedForeground,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            t.unlocked ? t.desc : 'bloqueado — ${t.desc.toLowerCase()}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AuraType.caption.copyWith(
              fontSize: 10,
              height: 1.35,
              color: t.unlocked
                  ? AuraColors.onPrimary.withValues(alpha: 0.82)
                  : AuraColors.mutedForeground.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
