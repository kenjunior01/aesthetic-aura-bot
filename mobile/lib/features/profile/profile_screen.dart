/// profile_screen.dart — o teu painel: ficha de perfil, estatísticas de
/// instrumento (nível, XP, streak), entrada para Referências e a Ligação ao
/// backend (o MESMO banco de dados do web — editável em runtime).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/config.dart';
import '../../core/data/diario_store.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/aura_card_share.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stagger_in.dart';
import '../references/references_screen.dart';
import '../evolucao/evolucao_screen.dart';
import '../diagnostico/diagnostico_screen.dart';
import '../conquistas/conquistas_screen.dart';
import '../home/ritual_guiado.dart';
import 'profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  /// Hora em minutos-do-dia → "20:30".
  String _horaBonita(int minutos) =>
      '${(minutos ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutos % 60).toString().padLeft(2, '0')}';

  Future<void> _escolherHora(BuildContext context, ProfileStore store) async {
    final escolhida = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: store.lembreteHora ~/ 60,
        minute: store.lembreteHora % 60,
      ),
      helpText: 'HORA DO RITUAL',
    );
    if (escolhida == null) return;
    AuraSfx.I.tap();
    store.setLembreteHora(escolhida.hour * 60 + escolhida.minute);
  }

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
              const SizedBox(height: 10),

              // Título do nível — a escada de prestígio.
              StaggerIn(
                index: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        size: 15,
                        color: AuraColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'NÍVEL ${store.level} · ${nivelTitulo(store.level).toUpperCase()}',
                        style: AuraType.chip.copyWith(
                          fontSize: 10,
                          color: AuraColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),

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

              // ── Identidade sonora ──────────────────────────────────────
              StaggerIn(
                index: 1,
                child: GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        store.sfxOn
                            ? Icons.volume_up_outlined
                            : Icons.volume_off_outlined,
                        color: AuraColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sons do app', style: AuraType.cardTitle),
                            const SizedBox(height: 2),
                            Text(
                              'Timbres de platina: navegação, ritual, a Aura.',
                              style: AuraType.caption,
                            ),
                          ],
                        ),
                      ),
                      _SfxInterruptor(on: store.sfxOn),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── A voz da Aura (TTS) ───────────────────────────────────
              StaggerIn(
                index: 1,
                child: GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        store.vozOn
                            ? Icons.record_voice_over
                            : Icons.voice_over_off,
                        color: AuraColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Voz da Aura', style: AuraType.cardTitle),
                            const SizedBox(height: 2),
                            Text(
                              'O chat lê as respostas em voz alta (pt).',
                              style: AuraType.caption,
                            ),
                          ],
                        ),
                      ),
                      _VozInterruptor(on: store.vozOn),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Lembretes locais (ritual + check-in) ──────────────────────
              StaggerIn(
                index: 1,
                child: GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        store.lembretesOn
                            ? Icons.notifications_active_outlined
                            : Icons.notifications_off_outlined,
                        color: AuraColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Lembretes', style: AuraType.cardTitle),
                            const SizedBox(height: 2),
                            Text(
                              store.lembretesOn
                                  ? 'Ritual às ${_horaBonita(store.lembreteHora)} + check-in às segundas.'
                                  : 'Ritual de hoje e check-in da jornada, na hora que escolheres.',
                              style: AuraType.caption,
                            ),
                            if (store.lembretesOn) ...[
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () => _escolherHora(context, store),
                                child: Text(
                                  'mudar a hora',
                                  style: AuraType.chip.copyWith(
                                    fontSize: 10.5,
                                    color: AuraColors.primary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AuraColors.primary
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      _LembretesInterruptor(on: store.lembretesOn),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Ficha ───────────────────────────────────────────────────
              StaggerIn(
                index: 1,
                child: GlassCard(
                  onTap: () {
                    AuraSfx.I.tap();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProfileEditScreen(),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        eyebrow: 'FICHA DE AURA',
                        title: 'Os teus traços',
                        subtitle: 'toca para editar — grava ao vivo',
                      ),
                      _row('Rosto', p.faceShape.isEmpty ? '—' : p.faceShape),
                      _row(
                        'Tom de pele',
                        p.skinTone > 0 ? '${p.skinTone}/14' : '—',
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
                        child: Icon(
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
                        child: Icon(
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

              // ── Conquistas — a sala dos troféus ──────────────────
              StaggerIn(
                index: 2,
                child: GlassCard(
                  onTap: () {
                    AuraSfx.I.tap();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ConquistasScreen(),
                      ),
                    );
                  },
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
                        child: Icon(
                          Icons.emoji_events_outlined,
                          size: 21,
                          color: AuraColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Conquistas', style: AuraType.cardTitle),
                            Text(
                              'A escada de streak e os teus troféus reais.',
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

              // ── Ritual guiado — o cronómetro que acompanha ──────────
              StaggerIn(
                index: 2,
                child: GlassCard(
                  onTap: () {
                    AuraSfx.I.tap();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RitualGuiadoScreen(),
                      ),
                    );
                  },
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
                        child: Icon(
                          Icons.timer_outlined,
                          size: 21,
                          color: AuraColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ritual guiado', style: AuraType.cardTitle),
                            Text(
                              'Um passo de cada vez, ao ritmo do cronómetro.',
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

              // ── AURA CARD — a ficha que se partilha ──────────────────
              StaggerIn(
                index: 2,
                child: GlassCard(
                  onTap: () {
                    AuraSfx.I.tap();
                    store.logEvent('aura_card_share', {});
                    partilharAuraCard(context);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AuraDecor.auraMetal,
                          boxShadow: AuraDecor.glowShadow(alpha: 0.25),
                        ),
                        padding: const EdgeInsets.all(1.4),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AuraColors.backgroundDeep,
                          ),
                          child: Icon(
                            Icons.card_giftcard_outlined,
                            size: 20,
                            color: AuraColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Aura Card', style: AuraType.cardTitle),
                            Text(
                              'A tua presença numa imagem — partilha com o mundo.',
                              style: AuraType.caption.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.ios_share,
                        size: 17,
                        color: AuraColors.mutedForeground,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Diagnóstico — as APIs provadas no telemóvel ─────────
              StaggerIn(
                index: 2,
                child: GlassCard(
                  onTap: () {
                    AuraSfx.I.tap();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DiagnosticoScreen(),
                      ),
                    );
                  },
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
                        child: Icon(
                          Icons.monitor_heart_outlined,
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
                              'Diagnóstico do app',
                              style: AuraType.cardTitle,
                            ),
                            Text(
                              'IA, bancos de imagens e clima — provados ao vivo.',
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
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
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
/// O chip de estado faz um ping real a GET /api: "Ligado" significa que o
/// banco de dados partilhado respondeu; "Offline" diz a verdade — as
/// features estão a correr nas reservas locais.
class BackendCard extends StatefulWidget {
  const BackendCard({super.key});

  @override
  State<BackendCard> createState() => _BackendCardState();
}

enum _EstadoLigacao { aTestar, ligado, offline }

class _BackendCardState extends State<BackendCard> {
  late final TextEditingController _controller = TextEditingController(
    text: AuraConfig.apiBase,
  );

  _EstadoLigacao _estado = _EstadoLigacao.aTestar;
  String _detalhe = '';

  @override
  void initState() {
    super.initState();
    _testar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ping honesto: GET /api no backend configurado (a rota raiz do Next.js).
  Future<void> _testar() async {
    if (!mounted) return;
    setState(() => _estado = _EstadoLigacao.aTestar);
    try {
      final r = await ApiClient.I.get('/api');
      final msg = r is Map ? (r['message']?.toString() ?? 'ok') : 'ok';
      if (mounted) {
        setState(() {
          _estado = _EstadoLigacao.ligado;
          _detalhe = msg;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _estado = _EstadoLigacao.offline;
          _detalhe = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final (dotColor, label) = switch (_estado) {
      _EstadoLigacao.aTestar => (
        const Color(0xFF8E96A2),
        'A testar o backend…',
      ),
      _EstadoLigacao.ligado => (
        const Color(0xFF7FD8A4),
        'Ligado — banco de dados partilhado a responder',
      ),
      _EstadoLigacao.offline => (
        const Color(0xFFE08A97),
        'Offline — as rotas /api não responderam',
      ),
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            eyebrow: 'LIGAÇÃO',
            title: 'Banco de dados partilhado',
            subtitle: 'As rotas /api do Next.js — as mesmas do app web.',
          ),
          // ── Estado da ligação (ping real a GET /api) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AuraColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: AuraType.caption.copyWith(fontSize: 11),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.refresh, size: 16),
                  color: const Color(0xFF8E96A2),
                  onPressed: () {
                    AuraSfx.I.tap();
                    _testar();
                  },
                ),
              ],
            ),
          ),
          if (_estado == _EstadoLigacao.offline && _detalhe.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _detalhe,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AuraType.caption.copyWith(
                fontSize: 10,
                height: 1.4,
                color: const Color(0xFF8E96A2),
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            style: AuraType.body.copyWith(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'https://o-teu-app.vercel.app',
            ),
            onSubmitted: (v) {
              // Persiste de verdade — antes resetava a cada arranque.
              AuraConfig.setApiBase(v).then((_) {
                if (mounted) _testar(); // retesta já com o novo destino
              });
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Emulador Android usa 10.0.2.2 (anfitrião). Num telemóvel real, '
            'aponta para o URL do deploy Vercel (ou IP da mesma rede). '
            'Sem backend o app continua nas reservas locais — o chip acima '
            'mostra sempre a verdade.',
            style: AuraType.caption.copyWith(fontSize: 10.5, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// Interruptor dos lembretes — replica o metal dos irmãos (modo, som, voz).
class _LembretesInterruptor extends StatelessWidget {
  const _LembretesInterruptor({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ProfileStore>();
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (!on) AuraSfx.I.toggle();
        store.setLembretes(!on);
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
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuraDecor.auraMetal,
                  boxShadow: AuraDecor.glowShadow(alpha: 0.4),
                ),
                child: Icon(
                  on
                      ? Icons.notifications_active
                      : Icons.notifications_off,
                  size: 14,
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

class _SfxInterruptor extends StatelessWidget {
  const _SfxInterruptor({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ProfileStore>();
    return GestureDetector(
      onTap: () {
        if (!on) AuraSfx.I.toggle(); // ao ligar, o app confirma com som
        HapticFeedback.lightImpact();
        store.setSfx(!on);
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
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuraDecor.auraMetal,
                  boxShadow: AuraDecor.glowShadow(alpha: 0.4),
                ),
                child: Icon(
                  on ? Icons.music_note : Icons.music_off,
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

/// Interruptor da voz da Aura — o mesmo desenho usinado dos outros.
class _VozInterruptor extends StatelessWidget {
  const _VozInterruptor({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ProfileStore>();
    return GestureDetector(
      onTap: () {
        AuraSfx.I.toggle();
        store.setVoz(!on);
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
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuraDecor.auraMetal,
                  boxShadow: AuraDecor.glowShadow(alpha: 0.4),
                ),
                child: Icon(
                  on ? Icons.record_voice_over : Icons.voice_over_off,
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

/// Interruptor cerimonial Noite/Alvor — disco usinado que desliza.
class _ModoInterruptor extends StatelessWidget {
  const _ModoInterruptor({required this.claro});

  final bool claro;

  @override
  Widget build(BuildContext context) {
    final store = context.read<ProfileStore>();
    return GestureDetector(
      onTap: () {
        AuraSfx.I.toggle();
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
