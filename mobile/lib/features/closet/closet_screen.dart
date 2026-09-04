/// closet_screen.dart — o Armário: coleções de cor para o teu subtom.
/// Toca numa cor para a guardar no perfil (profile.colors — a MESMA lista
/// que o web lê). Cartões com mostrador de amostras usinado.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stagger_in.dart';

class _Palette {
  const _Palette(this.name, this.note, this.hex);
  final String name;
  final String note;
  final List<Color> hex;
}

class ClosetScreen extends StatelessWidget {
  const ClosetScreen({super.key});

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
    _Palette('Obsidiana', 'noites frias · contraste máximo', [
      Color(0xFF04060A),
      Color(0xFF14191F),
      Color(0xFF2B3540),
      Color(0xFF51606F),
      Color(0xFF8E96A2),
    ]),
    _Palette('Pedra-Lua', 'acento glacial · toque lunar', [
      Color(0xFF4A5E75),
      Color(0xFF7391AC),
      Color(0xFF9BC3E5),
      Color(0xFFCDE9FD),
      Color(0xFFF0F7FD),
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

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ARMÁRIO', style: AuraType.eyebrow),
                const SizedBox(height: 6),
                Text(
                  'Cores que favorecem o teu subtom'
                  '${store.profile.undertone.isNotEmpty ? ' · ${store.profile.undertone}' : ''}',
                  style: AuraType.sectionTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  'Toca numa amostra para a guardar no perfil',
                  style: AuraType.caption,
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 110),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, i) {
              final pal = _palettes[i];
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
                                onTap: () => _toggleColor(context, store, c),
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
                                          store.profile.colors.contains(_hex(c))
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
            }, childCount: _palettes.length),
          ),
        ),
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
