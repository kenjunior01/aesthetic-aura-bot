/// cortes_data.dart — direções de corte por formato de rosto.
///
/// Cada formato tem um OBJETIVO (alongar, alargar, suavizar…) e 4 cortes
/// que o cumprem. As consultas de fotos reais têm variante masculina e
/// feminina ({g} → 'man' | 'woman' no banco de imagens).
library;

class Corte {
  const Corte(this.nome, this.porque, this.dica, this.consultaM, this.consultaF);

  final String nome;
  final String porque;
  final String dica;

  /// Consulta para o banco de imagens — versão masculina/feminina.
  final String consultaM;
  final String consultaF;

  String consulta(String genero) =>
      genero == 'feminino' ? consultaF : consultaM;
}

class FormaRosto {
  const FormaRosto(this.chave, this.nome, this.objetivo, this.cortes);

  /// Palavras-chave para casar com o faceShape do perfil.
  final List<String> chave;
  final String nome;
  final String objetivo;
  final List<Corte> cortes;
}

const List<FormaRosto> kFormas = [
  FormaRosto(
    ['oval'],
    'Rosto Oval',
    'mantém o equilíbrio — quase tudo te serve',
    [
      Corte(
        'Médio em camadas',
        'Preserva a proporção natural sem acrescentar volume onde não precisa.',
        'Camadas leves a partir do queixo.',
        'man medium layered haircut', 'woman medium layered haircut',
      ),
      Corte(
        'Pompadour suave',
        'Alonga de leve e traz elegância sem exagero.',
        'Volume no topo, laterais contidas.',
        'man pompadour haircut', 'woman voluminous quiff hairstyle',
      ),
      Corte(
        'Ondas definidas',
        'Movimento controlado — ondulado cai bem no oval.',
        'Creme de pentear e amassar com as mãos.',
        'man wavy hair defined', 'woman defined waves hairstyle',
      ),
      Corte(
        'Franja cortina',
        'Emoldura o rosto sem esconder a proporção.',
        'Secca para os lados a partir do centro.',
        'man curtain bangs', 'woman curtain bangs hairstyle',
      ),
    ],
  ),
  FormaRosto(
    ['redond', 'circular'],
    'Rosto Redondo',
    'alonga e cria ângulo',
    [
      Corte(
        'Undercut com topo texturizado',
        'Laterais curtos + altura no topo alongam o rosto de imediato.',
        'Matte clay para volume seco.',
        'man undercut textured haircut', 'woman undercut short haircut',
      ),
      Corte(
        'Topo alto com volume',
        'A altura vertical é o antídoto direto da curva horizontal.',
        'Soba e desfiar — nunca colar.',
        'man high volume quiff', 'woman long voluminous top hairstyle',
      ),
      Corte(
        'Risca lateral marcada',
        'A diagonal quebra a simetria da curva.',
        'Risca deslocada 3-4 cm do centro.',
        'man side part haircut', 'woman side part wavy hairstyle',
      ),
      Corte(
        'Franja alta irregular',
        'Encurta a testa apenas o necessário — mantém o alongamento.',
        'Textura pontuda, franja rala.',
        'man choppy fringe', 'woman choppy bangs',
      ),
    ],
  ),
  FormaRosto(
    ['quadrad', 'quadrada'],
    'Rosto Quadrado',
    'suaviza os cantos da mandíbula',
    [
      Corte(
        'Textura no topo',
        'Camadas irregulares amolecem a linha reta da mandíbula.',
        'Evita cortes a navalha nas laterais.',
        'man textured crop haircut', 'woman textured layers square face',
      ),
      Corte(
        'Ondas soltas',
        'A curva das ondas arredonda o contorno anguloso.',
        'Difusor em temperatura média.',
        'man loose waves haircut', 'woman soft waves square face',
      ),
      Corte(
        'Laterais desembaraçadas',
        'Laterais raspadas acentuam os cantos — o comprimento disfarça.',
        'Deixa a navalha só para o contorno da barba.',
        'man tapered sides long top', 'woman layered mid length square',
      ),
      Corte(
        'Franja lateral',
        'Corta o ângulo da testa em diagonal.',
        'Mais comprida para o lado externo do olho.',
        'man side swept fringe', 'woman side swept bangs',
      ),
    ],
  ),
  FormaRosto(
    ['coracao', 'coração', 'cardioide'],
    'Rosto Coração',
    'equilibra a testa larga com o queixo fino',
    [
      Corte(
        'Comprimento no queixo (lob)',
        'Volume na altura do queixo preenche a parte mais fina.',
        'Ondas começando na linha da mandíbula.',
        'man chin length haircut', 'woman lob haircut waves',
      ),
      Corte(
        'Franja lateral comprida',
        'Reduz visualmente a largura da testa.',
        'Desfiada, nunca reta.',
        'man long side fringe', 'woman long side bangs',
      ),
      Corte(
        'Ondas na base',
        'Curls na altura do queixo = equilíbrio instantâneo.',
        'Chapinho nas pontas para dentro.',
        'man curls jaw length', 'woman curly bob jaw length',
      ),
      Corte(
        'Coque alto solto',
        'Levanta o foco para o topo e alonga o rosto.',
        'Mechas soltas junto às orelhas.',
        'man top knot hairstyle', 'woman high bun face framing',
      ),
    ],
  ),
  FormaRosto(
    ['losang', 'diamante'],
    'Rosto Losango',
    'alarga a testa e amacia as maçãs',
    [
      Corte(
        'Franja cheia',
        'A testa fina ganha largura com franja completa.',
        'Corta seca para o arredondado.',
        'man full fringe', 'woman full bangs',
      ),
      Corte(
        'Volume na altura das orelhas',
        'Equilibra as maçãs proeminentes.',
        'Camadas começando na linha da orelha.',
        'man volume sides haircut', 'woman ear length layers',
      ),
      Corte(
        'Ondas amplas de lado',
        'Curvas largas suavizam o eixo estreito.',
        'Ondas grandes, movimento para fora.',
        'man side waves hair', 'woman side swept waves',
      ),
      Corte(
        'Meio recolhido com volume',
        'Topo com corpo cria largura onde falta.',
        'Poeira texturizante na raiz.',
        'man man bun volume', 'woman half up volume hairstyle',
      ),
    ],
  ),
  FormaRosto(
    ['oblong', 'retangular', 'alongado', 'comprido'],
    'Rosto Oblongo',
    'alarga e encurta visualmente',
    [
      Corte(
        'Franja cheia',
        'O atalho clássico: cobre a testa e encurta o rosto.',
        'Com peso — franja rala não segura o efeito.',
        'man full fringe haircut', 'woman blunt bangs',
      ),
      Corte(
        'Altura do queixo com ondas',
        'Largura na base + volume nas laterais = proporção.',
        'Evita comprimento além do peito liso.',
        'man jaw length waves', 'woman shoulder length waves',
      ),
      Corte(
        'Laterais com corpo',
        'Volume horizontal nas laterais alarga o contorno.',
        'Modela para fora, nunca para baixo colado.',
        'man voluminous sides hair', 'woman volume bob haircut',
      ),
      Corte(
        'Baixo recolhido com franja',
        'Recolher sem altura mantém a linha horizontal.',
        'Deixa mechas na frente do rosto.',
        'man low bun fringe', 'woman low bun bangs hairstyle',
      ),
    ],
  ),
];

FormaRosto? formaDoPerfil(String faceShape) {
  final f = faceShape.toLowerCase();
  if (f.isEmpty) return null;
  for (final forma in kFormas) {
    for (final k in forma.chave) {
      if (f.contains(k)) return forma;
    }
  }
  return null;
}
