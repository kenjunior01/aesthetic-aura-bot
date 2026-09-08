/// closet_screen.dart — o Armário, agora em duas abas:
///
///  • Cores — coleções de cor para o teu subtom (as paletas de sempre).
///    Toca numa amostra para a guardar no perfil (profile.colors).
///  • Peças — o Guarda-Roupa Vivo: fotografias das tuas peças reais
///    catalogadas pela Aura + o Look de Hoje montado com elas.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/guarda_roupa_store.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stagger_in.dart';
import '../../core/sfx/aura_sfx.dart';
import 'guarda_roupa_tab.dart';

class _Palette {
  const _Palette(this.name, this.note, this.hex);
  final String name;
  final String note;
  final List<Color> hex;
}

class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  bool _tabPecas = false;

  static const _palettes = <_Palette>[
    _Palette('Glacial Profundo', 'base fria · inverno puro', [
      Color(0xFF101C2C),
      Color(0xFF23405F),
      Color(0xFF3E6A96),
      Color(0xFF9BC3E5),
      Color(0xFFE9F3FC),
    ]),
    _Palette('Platina Solar', 'metais claros · brilho suave', [
      Color(0xFF6E7681),
      Color(0xFF9AA3AE),
      Color(0xFFC8D2DC),
      Color(0xFFB8D9F3),
      Color(0xFFF4F9FF),
    ]),
    _Palette(' Âmbar de Inverno', 'contraste quente · 1 peça só', [
      Color(0xFF7A4A3A),
      Color(0xFFB0714F),
      Color(0xFFDC9B90),
      Color(0xFFE9C4B8),
      Color(0xFFFAF0EA),
    ]),
    _Palette('Névoa Atlântica', 'tons médios · dia a dia', [
      Color(0xFF374A5C),
      Color(0xFF54708A),
      Color(0xFF7FA3BF),
      Color(0xFFAFC9DE),
      Color(0xFFE5EEF6),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final guarda = context.watch<GuardaRoupaStore>();
    final titulo = _tabPecas
        ? 'O teu guarda-roupa real'
        : 'Cores que favorecem o teu subtom'
            '${store.profile.undertone.isNotEmpty ? ' · ${store.profile.undertone}' : ''}';

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ARMÁRIO', style: AuraType.eyebrow),
                const SizedBox(height: 6),
                Text(titulo, style: AuraType.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  _tabPecas
                      ? '${guarda.pecas.length} peça${guarda.pecas.length == 1 ? '' : 's'} '
                          'catalogada${guarda.pecas.length == 1 ? '' : 's'} pela Aura'
                      : 'Toca numa amostra para a guardar no perfil',
                  style: AuraType.caption,
                ),
                const SizedBox(height: 12),
                // Segmentado usinado — Cores | Peças.
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AuraColors.surface,
                    border: Border.all(color: AuraColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _Segmento(
                          label: 'Cores',
                          icon: Icons.palette_outlined,
                          ativo: !_tabPecas,
                          onTap: () => setState(() => _tabPecas = false),
                        ),
                      ),
                      Expanded(
                        child: _Segmento(
                          label: 'Peças',
                          icon: Icons.checkroom,
                          ativo: _tabPecas,
                          onTap: () => setState(() => _tabPecas = true),
                          selo: guarda.pecas.isEmpty
                              ? null
                              : '${guarda.pecas.length}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_tabPecas)
          ...GuardaRoupaTab().buildSlivers(context)
        else
          _CoresView(palettes: _palettes),
      ],
    );
  }

  void _toggleColor(BuildContext context, ProfileStore store, Color c) {
    final hex = _hex(c);
    store.updateProfile(
      (p) => p.copyWith(
        colors: p.colors.contains(hex)
            ? p.colors.where((x) => x != hex).toList()
            : [...p.colors, hex],
      ),
    );
    store.logEvent('closet_pick', {'hex': hex});
  }

  String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Segmento do controle usinado.
class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.label,
    required this.icon,
    required this.ativo,
    required this.onTap,
    this.selo,
  });

  final String label;
  final IconData icon;
  final bool ativo;
  final VoidCallback onTap;
  final String? selo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AuraSfx.I.toggle();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: ativo ? AuraDecor.auraMetal : null,
          color: ativo ? null : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: ativo ? AuraColors.backgroundDeep : AuraColors.mutedForeground,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: AuraType.chip.copyWith(
                fontSize: 11.5,
                color: ativo
                    ? AuraColors.backgroundDeep
                    : AuraColors.mutedForeground,
              ),
            ),
            if (selo != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: ativo
                      ? AuraColors.backgroundDeep.withValues(alpha: 0.18)
                      : AuraColors.primary.withValues(alpha: 0.14),
                ),
                child: Text(
                  selo!,
                  style: AuraType.chip.copyWith(
                    fontSize: 9,
                    color: ativo
                        ? AuraColors.backgroundDeep
                        : AuraColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// As coleções de cor — as paletas de sempre, intocadas.
class _CoresView extends StatelessWidget {
  const _CoresView({required this.palettes});

  final List<_Palette> palettes;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final dono = context.findAncestorStateOfType<_ClosetScreenState>();
    if (dono == null) return const SliverToBoxAdapter(child: SizedBox());

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 110),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, i) {
          final pal = palettes[i];
          return StaggerIn(
            index: i,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(eyebrow: 'COLEÇÃO', title: ''),
                  // Amostras em régua usinada.
                  Row(
                    children: [
                      for (final c in pal.hex) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () => dono._toggleColor(context, store, c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              height: 58,
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.horizontal(
                                  left: Radius.circular(
                                    pal.hex.first == c ? 12 : 4,
                                  ),
                                  right: Radius.circular(
                                    pal.hex.last == c ? 12 : 4,
                                  ),
                                ),
                                border: Border.all(
                                  color:
                                      store.profile.colors.contains(dono._hex(c))
                                      ? AuraColors.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: c.withValues(alpha: 0.35),
                                    offset: const Offset(0, 8),
                                    blurRadius: 18,
                                    spreadRadius: -8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(pal.name.trim(), style: AuraType.cardTitle),
                  Text(
                    pal.note,
                    style: AuraType.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }, childCount: palettes.length),
      ),
    );
  }
}
