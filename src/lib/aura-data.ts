export const genders = [
  { id: 'feminino', label: 'Feminino' },
  { id: 'masculino', label: 'Masculino' },
  { id: 'nao-binario', label: 'Não-binário' },
  { id: 'outro', label: 'Prefiro não dizer' },
] as const;

export const regions = [
  'São Paulo, BR',
  'Rio de Janeiro, BR',
  'Belo Horizonte, BR',
  'Curitiba, BR',
  'Porto Alegre, BR',
  'Salvador, BR',
  'Recife, BR',
  'Fortaleza, BR',
  'Manaus, BR',
  'Brasília, BR',
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
  { id: 'coracao', label: 'Coração' },
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
  { id: 'sensivel', label: 'Sensível', icon: 'HeartPulse' },
  { id: 'normal', label: 'Normal', icon: 'Sparkles' },
] as const;

export const hairTypes = [
  { id: 'liso', label: 'Liso' },
  { id: 'ondulado', label: 'Ondulado' },
  { id: 'cacheado', label: 'Cacheado' },
  { id: 'crespo', label: 'Crespo' },
  { id: 'afro', label: 'Afro' },
  { id: 'trancas', label: 'Tranças' },
  { id: 'locks', label: 'Locks' },
  { id: 'rapado', label: 'Rapado' },
  { id: 'moicano', label: 'Moicano' },
  { id: 'careca', label: 'Careca' },
] as const;

export const hairColors = [
  { id: 'loiro-claro', label: 'Loiro claro', color: 'oklch(0.9 0.08 88)' },
  { id: 'loiro-escuro', label: 'Loiro escuro', color: 'oklch(0.75 0.09 80)' },
  { id: 'castanho-medio', label: 'Castanho médio', color: 'oklch(0.5 0.07 58)' },
  { id: 'castanho-escuro', label: 'Castanho escuro', color: 'oklch(0.35 0.05 50)' },
  { id: 'ruivo', label: 'Ruivo', color: 'oklch(0.55 0.16 40)' },
  { id: 'preto', label: 'Preto', color: 'oklch(0.22 0.02 285)' },
  { id: 'grisalho', label: 'Grisalho', color: 'oklch(0.78 0.01 285)' },
  { id: 'colorido', label: 'Colorido', color: 'oklch(0.65 0.22 320)' },
] as const;

export const hairLengths = [
  { id: 'buzz', label: 'Buzz cut' },
  { id: 'curto', label: 'Curto' },
  { id: 'medio', label: 'Médio' },
  { id: 'longo', label: 'Longo' },
] as const;

export const hairThickness = [
  { id: 'fino', label: 'Fino' },
  { id: 'medio', label: 'Médio' },
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
  { id: 'triangulo', label: 'Triângulo', desc: 'Quadris mais largos que os ombros' },
  { id: 'invertido', label: 'Triângulo invertido', desc: 'Ombros mais largos que os quadris' },
  { id: 'retangular', label: 'Retangular', desc: 'Ombros, cintura e quadris alinhados' },
  { id: 'oval', label: 'Oval', desc: 'Volume concentrado no centro' },
  { id: 'ampulheta', label: 'Ampulheta', desc: 'Cintura marcada, ombros e quadris equilibrados' },
] as const;

export const styles = [
  { id: 'casual', label: 'Casual', emoji: '👕' },
  { id: 'streetwear', label: 'Streetwear', emoji: '🧢' },
  { id: 'formal', label: 'Formal', emoji: '👔' },
  { id: 'minimalista', label: 'Minimalista', emoji: '⬜' },
  { id: 'esportivo', label: 'Esportivo', emoji: '🏃' },
  { id: 'boho', label: 'Boho', emoji: '🌸' },
  { id: 'grunge', label: 'Grunge', emoji: '🖣' },
  { id: 'classico', label: 'Clássico', emoji: '🎩' },
  { id: 'elegante', label: 'Elegante', emoji: '✨' },
  { id: 'rocker', label: 'Rocker', emoji: '🎸' },
] as const;

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
  { id: 'economico', label: 'Econômico', hint: '$' },
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
  'Saúde',
  'Educação',
  'Direito',
  'Marketing',
  'Engenharia',
  'Finanças',
  'Artes',
  'Gastronomia',
  'Estudante',
  'Empreendedor',
];

export const closetCategories = [
  'Camisetas',
  'Camisas',
  'Calças',
  'Vestidos',
  'Jaquetas',
  'Sapatos',
  'Acessórios',
];

// ============================================================
// DAILY CHALLENGES POOL
// ============================================================

export type DailyChallenge = {
  title: string;
  description: string;
  category: 'pele' | 'cabelo' | 'estilo' | 'bem-estar' | 'desafio';
  xp: number;
};

export const dailyChallenges: DailyChallenge[] = [
  // Pele
  { title: 'Protetor solar diário', description: 'Aplique FPS 30+ no rosto e pescoço. Proteção é o melhor anti-idade.', category: 'pele', xp: 20 },
  { title: 'Rotina de limpeza dupla', description: 'Faça limpeza com óleo seguida de sabonete. Remove 2x mais impurezas.', category: 'pele', xp: 25 },
  { title: 'Hidratação noturna', description: 'Aplique sérum + creme hidratante antes de dormir. Pele regenera à noite.', category: 'pele', xp: 20 },
  { title: 'Máscara facial', description: 'Use uma máscara de argila ou hidratante por 15 minutos. Tratamento intensivo.', category: 'pele', xp: 30 },
  { title: 'Beba 2L de água', description: 'Hidratação interna reflete na pele. Comece o dia com um copo em jejum.', category: 'pele', xp: 15 },
  { title: 'Esfoliação suave', description: 'Esfolie o rosto 1x com movimentos circulares. Não exagere para não irritar.', category: 'pele', xp: 25 },
  { title: 'Água micelar antes de dormir', description: 'Remova maquiagem e poluição do dia com água micelar. Pele limpa respira melhor.', category: 'pele', xp: 15 },
  { title: 'Contorno de olhos', description: 'Aplique creme específico para a área dos olhos com toques suaves.', category: 'pele', xp: 20 },
  // Cabelo
  { title: 'Tratamento capilar profundo', description: 'Aplique máscara de hidratação e deixe agir por 20 min. Cabelo sedoso garantido.', category: 'cabelo', xp: 30 },
  { title: 'Proteção térmica', description: 'Use protetor térmico antes de qualquer ferramenta quente. Previne quebra.', category: 'cabelo', xp: 20 },
  { title: 'Massagem no couro cabeludo', description: 'Massagem de 5 min estimula a circulação e promove crescimento saudável.', category: 'cabelo', xp: 15 },
  { title: 'Finalizou sem enxaguar', description: 'Experimente um leave-in ou óleo capilar para definição e brilho.', category: 'cabelo', xp: 20 },
  { title: 'Dia sem shampoo', description: 'Deixe o cabelo descansar. Lave só com água ou condicionador. Equilíbrio natural.', category: 'cabelo', xp: 20 },
  { title: 'Penteie com cuidado', description: 'Comece pelas pontas e suba. Evite puxar cabelo molhado para prevenir quebra.', category: 'cabelo', xp: 10 },
  { title: 'Tônica capilar', description: 'Aplique tônica no couro cabeludo para estimular folículos e combater queda.', category: 'cabelo', xp: 25 },
  // Estilo
  { title: 'Monte um look completo', description: 'Combine 3+ peças do seu armário em um look harmonioso. Fotografe e salve.', category: 'estilo', xp: 35 },
  { title: 'Experimente uma cor nova', description: 'Use uma peça em cor que normalmente não escolheria. Saia da zona de conforto.', category: 'estilo', xp: 25 },
  { title: 'Acessorize o look', description: 'Adicione pelo menos 2 acessórios ao look de hoje. Relógio, colar, cinto...', category: 'estilo', xp: 20 },
  { title: 'Organize seu armário', description: 'Separe 30 min para organizar peças por categoria e cor. Visualize melhor.', category: 'estilo', xp: 30 },
  { title: 'Pesquise referências', description: 'Busque 3 referências de estilo no Pinterest/Instagram que combinem com seu perfil.', category: 'estilo', xp: 20 },
  { title: 'Mix de texturas', description: 'Combine peças com texturas diferentes: algodão + couro + tricô, por exemplo.', category: 'estilo', xp: 25 },
  { title: 'Autoestilo do dia', description: 'Tire uma foto do seu look de hoje e avalie: o que funciona? O que mudaria?', category: 'estilo', xp: 15 },
  { title: 'Descubra sua paleta', description: 'Identifique 5 cores que mais combinam com seu tom de pele. Crie sua paleta pessoal.', category: 'estilo', xp: 30 },
  // Bem-estar
  { title: '10 min de meditação', description: 'Respire fundo e medite. Beleza vem de dentro. Reduza o estresse que reflete na pele.', category: 'bem-estar', xp: 20 },
  { title: 'Exercício físico', description: '30 min de qualquer atividade física. Circulação melhora a pele e o humor.', category: 'bem-estar', xp: 30 },
  { title: 'Sono de qualidade', description: 'Durma pelo menos 7h. O corpo regenera pele e cabelo durante o sono profundo.', category: 'bem-estar', xp: 25 },
  { title: 'Alimentação colorida', description: 'Inclua 5 cores diferentes de alimentos nas refeições de hoje. Antioxidantes naturais.', category: 'bem-estar', xp: 20 },
  { title: 'Postura corporal', description: 'Preste atenção à sua postura ao caminhar e sentar. Boa postura transforma a presença.', category: 'bem-estar', xp: 15 },
  { title: 'Digital detox 1h', description: 'Fique 1 hora sem redes sociais. Menos comparação, mais autoestima.', category: 'bem-estar', xp: 25 },
  // Desafio
  { title: 'No-makeup day', description: 'Saia de casa sem maquiagem e sinta-se confiante. Sua beleza natural é única.', category: 'desafio', xp: 40 },
  { title: 'Look monocrômico', description: 'Monte um look todo em uma só cor ou tons similares. Elegância na simplicidade.', category: 'desafio', xp: 35 },
  { title: 'Recrie um look de referência', description: 'Pegue uma inspiração e recrie com peças que você já tem. Criatividade!', category: 'desafio', xp: 40 },
  { title: 'Crie um cápsula de 5 peças', description: 'Selecione 5 peças versáteis que criem pelo menos 10 combinações diferentes.', category: 'desafio', xp: 45 },
  { title: 'Compartilhe seu estilo', description: 'Mande seu look de hoje para um amigo e peça opinião. Feedback é valioso.', category: 'desafio', xp: 30 },
];

// ============================================================
// ACHIEVEMENTS
// ============================================================

export type AchievementDef = {
  id: string;
  title: string;
  description: string;
  icon: string;
  xp: number;
};

export const achievementDefs: AchievementDef[] = [
  { id: 'primeira-atividade', title: 'Primeiro Passo', description: 'Complete sua primeira atividade diária', icon: '🌟', xp: 50 },
  { id: 'streak-3', title: 'Dedicação', description: 'Mantenha um streak de 3 dias', icon: '🔥', xp: 100 },
  { id: 'streak-7', title: 'Semana Perfeita', description: 'Mantenha um streak de 7 dias', icon: '⚡', xp: 200 },
  { id: 'streak-30', title: 'Mês de Ouro', description: 'Mantenha um streak de 30 dias', icon: '👑', xp: 500 },
  { id: '10-atividades', title: 'Em Movimento', description: 'Complete 10 atividades no total', icon: '🎯', xp: 75 },
  { id: '50-atividades', title: 'Estilista em Treino', description: 'Complete 50 atividades no total', icon: '📚', xp: 250 },
  { id: '100-atividades', title: 'Mestre do Estilo', description: 'Complete 100 atividades no total', icon: '🏆', xp: 500 },
  { id: 'primeiro-look', title: 'Criador de Looks', description: 'Monte seu primeiro look completo', icon: '🛍️', xp: 50 },
  { id: 'armario-10', title: 'Guarda-Roupa Ativo', description: 'Cadastre 10 peças no armário', icon: '👕', xp: 100 },
  { id: 'armario-30', title: 'Fashionista', description: 'Cadastre 30 peças no armário', icon: '📦', xp: 200 },
  { id: 'todos-dias', title: 'Dia Perfeito', description: 'Complete todas as atividades de um dia', icon: '⭐', xp: 150 },
  { id: 'explorador', title: 'Explorador', description: 'Visite todas as abas do app em um dia', icon: '🔍', xp: 50 },
  { id: 'meta-semanal', title: 'Focado', description: 'Complete uma meta semanal', icon: '🎯', xp: 100 },
  { id: 'todas-metas', title: 'Semana Produtiva', description: 'Complete todas as metas semanais', icon: '🏆', xp: 300 },
  { id: 'level-5', title: 'Estilista Júnior', description: 'Alcance o nível 5', icon: '🧑‍🥺', xp: 100 },
  { id: 'level-10', title: 'Estilista Sênior', description: 'Alcance o nível 10', icon: '👨‍🎨', xp: 250 },
  { id: 'level-25', title: 'Guru da Beleza', description: 'Alcance o nível 25', icon: '🌹', xp: 500 },
  { id: 'orçamento-sabio', title: 'Orçamento Sábio', description: 'Explore 5 recomendações de produtos', icon: '💰', xp: 75 },
  { id: 'rotina-completa', title: 'Rotina Impecável', description: 'Complete toda a rotina de cuidados 3 dias seguidos', icon: '✨', xp: 150 },
  { id: 'share-look', title: 'Influenciador', description: 'Compartilhe um look com amigos', icon: '📢', xp: 100 },
];

// ============================================================
// WEEKLY GOALS TEMPLATES
// ============================================================

export type WeeklyGoalTemplate = {
  id: string;
  title: string;
  target: number;
  unit: string;
  xp: number;
  category: 'pele' | 'cabelo' | 'estilo' | 'bem-estar';
};

export const weeklyGoalTemplates: WeeklyGoalTemplate[] = [
  { id: 'wg-rotina', title: 'Completar rotina de cuidados', target: 5, unit: 'dias', xp: 100, category: 'pele' },
  { id: 'wg-hidratacao', title: 'Bebber 2L de água', target: 5, unit: 'dias', xp: 80, category: 'bem-estar' },
  { id: 'wg-looks', title: 'Montar looks criativos', target: 3, unit: 'looks', xp: 120, category: 'estilo' },
  { id: 'wg-tratamento', title: 'Tratamentos capilares', target: 2, unit: 'sessões', xp: 80, category: 'cabelo' },
  { id: 'wg-exercicio', title: 'Exercício físico', target: 4, unit: 'dias', xp: 100, category: 'bem-estar' },
  { id: 'wg-armario', title: 'Adicionar peças ao armário', target: 5, unit: 'peças', xp: 80, category: 'estilo' },
  { id: 'wg-protetor', title: 'Usar protetor solar', target: 7, unit: 'dias', xp: 120, category: 'pele' },
  { id: 'wg-sono', title: 'Dormir 7h+ por noite', target: 5, unit: 'noites', xp: 100, category: 'bem-estar' },
];

// ============================================================
// REGIONAL PRODUCT RECOMMENDATIONS
// ============================================================

export type RegionalProduct = {
  id: string;
  name: string;
  brand: string;
  category: 'pele' | 'cabelo' | 'maquiagem' | 'fragrância' | 'acessório';
  price: number;
  currency: string;
  region: string;
  store: string;
  rating: number;
  description: string;
  skinType?: string[];
  hairType?: string[];
  budgetLevel: 'economico' | 'moderado' | 'premium' | 'luxo';
};

export const regionalProducts: RegionalProduct[] = [
  // São Paulo
  { id: 'sp-1', name: 'FPS Solar Fluid 50', brand: 'La Roche-Posay', category: 'pele', price: 89.90, currency: 'R$', region: 'São Paulo, BR', store: 'Drogasil', rating: 4.8, description: 'Protetor solar fluido toque seco, ideal para pele oleosa e mista. Proteção UVA/UVB alta com cor vitamina E.', skinType: ['oleosa', 'mista'], budgetLevel: 'moderado' },
  { id: 'sp-2', name: 'Shampoo Hidratação Profunda', brand: 'Seda', category: 'cabelo', price: 24.90, currency: 'R$', region: 'São Paulo, BR', store: 'Mercado Livre', rating: 4.5, description: 'Fórmula com óleo de argan para cabelos cacheados e crespos. Hidratação intensa.', hairType: ['cacheado', 'crespo', 'afro'], budgetLevel: 'economico' },
  { id: 'sp-3', name: 'Sérum Vitamina C 15%', brand: 'Skinceuticals', category: 'pele', price: 389.00, currency: 'R$', region: 'São Paulo, BR', store: 'Farmácia Raia', rating: 4.9, description: 'Sérum antioxidante com 15% de ácido L-ascórbico puro. Ilumina e uniformiza o tom.', budgetLevel: 'luxo' },
  { id: 'sp-4', name: 'Batom Líquido Matte', brand: 'MAC', category: 'maquiagem', price: 129.00, currency: 'R$', region: 'São Paulo, BR', store: 'Sephora', rating: 4.7, description: 'Acabamento matte longa duração. Fórmula confortável com pigmentação intensa.', budgetLevel: 'premium' },
  { id: 'sp-5', name: 'Óleo Capilar Marroquino', brand: 'Moroccanoil', category: 'cabelo', price: 219.00, currency: 'R$', region: 'São Paulo, BR', store: 'Bottega Verde', rating: 4.8, description: 'Tratamento com óleo de argan e vitaminas. Brilho instantâneo sem pesar.', hairType: ['liso', 'ondulado', 'cacheado'], budgetLevel: 'premium' },

  // Rio de Janeiro
  { id: 'rj-1', name: 'Protetor Solar Toque Seco', brand: 'Neutrogena', category: 'pele', price: 59.90, currency: 'R$', region: 'Rio de Janeiro, BR', store: 'Pague Menos', rating: 4.6, description: 'FPS 70 toque seco, perfeito para clima tropical e praia. Não deixa a pele oleosa.', skinType: ['oleosa', 'mista', 'normal'], budgetLevel: 'economico' },
  { id: 'rj-2', name: 'Máscara Capilar Tropical', brand: 'O Boticário', category: 'cabelo', price: 49.90, currency: 'R$', region: 'Rio de Janeiro, BR', store: 'O Boticário', rating: 4.5, description: 'Máscara com óleo de coco e manteiga de karitê. Recupera cabelos danificados pelo sol.', hairType: ['cacheado', 'crespo', 'afro', 'ondulado'], budgetLevel: 'moderado' },
  { id: 'rj-3', name: 'Água Micelar Bio', brand: 'Bioderma', category: 'pele', price: 79.90, currency: 'R$', region: 'Rio de Janeiro, BR', store: 'Drogaria São Paulo', rating: 4.7, description: 'Remove impurezas e maquiagem sem enxágue. Respeita o equilíbrio da pele.', budgetLevel: 'moderado' },

  // Brasília
  { id: 'bsb-1', name: 'Hidratante Facial com FPS', brand: 'Eucerin', category: 'pele', price: 119.00, currency: 'R$', region: 'Brasília, BR', store: 'Farmácia Popular', rating: 4.6, description: 'Hidratante com proteção solar FPS 30 e ácido hialurônico. Clima seco de Brasília pede hidratação extra.', skinType: ['seca', 'sensivel', 'normal'], budgetLevel: 'moderado' },
  { id: 'bsb-2', name: 'Creme de Mãos Premium', brand: 'L’Occitane', category: 'pele', price: 89.00, currency: 'R$', region: 'Brasília, BR', store: 'L’Occitane', rating: 4.8, description: 'Manteiga de karité 20%. Para mãos ressecadas pelo clima seco. Absorção rápida.', budgetLevel: 'premium' },

  // Salvador
  { id: 'ss-1', name: 'Bloqueador Solar Coral', brand: 'Coral', category: 'pele', price: 34.90, currency: 'R$', region: 'Salvador, BR', store: 'Bahia Farmácia', rating: 4.4, description: 'FPS 50 resistente à água e suor. Essencial para clima tropical e praia.', skinType: ['oleosa', 'mista', 'normal'], budgetLevel: 'economico' },
  { id: 'ss-2', name: 'Óleo para Cabelos Étnicos', brand: 'Akata', category: 'cabelo', price: 54.90, currency: 'R$', region: 'Salvador, BR', store: 'Akata', rating: 4.9, description: 'Blend de óleos naturais para cabelos crespos e afros. Definição e brilho.', hairType: ['crespo', 'afro', 'locks'], budgetLevel: 'moderado' },
  { id: 'ss-3', name: 'Base Fluida Matte', brand: 'NARS', category: 'maquiagem', price: 299.00, currency: 'R$', region: 'Salvador, BR', store: 'Sephora', rating: 4.8, description: 'Cobertura média com acabamento matte natural. 30 tons para todos os tons de pele.', budgetLevel: 'luxo' },

  // Lisboa
  { id: 'lx-1', name: 'Creme Hidratante Universal', brand: 'Caudalie', category: 'pele', price: 39.90, currency: '€', region: 'Lisboa, PT', store: 'El Corte Inglés', rating: 4.7, description: 'Hidratante com uva vinífera e ácido hialurônico. Textura leve para clima temperado.', budgetLevel: 'moderado' },
  { id: 'lx-2', name: 'Perfume Essence Pure', brand: 'Zara', category: 'fragrância', price: 19.99, currency: '€', region: 'Lisboa, PT', store: 'Zara', rating: 4.3, description: 'Fragrância fresca e floral, perfeita para o dia-a-dia europeu. Notas de jasmim e almíscar.', budgetLevel: 'economico' },
  { id: 'lx-3', name: 'Sérum Retinol 0.3%', brand: 'The Ordinary', category: 'pele', price: 12.90, currency: '€', region: 'Lisboa, PT', store: 'Lookfantastic', rating: 4.6, description: 'Retinol puro em base de squalane. Anti-idade acessível e eficaz. Comece 2x por semana.', budgetLevel: 'economico' },
  { id: 'lx-4', name: 'Máscara Capilar Reparadora', brand: 'Kérastase', category: 'cabelo', price: 42.00, currency: '€', region: 'Lisboa, PT', store: 'Sephora', rating: 4.9, description: 'Tratamento profissional para cabelos danificados. Reconstrói a fibra capilar.', budgetLevel: 'luxo' },

  // Porto
  { id: 'por-1', name: 'Protetor Solar Invisible', brand: 'ISDIN', category: 'pele', price: 29.90, currency: '€', region: 'Porto, PT', store: 'Farmácia Portuguesa', rating: 4.8, description: 'Ecran solar facial transparente FPS 50+. Toque seco, sem resíduos brancos.', budgetLevel: 'moderado' },
  { id: 'por-2', name: 'Chapéu Fedora Clássico', brand: 'Lock & Co.', category: 'acessório', price: 65.00, currency: '€', region: 'Porto, PT', store: 'Lock & Co.', rating: 4.5, description: 'Chapéu em feltro de lã. Protege do sol e eleva qualquer look casual com elegância europeia.', budgetLevel: 'premium' },

  // Luanda
  { id: 'lad-1', name: 'Óleo de Palma Capilar', brand: 'Djigui', category: 'cabelo', price: 3500, currency: 'Kz', region: 'Luanda, AO', store: 'Supermercado Kero', rating: 4.3, description: 'Óleo natural para cabelos afros e crespos. Hidratação profunda e brilho.', hairType: ['crespo', 'afro', 'locks'], budgetLevel: 'economico' },
  { id: 'lad-2', name: 'Creme Hidratante Clarins', brand: 'Clarins', category: 'pele', price: 18500, currency: 'Kz', region: 'Luanda, AO', store: 'Shopalma', rating: 4.7, description: 'Hidratante facial para clima tropical. Proteção e luminosidade para todos os tons de pele.', budgetLevel: 'luxo' },

  // Maputo
  { id: 'mpz-1', name: 'Manteiga de Karité Pura', brand: 'SheaMoisture', category: 'pele', price: 450, currency: 'MZN', region: 'Maputo, MZ', store: 'Shoprite', rating: 4.6, description: 'Manteiga de karité 100% natural. Hidratação intensa para pele e cabelo.', budgetLevel: 'economico' },
  { id: 'mpz-2', name: 'Perfume CLASSIC', brand: 'Club de Nuit', category: 'fragrância', price: 1200, currency: 'MZN', region: 'Maputo, MZ', store: 'Perfumaria Maputo', rating: 4.4, description: 'Fragrância sofisticada com notas amadeiradas e cítricas. Presença marcante.', budgetLevel: 'moderado' },

  // Belo Horizonte
  { id: 'bh-1', name: 'Sabonete Esfoliante', brand: 'Aesop', category: 'pele', price: 159.00, currency: 'R$', region: 'Belo Horizonte, BR', store: 'Aesop', rating: 4.8, description: 'Esfoliante com sementes de apricot e lavanda. Limpa e renova a pele suavemente.', budgetLevel: 'premium' },

  // Curitiba
  { id: 'cw-1', name: 'Hidratante Labial FPS', brand: 'Nivea', category: 'pele', price: 19.90, currency: 'R$', region: 'Curitiba, BR', store: 'Farmácia Araújo', rating: 4.5, description: 'Bálsamo labial com FPS 15 e manteiga de karité. Essencial para frio.', budgetLevel: 'economico' },
  { id: 'cw-2', name: 'Cachecol de Cashmere', brand: 'Farm Rio', category: 'acessório', price: 189.00, currency: 'R$', region: 'Curitiba, BR', store: 'Farm Rio', rating: 4.6, description: 'Cachecol em cashmere com estampa exclusiva. Aquece com estilo no frio.', budgetLevel: 'premium' },

  // Porto Alegre
  { id: 'poa-1', name: 'Creme de Mãos com FPS', brand: 'Garnier', category: 'pele', price: 29.90, currency: 'R$', region: 'Porto Alegre, BR', store: 'Drogaria Farma', rating: 4.4, description: 'Creme para mãos ressecadas com proteção solar. Clima frio resseca as mãos.', budgetLevel: 'economico' },

  // Recife
  { id: 'rec-1', name: 'Spray Fixador de Maquiagem', brand: 'Urban Decay', category: 'maquiagem', price: 169.00, currency: 'R$', region: 'Recife, BR', store: 'Sephora', rating: 4.7, description: 'Fixador all-nighter. Mantém a maquiagem intacta mesmo no calor tropical.', budgetLevel: 'premium' },
  { id: 'rec-2', name: 'Tônico Adstringente', brand: 'Vichy', category: 'pele', price: 89.90, currency: 'R$', region: 'Recife, BR', store: 'Drogasil', rating: 4.6, description: 'Tônico para pele oleosa no calor. Controla brilho e minimiza poros.', skinType: ['oleosa', 'mista'], budgetLevel: 'moderado' },

  // Fortaleza
  { id: 'for-1', name: 'Óleo Solar Corporal', brand: 'Hawaiian Tropic', category: 'pele', price: 44.90, currency: 'R$', region: 'Fortaleza, BR', store: 'Pague Menos', rating: 4.5, description: 'Bronzeador com FPS 15 e óleo de tamanu. Protege enquanto bronzeia.', budgetLevel: 'economico' },

  // Manaus
  { id: 'mn-1', name: 'Pó Compacto Translúcido', brand: 'Dior', category: 'maquiagem', price: 399.00, currency: 'R$', region: 'Manaus, BR', store: 'Dior', rating: 4.9, description: 'Pó translúcido que controla oleosidade no calor. Acabamento matte natural.', budgetLevel: 'luxo' },
];

// ============================================================
// HELPER: Get products for a region
// ============================================================

export function getProductsForRegion(region: string, budget?: string, skinTypes?: string[], hairType?: string[]): RegionalProduct[] {
  let products = regionalProducts.filter((p) => p.region === region);

  // If no products for exact region, show all as fallback
  if (products.length === 0) {
    products = [...regionalProducts];
  }

  // Filter by budget
  if (budget) {
    const budgetOrder = ['economico', 'moderado', 'premium', 'luxo'];
    const userBudgetIdx = budgetOrder.indexOf(budget);
    if (userBudgetIdx >= 0) {
      products = products.filter((p) => {
        const pIdx = budgetOrder.indexOf(p.budgetLevel);
        return pIdx <= userBudgetIdx + 1;
      });
    }
  }

  // Filter by skin type compatibility
  if (skinTypes && skinTypes.length > 0) {
    const skinFiltered = products.filter((p) => {
      if (!p.skinType || p.skinType.length === 0) return true;
      return p.skinType.some((st) => skinTypes.includes(st));
    });
    if (skinFiltered.length > 0) products = skinFiltered;
  }

  // Filter by hair type compatibility
  if (hairType) {
    const hairFiltered = products.filter((p) => {
      if (!p.hairType || p.hairType.length === 0) return true;
      return p.hairType.includes(hairType);
    });
    if (hairFiltered.length > 0) products = hairFiltered;
  }

  return products.sort((a, b) => b.rating - a.rating);
}

// ============================================================
// ACTIVITY CATEGORY CONFIG
// ============================================================

export const activityCategoryConfig: Record<string, { label: string; color: string; emoji: string }> = {
  'pele': { label: 'Pele', color: 'from-blue-500/20 to-teal-500/20', emoji: '🧴' },
  'cabelo': { label: 'Cabelo', color: 'from-gold/20 to-orange-500/20', emoji: '💇' },
  'estilo': { label: 'Estilo', color: 'from-primary/10 to-primary-glow/10', emoji: '👗' },
  'bem-estar': { label: 'Bem-estar', color: 'from-green-500/20 to-emerald-500/20', emoji: '🧘' },
  'desafio': { label: 'Desafio', color: 'from-purple-500/20 to-pink-500/20', emoji: '🎯' },
};

export const productCategoryConfig: Record<string, { label: string; emoji: string }> = {
  'pele': { label: 'Pele', emoji: '🧴' },
  'cabelo': { label: 'Cabelo', emoji: '💇' },
  'maquiagem': { label: 'Maquiagem', emoji: '💄' },
  'fragrância': { label: 'Fragrância', emoji: '🌸' },
  'acessório': { label: 'Acessório', emoji: '🕶️' },
};