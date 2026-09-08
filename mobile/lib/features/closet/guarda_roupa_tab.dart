/// guarda_roupa_tab.dart — a aba "Peças" do Armário: o teu guarda-roupa
/// real, fotografado. Tira uma foto → a Aura cataloga (nome, slot, cor,
/// ocasiões) → confirmas → a peça entra na grelha e passa a entrar nos
/// looks do dia. O formulário final é sempre editável: a IA propõe, tu
/// dispões.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
import 'look_do_dia.dart';

/// Cores rápidas do seletor manual (a cor da IA vem sempre pré-escolhida).
const _coresRapidas = <String, Color>{
  '#F4F6F8': Color(0xFFF4F6F8),
  '#B8D9F3': Color(0xFFB8D9F3),
  '#3E6A96': Color(0xFF3E6A96),
  '#101C2C': Color(0xFF101C2C),
  '#7A4A3A': Color(0xFF7A4A3A),
  '#DC9B90': Color(0xFFDC9B90),
  '#4E5D52': Color(0xFF4E5D52),
  '#D9C9A3': Color(0xFFD9C9A3),
  '#8A94A6': Color(0xFF8A94A6),
  '#1F2429': Color(0xFF1F2429),
};

/// Ocasiões e estações — chips da ficha.
const kOcasioes = <String>['casual', 'trabalho', 'festa', 'desporto', 'romance'];
const kEstacoes = <String>['todo o ano', 'verao', 'inverno'];

class GuardaRoupaTab extends StatelessWidget {
  const GuardaRoupaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: buildSlivers(context),
    );
  }

  /// Slivers do guarda-roupa — compostos no Armário (aba Peças) e
  /// utilizáveis sozinhos (estado vazio, grelha, look).
  List<Widget> buildSlivers(BuildContext context) {
    final store = context.watch<GuardaRoupaStore>();

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
        sliver: SliverToBoxAdapter(
          child: Column(
              children: [
                if (store.podeMontarLook) ...[
                  const LookCard(),
                  const SizedBox(height: 16),
                ],
                SectionHeader(
                  eyebrow: 'GUARDA-ROUPA VIVO',
                  title: 'As tuas peças',
                  subtitle:
                      'toca longo numa peça para a remover · +5 XP por peça',
                ),
                // Entrada: câmera | galeria.
                Row(
                  children: [
                    Expanded(
                      child: _BotaoOrigem(
                        icon: Icons.photo_camera_outlined,
                        label: 'Câmera',
                        onTap: () => _adicionarPeca(
                          context,
                          ImageSource.camera,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BotaoOrigem(
                        icon: Icons.photo_library_outlined,
                        label: 'Galeria',
                        onTap: () => _adicionarPeca(
                          context,
                          ImageSource.gallery,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
        // Grelha de peças (ou estado vazio).
        if (store.pecas.isEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
            sliver: SliverToBoxAdapter(child: _EstadoVazio()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 110),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.78,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _CardPeca(peca: store.pecas[i]),
                childCount: store.pecas.length,
              ),
            ),
          ),
    ];
  }

  // ── Fluxo: escolher foto → processar → IA → ficha editável ──────────────

  Future<void> _adicionarPeca(
    BuildContext context,
    ImageSource origem,
  ) async {
    final store = context.read<GuardaRoupaStore>();
    final perfil = context.read<ProfileStore>();
    AuraSfx.I.tap();
    perfil.logEvent('guardaroupa_add_open', {'origem': origem.name});

    final foto = await ImagePicker().pickImage(
      source: origem,
      maxWidth: 900,
      imageQuality: 72,
    );
    if (foto == null || !context.mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);

    // Overlay de processamento — a peça está a ser lida.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => const _LeituraOverlay(),
    );

    Uint8List? bytes;
    try {
      bytes = await foto.readAsBytes();
    } catch (_) {}
    if (bytes == null) {
      nav.pop();
      return;
    }
    if (!context.mounted) return;

    final (thumb, corMedia) = await GuardaRoupaStore.processarFoto(bytes);
    final fotoB64 = base64Encode(bytes);

    // A IA cataloga — se falhar, o formulário abre manual (cor média).
    final draft = await GuardaRoupaApi.classificar(fotoB64);

    if (!context.mounted) return;
    nav.pop();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FichaPeca(
        thumb: thumb,
        corMedia: corMedia,
        draft: draft,
        aoGuardar: (peca) {
          store.adicionar(peca);
          perfil.addXp(GuardaRoupaStore.xpPorPeca);
          AuraSfx.I.success();
          perfil.logEvent('guardaroupa_peca', {
            'categoria': peca.categoria,
            'fonte': peca.fonte,
          });
        },
      ),
    );
  }
}

// ── Botões e overlay ────────────────────────────────────────────────────────

class _BotaoOrigem extends StatelessWidget {
  const _BotaoOrigem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AuraDecor.auraMetal,
        ),
        padding: const EdgeInsets.all(1.2),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: AuraColors.backgroundDeep,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: AuraColors.primary),
              const SizedBox(width: 8),
              Text(label, style: AuraType.chip.copyWith(fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}

/// O instante da leitura — disco de platina a girar sobre obsidiana.
class _LeituraOverlay extends StatelessWidget {
  const _LeituraOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: AuraColors.cardFill,
          border: Border.all(color: AuraColors.border),
          boxShadow: AuraDecor.elevatedShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AuraColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text('A ler a peça…', style: AuraType.cardTitle),
            const SizedBox(height: 4),
            Text(
              'cor · categoria · ocasiões',
              style: AuraType.caption.copyWith(fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado vazio ────────────────────────────────────────────────────────────

class _EstadoVazio extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AuraDecor.auraMetal,
            ),
            padding: const EdgeInsets.all(1.4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AuraColors.backgroundDeep,
              ),
              child: Icon(
                Icons.checkroom,
                size: 24,
                color: AuraColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text('O teu guarda-roupa, vivo', style: AuraType.cardTitle),
          const SizedBox(height: 6),
          Text(
            'Fotografa 3 peças para começar — a Aura combina o teu '
            'primeiro look e passa a sugerir um por dia.',
            textAlign: TextAlign.center,
            style: AuraType.caption.copyWith(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ── Cartão de peça na grelha ────────────────────────────────────────────────

class _CardPeca extends StatelessWidget {
  const _CardPeca({required this.peca});

  final Peca peca;

  @override
  Widget build(BuildContext context) {
    final cor = corDaPeca(peca) ?? AuraColors.mutedForeground;
    return GlassCard(
      padding: const EdgeInsets.all(10),
      onTap: () => _confirmarRemover(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AuraColors.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: peca.thumb != null && peca.thumb!.isNotEmpty
                    ? Image.memory(
                        base64Decode(peca.thumb!),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) => _iconeReserva(),
                      )
                    : _iconeReserva(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            peca.nome,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AuraType.chip.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
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
                  '${PecaCategoria.label[peca.categoria] ?? 'Peça'}'
                  '${peca.fonte == 'ai' ? ' · IA' : ''}',
                  style: AuraType.caption.copyWith(fontSize: 9.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconeReserva() => Center(
        child: Icon(
          PecaCategoria.icon[peca.categoria] ?? Icons.checkroom,
          size: 30,
          color: AuraColors.mutedForeground,
        ),
      );

  void _confirmarRemover(BuildContext context) {
    AuraSfx.I.toggle();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AuraColors.border),
        ),
        title: Text(
          'Remover peça?',
          style: AuraType.cardTitle.copyWith(fontSize: 16),
        ),
        content: Text(
          '"${peca.nome}" sai do guarda-roupa e dos looks do dia.',
          style: AuraType.body.copyWith(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Manter',
              style: AuraType.chip.copyWith(color: AuraColors.mutedForeground),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<GuardaRoupaStore>().remover(peca.id);
              context.read<ProfileStore>().logEvent('guardaroupa_remove', {});
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Remover',
              style: AuraType.chip.copyWith(color: AuraColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ficha editável da peça (bottom sheet) ───────────────────────────────────

class _FichaPeca extends StatefulWidget {
  const _FichaPeca({
    required this.thumb,
    required this.corMedia,
    required this.draft,
    required this.aoGuardar,
  });

  final String thumb;
  final String corMedia;
  final PecaDraft? draft;
  final ValueChanged<Peca> aoGuardar;

  @override
  State<_FichaPeca> createState() => _FichaPecaState();
}

class _FichaPecaState extends State<_FichaPeca> {
  late String _categoria;
  late String _corHex;
  late final TextEditingController _nome;
  late final Set<String> _ocasioes;
  late String _estacao;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _nome = TextEditingController(text: d == null ? '' : d.nome);
    _categoria = d?.categoria ?? '';
    _corHex = d?.corHex ?? widget.corMedia;
    _ocasioes = {...?d?.ocasioes};
    _estacao = d?.estacao ?? 'todo o ano';
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  bool get _podeGuardar =>
      _nome.text.trim().isNotEmpty && _categoria.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final veioDaIA = widget.draft != null && widget.draft!.fonte == 'ai';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: AuraColors.backgroundDeep,
          border: Border.all(color: AuraColors.border),
          boxShadow: AuraDecor.elevatedShadow,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho: miniatura + estado da leitura.
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: AuraColors.surface,
                      border: Border.all(color: AuraColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: widget.thumb.isNotEmpty
                          ? Image.memory(
                              base64Decode(widget.thumb),
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.checkroom,
                              color: AuraColors.mutedForeground,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          veioDaIA ? 'LIDA PELA AURA' : 'FICHA DA PEÇA',
                          style: AuraType.eyebrow,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          veioDaIA
                              ? 'A Aura leu a peça — confirma ou corrige.'
                              : 'Completa a ficha — fica catalogada '
                                  'para os looks.',
                          style: AuraType.caption.copyWith(
                            fontSize: 11.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Nome.
              Text('Nome', style: AuraType.chip.copyWith(fontSize: 10)),
              const SizedBox(height: 6),
              TextField(
                controller: _nome,
                onChanged: (_) => setState(() {}),
                style: AuraType.body.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Camisa azul de linho',
                  hintStyle: AuraType.caption.copyWith(fontSize: 13),
                  filled: true,
                  fillColor: AuraColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: AuraColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide(color: AuraColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Categoria (slot do look).
              Text('Slot do look', style: AuraType.chip.copyWith(fontSize: 10)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final c in PecaCategoria.all)
                    _ChipEscolha(
                      label: PecaCategoria.label[c]!,
                      icon: PecaCategoria.icon[c],
                      ativo: _categoria == c,
                      onTap: () => setState(() => _categoria = c),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Cor dominante.
              Text('Cor dominante', style: AuraType.chip.copyWith(fontSize: 10)),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final entry in _coresRapidas.entries) ...[
                    GestureDetector(
                      onTap: () =>
                          setState(() => _corHex = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 27,
                        height: 27,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: entry.value,
                          border: Border.all(
                            color: _corHex == entry.key
                                ? AuraColors.primary
                                : AuraColors.border,
                            width: _corHex == entry.key ? 2.2 : 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'lida: $_corHex${widget.draft?.corNome.isNotEmpty == true ? ' · ${widget.draft!.corNome}' : ''}',
                style: AuraType.caption.copyWith(fontSize: 10.5),
              ),
              const SizedBox(height: 14),

              // Ocasiões.
              Text('Ocasiões', style: AuraType.chip.copyWith(fontSize: 10)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final o in kOcasioes)
                    _ChipEscolha(
                      label: o,
                      ativo: _ocasioes.contains(o),
                      onTap: () => setState(() {
                        _ocasioes.contains(o)
                            ? _ocasioes.remove(o)
                            : _ocasioes.add(o);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Estação.
              Text('Estação', style: AuraType.chip.copyWith(fontSize: 10)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final e in kEstacoes)
                    _ChipEscolha(
                      label: e,
                      ativo: _estacao == e,
                      onTap: () => setState(() => _estacao = e),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Guardar.
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _podeGuardar ? _guardar : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: _podeGuardar
                          ? AuraDecor.auraMetal
                          : null,
                      color: _podeGuardar ? null : AuraColors.surface,
                      border: _podeGuardar
                          ? null
                          : Border.all(color: AuraColors.border),
                    ),
                    child: Center(
                      child: Text(
                        'Guardar peça · +5 XP',
                        style: AuraType.chip.copyWith(
                          fontSize: 12.5,
                          color: _podeGuardar
                              ? AuraColors.backgroundDeep
                              : AuraColors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _guardar() {
    widget.aoGuardar(
      Peca(
        id: DateTime.now().toIso8601String(),
        nome: _nome.text.trim(),
        categoria: _categoria,
        corHex: _corHex,
        corNome: widget.draft?.corNome ?? '',
        ocasioes: _ocasioes.toList(),
        estacao: _estacao,
        fonte: widget.draft?.fonte ?? 'manual',
        thumb: widget.thumb,
        criadoEm: DateTime.now().toIso8601String(),
      ),
    );
    Navigator.of(context).pop();
  }
}

/// Chip de escolha machined — a base de toda a ficha.
class _ChipEscolha extends StatelessWidget {
  const _ChipEscolha({
    required this.label,
    required this.ativo,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool ativo;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        AuraSfx.I.tap();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: ativo ? AuraDecor.auraMetal : null,
          color: ativo ? null : AuraColors.surface,
          border: Border.all(
            color: ativo ? AuraColors.primary : AuraColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: ativo
                    ? AuraColors.backgroundDeep
                    : AuraColors.mutedForeground,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: AuraType.chip.copyWith(
                fontSize: 11,
                color: ativo
                    ? AuraColors.backgroundDeep
                    : AuraColors.foreground.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
