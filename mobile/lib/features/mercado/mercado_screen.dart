/// mercado_screen.dart — compras em modo VISUAL: fotografas a prateleira
/// (ou abes da galeria/partilha), a Aura lê os produtos, prioriza pelo teu
/// perfil + orçamento e entrega veredictos grandes e coloridos:
/// COMPRAR AGORA / DEPOIS / EVITA. Marcas locais honestas num separador.
/// Quase zero texto — só o essencial numa linha.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as p;

import '../../core/api/visual_api.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/shimmer_box.dart';

class MercadoScreen extends StatefulWidget {
  const MercadoScreen({super.key, this.emTab = false});

  /// Quando true, vive numa aba da concha (sem botão voltar).
  final bool emTab;

  @override
  State<MercadoScreen> createState() => _MercadoScreenState();
}

enum _EstadoMercado { idle, analisando, plano, falhou }

class _MercadoScreenState extends State<MercadoScreen> {
  final ImagePicker _picker = ImagePicker();

  _EstadoMercado _estado = _EstadoMercado.idle;
  PlanoCompra? _plano;
  String _aba = 'prateleira'; // prateleira | marcas
  List<MarcaLocal> _marcas = const [];
  bool _marcasACarregar = false;
  double _orcamento = 0;
  Uint8List? _foto;

  static const _orcamentos = <double>[0, 5000, 10000, 25000, 50000];

  @override
  void initState() {
    super.initState();
    final store = p.Provider.of<ProfileStore>(context, listen: false);
    VisualApi.bindProfile(store.profile);
  }

  Future<void> _fotografar({required bool camera}) async {
    try {
      final x = await _picker.pickImage(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 85,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() {
        _foto = bytes;
        _estado = _EstadoMercado.analisando;
      });
      HapticFeedback.mediumImpact();

      final produtos = await VisualApi.I.fotoParaProdutos(base64Encode(bytes));
      if (!mounted) return;
      if (produtos.isEmpty) {
        setState(() => _estado = _EstadoMercado.falhou);
        return;
      }
      final plano = await VisualApi.I.priorizar(produtos, budget: _orcamento);
      if (!mounted) return;
      setState(() {
        _plano = plano;
        _estado = _EstadoMercado.plano;
      });
      HapticFeedback.heavyImpact();
    } catch (_) {
      if (mounted) setState(() => _estado = _EstadoMercado.falhou);
    }
  }

  Future<void> _carregarMarcas() async {
    if (_marcas.isNotEmpty || _marcasACarregar) return;
    setState(() => _marcasACarregar = true);
    final marcas = await VisualApi.I.marcas();
    if (!mounted) return;
    setState(() {
      _marcas = marcas;
      _marcasACarregar = false;
    });
  }

  Future<void> _partilhar(PlanoItem item) async {
    final texto =
        'AuraStyle · ${item.comprar ? "COMPRAR" : "DEPOIS"} · '
        '${item.name}${item.brand.isEmpty ? "" : " (${item.brand})"}'
        '${item.price > 0 ? " — ${item.price.toStringAsFixed(0)}" : ""}\n'
        '${item.reason}';
    await Clipboard.setData(ClipboardData(text: texto));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veredicto copiado — cola onde quiseres'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
          children: [
            _cabecalho(),
            const SizedBox(height: 18),
            _abas(),
            const SizedBox(height: 16),
            if (_aba == 'prateleira') ...[
              _acoesFoto(),
              const SizedBox(height: 16),
              _orcamentosChips(),
              const SizedBox(height: 16),
              _corpo(),
            ] else
              _seccaoMarcas(),
          ],
        ),
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
              child: Icon(Icons.arrow_back, color: AuraColors.foreground, size: 20),
            ),
          ),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('MERCADO', style: AuraType.eyebrow),
              const SizedBox(height: 2),
              Text('Fotografa. A Aura decide.', style: AuraType.cardTitle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _abas() {
    return Row(
      children: [
        _abaChip('prateleira', Icons.storefront_outlined, 'Prateleira'),
        const SizedBox(width: 10),
        _abaChip('marcas', Icons.verified_user_outlined, 'Marcas'),
      ],
    );
  }

  Widget _abaChip(String valor, IconData icone, String rotulo) {
    final ativo = _aba == valor;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _aba = valor);
        if (valor == 'marcas') _carregarMarcas();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: ativo
              ? AuraColors.primary.withValues(alpha: 0.14)
              : AuraColors.cardFill,
          border: Border.all(
            color: ativo ? AuraColors.primary : AuraColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icone,
              size: 16,
              color: ativo ? AuraColors.primary : AuraColors.mutedForeground,
            ),
            const SizedBox(width: 7),
            Text(
              rotulo,
              style: AuraType.chip.copyWith(
                color: ativo ? AuraColors.primary : AuraColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _acoesFoto() {
    return Row(
      children: [
        Expanded(
          child: _acaoGrande(
            icone: Icons.photo_camera_outlined,
            rotulo: 'Fotografar',
            onTap: () => _fotografar(camera: true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _acaoGrande(
            icone: Icons.photo_library_outlined,
            rotulo: 'Galeria',
            onTap: () => _fotografar(camera: false),
          ),
        ),
      ],
    );
  }

  Widget _acaoGrande({
    required IconData icone,
    required String rotulo,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          borderRadius: AuraDecor.rounded,
          gradient: AuraDecor.softGlass,
          color: AuraColors.cardFill,
          border: Border.all(color: AuraColors.border),
          boxShadow: AuraDecor.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AuraDecor.auraMetal,
                boxShadow: AuraDecor.glowShadow(alpha: 0.3),
              ),
              child: Icon(icone, color: AuraColors.onPrimary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(rotulo, style: AuraType.chip),
          ],
        ),
      ),
    );
  }

  Widget _orcamentosChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _orcamentos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = _orcamentos[i];
          final ativo = _orcamento == v;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _orcamento = v);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: ativo
                    ? AuraColors.primary.withValues(alpha: 0.14)
                    : AuraColors.cardFill,
                border: Border.all(
                  color: ativo ? AuraColors.primary : AuraColors.border,
                ),
              ),
              child: Text(
                v == 0 ? 'Sem limite' : '$v',
                style: AuraType.chip.copyWith(
                  color: ativo ? AuraColors.primary : AuraColors.mutedForeground,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _corpo() {
    switch (_estado) {
      case _EstadoMercado.idle:
        return _dicaIdle();
      case _EstadoMercado.analisando:
        return _analisando();
      case _EstadoMercado.falhou:
        return _falhou();
      case _EstadoMercado.plano:
        return _planoView();
    }
  }

  Widget _dicaIdle() {
    return GlassCard(
      child: Column(
        children: [
          if (_foto != null) ...[
            ClipRRect(
              borderRadius: AuraDecor.roundedSmall,
              child: Image.memory(
                _foto!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Icon(Icons.center_focus_weak, color: AuraColors.primary, size: 34),
          const SizedBox(height: 8),
          Text(
            'Aponta para a prateleira e deixa a Aura ler',
            style: AuraType.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _analisando() {
    return GlassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          const ShimmerBox(height: 150.0),
          const SizedBox(height: 14),
          Text('A LER A PRATELEIRA', style: AuraType.eyebrow),
          const SizedBox(height: 8),
          const ShimmerBox(height: 52.0),
          const SizedBox(height: 8),
          const ShimmerBox(height: 52.0),
        ],
      ),
    );
  }

  Widget _falhou() {
    return GlassCard(
      child: Column(
        children: [
          Icon(Icons.search_off, color: AuraColors.chartWarm, size: 36),
          const SizedBox(height: 8),
          Text('Não li nada — tenta mais perto', style: AuraType.body,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _planoView() {
    final plano = _plano!;
    final paraComprar = plano.items.where((i) => i.comprar).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plano.advice.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(plano.advice, style: AuraType.caption),
          ),
        Row(
          children: [
            _selo(plano.source == 'local' ? Icons.offline_bolt : Icons.auto_awesome,
                plano.source == 'local' ? 'OFFLINE' : 'AURA + IA'),
            const SizedBox(width: 8),
            _selo(Icons.shopping_bag_outlined, '$paraComprar PARA COMPRAR'),
          ],
        ),
        const SizedBox(height: 14),
        SectionHeader(eyebrow: 'ORDEM', title: 'Prioridade'),
        const SizedBox(height: 10),
        for (final item in [...plano.items]..sort((a, b) => a.priority.compareTo(b.priority)))
          _cartaoVeredicto(item),
      ],
    );
  }

  Widget _selo(IconData icone, String rotulo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AuraColors.surface,
        border: Border.all(color: AuraColors.border),
      ),
      child: Row(
        children: [
          Icon(icone, size: 13, color: AuraColors.primary),
          const SizedBox(width: 5),
          Text(rotulo, style: AuraType.eyebrow.copyWith(fontSize: 8.5)),
        ],
      ),
    );
  }

  Widget _cartaoVeredicto(PlanoItem item) {
    final comprar = item.comprar;
    final cor = comprar ? AuraColors.primary : AuraColors.mutedForeground;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Veredicto grande — visto sem ler.
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cor.withValues(alpha: comprar ? 0.14 : 0.08),
                border: Border.all(color: cor, width: 1.4),
              ),
              child: Center(
                child: Text(
                  '${item.priority}',
                  style: AuraType.machinedNumber.copyWith(
                    fontSize: 20,
                    color: cor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AuraType.cardTitle.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        comprar ? Icons.check_circle : Icons.schedule,
                        size: 14,
                        color: cor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        comprar ? 'COMPRAR' : 'DEPOIS',
                        style: AuraType.chip.copyWith(fontSize: 9, color: cor),
                      ),
                      if (item.price > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.price.toStringAsFixed(0),
                          style: AuraType.caption,
                        ),
                      ],
                    ],
                  ),
                  if (item.reason.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.reason,
                      style: AuraType.caption.copyWith(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: 'Partilhar',
              onPressed: () => _partilhar(item),
              icon: Icon(Icons.ios_share, size: 18, color: AuraColors.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seccaoMarcas() {
    if (_marcasACarregar) {
      return Column(
        children: [
          const ShimmerBox(height: 64.0),
          const SizedBox(height: 8),
          const ShimmerBox(height: 64.0),
        ],
      );
    }
    if (_marcas.isEmpty) {
      return GlassCard(
        child: Column(
          children: [
            Icon(Icons.verified_user_outlined, color: AuraColors.primary, size: 32),
            const SizedBox(height: 8),
            Text('Marcas locais a chegar — liga-te ao backend', style: AuraType.caption),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(eyebrow: 'MARCAS', title: 'Confiáveis no teu país'),
        const SizedBox(height: 10),
        for (final m in _marcas)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AuraColors.surface,
                      border: Border.all(color: AuraColors.border),
                    ),
                    child: Icon(
                      m.domain == 'pele'
                          ? Icons.face_retouching_natural
                          : m.domain == 'cabelo'
                              ? Icons.spa_outlined
                              : Icons.all_inclusive,
                      color: AuraColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: AuraType.cardTitle.copyWith(fontSize: 14)),
                        const SizedBox(height: 2),
                        if (m.why.isNotEmpty)
                          Text(
                            m.why,
                            style: AuraType.caption.copyWith(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (m.typicalPrice.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(m.typicalPrice, style: AuraType.eyebrow.copyWith(fontSize: 9)),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
