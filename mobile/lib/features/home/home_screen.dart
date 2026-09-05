/// home_screen.dart — o painel vivo: saudação com a tua aura, gauge de nível
/// usinado, radar de prioridades, chama de streak e atalhos rápidos.
/// Tudo entra escalonado, como instrumentos a ligar um a um.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/aura_gauge.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/radar_chart.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stagger_in.dart';
import '../chat/chat_screen.dart';
import '../closet/closet_screen.dart';
import '../cortes/cortes_screen.dart';
import '../cromatica/cromatica_screen.dart';
import '../explore/explore_screen.dart';
import '../references/references_screen.dart';
import '../scan/scan_screen.dart';
import 'home_cards.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return 'Boa madrugada';
    if (h < 12) return 'Bom dia';
    if (h < 20) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final p = store.profile;
    final name = p.name.isEmpty ? 'tua Aura' : p.name.split(' ').first;
    final milestone = store.nextMilestone;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Cabeçalho ────────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AURA STYLE', style: AuraType.eyebrow),
                      const SizedBox(height: 6),
                      Text(
                        '${_greeting()},\n$name.',
                        style: AuraType.sectionTitle.copyWith(
                          fontSize: 26,
                          height: 1.12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botão do chat — disco de vidro com aura.
                GestureDetector(
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const ChatScreen())),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AuraColors.cardFill,
                      border: Border.all(color: AuraColors.border),
                      boxShadow: AuraDecor.glowShadow(alpha: 0.16),
                    ),
                    child:  Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: AuraColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 22)),

        // ── Instrumento: nível + radar ───────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              StaggerIn(
                index: 0,
                child: GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AuraGauge(
                            progress: store.levelProgress,
                            level: store.level,
                            xp: store.xp,
                            size: 132,
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('AURA', style: AuraType.eyebrow),
                                const SizedBox(height: 4),
                                Text(
                                  'A tua presença\ncresce a cada passo.',
                                  style: AuraType.caption.copyWith(height: 1.4),
                                ),
                                const SizedBox(height: 10),
                                // Barra de progresso usinada.
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    height: 6,
                                    color: AuraColors.surface,
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: store.levelProgress,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: AuraDecor.auraMetal,
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (store.streak > 0) ...[
                        const SizedBox(height: 16),
                        Container(height: 1, color: AuraColors.border),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                             Icon(
                              Icons.local_fire_department,
                              size: 17,
                              color: AuraColors.primary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              '${store.streak} dias seguidos',
                              style: AuraType.cardTitle.copyWith(fontSize: 14),
                            ),
                            const Spacer(),
                            if (milestone != null)
                              Text(
                                'próximo: ${milestone.label}',
                                style: AuraType.caption.copyWith(
                                  fontSize: 10.5,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Ritual de hoje ────────────────────────────────────────
              StaggerIn(index: 1, child: const RitualCard()),
              const SizedBox(height: 16),

              // ── Clima ao vivo ─────────────────────────────────────────
              StaggerIn(index: 2, child: const ClimaCard()),
              const SizedBox(height: 16),

              // ── Radar de prioridades ──────────────────────────────────────
              StaggerIn(
                index: 3,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        eyebrow: 'Aura Radar',
                        title: 'As tuas prioridades em órbita',
                      ),
                      Center(
                        child: RadarChart(
                          points: _radarPoints(p),
                          size: MediaQuery.of(context).size.width - 120,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Atalhos ───────────────────────────────────────────────────
              StaggerIn(
                index: 4,
                child: const SectionHeader(
                  eyebrow: 'Agora',
                  title: 'O que fazer já',
                ),
              ),
              StaggerIn(
                index: 5,
                child: _QuickActions(onScan: () => _openScan(context, store)),
              ),
              const SizedBox(height: 110), // respiro acima da barra
            ]),
          ),
        ),
      ],
    );
  }

  List<RadarPoint> _radarPoints(Profile p) {
    final all = {
      'Pele': 0.72,
      'Cabelo': 0.58,
      'Estilo': 0.64,
      'Corpo': 0.45,
      'Rotina': 0.52,
    };
    final keys = p.priorities.isEmpty
        ? all.keys.toList()
        : (p.priorities.take(5).toList());
    return [
      for (final k in keys)
        RadarPoint(
          label: k[0].toUpperCase() + k.substring(1),
          value: all[k] ?? 0.5,
        ),
    ];
  }

  void _openScan(BuildContext context, ProfileStore store) {
    store.logEvent('scan_open', {'from': 'home'});
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ScanScreen()));
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.center_focus_strong,
                title: 'Ler a aura',
                subtitle: 'Scan de rosto',
                onTap: onScan,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.palette_outlined,
                title: 'Cores',
                subtitle: 'A tua estação',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CromaticaScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 0, height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.content_cut,
                title: 'Cortes',
                subtitle: 'Para o teu rosto',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CortesScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.face_retouching_natural,
                title: 'Referências',
                subtitle: 'A quem te aproximas',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReferencesScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 0, height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.account_balance_outlined,
                title: 'Acervo',
                subtitle: 'Galeria do Met',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ExploreScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.checkroom_outlined,
                title: 'Armário',
                subtitle: 'Tons e paletas',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ClosetScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: AuraColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, size: 18, color: AuraColors.primary),
          ),
          const SizedBox(height: 12),
          Text(title, style: AuraType.cardTitle),
          const SizedBox(height: 2),
          Text(subtitle, style: AuraType.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
