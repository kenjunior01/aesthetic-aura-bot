/// cromatica.dart — motor de análise cromática pessoal (estações do ano).
///
/// Regras determinísticas 100% offline: subtom + profundidade de pele +
/// profundidade de cabelo → uma de 10 estações. Cada estação traz paleta de
/// cores que vestem, neutros, cores a evitar, metal (ouro/prata), combinações
/// de roupa prontas e consultas de fotos reais (Pexels/Unsplash).
///
/// Sem rede, sem IA, sem custo — o teu tom manda.
library;

import '../store/profile_store.dart';

class Swatch {
  const Swatch(this.nome, this.hex);

  /// Nome humano da cor (ex.: 'Terracota').
  final String nome;

  /// Hex sRGB (ex.: '#C26A4A').
  final String hex;
}

class Combo {
  const Combo(this.titulo, this.cores);

  final String titulo;
  final List<String> cores;
}

class Estacao {
  const Estacao({
    required this.id,
    required this.nome,
    required this.subtitulo,
    required this.historia,
    required this.metal,
    required this.paleta,
    required this.neutros,
    required this.evitar,
    required this.gradiente,
    required this.combos,
    required this.consultas,
  });

  final String id;
  final String nome;
  final String subtitulo;
  final String historia;

  /// 'ouro' | 'prata' | 'ambos'
  final String metal;
  final List<Swatch> paleta;
  final List<Swatch> neutros;
  final List<Swatch> evitar;

  /// 2–3 cores para o cartão-herói da estação.
  final List<String> gradiente;
  final List<Combo> combos;

  /// Consultas para o banco de imagens (fotos reais que vestem a estação).
  final List<String> consultas;
}

class Cromatica {
  Cromatica._();

  // ── As 10 estações ─────────────────────────────────────────────────────────

  static const Estacao primaveraLuminosa = Estacao(
    id: 'primavera-luminosa',
    nome: 'Primavera Luminosa',
    subtitulo: 'luz quente e clara',
    historia:
        'Tons de nascer do sol: cores claras, quentes e frescas. '
        'O teu rosto acende com cor — nunca com escuridão.',
    metal: 'ouro',
    paleta: [
      Swatch('Coral claro', '#F79E8C'),
      Swatch('Pêssego', '#FFC59E'),
      Swatch('Amarelo sol', '#F8C630'),
      Swatch('Verde maçã', '#A8D08D'),
      Swatch('Turquesa clara', '#7FD4C4'),
      Swatch('Azul céu', '#8CC3E8'),
      Swatch('Malva luminosa', '#A9B8E8'),
      Swatch('Salmão', '#F2907B'),
      Swatch('Camelo claro', '#D9B48F'),
      Swatch('Creme dourado', '#F3E3C3'),
    ],
    neutros: [
      Swatch('Bege claro', '#EFE0CE'),
      Swatch('Camelo', '#C9A87C'),
      Swatch('Marfim', '#F7F2E7'),
      Swatch('Jeans claro', '#92AFCB'),
    ],
    evitar: [
      Swatch('Bordô profundo', '#5C1F2E'),
      Swatch('Preto puro', '#0B0B0B'),
      Swatch('Cinza frio', '#6A6F75'),
    ],
    gradiente: ['#F8C630', '#F79E8C', '#7FD4C4'],
    combos: [
      Combo('Dia a dia', ['#FFC59E', '#F7F2E7', '#A8D08D']),
      Combo('Presença', ['#F2907B', '#F3E3C3']),
      Combo('Assinatura', ['#F8C630', '#7FD4C4', '#D9B48F']),
    ],
    consultas: ['spring pastel fashion outfit woman', 'coral peach outfit style'],
  );

  static const Estacao primaveraQuente = Estacao(
    id: 'primavera-quente',
    nome: 'Primavera Quente',
    subtitulo: 'cores vivas de calor',
    historia:
        'O coração do calor: cores claras, douradas e cheias de vida. '
        'Tudo o que brilha no amarelo-te-te acesa.',
    metal: 'ouro',
    paleta: [
      Swatch('Coral vivo', '#F8765C'),
      Swatch('Laranja dourado', '#F49F31'),
      Swatch('Amarelo vivo', '#F5C518'),
      Swatch('Verde folha', '#7FB069'),
      Swatch('Turquesa', '#3FBFA8'),
      Swatch('Esmeralda clara', '#2E9C8F'),
      Swatch('Azul quente', '#3E7CB1'),
      Swatch('Púrpura quente', '#B4639F'),
      Swatch('Rosa salmão', '#F28A80'),
      Swatch('Camelo', '#C69456'),
    ],
    neutros: [
      Swatch('Bege', '#E4CDA9'),
      Swatch('Camelo profundo', '#B98A4E'),
      Swatch('Marfim', '#F5EDD8'),
      Swatch('Marinho quente', '#2F4550'),
    ],
    evitar: [
      Swatch('Preto puro', '#0B0B0B'),
      Swatch('Bordô frio', '#5C2438'),
      Swatch('Cinza chumbo', '#4A4E54'),
    ],
    gradiente: ['#F49F31', '#F8765C', '#3FBFA8'],
    combos: [
      Combo('Dia a dia', ['#F5C518', '#7FB069', '#F5EDD8']),
      Combo('Presença', ['#F8765C', '#E4CDA9']),
      Combo('Assinatura', ['#F49F31', '#3E7CB1', '#C69456']),
    ],
    consultas: ['warm colorful spring fashion', 'golden hour style outfit'],
  );

  static const Estacao veraoSereno = Estacao(
    id: 'verao-sereno',
    nome: 'Verão Sereno',
    subtitulo: 'frescura de manhã clara',
    historia:
        'Cores lavadas pela névoa da manhã: claras, frias e suaves. '
        'A tua elegância nasce na calma.',
    metal: 'prata',
    paleta: [
      Swatch('Rosa pós', '#E9B7C0'),
      Swatch('Lavanda clara', '#C3B6E2'),
      Swatch('Azul bebê', '#A7C7E7'),
      Swatch('Azul sereno', '#7FA8D9'),
      Swatch('Menta', '#A5D5C8'),
      Swatch('Sálvia', '#9CBFAE'),
      Swatch('Uva clara', '#8E7CC3'),
      Swatch('Framboesa clara', '#D98BA3'),
      Swatch('Cinza azul', '#9FAEBF'),
      Swatch('Petróleo claro', '#6B9AAE'),
    ],
    neutros: [
      Swatch('Pérola', '#C8CDD4'),
      Swatch('Marinho suave', '#46586E'),
      Swatch('Branco fosco', '#F2F4F6'),
      Swatch('Cacaú frio claro', '#8A6E6E'),
    ],
    evitar: [
      Swatch('Laranja queimado', '#C96A3B'),
      Swatch('Mostarda', '#C9A227'),
      Swatch('Verde oliva', '#7A7040'),
    ],
    gradiente: ['#A7C7E7', '#C3B6E2', '#A5D5C8'],
    combos: [
      Combo('Dia a dia', ['#A7C7E7', '#F2F4F6', '#9CBFAE']),
      Combo('Presença', ['#D98BA3', '#C8CDD4']),
      Combo('Assinatura', ['#7FA8D9', '#E9B7C0', '#46586E']),
    ],
    consultas: ['pastel summer soft fashion', 'light blue lavender outfit'],
  );

  static const Estacao veraoFrio = Estacao(
    id: 'verao-frio',
    nome: 'Verão Frio',
    subtitulo: 'frio azul e elegante',
    historia:
        'Azuis, uvas e framboesas de fundo frio. O contraste é calmo — '
        'a tua força está na linha e não no grito.',
    metal: 'prata',
    paleta: [
      Swatch('Azul suave', '#5B7FB9'),
      Swatch('Cobalto claro', '#4E6FA3'),
      Swatch('Framboesa', '#C4607E'),
      Swatch('Uva', '#7D5BA6'),
      Swatch('Lilás', '#9B8FC0'),
      Swatch('Pinheiro suave', '#4E8578'),
      Swatch('Azul petróleo', '#3E6C80'),
      Swatch('Grafite suave', '#6E7B8A'),
      Swatch('Malva', '#B58BA6'),
      Swatch('Lavanda azul', '#8797C2'),
    ],
    neutros: [
      Swatch('Marinho', '#33465C'),
      Swatch('Cinza frio', '#8D97A1'),
      Swatch('Branco gelo', '#EFF3F6'),
      Swatch('Cacaú frio', '#6E5454'),
    ],
    evitar: [
      Swatch('Laranja', '#D97A34'),
      Swatch('Amarelo quente', '#E3B23C'),
      Swatch('Bege amarelado', '#D9BC8C'),
    ],
    gradiente: ['#5B7FB9', '#7D5BA6', '#C4607E'],
    combos: [
      Combo('Dia a dia', ['#4E6FA3', '#EFF3F6', '#4E8578']),
      Combo('Presença', ['#C4607E', '#33465C']),
      Combo('Assinatura', ['#7D5BA6', '#8797C2', '#6E5454']),
    ],
    consultas: ['cool tone blue fashion editorial', 'raspberry purple outfit'],
  );

  static const Estacao veraoSuave = Estacao(
    id: 'verao-suave',
    nome: 'Verão Suave',
    subtitulo: 'névoa fria e neutra',
    historia:
        'Cores acinzentadas e frias, sem choque. O teu subtom neutro pedia '
        'média-fusão: nada de extremos, tudo de harmonia.',
    metal: 'ambos',
    paleta: [
      Swatch('Rosa antigo', '#C08E9B'),
      Swatch('Malva cinza', '#A08BA5'),
      Swatch('Meia-noite suave', '#5C6E8C'),
      Swatch('Sálvia', '#8FAE9C'),
      Swatch('Azul acinzentado', '#7D93AC'),
      Swatch('Uva suave', '#8E7492'),
      Swatch('Vinho suave', '#96566B'),
      Swatch('Teal suave', '#4F7E7B'),
      Swatch('Rosado cinza', '#A99AA2'),
      Swatch('Denim', '#6A7F9B'),
    ],
    neutros: [
      Swatch('Cinza macio', '#9BA3AB'),
      Swatch('Marinho acinzentado', '#3E4A5C'),
      Swatch('Off-white', '#EDEEF0'),
      Swatch('Cacau', '#75605C'),
    ],
    evitar: [
      Swatch('Laranja vivo', '#E07030'),
      Swatch('Canário', '#F0C030'),
      Swatch('Preto puro', '#0B0B0B'),
    ],
    gradiente: ['#7D93AC', '#A08BA5', '#8FAE9C'],
    combos: [
      Combo('Dia a dia', ['#6A7F9B', '#EDEEF0', '#8FAE9C']),
      Combo('Presença', ['#96566B', '#3E4A5C']),
      Combo('Assinatura', ['#5C6E8C', '#C08E9B', '#75605C']),
    ],
    consultas: ['muted soft summer fashion', 'dusty rose grey outfit'],
  );

  static const Estacao outonoSuave = Estacao(
    id: 'outono-suave',
    nome: 'Outono Suave',
    subtitulo: 'terra em luz difusa',
    historia:
        'Neutro-quente: verdes de sálvia, camel e terracota lavada. '
        'Nada duro — tudo com textura e respiração.',
    metal: 'ouro',
    paleta: [
      Swatch('Sálvia quente', '#A3A380'),
      Swatch('Oliva suave', '#8B8B5E'),
      Swatch('Camelo', '#B99B6B'),
      Swatch('Terracota suave', '#C08267'),
      Swatch('Rosé queimado', '#B57D6E'),
      Swatch('Mostarda suave', '#C09643'),
      Swatch('Musgo', '#7E7A52'),
      Swatch('Azul cinza quente', '#6E8090'),
      Swatch('Pêssego suave', '#D9A98C'),
      Swatch('Vinho suave', '#8E5561'),
    ],
    neutros: [
      Swatch('Bege médio', '#CBB59A'),
      Swatch('Cacaú', '#6E5647'),
      Swatch('Pedra', '#A39A90'),
      Swatch('Creme', '#F0E8D8'),
    ],
    evitar: [
      Swatch('Rosa choque', '#E85C8F'),
      Swatch('Azul elétrico', '#2E6BE6'),
      Swatch('Preto puro', '#0B0B0B'),
    ],
    gradiente: ['#B99B6B', '#C08267', '#A3A380'],
    combos: [
      Combo('Dia a dia', ['#CBB59A', '#F0E8D8', '#8B8B5E']),
      Combo('Presença', ['#C08267', '#6E5647']),
      Combo('Assinatura', ['#B99B6B', '#6E8090', '#C09643']),
    ],
    consultas: ['soft autumn muted fashion', 'camel sage outfit style'],
  );

  static const Estacao outonoDourado = Estacao(
    id: 'outono-dourado',
    nome: 'Outono Dourado',
    subtitulo: 'folhas ao sol de tarde',
    historia:
        'O outono em pleno: terracota, mostarda e floresta. Cores densas '
        'e quentes que vestem como luz de fim de tarde.',
    metal: 'ouro',
    paleta: [
      Swatch('Terracota', '#C26A4A'),
      Swatch('Mostarda', '#D9A036'),
      Swatch('Abóbora', '#D97F36'),
      Swatch('Verde oliva', '#7E7440'),
      Swatch('Floresta quente', '#5E6B3C'),
      Swatch('Camelo', '#B68A4A'),
      Swatch('Dourado velho', '#C9A227'),
      Swatch('Tijolo', '#A64530'),
      Swatch('Petróleo quente', '#3E6E6E'),
      Swatch('Creme dourado', '#EFE0B8'),
    ],
    neutros: [
      Swatch('Café', '#5E4630'),
      Swatch('Bege', '#D9C4A0'),
      Swatch('Creme', '#F5EDD8'),
      Swatch('Marinho esverdeado', '#2E3D38'),
    ],
    evitar: [
      Swatch('Rosa bebê', '#F2C6D2'),
      Swatch('Azul gelo', '#C3DFF2'),
      Swatch('Vinho frio', '#6E2444'),
    ],
    gradiente: ['#C26A4A', '#D9A036', '#5E6B3C'],
    combos: [
      Combo('Dia a dia', ['#D9C4A0', '#F5EDD8', '#7E7440']),
      Combo('Presença', ['#A64530', '#D9C4A0']),
      Combo('Assinatura', ['#C26A4A', '#3E6E6E', '#C9A227']),
    ],
    consultas: ['autumn fashion warm tones', 'terracotta mustard outfit'],
  );

  static const Estacao outonoProfundo = Estacao(
    id: 'outono-profundo',
    nome: 'Outono Profundo',
    subtitulo: 'terra escura e dourada',
    historia:
        'Profundidade quente: bordôs, olivas escuras e dourado queimado. '
        'O teu contraste pede cores com raiz.',
    metal: 'ouro',
    paleta: [
      Swatch('Bordô', '#7E2D3C'),
      Swatch('Tijolo profundo', '#A6452E'),
      Swatch('Mostarda escura', '#B8860B'),
      Swatch('Floresta', '#3E5732'),
      Swatch('Oliva profundo', '#5E5A2E'),
      Swatch('Castanho dourado', '#8E6A3A'),
      Swatch('Azul petróleo', '#2E5555'),
      Swatch('Berinjela', '#4E2E44'),
      Swatch('Laranja queimado', '#C05E2E'),
      Swatch('Dourado', '#C9902E'),
    ],
    neutros: [
      Swatch('Chocolate', '#4A3526'),
      Swatch('Preto suave', '#26221E'),
      Swatch('Creme quente', '#EFE3CC'),
      Swatch('Azul carvão', '#2A3540'),
    ],
    evitar: [
      Swatch('Rosa pastel', '#F2BCC8'),
      Swatch('Lavanda clara', '#C9BCE8'),
      Swatch('Cinza claro frio', '#C0C6CC'),
    ],
    gradiente: ['#7E2D3C', '#B8860B', '#3E5732'],
    combos: [
      Combo('Dia a dia', ['#EFE3CC', '#5E5A2E', '#8E6A3A']),
      Combo('Presença', ['#7E2D3C', '#26221E']),
      Combo('Assinatura', ['#C05E2E', '#2E5555', '#C9902E']),
    ],
    consultas: ['deep autumn dark fashion', 'burgundy olive rich outfit'],
  );

  static const Estacao invernoReal = Estacao(
    id: 'inverno-real',
    nome: 'Inverno Real',
    subtitulo: 'contraste de gelo e rubi',
    historia:
        'Frio intenso e alto contraste: rubi, cobalto e esmeralda sobre '
        'preto e branco. O teu rosto é uma declaração.',
    metal: 'prata',
    paleta: [
      Swatch('Rubi', '#C41E3A'),
      Swatch('Bordô vivo', '#6E1F35'),
      Swatch('Azul royal', '#2E4FC0'),
      Swatch('Cobalto', '#1E5EC0'),
      Swatch('Esmeralda', '#1E8A6E'),
      Swatch('Fúcsia', '#C2428E'),
      Swatch('Púrpura', '#7E3FA8'),
      Swatch('Azul gelo vivo', '#8CC3E8'),
      Swatch('Pinheiro', '#14493E'),
      Swatch('Rosa quente', '#E8557E'),
    ],
    neutros: [
      Swatch('Preto', '#0E0E10'),
      Swatch('Branco puro', '#FAFBFC'),
      Swatch('Marinho', '#1A2438'),
      Swatch('Carvão', '#3A4048'),
    ],
    evitar: [
      Swatch('Bege', '#D9C4A0'),
      Swatch('Laranja terroso', '#C07040'),
      Swatch('Sálvia', '#A3A380'),
    ],
    gradiente: ['#C41E3A', '#2E4FC0', '#1E8A6E'],
    combos: [
      Combo('Dia a dia', ['#FAFBFC', '#1E5EC0', '#3A4048']),
      Combo('Presença', ['#C41E3A', '#0E0E10']),
      Combo('Assinatura', ['#C2428E', '#14493E', '#FAFBFC']),
    ],
    consultas: ['high contrast winter fashion', 'red royal blue editorial'],
  );

  static const Estacao invernoProfundo = Estacao(
    id: 'inverno-profundo',
    nome: 'Inverno Profundo',
    subtitulo: 'escuridão com brilho',
    historia:
        'Frio e fundo: vinho, meia-noite e esmeralda escura. Cores que '
        'engolem a luz — e devolvem em presença.',
    metal: 'prata',
    paleta: [
      Swatch('Vinho', '#5E1F30'),
      Swatch('Meia-noite', '#16223E'),
      Swatch('Esmeralda escura', '#14614E'),
      Swatch('Fúcsia intensa', '#B03A80'),
      Swatch('Rubi escuro', '#A6253E'),
      Swatch('Púrpura real', '#5E2E8E'),
      Swatch('Azul gelo', '#A8D0E8'),
      Swatch('Jade', '#2E8B74'),
      Swatch('Coral gelo', '#E88C7D'),
      Swatch('Royal intenso', '#2438B8'),
    ],
    neutros: [
      Swatch('Preto', '#0C0C0E'),
      Swatch('Branco', '#F7F9FA'),
      Swatch('Carvão', '#262A33'),
      Swatch('Marinho profundo', '#101A2E'),
    ],
    evitar: [
      Swatch('Camelo', '#C09A62'),
      Swatch('Mostarda', '#C9962E'),
      Swatch('Salmão pastel', '#F0A98F'),
    ],
    gradiente: ['#5E1F30', '#16223E', '#14614E'],
    combos: [
      Combo('Dia a dia', ['#F7F9FA', '#14614E', '#262A33']),
      Combo('Presença', ['#A6253E', '#0C0C0E']),
      Combo('Assinatura', ['#5E2E8E', '#A8D0E8', '#101A2E']),
    ],
    consultas: ['deep winter dark elegant fashion', 'emerald midnight outfit'],
  );

  static const Map<String, Estacao> _todas = {
    'primavera-luminosa': primaveraLuminosa,
    'primavera-quente': primaveraQuente,
    'verao-sereno': veraoSereno,
    'verao-frio': veraoFrio,
    'verao-suave': veraoSuave,
    'outono-suave': outonoSuave,
    'outono-dourado': outonoDourado,
    'outono-profundo': outonoProfundo,
    'inverno-real': invernoReal,
    'inverno-profundo': invernoProfundo,
  };

  static List<Estacao> get todas =>
      _todas.values.toList(growable: false);

  // ── Análise ────────────────────────────────────────────────────────────────

  /// Temperatura do subtom: 'quente' | 'frio' | 'neutro'.
  static String temperatura(String undertone) {
    final u = undertone.toLowerCase();
    if (u.contains('oliva') || u.contains('neut')) return 'neutro';
    if (u.contains('quent') || u.contains('doura') || u.contains('amarel')) {
      return 'quente';
    }
    if (u.contains('frio') || u.contains('rosad') || u.contains('azulad')) {
      return 'frio';
    }
    return 'neutro';
  }

  /// Profundidade do tom de pele: 'clara' (1-3), 'média' (4-7), 'profunda' (8-10).
  static String profundidade(int skinTone) {
    if (skinTone <= 0) return 'média';
    if (skinTone <= 3) return 'clara';
    if (skinTone <= 7) return 'média';
    return 'profunda';
  }

  /// Cabelo escuro? (aumenta o contraste → empurra para estações profundas)
  static bool cabeloEscuro(String hairColor) {
    final h = hairColor.toLowerCase();
    return h.contains('preto') ||
        h.contains('escuro') ||
        h.contains('dark') ||
        h.contains('carvão') ||
        h.contains('carvao');
  }

  /// Analisa o perfil e devolve a estação.
  static Estacao analisar(Profile p) {
    final temp = temperatura(p.undertone);
    final prof = profundidade(p.skinTone);
    final escuro = cabeloEscuro(p.hairColor);

    if (temp == 'quente') {
      switch (prof) {
        case 'clara':
          return primaveraLuminosa;
        case 'média':
          return escuro ? outonoDourado : primaveraQuente;
        default:
          return outonoProfundo;
      }
    }
    if (temp == 'frio') {
      switch (prof) {
        case 'clara':
          return veraoSereno;
        case 'média':
          return escuro ? invernoReal : veraoFrio;
        default:
          return invernoReal;
      }
    }
    // neutro
    switch (prof) {
      case 'clara':
        return veraoSuave;
      case 'média':
        return escuro ? invernoProfundo : outonoSuave;
      default:
        return invernoProfundo;
    }
  }

  /// A estação já tem dados suficientes no perfil?
  static bool temDados(Profile p) =>
      p.undertone.isNotEmpty && p.skinTone > 0;
}
