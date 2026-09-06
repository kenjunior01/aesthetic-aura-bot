/// jornada_screen.dart — a JORNADA DO AUGE: rota completa da evolução.
///
///  • Barra de chegada (CustomPainter) com as fases e a bandeira do auge
///  • Período estimado: quando SENTIR efeitos, quando VER mudanças
///  • Pontos de controlo: partilhas uma foto, a IA diz se o plano anda
///  • Fases com imagem REAL que se assemelha ao teu momento na rota
///  • Revisão: o plano e o período recalculam-se com os teus check-ins
library;

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/api/image_bank.dart';
import '../../core/api/visual_api.dart';
import '../../core/data/jornada_store.dart';
import '../../core/sfx/aura_sfx.dart';
import '../../core/store/profile_store.dart';
import '../../core/theme/aura_colors.dart';
import '../../core/theme/aura_decorations.dart';
import '../../core/theme/aura_typography.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/orbita_aura.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/shimmer_box.dart';
import '../../core/widgets/stagger_in.dart';
import 'barra_chegada.dart';

class JornadaScreen extends StatefulWidget {
  const JornadaScreen({super.key});

  @override
  State<JornadaScreen> createState() => _JornadaScreenState();
}

class _JornadaScreenState extends State<JornadaScreen> {
  bool _avaliando = false;

  ProfileStore get _store => context.read<ProfileStore>();

  Map<String, dynamic> _perfilCompleto() {
    final p = _store.profile;
    return {
      'name': p.name,
      'gender': p.gender,
      'age': p.age,
      'city': p.city,
      'country': p.country,
      'faceShape': p.faceShape,
      'skinTone': p.skinTone,
      'undertone': p.undertone,
      'eyeColor': p.eyeColor,
      'hairType': p.hairType,
      'hairColor': p.hairColor,
      'hairLength': p.hairLength,
      'bodyType': p.bodyType,
      'height': p.height,
      'weight': p.weight,
      'styles': p.styles,
      'colors': p.colors,
      'priorities': p.priorities,
      'budget': p.budget,
      'profession': p.profession,
      'climate': p.climate,
      'notes': p.notes,
    };
  }

  Future<void> _tracar() async {
    AuraSfx.I.toggle();
    final jStore = context.read<JornadaStore>();
    final j = await jStore.criarJornada(_perfilCompleto());
    if (!mounted) return;
    if (j != null) {
      _store.addXp(30);
      _store.logEvent('jornada_criada', {'fonte': j.fonte, 'semanas': j.totalSemanas});
      AuraSfx.I.sparkle();
    }
  }

  // ── Fluxo do check-in ─────────────────────────────────────────────────────
  Future<void> _abrirCheckin() async {
    AuraSfx.I.tap();
    final fonte = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _FolhaFonte(),
    );
    if (fonte == null || !mounted) return;
    XFile? foto;
    try {
      foto = await ImagePicker().pickImage(
        source: fonte == 'camera' ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 84,
        preferredCameraDevice: CameraDevice.front,
      );
    } catch (_) {
      return;
    }
    if (foto == null || !mounted) return;
    AuraSfx.I.camera();

    setState(() => _avaliando = true);
    final jStore = context.read<JornadaStore>();
    final thumb = await _miniatura(foto);
    String? base64Foto;
    try {
      final bytes = await File(foto.path).readAsBytes();
      base64Foto = base64Encode(bytes);
    } catch (_) {
      base64Foto = null;
    }
    CheckinJornada? c;
    if (base64Foto != null) {
      c = await jStore.registarCheckin(
        perfil: _perfilCompleto(),
        imageBase64: base64Foto,
        fotoThumb: thumb,
      );
    }
    if (!mounted) return;
    setState(() => _avaliando = false);
    if (c != null) {
      _store.addXp(40);
      _store.logEvent('jornada_checkin', {
        'semana': c.semana,
        'aderencia': c.aderencia,
        'veredito': c.veredito,
      });
      AuraSfx.I.success();
    } else {
      AuraSfx.I.tap();
    }
  }

  /// Miniatura pequena da foto (PNG, largura 128) — para a timeline.
  Future<String?> _miniatura(XFile foto) async {
    try {
      final bytes = await foto.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: 128,
        allowUpscaling: false,
      );
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      frame.image.dispose();
      codec.dispose();
      if (data == null) return null;
      return base64Encode(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<void> _revisar() async {
    AuraSfx.I.toggle();
    final jStore = context.read<JornadaStore>();
    final nova = await jStore.revisarJornada(_perfilCompleto());
    if (!mounted) return;
    if (nova != null) {
      _store.logEvent('jornada_revisada', {'versao': nova.versao});
      AuraSfx.I.sparkle();
    }
  }

  void _confirmarLimpar() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AuraColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AuraDecor.radius),
          side: BorderSide(color: AuraColors.border),
        ),
        title: Text(
          'Recomeçar a jornada?',
          style: AuraType.cardTitle.copyWith(fontSize: 16),
        ),
        content: Text(
          'A rota, os check-ins e o histórico apagam-se. Os scans ficam no '
          'diário.',
          style: AuraType.caption.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'MANTER',
              style: AuraType.chip.copyWith(color: AuraColors.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<JornadaStore>().limpar();
              AuraSfx.I.tap();
            },
            child: Text(
              'APAGAR',
              style: AuraType.chip.copyWith(color: AuraColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final jStore = context.watch<JornadaStore>();
    final jornada = jStore.jornada;

    return Scaffold(
      backgroundColor: AuraColors.background.withValues(alpha: 0.98),
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                    child: _topBar(jornada),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (jornada == null) ...[
                        if (jStore.gerando) _gerando() else _vazia(),
                      ] else ...[
                        _hero(jornada, jStore),
                        const SizedBox(height: 14),
                        _checkin(jornada, jStore),
                        const SizedBox(height: 22),
                        SectionHeader(
                          eyebrow: 'A rota',
                          title: 'As fases até o auge',
                          subtitle: jornada.versao > 1
                              ? 'Revista na semana ${semanaDeData(jornada.atualizada, jStore)} — versão ${jornada.versao}'
                              : 'Traçada para o teu perfil real',
                        ),
                        ..._fases(jornada, jStore),
                        if (jornada.checkins.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _historico(jornada),
                        ],
                        const SizedBox(height: 20),
                        _rodape(),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
            if (_avaliando || (jStore.gerando && jornada != null)) _overlay(),
          ],
        ),
      ),
    );
  }

  Widget _overlay() => Positioned.fill(
    child: Container(
      color: AuraColors.backgroundDeep.withValues(alpha: 0.82),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const OrbitaAura(tamanho: 74),
          const SizedBox(height: 18),
          Text(
            _avaliando ? 'A LER O TEU MOMENTO' : 'A ATUALIZAR A ROTA',
            style: AuraType.eyebrow,
          ),
          const SizedBox(height: 8),
          Text(
            _avaliando
                ? 'A comparar com a semana que estava prevista…'
                : 'A recalcular fases e períodos com os teus check-ins…',
            textAlign: TextAlign.center,
            style: AuraType.caption.copyWith(height: 1.5),
          ),
        ],
      ),
    ),
  );

  Widget _topBar(Jornada? jornada) => Row(
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
      Column(
        children: [
          Text('JORNADA DO AUGE', style: AuraType.eyebrow),
          if (jornada != null)
            Text(
              jornada.fonte == 'groq' ? 'rota da IA' : 'rota local',
              style: AuraType.caption.copyWith(fontSize: 9.5),
            ),
        ],
      ),
      const Spacer(),
      const SizedBox(width: 40),
    ],
  );

  // ── Vazio / gerando ───────────────────────────────────────────────────────
  Widget _vazia() => StaggerIn(
    index: 0,
    child: GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuraDecor.auraMetal,
                  boxShadow: AuraDecor.glowShadow(alpha: 0.3),
                ),
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AuraColors.backgroundDeep,
                  ),
                  child: Icon(
                    Icons.route_outlined,
                    size: 20,
                    color: AuraColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'A tua rota até o auge começa aqui',
                  style: AuraType.sectionTitle.copyWith(fontSize: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A Aura lê tudo o que deste à plataforma — pele, cabelo, corpo, '
            'rotina, prioridades — e traça a jornada realista: em quantas '
            'semanas sentes os primeiros efeitos, quando as mudanças ficam '
            'visíveis e as fases até o teu auge. Depois, em cada ponto de '
            'controlo, partilhas uma foto e a rota ajusta-se ao teu ritmo '
            'verdadeiro.',
            style: AuraType.caption.copyWith(height: 1.55, fontSize: 12.5),
          ),
          const SizedBox(height: 16),
          PlatinaButton(
            label: 'Traçar a minha jornada',
            icon: Icons.auto_awesome,
            expanded: true,
            onTap: _tracar,
          ),
        ],
      ),
    ),
  );

  Widget _gerando() => GlassCard(
    child: Column(
      children: [
        const SizedBox(height: 10),
        const OrbitaAura(tamanho: 84),
        const SizedBox(height: 22),
        Text('A TRAÇAR A TUA ROTA', style: AuraType.eyebrow),
        const SizedBox(height: 10),
        Text(
          'A ler o teu perfil… a calcular ritmos de pele e cabelo…\n'
          'a escolher as imagens que se parecem contigo.',
        textAlign: TextAlign.center,
        style: AuraType.caption.copyWith(height: 1.55),
        ),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: ShimmerBox(width: double.infinity, height: 8),
        ),
        const SizedBox(height: 10),
      ],
    ),
  );

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _hero(Jornada j, JornadaStore jStore) {
    final semana = jStore.semanaAtual;
    final total = j.totalSemanas <= 1 ? 1 : j.totalSemanas;
    final nos = [
      for (final f in j.fases.skip(1)) (f.semanaInicio - 1) / total,
    ];
    return StaggerIn(
      index: 0,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BarraChegada(
              progresso: jStore.progresso,
              totalSemanas: j.totalSemanas,
              nos: nos,
              semanaAtual: semana,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _marco('SENTIR', j.efeitosSemanas, 'sem'),
                _fioVertical(),
                _marco('VER', j.mudancasSemanas, 'sem'),
                _fioVertical(),
                _marco('AUGE', j.totalSemanas, 'sem'),
              ],
            ),
            if (j.resumo.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(j.resumo, style: AuraType.body.copyWith(height: 1.5)),
            ],
            if (j.dicaChave.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AuraColors.primary.withValues(alpha: 0.08),
                  border: Border.all(
                    color: AuraColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.key_outlined,
                      size: 15,
                      color: AuraColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        j.dicaChave,
                        style: AuraType.caption.copyWith(
                          fontSize: 12,
                          height: 1.4,
                          color: AuraColors.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _marco(String label, int semanas, String unidade) => Expanded(
    child: Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$semanas',
                style: AuraType.machinedNumber.copyWith(fontSize: 26),
              ),
              TextSpan(
                text: ' $unidade',
                style: AuraType.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AuraType.eyebrow.copyWith(fontSize: 7.5, letterSpacing: 1.6),
        ),
      ],
    ),
  );

  Widget _fioVertical() => Container(
    width: 1,
    height: 30,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    color: AuraColors.border,
  );

  // ── Check-in ──────────────────────────────────────────────────────────────
  Widget _checkin(Jornada j, JornadaStore jStore) {
    final ultimo = j.checkins.isNotEmpty ? j.checkins.first : null;
    final due = jStore.checkinDue;
    final dias = jStore.diasParaCheckin;

    return StaggerIn(
      index: 1,
      child: GlassCard(
        onTap: null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('PONTO DE CONTROLO', style: AuraType.eyebrow),
                const Spacer(),
                if (due)
                  _chipEstado('a tempo', destaque: true)
                else
                  _chipEstado('em ${dias > 0 ? dias : 0} dias'),
              ],
            ),
            const SizedBox(height: 10),
            if (ultimo != null) ..._resultado(ultimo, jStore),
            const SizedBox(height: 8),
            Text(
              due
                  ? 'Chegou a hora de confirmar: partilha uma foto de como '
                      'estás e a Aura compara com o que estava previsto '
                      'nesta semana.'
                  : 'O próximo registo de foto abre em ${dias > 0 ? dias : 0} '
                      'dias — alinhado com o período em que as mudanças '
                      'começam a aparecer.',
              style: AuraType.caption.copyWith(height: 1.5, fontSize: 12.5),
            ),
            const SizedBox(height: 14),
            PlatinaButton(
              label: due
                  ? 'Partilhar como estou'
                  : 'Partilhar foto antecipada',
              icon: Icons.camera_alt_outlined,
              expanded: true,
              onTap: _avaliando ? null : _abrirCheckin,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _resultado(CheckinJornada c, JornadaStore jStore) => [
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AuraColors.surface,
        border: Border.all(color: AuraColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _AderenciaRing(valor: c.aderencia, noTrilho: c.noTrilho),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semana ${c.semana} · ${_dataBonita(c.data)}',
                  style: AuraType.cardTitle.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 4),
                Text(
                  c.mensagem,
                  style: AuraType.caption.copyWith(height: 1.45, fontSize: 11.5),
                ),
              ],
            ),
          ),
          if (c.fotoThumb != null) ...[
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                base64Decode(c.fotoThumb!),
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          ],
        ],
      ),
    ),
    if (c.mudancas.isNotEmpty) ...[
      const SizedBox(height: 10),
      _listaSimples('JÁ SE NOTA', c.mudancas, Icons.wb_sunny_outlined),
    ],
    if (c.ajustes.isNotEmpty) ...[
      const SizedBox(height: 8),
      _listaSimples('AFINAR', c.ajustes, Icons.tune),
    ],
  ];

  Widget _listaSimples(String titulo, List<String> items, IconData icon) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AuraColors.primary),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: AuraType.eyebrow.copyWith(
                  fontSize: 7.5,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                '· $item',
                style: AuraType.caption.copyWith(fontSize: 11.5, height: 1.4),
              ),
            ),
        ],
      );

  Widget _chipEstado(String texto, {bool destaque = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: destaque ? AuraDecor.auraMetal : null,
      color: destaque ? null : AuraColors.surface,
      border: destaque ? null : Border.all(color: AuraColors.border),
    ),
    child: Text(
      texto,
      style: AuraType.chip.copyWith(
        fontSize: 9,
        letterSpacing: 0.6,
        color: destaque
            ? AuraColors.onPrimary
            : AuraColors.mutedForeground,
      ),
    ),
  );

  // ── Fases ─────────────────────────────────────────────────────────────────
  List<Widget> _fases(Jornada j, JornadaStore jStore) {
    final semana = jStore.semanaAtual;
    final out = <Widget>[];
    for (final (i, f) in j.fases.indexed) {
      final estado = semana >= f.semanaFim
          ? _EstadoFase.vivida
          : (semana >= f.semanaInicio ? _EstadoFase.atual : _EstadoFase.futura);
      out.add(
        StaggerIn(
          index: i + 2,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FaseCard(
              fase: f,
              estado: estado,
              indice: i,
              onImagem: (url) => jStore.guardarImagemFase(i, url),
            ),
          ),
        ),
      );
    }
    return out;
  }

  // ── Histórico ─────────────────────────────────────────────────────────────
  Widget _historico(Jornada j) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionHeader(
        eyebrow: 'Memória',
        title: 'Os teus pontos de controlo',
      ),
      for (final (i, c) in j.checkins.indexed)
        StaggerIn(
          index: i,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              onTap: null,
              child: Row(
                children: [
                  if (c.fotoThumb != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(c.fotoThumb!),
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Semana ${c.semana} · ${_dataBonita(c.data)}',
                          style: AuraType.cardTitle.copyWith(fontSize: 12),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${c.noTrilho ? 'no trilho' : 'a ajustar'} · '
                          'aderência ${c.aderencia}%'
                          '${c.revisouPlano ? ' · plano revisto' : ''}',
                          style: AuraType.caption.copyWith(fontSize: 10.5),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    c.noTrilho
                        ? Icons.check_circle_outline
                        : Icons.tune,
                    size: 16,
                    color: c.noTrilho
                        ? AuraColors.primary
                        : AuraColors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  // ── Rodapé ────────────────────────────────────────────────────────────────
  Widget _rodape() => Column(
    children: [
      GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.radar, size: 16, color: AuraColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'A vida atrasa a rota? Revê o plano com base nos teus '
                'check-ins — as fases e o período recalculam-se.',
                style: AuraType.caption.copyWith(fontSize: 11.5, height: 1.45),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _revisar,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AuraColors.surface,
                  border: Border.all(
                    color: AuraColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, size: 15, color: AuraColors.primary),
                    const SizedBox(width: 7),
                    Text(
                      'REVISAR A ROTA',
                      style: AuraType.chip.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        color: AuraColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: _confirmarLimpar,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AuraColors.surface,
                  border: Border.all(color: AuraColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 15,
                      color: AuraColors.mutedForeground,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'RECOMEÇAR',
                      style: AuraType.chip.copyWith(
                        fontSize: 10,
                        letterSpacing: 1.4,
                        color: AuraColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );

  String _dataBonita(String iso) {
    final meses = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
    ];
    final p = iso.split('-');
    if (p.length < 3) return iso;
    return '${p[2]} ${meses[(int.tryParse(p[1]) ?? 1) - 1]}';
  }

  int semanaDeData(String iso, JornadaStore jStore) {
    final inicio = jStore.jornada?.criada ?? '';
    final d0 = DateTime.tryParse(inicio);
    final d1 = DateTime.tryParse(iso);
    if (d0 == null || d1 == null) return 0;
    return (d1.difference(d0).inDays ~/ 7) + 1;
  }
}

enum _EstadoFase { vivida, atual, futura }

// ── Cartão de fase com imagem real ──────────────────────────────────────────
class _FaseCard extends StatefulWidget {
  const _FaseCard({
    required this.fase,
    required this.estado,
    required this.indice,
    required this.onImagem,
  });

  final FaseJornada fase;
  final _EstadoFase estado;
  final int indice;
  final ValueChanged<String> onImagem;

  @override
  State<_FaseCard> createState() => _FaseCardState();
}

class _FaseCardState extends State<_FaseCard> {
  VisualItem? _imagem;
  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    if (widget.fase.imagemUrl != null) {
      _imagem = VisualItem(
        id: 'cache',
        url: widget.fase.imagemUrl!,
        thumb: widget.fase.imagemUrl!,
        alt: widget.fase.titulo,
        autor: '',
      );
    } else {
      _buscar();
    }
  }

  Future<void> _buscar() async {
    if (_buscando || !mounted) return;
    _buscando = true;
    try {
      final r = await BancoImagens.I.buscar(
        widget.fase.imagemQuery,
        count: 3,
      );
      if (!mounted) return;
      if (r.items.isNotEmpty) {
        setState(() => _imagem = r.items.first);
        widget.onImagem(r.items.first.thumb);
      }
    } catch (_) {
      // Sem imagem agora — fica o placeholder elegante.
    } finally {
      _buscando = false;
    }
  }

  String get _estadoLabel => switch (widget.estado) {
    _EstadoFase.vivida => 'vivida',
    _EstadoFase.atual => 'agora',
    _EstadoFase.futura => 'a caminho',
  };

  @override
  Widget build(BuildContext context) {
    final f = widget.fase;
    final atual = widget.estado == _EstadoFase.atual;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AuraDecor.radius),
        gradient: AuraDecor.softGlass,
        color: AuraColors.cardFill.withValues(alpha: 0.55),
        border: Border.all(
          color: atual
              ? AuraColors.primary.withValues(alpha: 0.5)
              : AuraColors.border,
          width: atual ? 1.2 : 1,
        ),
        boxShadow: atual
            ? AuraDecor.glowShadow(alpha: 0.12)
            : AuraDecor.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem real da fase (ou placeholder usinado).
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AuraDecor.radius - 0.5),
            ),
            child: SizedBox(
              height: 150,
              width: double.infinity,
              child: _imagem != null
                  ? Image.network(
                      _imagem!.thumb,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, prog) =>
                          prog != null && prog.expectedTotalBytes != null
                              ? ShimmerBox(
                                  width: double.infinity, height: 150)
                              : child,
                      errorBuilder: (c, e, s) => _placeholderImagem(),
                    )
                  : _placeholderImagem(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'FASE ${widget.indice + 1} · ${f.nome.toUpperCase()}',
                      style: AuraType.eyebrow.copyWith(
                        fontSize: 7.5,
                        letterSpacing: 1.7,
                        color: atual
                            ? AuraColors.primary
                            : AuraColors.mutedForeground,
                      ),
                    ),
                    const Spacer(),
                    if (atual)
                      _seloAtual()
                    else
                      Text(
                        _estadoLabel,
                        style: AuraType.caption.copyWith(fontSize: 10),
                      ),
                  ],
                ),
                if (f.titulo.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(f.titulo, style: AuraType.cardTitle.copyWith(fontSize: 15)),
                ],
                const SizedBox(height: 4),
                Text(
                  'Semana ${f.semanaInicio} – ${f.semanaFim}',
                  style: AuraType.caption.copyWith(fontSize: 10.5),
                ),
                if (f.foco.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    f.foco,
                    style: AuraType.caption.copyWith(height: 1.5, fontSize: 12),
                  ),
                ],
                if (f.acoes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final a in f.acoes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Icon(
                              widget.estado == _EstadoFase.futura
                                  ? Icons.circle_outlined
                                  : Icons.check_circle_outline,
                              size: 11,
                              color: AuraColors.primary.withValues(
                                alpha: widget.estado == _EstadoFase.futura
                                    ? 0.55
                                    : 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a,
                              style: AuraType.caption.copyWith(
                                fontSize: 11.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                if (f.visivel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: AuraColors.primary.withValues(alpha: 0.07),
                      border: Border.all(
                        color: AuraColors.primary.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 13,
                          color: AuraColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f.visivel,
                            style: AuraType.caption.copyWith(
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImagem() => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AuraColors.secondary,
          AuraColors.backgroundDeep,
        ],
      ),
    ),
    alignment: Alignment.center,
    child: Icon(
      Icons.portrait_outlined,
      size: 34,
      color: AuraColors.mutedForeground,
    ),
  );

  Widget _seloAtual() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: AuraDecor.auraMetal,
      boxShadow: AuraDecor.glowShadow(alpha: 0.25),
    ),
    child: Text(
      'AGORA',
      style: AuraType.chip.copyWith(
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: AuraColors.onPrimary,
      ),
    ),
  );
}

// ── Anel de aderência ───────────────────────────────────────────────────────
class _AderenciaRing extends StatelessWidget {
  const _AderenciaRing({required this.valor, required this.noTrilho});

  final int valor;
  final bool noTrilho;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: valor / 100),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => CustomPaint(
        size: const Size(54, 54),
        painter: _AderenciaPainter(
          valor: v,
          cor: noTrilho ? AuraColors.primary : AuraColors.chartWarm,
        ),
        child: Center(
          child: Text(
            '$valor',
            style: AuraType.machinedNumber.copyWith(fontSize: 15),
          ),
        ),
      ),
    );
  }
}

class _AderenciaPainter extends CustomPainter {
  _AderenciaPainter({required this.valor, required this.cor});

  final double valor;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final raio = size.width / 2 - 4;
    final rect = Rect.fromCircle(center: centro, radius: raio);
    canvas.drawArc(
      rect,
      0,
      2 * 3.141592653589793,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = AuraColors.surfaceStrong,
    );
    canvas.drawArc(
      rect,
      -1.5707963267948966,
      2 * 3.141592653589793 * valor.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = cor,
    );
  }

  @override
  bool shouldRepaint(covariant _AderenciaPainter old) => old.valor != valor;
}

// ── Folha de fonte da foto ──────────────────────────────────────────────────
class _FolhaFonte extends StatelessWidget {
  const _FolhaFonte();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AuraColors.card,
        border: Border.all(color: AuraColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text('DE ONDE VEM A FOTO?', style: AuraType.eyebrow),
          const SizedBox(height: 6),
          ListTile(
            leading: Icon(
              Icons.camera_alt_outlined,
              color: AuraColors.primary,
              size: 20,
            ),
            title: Text(
              'Câmara — agora',
              style: AuraType.body.copyWith(fontSize: 14),
            ),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: Icon(
              Icons.photo_library_outlined,
              color: AuraColors.primary,
              size: 20,
            ),
            title: Text(
              'Galeria',
              style: AuraType.body.copyWith(fontSize: 14),
            ),
            onTap: () => Navigator.pop(context, 'galeria'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
