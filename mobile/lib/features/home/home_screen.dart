/// home_screen.dart — o painel vivo: saudação com a tua aura, gauge de nível
/// usinado, radar de prioridades, chama de streak e atalhos rápidos.
/// Tudo entra escalonado, como instrumentos a ligar um a um.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/diario_store.dart';
import '../../core/data/evento_store.dart';
import '../../core/data/jornada_store.dart';
import '../../core/data/missoes_store.dart';
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
import '../closet/look_do_dia.dart';
import '../cortes/cortes_screen.dart';
import '../cromatica/cromatica_screen.dart';
import '../evento/evento_screen.dart';
import '../explore/explore_screen.dart';
import '../lookcheck/lookcheck_screen.dart';
import '../references/references_screen.dart';
import '../scan/scan_screen.dart';
import 'home_cards.dart';
import 'missao_card.dart';

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
              StaggerIn(index: 1, child: const JornadaCard()),
              const SizedBox(height: 16),

              // ── Look de Hoje (vitrine do guarda-roupa vivo) ──────────
              StaggerIn(index: 2, child: const LookCompactCard()),
              const SizedBox(height: 16),

              // ── Ritual de hoje ─────────────────────────────────────
              StaggerIn(index: 3, child: const RitualCard()),
              const SizedBox(height: 16),

              // ── Missões da semana ──────────────────────────────────────
              StaggerIn(index: 4, child: const MissoesCard()),
              const SizedBox(height: 16),

              // ── Clima ao vivo ─────────────────────────────────────────
              StaggerIn(index: 5, child: const ClimaCard()),
              const SizedBox(height: 16),

              // ── Radar de prioridades ──────────────────────────────────────
              const StaggerIn(index: 6, child: _RadarCard()),
              const SizedBox(height: 16),

              // ── Atalhos ───────────────────────────────────────────────────
              StaggerIn(
                index: 7,
                child: const SectionHeader(
                  eyebrow: 'Agora',
                  title: 'O que fazer já',
                ),
              ),
              StaggerIn(
                index: 7,
                child: _QuickActions(onScan: () => _openScan(context, store)),
              ),
              const SizedBox(height: 110), // respiro acima da barra
            ]),
          ),
        ),
      ],
    );
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
    final evento = context.watch<EventoStore>().evento;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.checkroom_outlined,
                title: 'Avalia o look',
                subtitle: 'Nota 0-100 + ajustes',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LookCheckScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.event_outlined,
                title: 'Evento',
                subtitle: evento == null
                    ? 'Plano até o dia'
                    : evento.diasRestantes <= 0
                        ? 'É hoje!'
                        : '${evento.diasRestantes} dias',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EventoScreen()),
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
                subtitle: 'Cores e peças',
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

/// AURA RADAR — medido na vida real, zero números decorativos. Cada eixo
/// combina três sinais honestos do telemóvel:
///  • conhecimento (o perfil já tem os traços dessa área? scan, espelho, ficha)
///  • consistência (streak de rituais, registos no diário)
///  • evolução (progresso real na Jornada do Auge)
class _RadarCard extends StatelessWidget {
  const _RadarCard();

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final p = store.profile;
    final jStore = context.watch<JornadaStore>();
    final dStore = context.watch<DiarioStore>();
    final mStore = context.watch<MissaoStore>();

    // Sinais partilhados (0..1).
    final streakF = (store.streak / 21).clamp(0.0, 1.0);
    final evolucao = (jStore.jornada == null ? 0.0 : jStore.progresso);
    final diarioF = (dStore.entradas.length / 6).clamp(0.0, 1.0);
    final ritualF = store.ritualComplete
        ? 1.0
        : store.ritualDone.length / ProfileStore.kRitualSteps.length;
    final missoesF = mStore.fracaoSemana.clamp(0.0, 1.0);

    double radar(String area) {
      // Conhecimento por área — o que o perfil já sabe de ti.
      final double conhecimento = switch (area) {
        'pele' => (p.skinTone > 0 ? 0.6 : 0.0) +
            (p.undertone.isNotEmpty ? 0.4 : 0.0),
        'cabelo' => (p.hairType.isNotEmpty ? 0.5 : 0.0) +
            (p.hairColor.isNotEmpty ? 0.25 : 0.0) +
            (p.hairLength.isNotEmpty ? 0.25 : 0.0),
        'estilo' => ((p.styles.length / 3) * 0.7)
            .clamp(0.0, 0.7) +
            ((p.colors.length / 2) * 0.3).clamp(0.0, 0.3),
        'corpo' => (p.bodyType.isNotEmpty ? 0.5 : 0.0) +
            (p.height > 0 ? 0.25 : 0.0) +
            (p.weight > 0 ? 0.25 : 0.0),
        'rotina' => 1.0,
        'compras' => (p.budget.isNotEmpty ? 0.6 : 0.0) +
            (p.priorities.contains('compras') ? 0.4 : 0.0),
        _ => 0.5,
      };
      final double consistencia = switch (area) {
        'rotina' => (streakF * 0.5 + diarioF * 0.3 + ritualF * 0.2),
        'pele' => streakF * 0.8 + ritualF * 0.2,
        'cabelo' => streakF * 0.8 + ritualF * 0.2,
        _ => streakF * 0.6 + missoesF * 0.4,
      };
      return (0.55 * conhecimento + 0.25 * consistencia + 0.20 * evolucao)
          .clamp(0.06, 1.0);
    }

    final areas = p.priorities.isEmpty
        ? const ['pele', 'cabelo', 'estilo', 'corpo', 'rotina']
        : p.priorities.take(5).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'Aura Radar',
            title: 'As tuas prioridades em órbita',
          ),
          Center(
            child: RadarChart(
              points: [
                for (final k in areas)
                  RadarPoint(
                    label: k[0].toUpperCase() + k.substring(1),
                    value: radar(k),
                  ),
              ],
              size: MediaQuery.of(context).size.width - 120,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'medido na tua atividade real: conhecimento do perfil + '
            'consistência + progresso na jornada',
            style: AuraType.caption.copyWith(
              fontSize: 10.5,
              height: 1.4,
              color: AuraColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
