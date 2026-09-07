/// profile_edit_screen.dart — a Ficha de Aura editável. O que faltava no
/// telemóvel: cada traço que aqui defines entra direto no perfil e alimenta
/// TODA a IA (chat, jornada, mercado, cromática). Chips de escolha única e
/// múltipla, sliders usinados — tudo grava ao vivo, zero botão "salvar".
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stagger_in.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<ProfileStore>();
    final p = store.profile;

    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
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
                        child: const Icon(Icons.arrow_back, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('A tua ficha', style: AuraType.cardTitle),
                          Text(
                            'cada traço aqui alimenta a tua Aura',
                            style: AuraType.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),

            // ── Localização & vida ──────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: StaggerIn(
                  index: 0,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          eyebrow: 'ONDE E QUEM',
                          title: 'Localização & vida',
                          subtitle:
                              'clima e cidade afinam rotina, cores e produtos',
                        ),
                        _TextFieldRow(
                          label: 'Cidade',
                          value: p.city,
                          hint: 'Luanda, Lisboa, São Paulo…',
                          onChanged: (v) => _set(context, (q) => q.copyWith(city: v)),
                        ),
                        _TextFieldRow(
                          label: 'País',
                          value: p.country,
                          hint: 'AO, PT, BR, MZ…',
                          onChanged: (v) =>
                              _set(context, (q) => q.copyWith(country: v)),
                        ),
                        _TextFieldRow(
                          label: 'Profissão',
                          value: p.profession,
                          hint: 'Design, Tecnologia, Saúde…',
                          onChanged: (v) =>
                              _set(context, (q) => q.copyWith(profession: v)),
                        ),
                        const SizedBox(height: 8),
                        _ChipGroup(
                          titulo: 'Clima',
                          opcoes: const [
                            ('tropical', 'Tropical'),
                            ('temperado', 'Temperado'),
                            ('frio', 'Frio'),
                            ('arido', 'Árido'),
                          ],
                          selecionado: p.climate,
                          onSel: (v) =>
                              _set(context, (q) => q.copyWith(climate: v)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Rosto & pele ────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: StaggerIn(
                  index: 1,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          eyebrow: 'O ESPELHO',
                          title: 'Rosto & pele',
                          subtitle:
                              'escala 1–14 de tom — a mesma que a IA lê nas fotos',
                        ),
                        _ChipGroup(
                          titulo: 'Formato do rosto',
                          opcoes: const [
                            ('oval', 'Oval'),
                            ('redondo', 'Redondo'),
                            ('quadrado', 'Quadrado'),
                            ('retangular', 'Retangular'),
                            ('coracao', 'Coração'),
                            ('diamante', 'Diamante'),
                            ('losango', 'Losango'),
                          ],
                          selecionado: p.faceShape,
                          onSel: (v) =>
                              _set(context, (q) => q.copyWith(faceShape: v)),
                        ),
                        _SliderRow(
                          titulo: 'Tom de pele',
                          valor: p.skinTone > 0 ? p.skinTone.toDouble() : 7,
                          min: 1,
                          max: 14,
                          fracoes: 0,
                          rotulo: (v) => v <= 4
                              ? 'clara'
                              : v <= 8
                                  ? 'média'
                                  : v <= 11
                                      ? 'achocolatada'
                                      : 'profunda',
                          onChanged: (v) => _set(
                            context,
                            (q) => q.copyWith(skinTone: v.round()),
                          ),
                        ),
                        _ChipGroup(
                          titulo: 'Subtom',
                          opcoes: const [
                            ('quente', 'Quente'),
                            ('frio', 'Frio'),
                            ('neutro', 'Neutro'),
                            ('oliva', 'Oliva'),
                          ],
                          selecionado: p.undertone,
                          onSel: (v) =>
                              _set(context, (q) => q.copyWith(undertone: v)),
                        ),
                        _ChipGroup(
                          titulo: 'Olhos',
                          opcoes: const [
                            ('castanho', 'Castanho'),
                            ('mel', 'Mel'),
                            ('verde', 'Verde'),
                            ('azul', 'Azul'),
                            ('cinza', 'Cinza'),
                            ('preto', 'Preto'),
                          ],
                          selecionado: p.eyeColor,
                          onSel: (v) =>
                              _set(context, (q) => q.copyWith(eyeColor: v)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Cabelo ──────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: StaggerIn(
                  index: 2,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          eyebrow: 'A COROA',
                          title: 'Cabelo',
                          subtitle: 'tipo, cor e comprimento de hoje',
                        ),
                        _ChipGroup(
                          titulo: 'Tipo',
                          opcoes: const [
                            ('liso', 'Liso'),
                            ('ondulado', 'Ondulado'),
                            ('cacheado', 'Cacheado'),
                            ('crespo', 'Crespo'),
                            ('afro', 'Afro'),
                            ('trancas', 'Tranças'),
                            ('locks', 'Locks'),
                            ('rapado', 'Rapado'),
                            ('moicano', 'Moicano'),
                            ('careca', 'Careca'),
                          ],
                          selecionado: p.hairType,
                          onSel: (v) =>
                              _set(context, (q) => q.copyWith(hairType: v)),
                        ),
                        _ChipGroup(
                          titulo: 'Cor',
                          opcoes: const [
                            ('loiro-claro', 'Loiro claro'),
                            ('loiro-escuro', 'Loiro escuro'),
                            ('castanho-medio', 'Castanho médio'),
                            ('castanho-escuro', 'Castanho escuro'),
                            ('ruivo', 'Ruivo'),
                            ('preto', 'Preto'),
                            ('grisalho', 'Grisalho'),
                            ('colorido', 'Colorido'),
                          ],
                          selecionado: p.hairColor,
                          onSel: (v) =>
                              _set(context, (q) => q.copyWith(hairColor: v)),
                        ),
                        _ChipGroup(
                          titulo: 'Comprimento',
                          opcoes: const [
                            ('buzz', 'Buzz cut'),
                            ('curto', 'Curto'),
                            ('medio', 'Médio'),
                            ('longo', 'Longo'),
                          ],
                          selecionado: p.hairLength,
                          onSel: (v) =>
                              _set(context, (q) => q.copyWith(hairLength: v)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Corpo ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: StaggerIn(
                  index: 3,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          eyebrow: 'A ESTRUTURA',
                          title: 'Corpo',
                          subtitle: 'silhueta e medidas para cortes e caimento',
                        ),
                        _ChipGroup(
                          titulo: 'Silhueta',
                          opcoes: const [
                            ('triangulo', 'Triângulo'),
                            ('invertido', 'Triângulo invertido'),
                            ('retangular', 'Retangular'),
                            ('oval', 'Oval'),
                            ('ampulheta', 'Ampulheta'),
                          ],
                          selecionado: p.bodyType,
                          onSel: (v) =>
                              _set(context, (q) => q.copyWith(bodyType: v)),
                        ),
                        _SliderRow(
                          titulo: 'Altura',
                          valor: p.height > 0
                              ? p.height.toDouble()
                              : 175,
                          min: 140,
                          max: 210,
                          fracoes: 0,
                          rotulo: (v) => '${v.round()} cm',
                          onChanged: (v) =>
                              _set(context, (q) => q.copyWith(height: v.round())),
                        ),
                        _SliderRow(
                          titulo: 'Peso',
                          valor: p.weight > 0 ? p.weight.toDouble() : 70,
                          min: 40,
                          max: 150,
                          fracoes: 0,
                          rotulo: (v) => '${v.round()} kg',
                          onChanged: (v) =>
                              _set(context, (q) => q.copyWith(weight: v.round())),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Estilo & compras ────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: StaggerIn(
                  index: 4,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          eyebrow: 'A ASSINATURA',
                          title: 'Estilo & compras',
                          subtitle: 'até 3 estilos — a 1.ª domina as sugestões',
                        ),
                        _ChipGroup(
                          titulo: 'Estilos',
                          multi: true,
                          opcoes: const [
                            ('casual', 'Casual'),
                            ('streetwear', 'Streetwear'),
                            ('formal', 'Formal'),
                            ('minimalista', 'Minimalista'),
                            ('esportivo', 'Desportivo'),
                            ('elegante', 'Elegante'),
                            ('criativo', 'Criativo'),
                            ('romantico', 'Romântico'),
                          ],
                          selecionado: p.styles.isEmpty ? '' : p.styles.first,
                          selecionados: p.styles,
                          onSel: (_) {},
                          onSelMulti: (v) {
                            final List<String> nova = p.styles.contains(v)
                                ? p.styles.where((s) => s != v).toList()
                                : [...p.styles.take(2), v];
                            _set(context, (q) => q.copyWith(styles: nova));
                          },
                        ),
                        _ChipGroup(
                          titulo: 'Orçamento',
                          opcoes: const [
                            ('economico', 'Econômico \$'),
                            ('moderado', 'Moderado \$\$'),
                            ('premium', 'Premium \$\$\$'),
                            ('luxo', 'Luxo \$\$\$\$'),
                          ],
                          selecionado: p.budget,
                          onSel: (v) =>
                              _set(context, (q) => q.copyWith(budget: v)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Notas ───────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              sliver: SliverToBoxAdapter(
                child: StaggerIn(
                  index: 5,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeader(
                          eyebrow: 'AO TEU MODO',
                          title: 'Observações',
                          subtitle:
                              'alergias, o que evitas, o que sonhas — a IA lê isto',
                        ),
                        TextField(
                          controller: TextEditingController(text: p.notes)
                            ..selection = TextSelection.collapsed(
                              offset: p.notes.length,
                            ),
                          style: AuraType.body.copyWith(fontSize: 13),
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText:
                                'Ex.: alergia a fragrâncias; odeio gola alta…',
                          ),
                          onChanged: (v) =>
                              _set(context, (q) => q.copyWith(notes: v)),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: PlatinaButton(
                            label: 'Guardar e sair',
                            icon: Icons.check_rounded,
                            expanded: true,
                            onTap: () {
                              AuraSfx.I.success();
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  void _set(BuildContext context, Profile Function(Profile) updater) {
    AuraSfx.I.toggle();
    context.read<ProfileStore>().updateProfile(updater);
  }
}

// ── Peças da ficha ────────────────────────────────────────────────────────────

class _TextFieldRow extends StatelessWidget {
  const _TextFieldRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: AuraType.caption.copyWith(fontSize: 12)),
          ),
          Expanded(
            child: TextField(
              controller: TextEditingController(text: value)
                ..selection = TextSelection.collapsed(offset: value.length),
              style: AuraType.body.copyWith(fontSize: 13),
              decoration: InputDecoration(hintText: hint),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.titulo,
    required this.opcoes,
    this.onSel,
    this.selecionado = '',
    this.selecionados,
    this.onSelMulti,
    this.multi = false,
  });

  final String titulo;
  final List<(String, String)> opcoes;
  final String selecionado;
  final List<String>? selecionados;
  final ValueChanged<String>? onSel;
  final ValueChanged<String>? onSelMulti;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final ativos = selecionados ?? [selecionado];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: AuraType.caption.copyWith(fontSize: 11.5)),
          const SizedBox(height: 7),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final (id, rotulo) in opcoes)
                GestureDetector(
                  onTap: () => multi
                      ? (onSelMulti ?? onSel ?? (_) {})(id)
                      : (onSel ?? onSelMulti ?? (_) {})(id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: ativos.contains(id) && multi
                          ? AuraDecor.auraMetal
                          : null,
                      color: ativos.contains(id) && !multi
                          ? AuraColors.primary.withValues(alpha: 0.14)
                          : AuraColors.surface,
                      border: Border.all(
                        color: ativos.contains(id)
                            ? AuraColors.primary.withValues(alpha: 0.55)
                            : AuraColors.border,
                      ),
                    ),
                    child: Text(
                      rotulo,
                      style: AuraType.caption.copyWith(
                        fontSize: 11.5,
                        color: ativos.contains(id)
                            ? (multi
                                  ? AuraColors.onPrimary
                                  : AuraColors.primary)
                            : AuraColors.foreground.withValues(alpha: 0.85),
                        fontWeight: ativos.contains(id)
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.titulo,
    required this.valor,
    required this.min,
    required this.max,
    required this.fracoes,
    required this.rotulo,
    required this.onChanged,
  });

  final String titulo;
  final double valor;
  final double min;
  final double max;
  final int fracoes;
  final String Function(double) rotulo;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(titulo, style: AuraType.caption.copyWith(fontSize: 11.5)),
              const Spacer(),
              Text(
                rotulo(valor),
                style: AuraType.chip.copyWith(
                  fontSize: 11,
                  color: AuraColors.primary,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: valor.clamp(min, max),
              min: min,
              max: max,
              divisions: (max - min).round(),
              activeColor: AuraColors.primary,
              inactiveColor: AuraColors.border,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
