/// evento_screen.dart — PLANO DE EVENTO: crias o evento, a Aura traça o
/// plano semana a semana até ao dia. Contagem decrescente no topo, etapas
/// com tarefas a riscar, XP por tarefa e celebração no dia.
///
/// Estados: sem evento → criar (nome, tipo, data) → plano ativo.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/data/evento_store.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/stagger_in.dart';
import '../home/home_cards.dart' show MachinedChipXP;

class EventoScreen extends StatefulWidget {
  const EventoScreen({super.key});

  @override
  State<EventoScreen> createState() => _EventoScreenState();
}

class _EventoScreenState extends State<EventoScreen> {
  @override
  Widget build(BuildContext context) {
    final eStore = context.watch<EventoStore>();
    final evento = eStore.evento;

    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 380),
          child: eStore.gerando
              ? _gerandoView()
              : evento == null
                  ? _criarView(eStore)
                  : _planoView(evento),
        ),
      ),
    );
  }

  // ── Topo comum ─────────────────────────────────────────────────────────────
  Widget _topBar(String eyebrow) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
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
                child: const Icon(Icons.close, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Text(eyebrow, style: AuraType.eyebrow),
          ],
        ),
      );

  // ── 1 · Criar ──────────────────────────────────────────────────────────────
  Widget _criarView(EventoStore eStore) {
    return _CriarForm(
      key: const ValueKey('criar'),
      topBar: _topBar('PLANO DE EVENTO'),
      erro: eStore.erro,
      onCriar: (nome, tipo, data) async {
        final store = context.read<ProfileStore>();
        final criado = await eStore.criar(
          nome: nome,
          tipo: tipo,
          data: data,
          perfil: store.aiContext(),
        );
        if (criado != null && mounted) {
          AuraSfx.I.success();
          store.addXp(10);
          store.logEvent('evento_criado', {'tipo': tipo});
        }
      },
    );
  }

  // ── 2 · A gerar ────────────────────────────────────────────────────────────
  Widget _gerandoView() => Padding(
        key: const ValueKey('gerando'),
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Align(alignment: Alignment.centerLeft, child: _topBar('A TRAÇAR')),
            const Spacer(),
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AuraColors.primary.withValues(alpha: 0.4),
                ),
                boxShadow: AuraDecor.glowShadow(alpha: 0.25),
              ),
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              'A traçar o plano até o dia…',
              style: AuraType.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Pele, cabelo, roupa e acabamento — semana a semana, com o teu '
              'perfil na mão.',
              style: AuraType.caption.copyWith(height: 1.5),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
          ],
        ),
      );

  // ── 3 · Plano ativo ────────────────────────────────────────────────────────
  Widget _planoView(Evento evento) {
    final eStore = context.read<EventoStore>();
    final store = context.read<ProfileStore>();
    final dias = evento.diasRestantes;
    final etapaHoje = _etapaAtual(evento);

    return ListView(
      key: const ValueKey('plano'),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
      children: [
        _topBar('PLANO DE EVENTO'),
        const SizedBox(height: 22),
        // Contagem decrescente — o instrumento do prazo.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: StaggerIn(
            index: 0,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.event_outlined,
                        size: 15,
                        color: AuraColors.primary,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          evento.nome,
                          style: AuraType.cardTitle.copyWith(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      MachinedChipXP(
                        EventoStore.tipos[evento.tipo] ?? evento.tipo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$dias',
                        style: AuraType.machinedNumber.copyWith(
                          fontSize: 54,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          dias == 0 ? 'É HOJE' : 'dias restantes',
                          style: AuraType.caption.copyWith(fontSize: 13),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${evento.tarefasFeitas}/${evento.totalTarefas} '
                        'tarefas',
                        style: AuraType.caption.copyWith(
                          fontSize: 11,
                          color: AuraColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      color: AuraColors.surface,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: evento.progresso,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AuraDecor.auraMetal,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    evento.resumo,
                    style: AuraType.caption.copyWith(height: 1.5),
                  ),
                  if (evento.dicaChave.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 7, right: 9),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AuraColors.primary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            evento.dicaChave,
                            style: AuraType.caption.copyWith(
                              height: 1.5,
                              fontSize: 11.5,
                              color: AuraColors.primary.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: PlatinaButton(
                      label: 'Criar novo plano',
                      icon: Icons.restart_alt,
                      expanded: true,
                      onTap: () => _confirmarNovoPlano(eStore, store),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Etapas — semana a semana.
        for (var i = 0; i < evento.etapas.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: StaggerIn(
              index: i + 1,
              child: _EtapaCard(
                etapa: evento.etapas[i],
                atual: i == etapaHoje,
                indice: i,
                onTarefa: (t) => _alternarTarefa(evento, eStore, store, i, t),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            'fonte do plano: ${evento.fonte == 'groq' ? 'IA' : 'local'} · '
            'cada tarefa +8 XP · etapa completa +20 XP',
            style: AuraType.caption.copyWith(
              fontSize: 10.5,
              color: AuraColors.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Future<void> _alternarTarefa(
    Evento evento,
    EventoStore eStore,
    ProfileStore store,
    int etapa,
    int tarefa,
  ) async {
    final eraCompleta = evento.etapas[etapa].completa;
    final tarefaJaFeita = evento.etapas[etapa].feitas[tarefa];
    await eStore.alternarTarefa(etapa, tarefa);
    if (!tarefaJaFeita) {
      AuraSfx.I.complete();
      store.addXp(8);
    } else {
      AuraSfx.I.toggle();
    }
    // Etapa completa inteira (e não estava): acorde maior + bónus.
    if (!tarefaJaFeita && !eraCompleta) {
      final atual = eStore.evento;
      if (atual != null && atual.etapas[etapa].completa) {
        AuraSfx.I.success();
        store.addXp(20);
      }
    }
  }

  /// Índice da etapa ativa: a 1ª não completa; todas completas = última.
  int _etapaAtual(Evento evento) {
    for (var i = 0; i < evento.etapas.length; i++) {
      if (!evento.etapas[i].completa) return i;
    }
    return evento.etapas.isEmpty ? 0 : evento.etapas.length - 1;
  }

  Future<void> _confirmarNovoPlano(
    EventoStore eStore,
    ProfileStore store,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.cardFill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AuraColors.border),
        ),
        title: Text(
          'Criar novo plano?',
          style: AuraType.cardTitle.copyWith(fontSize: 16),
        ),
        content: Text(
          'O plano atual e o seu progresso são substituídos. O XP já ganho '
          'fica intacto.',
          style: AuraType.caption.copyWith(height: 1.5, fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancelar',
              style: AuraType.body.copyWith(fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Substituir',
              style: AuraType.body.copyWith(
                fontSize: 13,
                color: AuraColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      AuraSfx.I.tap();
      await eStore.cancelar();
      store.logEvent('evento_novo_plano');
    }
  }
}

// ── Formulário de criação ─────────────────────────────────────────────────────
class _CriarForm extends StatefulWidget {
  const _CriarForm({
    super.key,
    required this.onCriar,
    this.erro,
    required this.topBar,
  });

  final Widget topBar;
  final String? erro;
  final Future<void> Function(String nome, String tipo, DateTime data) onCriar;

  @override
  State<_CriarForm> createState() => _CriarFormState();
}

class _CriarFormState extends State<_CriarForm> {
  final _nomeCtrl = TextEditingController();
  String _tipo = 'festa';
  DateTime _data = DateTime.now().add(const Duration(days: 21));

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AuraColors.primary,
            surface: AuraColors.cardFill,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _data = d);
  }

  void _submeter() {
    AuraSfx.I.send();
    widget.onCriar(_nomeCtrl.text, _tipo, _data);
  }

  @override
  Widget build(BuildContext context) {
    final dias = _data.difference(DateTime.now()).inDays;
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 40),
      children: [
        widget.topBar,
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Há um dia marcado?\nA Aura prepara-te para ele.',
                style: AuraType.sectionTitle.copyWith(
                  fontSize: 26,
                  height: 1.14,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Diz-nos o evento e a data. O plano chega semana a semana — '
                'pele, cabelo, roupa e acabamento, com o teu perfil na mão.',
                style: AuraType.caption.copyWith(height: 1.5),
              ),
              const SizedBox(height: 22),
              Text('NOME DO EVENTO', style: AuraType.eyebrow),
              const SizedBox(height: 8),
              TextField(
                controller: _nomeCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: AuraType.body.copyWith(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Casamento da Ana, entrevista na Nkosi…',
                  hintStyle: AuraType.caption.copyWith(
                    fontSize: 13,
                    color: AuraColors.mutedForeground,
                  ),
                  filled: true,
                  fillColor: AuraColors.cardFill,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AuraColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: AuraColors.primary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('TIPO', style: AuraType.eyebrow),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in EventoStore.tipos.entries)
                    GestureDetector(
                      onTap: () {
                        AuraSfx.I.toggle();
                        setState(() => _tipo = entry.key);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient:
                              _tipo == entry.key ? AuraDecor.auraMetal : null,
                          color: _tipo == entry.key ? null : AuraColors.cardFill,
                          border: Border.all(
                            color: _tipo == entry.key
                                ? Colors.transparent
                                : AuraColors.border,
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: AuraType.body.copyWith(
                            fontSize: 12.5,
                            fontWeight: _tipo == entry.key
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _tipo == entry.key
                                ? AuraColors.onPrimary
                                : AuraColors.foreground,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text('DATA', style: AuraType.eyebrow),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _escolherData,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AuraColors.cardFill,
                    border: Border.all(color: AuraColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: AuraColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_data.day}/${_data.month}/${_data.year}',
                        style: AuraType.body.copyWith(fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        'daqui a $dias dias',
                        style: AuraType.caption.copyWith(
                          fontSize: 11.5,
                          color: AuraColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.erro != null) ...[
                const SizedBox(height: 12),
                Text(
                  widget.erro!,
                  style: AuraType.caption.copyWith(
                    fontSize: 12,
                    color: Colors.redAccent,
                  ),
                ),
              ],
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: PlatinaButton(
                  label: 'Traçar o plano',
                  icon: Icons.route_outlined,
                  expanded: true,
                  onTap: _submeter,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cartão de etapa ───────────────────────────────────────────────────────────
class _EtapaCard extends StatelessWidget {
  const _EtapaCard({
    required this.etapa,
    required this.atual,
    required this.indice,
    required this.onTarefa,
  });

  final EtapaEvento etapa;
  final bool atual;
  final int indice;
  final void Function(int tarefa) onTarefa;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (atual) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AuraDecor.auraMetal,
                    boxShadow: AuraDecor.glowShadow(alpha: 0.35),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  etapa.titulo,
                  style: AuraType.cardTitle.copyWith(
                    fontSize: 14,
                    color: etapa.completa
                        ? AuraColors.mutedForeground
                        : AuraColors.foreground,
                  ),
                ),
              ),
              if (etapa.completa)
                Icon(Icons.check_circle, size: 16, color: AuraColors.primary)
              else if (atual)
                const MachinedChipXP('AGORA'),
            ],
          ),
          if (etapa.foco.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              etapa.foco,
              style: AuraType.caption.copyWith(
                height: 1.5,
                fontSize: 12,
                color: AuraColors.mutedForeground,
              ),
            ),
          ],
          const SizedBox(height: 10),
          for (var t = 0; t < etapa.total; t++)
            _TarefaRow(
              texto: etapa.tarefas[t],
              feita: etapa.feitas[t],
              onTap: () => onTarefa(t),
            ),
        ],
      ),
    );
  }
}

class _TarefaRow extends StatelessWidget {
  const _TarefaRow({
    required this.texto,
    required this.feita,
    required this.onTap,
  });

  final String texto;
  final bool feita;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutBack,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: feita ? AuraDecor.auraMetal : null,
                color: feita ? null : AuraColors.surface,
                border: feita ? null : Border.all(color: AuraColors.border),
                boxShadow: feita ? AuraDecor.glowShadow(alpha: 0.3) : null,
              ),
              child: feita
                  ? Icon(Icons.check, size: 13, color: AuraColors.onPrimary)
                  : null,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                style: AuraType.body.copyWith(
                  fontSize: 13,
                  height: 1.4,
                  color:
                      feita ? AuraColors.mutedForeground : AuraColors.foreground,
                  decoration: feita ? TextDecoration.lineThrough : null,
                  decorationColor: AuraColors.mutedForeground,
                ),
                child: Text(texto),
              ),
            ),
            Text(
              '+8',
              style: AuraType.chip.copyWith(
                fontSize: 9,
                color:
                    feita ? AuraColors.primary : AuraColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
