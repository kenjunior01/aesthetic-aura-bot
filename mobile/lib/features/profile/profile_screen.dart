/// profile_screen.dart — o teu painel: ficha de perfil, estatísticas de
/// instrumento (nível, XP, streak), entrada para Referências e a Ligação ao
/// backend (o MESMO banco de dados do web — editável em runtime).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config.dart';
import '../../core/data/diario_store.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stagger_in.dart';
import '../references/references_screen.dart';
import '../evolucao/evolucao_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final p = store.profile;
    final diarioVazio = context.watch<DiarioStore>().entradas.isEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('PERFIL', style: AuraType.eyebrow),
                const SizedBox(height: 6),
                Text(
                  p.name.isEmpty ? 'Sem nome ainda' : p.name,
                  style: AuraType.sectionTitle.copyWith(fontSize: 24),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Estatísticas de instrumento ────────────────────────────────
              StaggerIn(
                index: 0,
                child: GlassCard(
                  child: Row(
                    children: [
                      _stat('NÍVEL', '${store.level}'),
                      _divider(),
                      _stat('XP', '${store.xp}'),
                      _divider(),
                      _stat('STREAK', '${store.streak}d'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Aparencia - Noite <-> Alvor
              StaggerIn(
                index: 1,
                child: GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        store.modoClaro
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: AuraColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              store.modoClaro
                                  ? 'Alvor glacial'
                                  : 'Noite de observidana',
                              style: AuraType.cardTitle,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              store.modoClaro
                                  ? 'Gelo claro, luz de inverno'
                                  : 'Ceu interstellar, metal frio',
                              style: AuraType.caption,
                            ),
                          ],
                        ),
                      ),
                      _ModoInterruptor(claro: store.modoClaro),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Ficha ──────────────────────────────────────────────────────
              StaggerIn(
                index: 1,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        eyebrow: 'FICHA DE AURA',
                        title: 'Os teus traços',
                      ),
                      _row('Rosto', p.faceShape.isEmpty ? '—' : p.faceShape),
                      _row(
                        'Tom de pele',
                        p.skinTone > 0 ? '${p.skinTone}/10' : '—',
                      ),
                      _row('Subtom', p.undertone.isEmpty ? '—' : p.undertone),
                      _row(
                        'Cabelo',
                        [
                              p.hairType,
                              p.hairLength,
                            ].where((s) => s.isNotEmpty).join(' · ').isEmpty
                            ? '—'
                            : [
                                p.hairType,
                                p.hairLength,
                              ].where((s) => s.isNotEmpty).join(' · '),
                      ),
                      _row(
                        'Cores guardadas',
                        p.colors.isEmpty
                            ? '—'
                            : '${p.colors.length} amostra${p.colors.length == 1 ? '' : 's'}',
                      ),
                      _row(
                        'Prioridades',
                        p.priorities.isEmpty ? '—' : p.priorities.join(', '),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Referências ────────────────────────────────────────────────
              StaggerIn(
                index: 2,
                child: GlassCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReferencesScreen()),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuraColors.primary.withValues(alpha: 0.1),
                          border: Border.all(
                            color: AuraColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child:  Icon(
                          Icons.face_retouching_natural,
                          size: 21,
                          color: AuraColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Referências de estilo',
                              style: AuraType.cardTitle,
                            ),
                            Text(
                              'A quem a tua cara se aproxima?',
                              style: AuraType.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                       Icon(
                        Icons.chevron_right,
                        color: AuraColors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Diário de evolução ────────────────────────────────────────
              StaggerIn(
                index: 2,
                child: GlassCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EvolucaoScreen()),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AuraColors.primary.withValues(alpha: 0.1),
                          border: Border.all(
                            color: AuraColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child:  Icon(
                          Icons.timeline,
                          size: 21,
                          color: AuraColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Diário de evolução',
                              style: AuraType.cardTitle,
                            ),
                            Text(
                              diarioVazio
                                  ? 'A tua linha do tempo começa no 1.º scan'
                                  : 'A última leitura: ${_ultimaData(context)}',
                              style: AuraType.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                       Icon(
                        Icons.chevron_right,
                        color: AuraColors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Ligação ao backend ─────────────────────────────────────────
              StaggerIn(index: 3, child: const BackendCard()),
            ]),
          ),
        ),
      ],
    );
  }

  String _ultimaData(BuildContext context) {
    final diario = context.read<DiarioStore>();
    if (diario.entradas.isEmpty) return '—';
    final p = diario.entradas.first.data.split('-');
    if (p.length < 3) return diario.entradas.first.data;
    const meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    return '${p[2]} ${meses[(int.tryParse(p[1]) ?? 1) - 1]} ${p[0]}';
  }

  Widget _stat(String label, String value) => Expanded(
    child: Column(
      children: [
        Text(label, style: AuraType.eyebrow.copyWith(fontSize: 8.5)),
        const SizedBox(height: 5),
        Text(value, style: AuraType.machinedNumber.copyWith(fontSize: 24)),
      ],
    ),
  );

  Widget _divider() =>
      Container(width: 1, height: 38, color: AuraColors.border);

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: AuraType.caption)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AuraType.body.copyWith(fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

/// Configuração da Ligação — onde ficam as rotas /api partilhadas com o web.
class BackendCard extends StatefulWidget {
  const BackendCard({super.key});

  @override
  State<BackendCard> createState() => _BackendCardState();
}

class _BackendCardState extends State<BackendCard> {
  late final TextEditingController _controller = TextEditingController(
    text: AuraConfig.apiBase,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'LIGAÇÃO',
            title: 'Banco de dados partilhado',
            subtitle: 'As rotas /api do Next.js — as mesmas do app web.',
          ),
          TextField(
            controller: _controller,
            style: AuraType.body.copyWith(fontSize: 13),
            decoration: const InputDecoration(hintText: 'http://10.0.2.2:3000'),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) {
                setState(() => AuraConfig.apiBase = v.trim());
              }
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Emulador Android usa 10.0.2.2 (anfitrião). Numa máquina real, '
            'aponta para o IP da mesma rede ou para o URL de produção.',
            style: AuraType.caption.copyWith(fontSize: 10.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Interruptor cerimonial Noite/Alvor — disco usinado que desliza.
class _ModoInterruptor extends StatelessWidget {
  const _ModoInterruptor({required this.claro});

  final bool claro;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ProfileStore>();
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        store.setModoClaro(!claro);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: 62,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AuraColors.surface,
          border: Border.all(color: AuraColors.border),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: claro ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuraDecor.auraMetal,
                  boxShadow: AuraDecor.glowShadow(alpha: 0.4),
                ),
                child: Icon(
                  claro ? Icons.light_mode : Icons.dark_mode,
                  size: 15,
                  color: AuraColors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
