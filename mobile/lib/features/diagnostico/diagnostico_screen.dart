/// diagnostico_screen.dart — "está mesmo a funcionar?" respondido com números.
///
/// Cada serviço que o app usa (IA texto, IA visão, Pexels, Unsplash, Met,
/// Clima) é pingado AQUI DO TELEMÓVEL com as mesmas chaves do APK. A resposta
/// vira uma ficha de instrumento: ponto de estado, latência medida, detalhe
/// real ("respondeu: vivo", "foto viva: Fulano"). Nada de adivinhação.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/diagnostico_api.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';

class DiagnosticoScreen extends StatefulWidget {
  const DiagnosticoScreen({super.key});

  @override
  State<DiagnosticoScreen> createState() => _DiagnosticoScreenState();
}

class _DiagnosticoScreenState extends State<DiagnosticoScreen>
    with SingleTickerProviderStateMixin {
  List<ResultadoPing>? _resultados;
  bool _rodando = false;
  DateTime? _ultima;

  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _rodar();
  }

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  Future<void> _rodar() async {
    if (_rodando) return;
    setState(() {
      _rodando = true;
      _resultados = null;
    });
    _pulso.repeat();
    final r = await DiagnosticoApi.I.todos();
    if (!mounted) return;
    setState(() {
      _resultados = r;
      _rodando = false;
      _ultima = DateTime.now();
    });
    _pulso.stop();
    // Sons: vitória total é comemorada; falha parcial apenas notifica.
    final vivos = r.where((e) => e.ok).length;
    if (vivos == r.length) {
      AuraSfx.I.sparkle();
    } else {
      AuraSfx.I.receive();
    }
  }

  int get _vivos => _resultados?.where((e) => e.ok).length ?? 0;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final sfx = AuraSfx.I;
    return Scaffold(
      backgroundColor: AuraColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        sfx.tap();
                        Navigator.of(context).pop();
                      },
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
                      child: Text('Diagnóstico', style: AuraType.cardTitle),
                    ),
                    GestureDetector(
                      onTap: () {
                        sfx.toggle();
                        store.setSfx(!store.sfxOn);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: store.sfxOn
                              ? AuraColors.primary.withValues(alpha: 0.12)
                              : AuraColors.surface,
                          border: Border.all(
                            color: store.sfxOn
                                ? AuraColors.primary.withValues(alpha: 0.4)
                                : AuraColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              store.sfxOn ? Icons.volume_up : Icons.volume_off,
                              size: 14,
                              color: store.sfxOn
                                  ? AuraColors.primary
                                  : AuraColors.mutedForeground,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SOM',
                              style: AuraType.chip.copyWith(
                                fontSize: 9,
                                color: store.sfxOn
                                    ? AuraColors.primary
                                    : AuraColors.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Dial resumo ───────────────────────────────────────────
                  GlassCard(
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulso,
                          builder: (context, _) => Container(
                            width: 74,
                            height: 74,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AuraDecor.auraMetal,
                              boxShadow: [
                                ...AuraDecor.glowShadow(
                                  alpha: _rodando
                                      ? 0.25 + 0.2 * _pulso.value
                                      : (_vivos == (_resultados?.length ?? 6)
                                            ? 0.45
                                            : 0.2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(2.6),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AuraColors.backgroundDeep,
                              ),
                              child: Center(
                                child: _rodando
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AuraColors.primary,
                                        ),
                                      )
                                    : Text(
                                        '$_vivos/'
                                        '${_resultados?.length ?? 6}',
                                        style: AuraType.machinedNumber.copyWith(
                                          fontSize: 17,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _rodando
                                    ? 'A medir da tua rede…'
                                    : (_vivos == (_resultados?.length ?? 6)
                                          ? 'Tudo vivo por aqui'
                                          : 'Alguns serviços não responderam'),
                                style: AuraType.cardTitle.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _rodando
                                    ? 'Cada teste corre do telemóvel, com as '
                                          'mesmas chaves do app.'
                                    : (_ultima == null
                                          ? ''
                                          : 'Última leitura às '
                                                '${_ultima!.hour.toString().padLeft(2, '0')}:'
                                                '${_ultima!.minute.toString().padLeft(2, '0')}'),
                                style: AuraType.caption.copyWith(
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Fichas de serviço ─────────────────────────────────────
                  if (!_rodando && _resultados != null)
                    for (final r in _resultados!) ...[
                      _FichaServico(r: r),
                      const SizedBox(height: 10),
                    ]
                  else if (_rodando)
                    for (var i = 0; i < 6; i++) ...[
                      const _FichaEsqueleto(),
                      const SizedBox(height: 10),
                    ],

                  // ── Nota honesta sobre bloqueios de rede ──────────────────
                  const SizedBox(height: 4),
                  GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AuraColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'A IA Groq bloqueia alguns datacenters — mas o teu '
                            'telemóvel usa a tua própria rede. Se um teste '
                            'falhar aqui, ele cai para o plano B do app '
                            '(backend partilhado → heurística local): nada '
                            'deixa de funcionar.',
                            style: AuraType.caption.copyWith(
                              fontSize: 11,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Botão: testar outra vez ───────────────────────────────
                  GestureDetector(
                    onTap: () {
                      AuraSfx.I.tap();
                      _rodar();
                    },
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: AuraDecor.auraMetal,
                        boxShadow: AuraDecor.glowShadow(alpha: 0.3),
                      ),
                      child: Center(
                        child: Text(
                          _rodando ? 'A testar…' : 'Testar outra vez',
                          style: AuraType.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AuraColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FichaServico extends StatelessWidget {
  const _FichaServico({required this.r});

  final ResultadoPing r;

  @override
  Widget build(BuildContext context) {
    final cor = r.ok ? const Color(0xFF4ADE80) : const Color(0xFFF87171);
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: r.ok
                  ? cor.withValues(alpha: 0.1)
                  : cor.withValues(alpha: 0.08),
              border: Border.all(color: cor.withValues(alpha: 0.35)),
            ),
            child: Icon(r.icone, size: 19, color: r.ok ? cor : cor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        r.nome,
                        style: AuraType.cardTitle.copyWith(fontSize: 13.5),
                      ),
                    ),
                    Text(
                      r.ok
                          ? '${r.ms}ms'
                          : (r.semChave ? '—' : 'HTTP ${r.httpCode}'),
                      style: AuraType.chip.copyWith(
                        fontSize: 10,
                        color: r.ok ? cor : AuraColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  r.sub,
                  style: AuraType.caption.copyWith(
                    fontSize: 10.5,
                    color: AuraColors.mutedForeground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Latência medida — barra de instrumento.
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 3,
                    color: AuraColors.surface,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: r.ok
                          ? (1 - (r.ms / 6000).clamp(0.06, 1.0)).clamp(
                              0.1,
                              0.95,
                            )
                          : 0.06,
                      child: Container(color: cor),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  r.ok ? r.detalhe : 'sem resposta aqui — plano B ativo no app',
                  style: AuraType.caption.copyWith(
                    fontSize: 10.5,
                    height: 1.35,
                    color: r.ok
                        ? AuraColors.foreground
                        : AuraColors.mutedForeground,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FichaEsqueleto extends StatelessWidget {
  const _FichaEsqueleto();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AuraColors.surface,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 11, width: 130, color: AuraColors.surface),
                const SizedBox(height: 8),
                Container(height: 3, color: AuraColors.surface),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
