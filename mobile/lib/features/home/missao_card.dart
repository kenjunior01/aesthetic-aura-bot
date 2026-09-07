/// missao_card.dart — MISSÕES DA SEMANA no painel: o jogo fino da Aura.
///
///  • 5 missões da semana com progresso alimentado pelas tuas ações reais
///    (scan, check-in da jornada, cromática, armário, referências, chat,
///    exploração) — nada de missões de pretextos.
///  • Completar dá XP na hora e rebenta confetti de platina no cartão.
///  • Tocar numa missão abre o ecrã certo — a missão é sempre um atalho
///    para o que importa.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/missoes_store.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/confetti_burst.dart';
import '../../core/widgets/glass_card.dart';
import '../chat/chat_screen.dart';
import '../closet/closet_screen.dart';
import '../cortes/cortes_screen.dart';
import '../cromatica/cromatica_screen.dart';
import '../explore/explore_screen.dart';
import '../jornada/jornada_screen.dart';
import '../references/references_screen.dart';
import '../scan/scan_screen.dart';

class MissoesCard extends StatefulWidget {
  const MissoesCard({super.key});

  @override
  State<MissoesCard> createState() => _MissoesCardState();
}

class _MissoesCardState extends State<MissoesCard> {
  int _ultimasFeitas = 0;
  int _rajada = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = context.watch<MissaoStore>();
    if (store.feitasCount > _ultimasFeitas) {
      final m = store.consumirCelebracao();
      _ultimasFeitas = store.feitasCount;
      if (m != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AuraSfx.I.chime();
            setState(() => _rajada++);
          }
        });
      }
    } else if (store.feitasCount < _ultimasFeitas) {
      _ultimasFeitas = store.feitasCount;
    }
  }

  void _abrirMissao(BuildContext context, Missao m) {
    AuraSfx.I.tap();
    final routes = <String, WidgetBuilder>{
      'scan': (_) => const ScanScreen(),
      'jornada': (_) => const JornadaScreen(),
      'cromatica': (_) => const CromaticaScreen(),
      'closet': (_) => const ClosetScreen(),
      'references': (_) => const ReferencesScreen(),
      'chat': (_) => const ChatScreen(),
      'explorar': (_) => const ExploreScreen(),
      'cortes': (_) => const CortesScreen(),
    };
    final builder = routes[m.destino];
    if (builder == null) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, _, _) => builder(context),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween(begin: const Offset(0, 0.02), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: anim, child: child),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<MissaoStore>();
    final estados = store.estados;
    if (estados.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.military_tech_outlined,
                    size: 15,
                    color: AuraColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Text('MISSÕES DA SEMANA', style: AuraType.eyebrow),
                  const Spacer(),
                  Text(
                    '${store.feitasCount}/${estados.length}',
                    style: AuraType.cardTitle.copyWith(
                      fontSize: 13,
                      color: store.feitasCount > 0
                          ? AuraColors.primary
                          : AuraColors.mutedForeground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Barra da semana — metal usinado.
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 5,
                  color: AuraColors.surface,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: store.fracaoSemana,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AuraDecor.auraMetal,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              ...[
                for (final e in estados) _linha(context, e),
              ],
              const SizedBox(height: 2),
              // Rodapé — semana perfeita brilha; senão, o saldo corrente.
              if (store.semanaPerfeita)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AuraDecor.auraMetal,
                    boxShadow: AuraDecor.glowShadow(alpha: 0.24),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium_outlined,
                        size: 16,
                        color: AuraColors.background,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        store.semanasPerfeitas > 1
                            ? 'SEMANA COMPLETA ×${store.semanasPerfeitas}'
                            : 'SEMANA COMPLETA',
                        style: AuraType.chip.copyWith(
                          fontSize: 10,
                          letterSpacing: 1.6,
                          color: AuraColors.background,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '+${store.xpSemana} XP',
                        style: AuraType.cardTitle.copyWith(
                          fontSize: 12,
                          color: AuraColors.background,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  store.xpSemana > 0
                      ? '${store.xpSemana} xp de missões esta semana · renasce segunda'
                      : 'renasce toda segunda · xp direto na tua aura',
                  style: AuraType.caption.copyWith(fontSize: 9.5),
                ),
            ],
          ),
        ),
        // Confetti de platina quando uma missão fica completa.
        if (_rajada > 0)
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiBurst(
                key: ValueKey('missao-confetti-$_rajada'),
                pouco: true,
              ),
            ),
          ),
      ],
    );
  }

  Widget _linha(BuildContext context, MissaoEstado e) {
    final completa = e.feita;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: completa ? null : () => _abrirMissao(context, e.missao),
        child: Row(
          children: [
            // Selo da missão — usinado, acende quando completa.
            AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutCubic,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: completa ? AuraDecor.auraMetal : null,
                color: completa ? null : AuraColors.surface,
                border: Border.all(
                  color: completa ? Colors.transparent : AuraColors.border,
                ),
                boxShadow: completa
                    ? AuraDecor.glowShadow(alpha: 0.22)
                    : const [],
              ),
              child: Icon(
                completa ? Icons.check : e.missao.icone,
                size: 16,
                color: completa
                    ? AuraColors.background
                    : AuraColors.mutedForeground,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.missao.titulo,
                    style: AuraType.cardTitle.copyWith(
                      fontSize: 13,
                      color: completa
                          ? AuraColors.mutedForeground
                          : AuraColors.foreground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.missao.descricao,
                    style: AuraType.caption.copyWith(
                      fontSize: 10.5,
                      height: 1.35,
                    ),
                  ),
                  // Progresso fino das missões multi-passo.
                  if (e.missao.alvo > 1) ...[
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        height: 3,
                        color: AuraColors.surface,
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: e.fracao,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: AuraDecor.auraMetal,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: completa
                    ? AuraColors.primary.withValues(alpha: 0.16)
                    : AuraColors.surface,
                border: Border.all(
                  color: completa
                      ? Colors.transparent
                      : AuraColors.border,
                ),
              ),
              child: Text(
                completa ? '+${e.missao.xp} XP' : '${e.missao.xp} XP',
                style: AuraType.chip.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.6,
                  color: completa
                      ? AuraColors.primary
                      : AuraColors.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
