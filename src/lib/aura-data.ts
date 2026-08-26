export const genders = [
  { id: 'feminino', label: 'Feminino' },
  { id: 'masculino', label: 'Masculino' },
  { id: 'nao-binario', label: 'N\u00e3o-bin\u00e1rio' },
  { id: 'outro', label: 'Prefiro n\u00e3o dizer' },
] as const;

export const regions = [
  'S\u00e3o Paulo, BR',
  'Rio de Janeiro, BR',
  'Belo Horizonte, BR',
  'Curitiba, BR',
  'Porto Alegre, BR',
  'Salvador, BR',
  'Recife, BR',
  'Fortaleza, BR',
  'Manaus, BR',
  'Bras\u00edlia, BR',
  'Lisboa, PT',
  'Porto, PT',
  'Luanda, AO',
  'Maputo, MZ',
];

export const climateByRegion: Record<string, string> = {
  'Manaus, BR': 'tropical',
  'Salvador, BR': 'tropical',
  'Recife, BR': 'tropical',
  'Fortaleza, BR': 'tropical',
  'Porto Alegre, BR': 'temperado',
  'Curitiba, BR': 'frio',
  'Lisboa, PT': 'temperado',
  'Porto, PT': 'temperado',
};

export const faceShapes = [
  { id: 'oval', label: 'Oval' },
  { id: 'redondo', label: 'Redondo' },
  { id: 'quadrado', label: 'Quadrado' },
  { id: 'retangular', label: 'Retangular' },
  { id: 'coracao', label: 'Cora\u00e7\u00e3o' },
  { id: 'diamante', label: 'Diamante' },
  { id: 'losango', label: 'Losango' },
] as const;

export const skinTones = [
  'oklch(0.95 0.02 70)',
  'oklch(0.91 0.035 70)',
  'oklch(0.87 0.045 68)',
  'oklch(0.83 0.055 66)',
  'oklch(0.78 0.065 64)',
  'oklch(0.73 0.075 62)',
  'oklch(0.67 0.08 60)',
  'oklch(0.61 0.085 58)',
  'oklch(0.55 0.085 55)',
  'oklch(0.48 0.08 50)',
  'oklch(0.41 0.07 47)',
  'oklch(0.35 0.06 45)',
  'oklch(0.29 0.05 42)',
  'oklch(0.23 0.04 40)',
];

export const undertones = [
  { id: 'quente', label: 'Quente', color: 'oklch(0.8 0.13 70)' },
  { id: 'frio', label: 'Frio', color: 'oklch(0.75 0.1 250)' },
  { id: 'neutro', label: 'Neutro', color: 'oklch(0.78 0.03 300)' },
  { id: 'oliva', label: 'Oliva', color: 'oklch(0.72 0.09 130)' },
] as const;

export const eyeColors = [
  { id: 'castanho', label: 'Castanho', color: 'oklch(0.45 0.08 55)' },
  { id: 'mel', label: 'Mel', color: 'oklch(0.7 0.12 75)' },
  { id: 'verde', label: 'Verde', color: 'oklch(0.6 0.12 150)' },
  { id: 'azul', label: 'Azul', color: 'oklch(0.65 0.12 240)' },
  { id: 'cinza', label: 'Cinza', color: 'oklch(0.65 0.02 250)' },
  { id: 'preto', label: 'Preto', color: 'oklch(0.25 0.02 285)' },
] as const;

export const skinTypes = [
  { id: 'oleosa', label: 'Oleosa', icon: 'Droplets' },
  { id: 'seca', label: 'Seca', icon: 'Wind' },
  { id: 'mista', label: 'Mista', icon: 'Blend' },
  { id: 'sensivel', label: 'Sens\u00edvel', icon: 'HeartPulse' },
  { id: 'normal', label: 'Normal', icon: 'Sparkles' },
] as const;

export const hairTypes = [
  { id: 'liso', label: 'Liso' },
  { id: 'ondulado', label: 'Ondulado' },
  { id: 'cacheado', label: 'Cacheado' },
  { id: 'crespo', label: 'Crespo' },
  { id: 'afro', label: 'Afro' },
  { id: 'trancas', label: 'Tran\u00e7as' },
  { id: 'locks', label: 'Locks' },
  { id: 'rapado', label: 'Rapado' },
  { id: 'moicano', label: 'Moicano' },
  { id: 'careca', label: 'Careca' },
] as const;

export const hairColors = [
  { id: 'loiro-claro', label: 'Loiro claro', color: 'oklch(0.9 0.08 88)' },
  { id: 'loiro-escuro', label: 'Loiro escuro', color: 'oklch(0.75 0.09 80)' },
  { id: 'castanho-medio', label: 'Castanho m\u00e9dio', color: 'oklch(0.5 0.07 58)' },
  { id: 'castanho-escuro', label: 'Castanho escuro', color: 'oklch(0.35 0.05 50)' },
  { id: 'ruivo', label: 'Ruivo', color: 'oklch(0.55 0.16 40)' },
  { id: 'preto', label: 'Preto', color: 'oklch(0.22 0.02 285)' },
  { id: 'grisalho', label: 'Grisalho', color: 'oklch(0.78 0.01 285)' },
  { id: 'colorido', label: 'Colorido', color: 'oklch(0.65 0.22 320)' },
] as const;

export const hairLengths = [
  { id: 'buzz', label: 'Buzz cut' },
  { id: 'curto', label: 'Curto' },
  { id: 'medio', label: 'M\u00e9dio' },
  { id: 'longo', label: 'Longo' },
] as const;

export const hairThickness = [
  { id: 'fino', label: 'Fino' },
  { id: 'medio', label: 'M\u00e9dio' },
  { id: 'grosso', label: 'Grosso' },
] as const;

export const hairIssues = [
  'Queda',
  'Caspa',
  'Ressecamento',
  'Frizz',
  'Quebra',
  'Oleosidade',
];

export const bodyTypes = [
  { id: 'triangulo', label: 'Tri\u00e2ngulo', desc: 'Quadris mais largos que os ombros' },
  { id: 'invertido', label: 'Tri\u00e2ngulo invertido', desc: 'Ombros mais largos que os quadris' },
  { id: 'retangular', label: 'Retangular', desc: 'Ombros, cintura e quadris alinhados' },
  { id: 'oval', label: 'Oval', desc: 'Volume concentrado no centro' },
  { id: 'ampulheta', label: 'Ampulheta', desc: 'Cintura marcada, ombros e quadris equilibrados' },
] as const;

export const styles = [
  { id: 'casual', label: 'Casual', emoji: '\ud83d\udc55' },
  { id: 'streetwear', label: 'Streetwear', emoji: '\ud83e\udde2' },
  { id: 'formal', label: 'Formal', emoji: '\ud83d\udc54' },
  { id: 'minimalista', label: 'Minimalista', emoji: '\u2b1c' },
  { id: 'esportivo', label: 'Esportivo', emoji: '\ud83c\udfc3' },
  { id: 'boho', label: 'Boho', emoji: '\ud83c\udf38' },
  { id: 'grunge', label: 'Grunge', emoji: '\ud83d\udda3' },
  { id: 'classico', label: 'Cl\u00e1ssico', emoji: '\ud83c\udfa9' },
  { id: 'elegante', label: 'Elegante', emoji: '\u2728' },
  { id: 'rocker', label: 'Rocker', emoji: '\ud83c\udfb8' },
];

export const occasions = [
  'Trabalho',
  'Festa',
  'Casual',
  'Date',
  'Academia',
  'Viagem',
  'Evento social',
];

export const budgets = [
  { id: 'economico', label: 'Econ\u00f4mico', hint: '$' },
  { id: 'moderado', label: 'Moderado', hint: '$$' },
  { id: 'premium', label: 'Premium', hint: '$$$' },
  { id: 'luxo', label: 'Luxo', hint: '$$$$' },
] as const;

export const favoriteColors = [
  'oklch(0.22 0.02 285)',
  'oklch(0.97 0.01 285)',
  'oklch(0.55 0.2 25)',
  'oklch(0.72 0.16 60)',
  'oklch(0.82 0.14 85)',
  'oklch(0.68 0.15 145)',
  'oklch(0.62 0.14 195)',
  'oklch(0.6 0.19 255)',
  'oklch(0.55 0.22 300)',
  'oklch(0.68 0.18 340)',
  'oklch(0.5 0.06 60)',
  'oklch(0.75 0.05 200)',
];

export const climates = ['tropical', 'temperado', 'frio', 'arido'];

export const professions = [
  'Design',
  'Tecnologia',
  'Sa\u00fade',
  'Educa\u00e7\u00e3o',
  'Direito',
  'Marketing',
  'Engenharia',
  'Finan\u00e7as',
  'Artes',
  'Gastronomia',
  'Estudante',
  'Empreendedor',
];

export const closetCategories = [
  'Camisetas',
  'Camisas',
  'Cal\u00e7as',
  'Vestidos',
  'Jaquetas',
  'Sapatos',
  'Acess\u00f3rios',
];