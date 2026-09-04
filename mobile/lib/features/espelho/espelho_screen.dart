/// espelho_screen.dart — o Espelho: identidade por IMAGENS REAIS, não texto.
///
/// A pessoa vê fotografias reais (banco visual partilhado) de cabelos e
/// estilos, toca no que é parecido consigo, pode acrescentar a própria foto,
/// e o perfil absorve tudo — o chat, as análises e o mercado passam a
/// falar a língua visual dela. Mínimo de texto; máximo de imagem.
library;


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/visual_api.dart';
import '../../core/secrets.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/shimmer_box.dart';

class EspelhoScreen extends StatefulWidget {
  const EspelhoScreen({super.key, this.emTab = false});

  /// Quando true, vive numa aba da concha (sem botão voltar).
  final bool emTab;

  @override
  State<EspelhoScreen> createState() => _EspelhoScreenState();
}

class _EspelhoScreenState extends State<EspelhoScreen> {
  final VisualApi _api = VisualApi.I;

  // Categorias em ordem fixa — cada tile carrega a sua categoria.
  late final List<(String, String)> _cabelo = [
    for (final e in VisualApi.cabeloQueries.entries) (e.key, e.value),
  ];
  late final List<(String, String)> _estilos = [
    for (final e in VisualApi.estiloQueries.entries) (e.key, e.value),
  ];

  final Map<String, List<VisualItem>> _fotos = {};
  String? _cabeloSel;
  String? _estiloSel;
  final Set<String> _refs = {};
  Uint8List? _minhaFoto;
  bool _temFotoLocal = false;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final store = p.Provider.of<ProfileStore>(context, listen: false);
    _cabeloSel =
        store.profile.hairType.isEmpty ? null : store.profile.hairType;
    _estiloSel =
        store.profile.styles.isNotEmpty ? store.profile.styles.first : null;
    _refs.addAll(store.profile.espelho);
    _carregarTudo();
    _carregarFotoLocal();
  }

  Future<void> _carregarTudo() async {
    for (final (tipo, query) in [..._cabelo, ..._estilos]) {
      if (_fotos.containsKey(tipo)) continue;
      final r = await _api.buscar(query, count: 3);
      if (!mounted) return;
      setState(() => _fotos[tipo] = r.items);
    }
  }

  Future<void> _carregarFotoLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final temFoto = (prefs.getString('aurastyle-espelho-foto') ?? '').isNotEmpty;
    if (temFoto && mounted) {
      setState(() => _temFotoLocal = true);
    }
  }

  Future<void> _escolherFoto() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 82,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      await SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(
          'aurastyle-espelho-foto',
          Uri.encodeComponent(x.name),
        ),
      );
      if (!mounted) return;
      setState(() {
        _minhaFoto = bytes;
        _temFotoLocal = true;
      });
      HapticFeedback.selectionClick();
    } catch (_) {
      // permissão negada etc. — segue sem foto
    }
  }

  Future<void> _guardar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    final store = p.Provider.of<ProfileStore>(context, listen: false);
    VisualApi.bindProfile(store.profile);
    final jaTinha = store.profile.hairType.isNotEmpty;
    store.updateProfile(
      (prof) => prof.copyWith(
        hairType: _cabeloSel ?? prof.hairType,
        styles: _estiloSel == null
            ? prof.styles
            : [_estiloSel!, ...prof.styles.where((s) => s != _estiloSel!)],
        espelho: _refs.toList(),
      ),
    );
    if (!jaTinha && _cabeloSel != null) store.addXp(15);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _cabeloSel == null
              ? 'Espelho guardado — volta quando quiseres'
              : 'Espelho guardado · +15 XP · a Aura leu-te',
          style: AuraType.body,
        ),
      ),
    );
    // Em aba da concha não há rota para fechar — só sai quando houver.
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Quando o Espelho vive numa aba da concha, o menu de vidro flutuante
    // (66px + margens) e a coroa do Scan ocupam a base do ecrã — a barra de
    // guardar tem de subir ACIMA deles ou fica inacessível (bug do APK).
    final navInset = MediaQuery.of(context).padding.bottom + 66 + 14 + 12;
    final barraBaixo = widget.emTab ? navInset : 18.0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18,
                8,
                18,
                widget.emTab ? navInset + 84 : 130,
              ),
              children: [
                _cabecalho(),
                const SizedBox(height: 22),
                _seccao(
                  titulo: 'CABELO',
                  itens: _cabelo,
                  sel: _cabeloSel,
                  onSel: (t) {
                    HapticFeedback.selectionClick();
                    setState(() => _cabeloSel = t);
                  },
                ),
                const SizedBox(height: 26),
                _seccao(
                  titulo: 'ESTILO',
                  itens: _estilos,
                  sel: _estiloSel,
                  onSel: (t) {
                    HapticFeedback.selectionClick();
                    setState(() => _estiloSel = t);
                  },
                ),
                const SizedBox(height: 26),
                _minhaSecaoFoto(),
              ],
            ),
          ),
          // Barra de guardado flutuante — acima do menu quando em aba.
          Positioned(
            left: 18,
            right: 18,
            bottom: barraBaixo,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ESPELHO', style: AuraType.eyebrow),
                        const SizedBox(height: 2),
                        Text(
                          _resumo(),
                          style: AuraType.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _botaoGuardar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cabecalho() {
    return Row(
      children: [
        if (!widget.emTab) ...[
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AuraColors.cardFill,
                border: Border.all(color: AuraColors.border),
              ),
              child: Icon(
                Icons.arrow_back,
                color: AuraColors.foreground,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ESPELHO', style: AuraType.eyebrow),
              const SizedBox(height: 2),
              Text('Escolhe o que te parece contigo', style: AuraType.cardTitle),
            ],
          ),
        ),
        if (AuraSecrets.temBancosImagem)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AuraColors.cardFill,
              border: Border.all(color: AuraColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 13,
                  color: AuraColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Pexels + Unsplash',
                  style: AuraType.chip.copyWith(
                    color: AuraColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _resumo() {
    final c = _cabeloSel ?? 'cabelo —';
    final e = _estiloSel ?? 'estilo —';
    return '$c · $e${_temFotoLocal ? ' · foto ✓' : ''}';
  }

  Widget _seccao({
    required String titulo,
    required List<(String, String)> itens,
    required String? sel,
    required ValueChanged<String> onSel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          eyebrow: titulo,
          title: titulo == 'CABELO' ? 'O teu cabelo' : 'O teu estilo',
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
          children: [
            for (final (tipo, _) in itens)
              _tileCategoria(
                tipo: tipo,
                fotos: _fotos[tipo] ?? const [],
                sel: sel == tipo,
                onTap: () => onSel(tipo),
              ),
          ],
        ),
      ],
    );
  }

  Widget _tileCategoria({
    required String tipo,
    required List<VisualItem> fotos,
    required bool sel,
    required VoidCallback onTap,
  }) {
    final foto = fotos.isEmpty ? null : fotos.first;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: AuraDecor.rounded,
          border: Border.all(
            color: sel ? AuraColors.primary : AuraColors.border,
            width: sel ? 2 : 1,
          ),
          boxShadow: sel ? AuraDecor.glowShadow(alpha: 0.35) : AuraDecor.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: AuraDecor.rounded,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (foto != null && foto.thumb.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: foto.thumb,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const ShimmerBox(),
                  errorWidget: (_, _, _) => _fallback(tipo),
                )
              else
                _fallback(tipo),
              // Base de legenda.
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 46,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x0004060A), Color(0xB304060A)],
                    ),
                  ),
                  padding: const EdgeInsets.all(6),
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    tipo,
                    style: AuraType.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (sel)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AuraDecor.auraMetal,
                    ),
                    child: Icon(Icons.check, size: 15, color: AuraColors.onPrimary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallback(String tipo) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AuraColors.surface, AuraColors.secondary],
        ),
      ),
      child: Center(
        child: Icon(
          _iconeTipo(tipo),
          color: AuraColors.primary.withValues(alpha: 0.7),
          size: 30,
        ),
      ),
    );
  }

  IconData _iconeTipo(String tipo) {
    switch (tipo) {
      case 'Liso':
        return Icons.waves;
      case 'Ondulado':
        return Icons.air;
      case 'Cacheado':
        return Icons.loop;
      case 'Cacheado 4C':
        return Icons.blur_on;
      case 'Transças':
        return Icons.line_style;
      case 'Coque':
        return Icons.circle_outlined;
      case 'Clássico':
        return Icons.workspace_premium_outlined;
      case 'Rua':
        return Icons.snowshoeing_outlined;
      case 'Desportivo':
        return Icons.directions_run;
      case 'Criativo':
        return Icons.palette_outlined;
      case 'Minimal':
        return Icons.crop_square;
      case 'Romântico':
        return Icons.favorite_outline;
      default:
        return Icons.auto_awesome;
    }
  }

  Widget _minhaSecaoFoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(eyebrow: 'RETRATO', title: 'A tua foto'),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _escolherFoto,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: AuraDecor.rounded,
              color: AuraColors.cardFill,
              border: Border.all(
                color: _temFotoLocal
                    ? AuraColors.primary.withValues(alpha: 0.6)
                    : AuraColors.border,
              ),
            ),
            child: _minhaFoto != null
                ? ClipRRect(
                    borderRadius: AuraDecor.rounded,
                    child: Image.memory(
                      _minhaFoto!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : _temFotoLocal
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_outlined,
                          color: AuraColors.primary, size: 26),
                      const SizedBox(width: 10),
                      Text('Foto no espelho — toca para trocar',
                          style: AuraType.caption),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          color: AuraColors.primary, size: 26),
                      const SizedBox(width: 10),
                      Text('Acrescenta a tua foto', style: AuraType.caption),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _botaoGuardar() {
    return GestureDetector(
      onTap: _guardar,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: AuraDecor.auraMetal,
          boxShadow: AuraDecor.glowShadow(alpha: 0.35),
        ),
        child: _salvando
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                children: [
                  Icon(Icons.check_rounded, size: 18, color: AuraColors.onPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Guardar',
                    style: AuraType.chip.copyWith(color: AuraColors.onPrimary),
                  ),
                ],
              ),
      ),
    );
  }
}
