/**
 * Fonte única de verdade do banco de Referências AuraStyle.
 *
 * O seed (prisma/seed.ts) escreve estes arquétipos no Prisma/SQLite.
 * A API usa o banco como armazenamento primário — e este array como
 * reserva determinística quando a tabela está vazia (ex.: deploy
 * serverless sem SQLite persistente). Assim o banco "Referências"
 * funciona em qualquer ambiente, com ou sem migração prévia.
 */

export type Upgrade = { area: string; action: string; why: string };

export type ReferenceLookSeed = {
  slug: string;
  name: string;
  tagline: string;
  image: string;
  order: number;
  faceShape: string;
  jawline: string;
  cheekbones: string;
  eyeShape: string;
  browType: string;
  hairTexture: string;
  facialHair: string;
  skinToneCenter: number;
  styleVibe: string;
  signature: string[]; // serializado para o banco
  upgrades: Record<string, Upgrade>; // serializado para o banco
};

const U = (area: string, action: string, why: string): Upgrade => ({ area, action, why });

export const REFERENCE_LOOKS: ReferenceLookSeed[] = [
  {
    slug: 'o-classico',
    name: 'O Clássico',
    tagline: 'Equilíbrio que nunca falha — a elegância do meio-termo',
    image: '/references/o-classico.jpg',
    order: 1,
    faceShape: 'oval',
    jawline: 'equilibrado',
    cheekbones: 'presentes',
    eyeShape: 'amendoados',
    browType: 'naturais',
    hairTexture: 'liso',
    facialHair: 'nenhum',
    skinToneCenter: 6,
    styleVibe: 'Alfaiataria sem esforço, peças que duram décadas, nada grita — tudo fala.',
    signature: [
      'Gola limpa e ombros certos — o corte da camiseta vale mais que o logo',
      'Laterais do cabelo sempre resolvidas: volume no topo, disciplina nas bordas',
      'Paleta: azul-marinho, carvão, branco-óssio — um acento por look',
    ],
    upgrades: {
      faceShape: U('Estrutura', 'Aponta o volume do topo levemente para cima', 'Estica visualmente rostos mais largos na direção do oval clássico'),
      jawline: U('Contorno', 'Barba feita 2x/semana mantendo 2mm', 'Define o maxilar sem brigar com a tua linha natural'),
      hairTexture: U('Cabelo', 'Corte lateral médio com topo pentado', 'O movimento suave do liso é a tua melhor matéria-prima'),
      browType: U('Sobrancelhas', 'Só limpeza da área entre os olhos e laterais', 'Manter a linha natural lê como cuidado, não como desenho'),
      geral: U('Base', 'Camiseta estruturada + relógio de pulso discreto', 'O Clássico vive de encaixe: 90% do impacto é proporção'),
    },
  },
  {
    slug: 'o-estruturado',
    name: 'O Estruturado',
    tagline: 'Maxilar de corte reto — presença que dispensa volume',
    image: '/references/o-estruturado.jpg',
    order: 2,
    faceShape: 'quadrado',
    jawline: 'marcado',
    cheekbones: 'presentes',
    eyeShape: 'fundos',
    browType: 'marcados',
    hairTexture: 'liso',
    facialHair: 'barba-curta',
    skinToneCenter: 5,
    styleVibe: 'Linhas retas, tecidos com corpo, acabamento fosco — força sem barulho.',
    signature: [
      'Barba curta desenhada: contorno do maxilar definido a cada 3 dias',
      'Cabelo crop texturizado com matte — zero brilho, toda a textura',
      'Golas altas e ombros retos: moletons e jaquetas com estrutura',
    ],
    upgrades: {
      faceShape: U('Estrutura', 'Laterais mais curtas, topo com textura para cima', 'Aproveita o ângulo do maxilar criando silhueta vertical limpa'),
      jawline: U('Contorno', 'Barba de 3-5mm com contorno reto no maxilar', 'No rosto estruturado a barba é arquitetura, não disfarce'),
      cheekbones: U('Iluminação', 'Pele hidratada com acabamento matte', 'Zigomático presente pede pele uniforme, não brilho'),
      browType: U('Sobrancelhas', 'Manter espessura, limpar só excessos inferiores', 'Sobrancelha marcada ancora o olhar fundo do rosto quadrado'),
      geral: U('Base', 'Peças foscas pretas ou cinza-chumbo', 'Estrutura combina com sombra: brilho dilui a tua vantagem'),
    },
  },
  {
    slug: 'o-criativo',
    name: 'O Criativo',
    tagline: 'Curvas no cabelo, coragem nas escolhas',
    image: '/references/o-criativo.jpg',
    order: 3,
    faceShape: 'coracao',
    jawline: 'suave',
    cheekbones: 'altos',
    eyeShape: 'expressivos',
    browType: 'naturais',
    hairTexture: 'cacheado',
    facialHair: 'nenhum',
    skinToneCenter: 10,
    styleVibe: 'Volume onde interessa, círculos e óculos como assinatura — expressividade estudada.',
    signature: [
      'Cachos médios com definição: creme de pentear é o teu melhor amigo',
      'Óculos de aro redondo ou acetato — moldura para olhos expressivos',
      'Volumetria no tronco: camisas amplas, bases retas',
    ],
    upgrades: {
      faceShape: U('Estrutura', 'Volume nas têmporas, nunca no topo', 'Equilibra o queixo fino do rosto coração com largura no meio'),
      cheekbones: U('Iluminação', 'Hidratante com leve acabamento acetinado', 'Zigomáticos altos ganham profundidade com pele nutrida'),
      hairTexture: U('Cabelo', 'Ritual de cachos: leave-in + amassar com as mãos', 'Cachos definidos são a tua assinatura — não esconda com corte curto'),
      eyeShape: U('Olhar', 'Aro de óculos que siga a linha da sobrancelha', 'Olhos expressivos pedem moldura limpa, não competição'),
      geral: U('Base', 'Uma peça statement por look — só uma', 'O criativo se lê pela edição: volume + aro + cor = demais'),
    },
  },
  {
    slug: 'o-atletico',
    name: 'O Atlético',
    tagline: 'Limpeza total — energia que vem do encaixe',
    image: '/references/o-atletico.jpg',
    order: 4,
    faceShape: 'redondo',
    jawline: 'equilibrado',
    cheekbones: 'discretos',
    eyeShape: 'amendoados',
    browType: 'naturais',
    hairTexture: 'liso',
    facialHair: 'nenhum',
    skinToneCenter: 7,
    styleVibe: 'Tecidos técnicos, cortes funcionais, zero excesso — performance como estética.',
    signature: [
      'Fade baixo com topo curto: manutenção a cada 2 semanas',
      'Peças com encaixe no ombro — nem justas, nem largas',
      'Cores sólidas com um detalhe técnico: zíper, malha, textura',
    ],
    upgrades: {
      faceShape: U('Estrutura', 'Altura no topo do corte, laterais fechadas', 'No rosto redondo, o volume vertical cria o ângulo que falta'),
      jawline: U('Contorno', 'Barba zero com contorno nítido na linha da mandíbula', 'Define sem adicionar volume lateral ao rosto largo'),
      cheekbones: U('Iluminação', 'Protetor solar diário — tom uniforme', 'Pele cuidada substitui o relevo que o osso não dá'),
      browType: U('Sobrancelhas', 'Escovar para cima com gel transparente', 'Abre o olhar e dá expressão ao rosto amigável'),
      geral: U('Base', 'Jaqueta com ombro estruturado', 'O ombro certo é o ombro do traje — presente em toda a silhueta'),
    },
  },
  {
    slug: 'o-romantico',
    name: 'O Romântico',
    tagline: 'Ondas suaves, tecidos que respiram',
    image: '/references/o-romantico.jpg',
    order: 5,
    faceShape: 'oval',
    jawline: 'suave',
    cheekbones: 'presentes',
    eyeShape: 'amendoados',
    browType: 'finos',
    hairTexture: 'ondulado',
    facialHair: 'cavanhaque-suave',
    skinToneCenter: 4,
    styleVibe: 'Linho, camadas abertas, movimento no cabelo — delicadeza intencional.',
    signature: [
      'Ondas médias soltas com creme leve — nunca armado demais',
      'Camisas de linho com gola aberta em V',
      'Barba curta suave — contorno orgânico, sem régua',
    ],
    upgrades: {
      faceShape: U('Estrutura', 'Ondas começando na altura das orelhas', 'Amplia suavemente laterais e valoriza o oval macio'),
      jawline: U('Contorno', 'Cavanhaque suave ligando ao bigode', 'No maxilar doce, a barba leve desenha presença sem dureza'),
      browType: U('Sobrancelhas', 'Não afinar — só alinhar com escova', 'Sobrancelha fina pede naturalidade para não sumir no rosto'),
      hairTexture: U('Cabelo', 'Difusor em temperatura baixa, movimento natural', 'O ondulado romântico vive do movimento — seca ao vento'),
      geral: U('Base', 'Tecidos naturais: linho, algodão cru', 'O romantismo é tático: materiais que dobram como o corpo'),
    },
  },
  {
    slug: 'o-sofisticado',
    name: 'O Sofisticado',
    tagline: 'Barba cheia, palavra contada',
    image: '/references/o-sofisticado.jpg',
    order: 6,
    faceShape: 'retangular',
    jawline: 'marcado',
    cheekbones: 'presentes',
    eyeShape: 'fundos',
    browType: 'marcados',
    hairTexture: 'liso',
    facialHair: 'barba-cheia',
    skinToneCenter: 6,
    styleVibe: 'Superfícies polidas, monocromia absoluta, autoridade tranquila.',
    signature: [
      'Barba cheia escovada com óleo — forma quadrada, bochecha limpa',
      'Cabelo penteado para trás com brilho controlado',
      'Blazer preto sobre preto — textura faz o contraste',
    ],
    upgrades: {
      faceShape: U('Estrutura', 'Volume lateral controlado, nunca alto demais', 'No rosto retangular, altura extra alonga — o segredo é equilíbrio'),
      jawline: U('Contorno', 'Barba cheia com bochechas aparadas a 10mm', 'Suaviza o comprimento facial e emoldura o maxilar forte'),
      hairTexture: U('Cabelo', 'Pente para trás com pomada de brilho médio', 'O liso sofisticado pede direção — fugir do formato solto'),
      browType: U('Sobrancelhas', 'Manter grossura, definir arco com pente', 'Sobrancelha marcada fecha o trio de autoridade do rosto longo'),
      geral: U('Base', 'Óleo de barba diário + pente de madeira', 'A barba cheia é um projeto de 90 dias — consistência é tudo'),
    },
  },
  {
    slug: 'o-moderno',
    name: 'O Moderno',
    tagline: 'Precisão de barbearia, atitude de rua',
    image: '/references/o-moderno.jpg',
    order: 7,
    faceShape: 'losango',
    jawline: 'marcado',
    cheekbones: 'altos',
    eyeShape: 'expressivos',
    browType: 'marcados',
    hairTexture: 'cacheado',
    facialHair: 'nenhum',
    skinToneCenter: 9,
    styleVibe: 'Linhas desenhadas a navalha, streetwear minimal, contraste alto.',
    signature: [
      'Line-up navalhado a cada 10 dias — precisão é a assinatura',
      'Topo box curto definido — cachos desenhados, não soltos',
      'Streetwear de uma cor: capuz + calça reta + sneaker limpo',
    ],
    upgrades: {
      faceShape: U('Estrutura', 'Respeitar as têmporas: sem volume pontual', 'No rosto losango, o line-up reto reequilibra as maçãs altas'),
      cheekbones: U('Iluminação', 'Rotina de pele simples: limpar + hidratar', 'Maçãs altas + pele uniforme = contraste que dispensa filtro'),
      hairTexture: U('Cabelo', 'Sponge nos cachos curtos, 2 min/dia', 'Definição de círculos é o que separa o moderno do desleixado'),
      browType: U('Sobrancelhas', 'Linha inferior reta, manutenção com pinça', 'No corte navalhado, a sobrancelha é a segunda linha do desenho'),
      geral: U('Base', 'Sneaker sempre impecável — é o teu relógio', 'No streetwear minimal, o calçado carrega a leitura de cuidado'),
    },
  },
  {
    slug: 'o-natural',
    name: 'O Natural',
    tagline: 'Textura no estado puro — volume que nasceu pronto',
    image: '/references/o-natural.jpg',
    order: 8,
    faceShape: 'oblongo',
    jawline: 'equilibrado',
    cheekbones: 'presentes',
    eyeShape: 'redondos',
    browType: 'naturais',
    hairTexture: 'crespo',
    facialHair: 'nenhum',
    skinToneCenter: 12,
    styleVibe: 'Cabelo crespo em volume honesto, tricôs e algodões macios, sorriso como acessório.',
    signature: [
      'Crespo com forma arredondada hidratada — never dry',
      'Golas redondas e tricôs de textura visível',
      'Skincare mínimo e constante: água, sabonete suave, FPS',
    ],
    upgrades: {
      faceShape: U('Estrutura', 'Volume lateral moderado, evitar torre no topo', 'No rosto oblongo, largura equilibra comprimento — afro arredondado é ideal'),
      hairTexture: U('Cabelo', 'LOC semanal: leave-in + óleo + creme', 'Crespo saudável tem brilho próprio — hidratação é o segredo público'),
      eyeShape: U('Olhar', 'Sobrancelha natural escovada para cima', 'Olhos redondos ganham amplitude com sobrancelha alta e limpa'),
      jawline: U('Contorno', 'Pele bem cuidada, sem barba', 'Maxilar equilibrado não precisa disfarce — precisa de pele radiante'),
      geral: U('Base', 'Travesseiro de cetim + água 2L/dia', 'Textura natural é 80% rotina interna, 20% produto'),
    },
  },
];
