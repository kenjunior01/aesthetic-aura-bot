/// look_do_dia.dart — o momento de glória do Guarda-Roupa Vivo: as tuas
/// próprias peças combinadas pelo motor de harmonia, com o comentário da
/// Aura a explicar o porquê.
///
///  • LookCard        → cartão completo no Armário (trocar combinação,
///                      "vou usar isto" com +15 XP 1×/dia).
///  • LookCompactCard → versão de vitrine no Início — toca e abre o armário.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/guarda_roupa_api.dart';
import '../../core/data/guarda_roupa_store.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../closet/closet_screen.dart';

class LookCard extends StatefulWidget {
  const LookCard({super.key});

  @override
  State<LookCard> createState() => _LookCardState();
}

class _LookCardState extends State<LookCard> {
  int _attempt = 0;
  String? _comentario;
  bool _comentando = false;
  String _chaveComentario = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GuardaRoupaStore>();
    final look = store.montarLook(attempt: _attempt);
    if (look == null) return const SizedBox.shrink();

    final chave = look.pecas.map((p) => p.id).join('|');
    if (chave != _chaveComentario) {
      _chaveComentario = chave;
      _comentario = null;
      _pedirComentario(look);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            eyebrow: 'LOOK DE HOJE',
            title: look.conceito,
            subtitle: 'das tuas peças · harmonia '
                '${(look.harmonia * 100).round()}%',
            trailing: _SeloHarmonia(look: look),
          ),
          const SizedBox(height: 4),
          // As peças do look — polaroides lado a lado.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (var i = 0; i < look.pecas.length; i++) ...[
                  if (i > 0) const _Mais(),
                  _TilePeca(peca: look.pecas[i]),
                ],
              ],
            ),
          ),
          // O porquê — comentário da Aura.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            child: _comentario != null
                ? Padding(
                    key: ValueKey(_comentario),
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 2.4,
                          height: 34,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: AuraDecor.auraMetal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _comentario!,
                            style: AuraType.caption.copyWith(
                              fontSize: 12,
                              height: 1.45,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(height: 4),
          ),
          const SizedBox(height: 14),
          // Ações: trocar combinação + vou usar isto.
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  AuraSfx.I.toggle();
                  setState(() {
                    _attempt++;
                    _comentario = null;
                  });
                  context.read<ProfileStore>().logEvent('look_trocar', {
                    'attempt': _attempt,
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AuraColors.surface,
                    border: Border.all(color: AuraColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.shuffle,
                        size: 15,
                        color: AuraColors.foreground.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Trocar',
                        style: AuraType.chip.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              _BotaoUsar(look: look),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pedirComentario(LookMontado look) async {
    if (_comentando) return;
    _comentando = true;
    try {
      final perfil = context.read<ProfileStore>();
      final texto = await GuardaRoupaApi.comentarLook(
        conceito: look.conceito,
        linhas: [
          for (final p in look.pecas) '${p.nome} (${p.corNome})',
        ],
        contexto: perfil.aiContext(),
      );
      if (!mounted || chaveDiferente(look)) return;
      setState(() => _comentario = texto ??
          'Combinação ${look.conceito.toLowerCase()} — funciona porque as '
              'cores conversam sem competir. Acaba com um acessório '
              'metálico.');
    } finally {
      _comentando = false;
    }
  }

  bool chaveDiferente(LookMontado look) =>
      look.pecas.map((p) => p.id).join('|') != _chaveComentario;
}

/// Selo de harmonia — disco usinado com a percentagem.
class _SeloHarmonia extends StatelessWidget {
  const _SeloHarmonia({required this.look});
  final LookMontado look;

  @override
  Widget build(BuildContext context) {
    final pct = (look.harmonia * 100).round();
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AuraDecor.auraMetal,
      ),
      padding: const EdgeInsets.all(1.6),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AuraColors.backgroundDeep,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$pct',
              style: AuraType.machinedNumber.copyWith(fontSize: 15),
            ),
            Text(
              'HARM',
              style: AuraType.chip.copyWith(
                fontSize: 6.5,
                letterSpacing: 1.2,
                color: AuraColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile de peça — polaroid de obsidiana com a foto, nome e cor.
class _TilePeca extends StatelessWidget {
  const _TilePeca({required this.peca});

  final Peca peca;

  @override
  Widget build(BuildContext context) {
    final cor = corDaPeca(peca) ?? AuraColors.mutedForeground;
    return Container(
      width: 92,
      margin: const EdgeInsets.only(right: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 92,
            height: 112,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AuraColors.surface,
              border: Border.all(color: AuraColors.border),
              boxShadow: [
                BoxShadow(
                  color: cor.withValues(alpha: 0.22),
                  offset: const Offset(0, 10),
                  blurRadius: 20,
                  spreadRadius: -8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: peca.thumb != null && peca.thumb!.isNotEmpty
                  ? Image.memory(
                      base64Decode(peca.thumb!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, _, _) => _IconeCategoria(peca: peca),
                    )
                  : _IconeCategoria(peca: peca),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            peca.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuraType.chip.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cor,
                  border: Border.all(
                    color: AuraColors.border,
                    width: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  peca.corNome.isEmpty ? 'Cor' : peca.corNome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AuraType.caption.copyWith(fontSize: 9.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IconeCategoria extends StatelessWidget {
  const _IconeCategoria({required this.peca});
  final Peca peca;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        PecaCategoria.icon[peca.categoria] ?? Icons.checkroom,
        size: 26,
        color: AuraColors.mutedForeground,
      ),
    );
  }
}

/// Conector "+" usinado entre as peças.
class _Mais extends StatelessWidget {
  const _Mais();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AuraColors.surface,
        border: Border.all(color: AuraColors.border),
      ),
      child: Center(
        child: Icon(Icons.add, size: 12, color: AuraColors.primary),
      ),
    );
  }
}

/// Botão "vou usar isto" — machined; uma vez por dia (+15 XP).
class _BotaoUsar extends StatelessWidget {
  const _BotaoUsar({required this.look});

  final LookMontado look;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GuardaRoupaStore>();
    final usado = store.lookUsadoHoje;

    return GestureDetector(
      onTap: usado
          ? null
          : () {
              if (store.usarLook()) {
                final perfil = context.read<ProfileStore>();
                perfil.addXp(GuardaRoupaStore.xpPorLook);
                AuraSfx.I.success();
                perfil.logEvent('look_usado', {'conceito': look.conceito});
              }
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: usado ? null : AuraDecor.auraMetal,
          color: usado ? AuraColors.surface : null,
          border: usado ? Border.all(color: AuraColors.primary) : null,
        ),
        child: Row(
          children: [
            Icon(
              usado ? Icons.check : Icons.wb_sunny_outlined,
              size: 15,
              color: usado ? AuraColors.primary : AuraColors.backgroundDeep,
            ),
            const SizedBox(width: 7),
            Text(
              usado ? 'Look em uso' : 'Vou usar isto',
              style: AuraType.chip.copyWith(
                fontSize: 11,
                color: usado ? AuraColors.primary : AuraColors.backgroundDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Versão compacta para o Início — vitrine do dia, toca e abre o armário.
class LookCompactCard extends StatelessWidget {
  const LookCompactCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<GuardaRoupaStore>();
    if (!store.podeMontarLook) return const SizedBox.shrink();
    final look = store.montarLook(attempt: 0);
    if (look == null) return const SizedBox.shrink();

    return GlassCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ClosetScreen()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LOOK DE HOJE', style: AuraType.eyebrow),
                    const SizedBox(height: 5),
                    Text(
                      look.conceito,
                      style: AuraType.cardTitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'das tuas peças · harmonia '
                      '${(look.harmonia * 100).round()}%',
                      style: AuraType.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: AuraColors.mutedForeground,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < look.pecas.length.clamp(0, 4); i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _Miniatura(peca: look.pecas[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Miniatura circular da vitrine compacta.
class _Miniatura extends StatelessWidget {
  const _Miniatura({required this.peca});

  final Peca peca;

  @override
  Widget build(BuildContext context) {
    final cor = corDaPeca(peca) ?? AuraColors.mutedForeground;
    return Container(
      width: 54,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(9),
        gradient: AuraDecor.auraMetal,
      ),
      padding: const EdgeInsets.all(1.2),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          color: AuraColors.surface,
          child: peca.thumb != null && peca.thumb!.isNotEmpty
              ? Image.memory(
                  base64Decode(peca.thumb!),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => Icon(
                    PecaCategoria.icon[peca.categoria] ?? Icons.checkroom,
                    size: 18,
                    color: AuraColors.mutedForeground,
                  ),
                )
              : Icon(
                  PecaCategoria.icon[peca.categoria] ?? Icons.checkroom,
                  size: 18,
                  color: cor,
                ),
        ),
      ),
    );
  }
}
