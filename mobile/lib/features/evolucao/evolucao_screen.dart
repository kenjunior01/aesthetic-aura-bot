/// evolucao_screen.dart — o Diário de Evolução: linha do tempo vertical da
/// tua aura. Cada scan fica com data, miniatura da foto e leituras; as
/// diferenças com a entrada anterior aparecem à direita (o que mudou).
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/diario_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stagger_in.dart';
import '../scan/scan_screen.dart';

class EvolucaoScreen extends StatefulWidget {
  const EvolucaoScreen({super.key});

  @override
  State<EvolucaoScreen> createState() => _EvolucaoScreenState();
}

class _EvolucaoScreenState extends State<EvolucaoScreen> {
  @override
  Widget build(BuildContext context) {
    final diario = context.watch<DiarioStore>();
    final entradas = diario.entradas;

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
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (entradas.isEmpty)
                    _vazia()
                  else
                    ..._timeline(entradas),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
      Text('DIÁRIO DE EVOLUÇÃO', style: AuraType.eyebrow),
      const Spacer(),
      const SizedBox(width: 40),
    ],
  );

  Widget _vazia() => StaggerIn(
    index: 0,
    child: GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A tua linha do tempo começa aqui', style: AuraType.sectionTitle),
          const SizedBox(height: 8),
          Text(
            'Cada scan de aura fica guardado com data, foto e leituras. '
            'Daqui a um mês comparas: o que mudou no tom, no rosto, no '
            'cabelo. Evolução que se vê.',
            style: AuraType.caption.copyWith(height: 1.5),
          ),
          const SizedBox(height: 14),
          PlatinaButton(
            label: 'Fazer o primeiro scan',
            icon: Icons.center_focus_strong,
            expanded: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ScanScreen()),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _timeline(List<EntradaDiario> entradas) {
    final out = <Widget>[];
    for (final (i, e) in entradas.indexed) {
      final anterior = i + 1 < entradas.length ? entradas[i + 1] : null;
      out.add(
        StaggerIn(
          index: i,
          child: _entrada(e, anterior, primeiro: i == 0),
        ),
      );
      if (i < entradas.length - 1) out.add(_ponte());
    }
    out.add(const SizedBox(height: 8));
    out.add(
      StaggerIn(
        index: entradas.length,
        child: Text(
          'guardado no aparelho · máximo 12 registos',
          style: AuraType.caption.copyWith(fontSize: 10),
        ),
      ),
    );
    return out;
  }

  /// A linha vertical que liga as entradas.
  Widget _ponte() => Padding(
    padding: const EdgeInsets.only(left: 21),
    child: Container(width: 1.5, height: 18, color: AuraColors.border),
  );

  Widget _entrada(EntradaDiario e, EntradaDiario? anterior, {required bool primeiro}) {
    final delta = _deltas(e, anterior);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: primeiro ? AuraDecor.auraMetal : null,
                    color: primeiro ? null : AuraColors.muted,
                    border: Border.all(
                      color: primeiro
                          ? Colors.transparent
                          : AuraColors.border,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _dataBonita(e.data),
                        style: AuraType.cardTitle.copyWith(fontSize: 13.5),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: e.fonte == 'ai'
                              ? AuraColors.primary.withValues(alpha: 0.14)
                              : AuraColors.muted,
                        ),
                        child: Text(
                          e.fonte == 'ai' ? 'IA' : 'local',
                          style: AuraType.chip.copyWith(
                            fontSize: 8,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context
                            .read<DiarioStore>()
                            .remover(e.id),
                        child: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AuraColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (e.thumb != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(e.thumb!),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(child: _leituras(e, delta)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _leituras(EntradaDiario e, List<(String, String?)> delta) {
    String? difTom;
    for (final d in delta) {
      if (d.$1 == 'TOM') difTom = d.$2;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (e.faceShape.isNotEmpty) _chipLeitura('ROSTO', e.faceShape, null),
        if (e.skinTone > 0) _chipLeitura('TOM', '${e.skinTone}/10', difTom),
        if (e.undertone.isNotEmpty) _chipLeitura('SUBTOM', e.undertone, null),
        if (e.hairColor.isNotEmpty) _chipLeitura('CABELO', e.hairColor, null),
      ],
    );
  }

  Widget _chipLeitura(String label, String valor, String? dif) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(
            label,
            style: AuraType.eyebrow.copyWith(fontSize: 7.5, letterSpacing: 1.6),
          ),
        ),
        Text(
          valor,
          style: AuraType.body.copyWith(fontSize: 12.5),
        ),
        if (dif != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: AuraColors.primary.withValues(alpha: 0.12),
            ),
            child: Text(
              dif,
              style: AuraType.chip.copyWith(fontSize: 9, letterSpacing: 0.4),
            ),
          ),
        ],
      ],
    ),
  );

  /// Diferenças para a entrada anterior (mais antiga).
  List<(String, String?)> _deltas(EntradaDiario e, EntradaDiario? anterior) {
    if (anterior == null) return const [];
    final out = <(String, String?)>[];
    if (anterior.skinTone > 0 && e.skinTone > 0) {
      final d = e.skinTone - anterior.skinTone;
      if (d != 0) out.add(('TOM', d > 0 ? '+$d' : '$d'));
    }
    return out;
  }

  String _dataBonita(String iso) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    final p = iso.split('-');
    if (p.length < 3) return iso;
    return '${p[2]} ${meses[(int.tryParse(p[1]) ?? 1) - 1]} ${p[0]}';
  }
}
