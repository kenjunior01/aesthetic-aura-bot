/// cromatica_screen.dart — A TUA ESTAÇÃO: a paleta pessoal calculada do teu
/// subtom, tom de pele e cabelo. O ecrã mais visual do app:
///
///  1. Cartão-herói com o gradiente da estação
///  2. Paleta de 10 cores que vestem (grid 5×2)
///  3. Neutros que salvam qualquer look
///  4. Cores a evitar (com marcas de risco)
///  5. Combinações prontas (círculos sobrepostos)
///  6. Fotos reais da estação (Pexels/Unsplash intercalados)
///
/// Sem dados de scan, deixa explorar as 10 estações e aponta ao Scan.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api/image_bank.dart';
import '../../core/api/visual_api.dart';
import '../../core/data/cromatica.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/widgets/stagger_in.dart';
import '../scan/scan_screen.dart';

Color corDe(String hex) {
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse(h, radix: 16) ?? 0x888888;
  return Color(0xFF000000 | v);
}

Color textoSobre(Color c) =>
    c.computeLuminance() > 0.55 ? const Color(0xFF141A22) : Colors.white;

class CromaticaScreen extends StatefulWidget {
  const CromaticaScreen({super.key});

  @override
  State<CromaticaScreen> createState() => _CromaticaScreenState();
}

class _CromaticaScreenState extends State<CromaticaScreen> {
  Estacao? _manual; // exploração livre das 10 estações

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final store = context.read<ProfileStore>();
      store.logEvent('cromatica_open', {});
      // +30 XP só na primeira leitura da estação.
      if (Cromatica.temDados(store.profile) &&
          !store.events.any((e) => e.contains('cromatica_xp'))) {
        store.addXp(30);
        store.logEvent('cromatica_xp', {'amount': 30});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final temDados = Cromatica.temDados(store.profile);
    final estacao =
        _manual ?? (temDados ? Cromatica.analisar(store.profile) : null);

    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: _topBar(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (estacao != null) ...[
                    StaggerIn(index: 0, child: _heroi(estacao)),
                    const SizedBox(height: 16),
                    StaggerIn(
                      index: 1,
                      child: _secao('A TUA PALETA', 'dez cores que vestem o teu tom', [
                        _gradePaleta(estacao.paleta),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    StaggerIn(
                      index: 2,
                      child: _secao('NEUTROS QUE SALVAM', 'a base de tudo', [
                        _linhaNeutros(estacao.neutros),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    StaggerIn(
                      index: 3,
                      child: _secao('A EVITAR', 'roubam a tua luz', [
                        _linhaEvitar(estacao.evitar),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    StaggerIn(
                      index: 4,
                      child: _secao('COMBINAÇÕES', 'prontas para usar', [
                        for (final c in estacao.combos) _combo(c),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    StaggerIn(
                      index: 5,
                      child: _secao('AO VIVO', 'a estação em fotos reais', [
                        _fotosEstacao(estacao),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    StaggerIn(index: 6, child: _rodape(estacao, store.profile)),
                  ] else ...[
                    StaggerIn(
                      index: 0,
                      child: GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              eyebrow: 'CROMÁTICA',
                              title: 'O teu tom ainda não foi lido',
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Faz o Scan de aura e a estação nasce do teu '
                              'subtom, tom de pele e cabelo. Ou explora as '
                              'dez estações abaixo.',
                              style: AuraType.caption.copyWith(height: 1.5),
                            ),
                            const SizedBox(height: 14),
                            PlatinaButton(
                              label: 'Fazer scan',
                              icon: Icons.center_focus_strong,
                              expanded: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ScanScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StaggerIn(
                      index: 1,
                      child: const SectionHeader(
                        eyebrow: 'AS DEZ ESTAÇÕES',
                        title: 'Explora cada mundo',
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final (i, e) in Cromatica.todas.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: StaggerIn(index: i, child: _miniEstacao(e)),
                      ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Topo ────────────────────────────────────────────────────────────────────

  Widget _topBar() => Row(
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
          child: Icon(
            Icons.arrow_back,
            size: 18,
            color: AuraColors.foreground,
          ),
        ),
      ),
      const Spacer(),
      Text('ANÁLISE CROMÁTICA', style: AuraType.eyebrow),
      const Spacer(),
      const SizedBox(width: 40),
    ],
  );

  // ── Herói ───────────────────────────────────────────────────────────────────

  Widget _heroi(Estacao e) {
    final cores = e.gradiente.map(corDe).toList();
    final tinta = textoSobre(cores.first);
    return ClipRRect(
      borderRadius: AuraDecor.roundedLarge,
      child: Container(
        height: 212,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: cores,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.25, 1],
                  colors: [
                    Colors.transparent,
                    corDe(e.gradiente.first).withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                    child: Text(
                      _metalLabel(e.metal),
                      style: AuraType.chip.copyWith(
                        fontSize: 9.5,
                        color: Colors.white,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    e.nome,
                    style: AuraType.sectionTitle.copyWith(
                      fontSize: 27,
                      color: tinta,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.subtitulo,
                    style: AuraType.caption.copyWith(
                      fontSize: 13,
                      color: tinta.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    e.historia,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AuraType.caption.copyWith(
                      fontSize: 11.5,
                      height: 1.45,
                      color: tinta.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _metalLabel(String metal) {
    switch (metal) {
      case 'ouro':
        return 'METAL · OURO QUENTE';
      case 'prata':
        return 'METAL · PRATA FRIA';
      default:
        return 'METAL · OURO E PRATA';
    }
  }

  // ── Secções ─────────────────────────────────────────────────────────────────

  Widget _secao(String eyebrow, String titulo, List<Widget> children) =>
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(eyebrow: eyebrow, title: titulo),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _gradePaleta(List<Swatch> paleta) => Column(
    children: [
      for (final linha in _partition(paleta, 5))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (final (j, s) in linha.indexed) ...[
                if (j > 0) const SizedBox(width: 8),
                Expanded(child: _swatch(s)),
              ],
            ],
          ),
        ),
    ],
  );

  Widget _swatch(Swatch s) {
    final c = corDe(s.hex);
    return Column(
      children: [
        Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AuraDecor.radiusSmall),
            color: c,
            border: Border.all(color: AuraColors.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: c.withValues(alpha: 0.35),
                offset: const Offset(0, 6),
                blurRadius: 14,
                spreadRadius: -6,
              ),
            ],
          ),
          child: Center(
            child: Text(
              s.nome.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AuraType.sans,
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: textoSobre(c).withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AuraType.caption.copyWith(fontSize: 8.5),
        ),
      ],
    );
  }

  Widget _linhaNeutros(List<Swatch> neutros) => Row(
    children: [
      for (final (i, s) in neutros.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AuraDecor.radiusSmall),
              color: corDe(s.hex),
              border: Border.all(color: AuraColors.border, width: 0.8),
            ),
            alignment: Alignment.bottomLeft,
            padding: const EdgeInsets.all(6),
            child: Text(
              s.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AuraType.sans,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: textoSobre(corDe(s.hex)).withValues(alpha: 0.9),
              ),
            ),
          ),
        ),
      ],
    ],
  );

  Widget _linhaEvitar(List<Swatch> evitar) => Row(
    children: [
      for (final (i, s) in evitar.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: _evitarSwatch(s)),
      ],
    ],
  );

  Widget _evitarSwatch(Swatch s) {
    final c = corDe(s.hex);
    final tinta = textoSobre(c);
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AuraDecor.radiusSmall),
        border: Border.all(color: AuraColors.border, width: 0.8),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AuraDecor.radiusSmall - 1),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0x9E888888),
                BlendMode.saturation,
              ),
              child: ColoredBox(color: c),
            ),
          ),
          Center(
            child: Text(
              '×',
              style: TextStyle(
                fontFamily: AuraType.display,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: tinta.withValues(alpha: 0.85),
              ),
            ),
          ),
          Positioned(
            left: 6,
            bottom: 5,
            right: 6,
            child: Text(
              s.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AuraType.sans,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: tinta.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _combo(Combo c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            c.titulo,
            style: AuraType.cardTitle.copyWith(fontSize: 12.5),
          ),
        ),
        for (final hex in c.cores)
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: -10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: corDe(hex),
              border: Border.all(color: AuraColors.card, width: 2.2),
              boxShadow: AuraDecor.cardShadow,
            ),
          ),
        const SizedBox(width: 20),
        Expanded(
          child: Text(
            c.cores.map(_nomeCurto).join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AuraType.caption.copyWith(fontSize: 10),
          ),
        ),
      ],
    ),
  );

  String _nomeCurto(String hex) {
    for (final e in Cromatica.todas) {
      for (final s in [...e.paleta, ...e.neutros]) {
        if (s.hex.toUpperCase() == hex.toUpperCase()) return s.nome;
      }
    }
    return hex;
  }

  Widget _fotosEstacao(Estacao e) => FutureBuilder<VisualResult>(
    future: BancoImagens.I.buscar(e.consultas.first, count: 4),
    builder: (context, snap) {
      final items = snap.data?.items ?? const <VisualItem>[];
      if (items.isEmpty) {
        return const ShimmerBox(height: 120, radius: 14);
      }
      return Column(
        children: [
          for (final linha in _partition(items.take(4).toList(), 2))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  for (final (j, item) in linha.indexed) ...[
                    if (j > 0) const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AuraDecor.radiusSmall),
                        child: Container(
                          height: 118,
                          foregroundDecoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              AuraDecor.radiusSmall,
                            ),
                            border: Border.all(color: AuraColors.border),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: item.thumb,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const ShimmerBox(radius: 0),
                            errorWidget: (_, _, _) => Container(
                              color: AuraColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'fotos · ${snap.data?.source ?? ''}',
              style: AuraType.caption.copyWith(fontSize: 9),
            ),
          ),
        ],
      );
    },
  );

  Widget _rodape(Estacao e, Profile p) => Text(
    'calculado do teu subtom (${p.undertone.toLowerCase()}), tom de pele '
    '${p.skinTone > 0 ? '${p.skinTone}/10' : 'por definir'} e cabelo '
    '${p.hairColor.isEmpty ? 'por definir' : p.hairColor.toLowerCase()}. '
    'Refaz no Scan se algo mudou.',
    style: AuraType.caption.copyWith(fontSize: 10.5, height: 1.5),
  );

  Widget _miniEstacao(Estacao e) => GlassCard(
    onTap: () => setState(() => _manual = e),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: e.gradiente.map(corDe).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(e.nome, style: AuraType.cardTitle.copyWith(fontSize: 14)),
        ),
        Icon(Icons.chevron_right, size: 18, color: AuraColors.mutedForeground),
      ],
    ),
  );

  // ── Util ────────────────────────────────────────────────────────────────────

  List<List<T>> _partition<T>(List<T> list, int size) {
    final out = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      out.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return out;
  }
}
