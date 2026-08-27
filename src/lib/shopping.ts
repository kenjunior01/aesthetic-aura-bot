/**
 * AuraStyle — Consultor de Compras (dados + heurística local)
 *
 * Cenário real: o usuário está numa loja/supermercado, tem um orçamento X,
 * vê vários produtos e precisa saber:
 *   1. Em que ordem de prioridade comprar com o dinheiro disponível;
 *   2. Quais marcas acessíveis existem no SEU país;
 *   3. Pode tirar uma foto da prateleira para o app ler os produtos.
 *
 * Tudo aqui funciona offline (heurística local) e é enriquecido por IA
 * na rota /api/shopping-advisor quando disponível.
 */

// ============================================================
// 1. PAÍSES E MOEDAS (detecção por fuso horário no cliente)
// ============================================================

export type CountryInfo = {
  code: string;
  name: string;
  currency: string;
  symbol: string;
  timezones: string[];
};

export const COUNTRIES: CountryInfo[] = [
  { code: 'AO', name: 'Angola', currency: 'AOA', symbol: 'Kz', timezones: ['Africa/Luanda'] },
  { code: 'MZ', name: 'Moçambique', currency: 'MZN', symbol: 'MT', timezones: ['Africa/Maputo'] },
  { code: 'PT', name: 'Portugal', currency: 'EUR', symbol: '€', timezones: ['Europe/Lisbon', 'Atlantic/Azores', 'Atlantic/Madeira'] },
  { code: 'BR', name: 'Brasil', currency: 'BRL', symbol: 'R$', timezones: ['America/Sao_Paulo', 'America/Bahia', 'America/Fortaleza', 'America/Manaus', 'America/Belem', 'America/Recife', 'America/Rio_Branco'] },
  { code: 'CV', name: 'Cabo Verde', currency: 'CVE', symbol: '$', timezones: ['Atlantic/Cape_Verde'] },
  { code: 'GW', name: 'Guiné-Bissau', currency: 'XOF', symbol: 'CFA', timezones: ['Africa/Bissau'] },
  { code: 'ST', name: 'São Tomé e Príncipe', currency: 'STN', symbol: 'Db', timezones: ['Africa/Sao_Tome'] },
  { code: 'NG', name: 'Nigéria', currency: 'NGN', symbol: '₦', timezones: ['Africa/Lagos'] },
  { code: 'ZA', name: 'África do Sul', currency: 'ZAR', symbol: 'R', timezones: ['Africa/Johannesburg'] },
  { code: 'NA', name: 'Namíbia', currency: 'NAD', symbol: 'N$', timezones: ['Africa/Windhoek'] },
  { code: 'KE', name: 'Quénia', currency: 'KES', symbol: 'KSh', timezones: ['Africa/Nairobi'] },
  { code: 'GH', name: 'Gana', currency: 'GHS', symbol: '₵', timezones: ['Africa/Accra'] },
  { code: 'CM', name: 'Camarões', currency: 'XAF', symbol: 'FCFA', timezones: ['Africa/Douala'] },
  { code: 'CI', name: 'Costa do Marfim', currency: 'XOF', symbol: 'CFA', timezones: ['Africa/Abidjan'] },
  { code: 'SN', name: 'Senegal', currency: 'XOF', symbol: 'CFA', timezones: ['Africa/Dakar'] },
  { code: 'FR', name: 'França', currency: 'EUR', symbol: '€', timezones: ['Europe/Paris'] },
  { code: 'ES', name: 'Espanha', currency: 'EUR', symbol: '€', timezones: ['Europe/Madrid', 'Atlantic/Canary'] },
  { code: 'US', name: 'Estados Unidos', currency: 'USD', symbol: '$', timezones: ['America/New_York', 'America/Chicago', 'America/Los_Angeles', 'America/Denver'] },
];

export const GENERIC_COUNTRY: CountryInfo = {
  code: 'XX',
  name: 'Internacional',
  currency: 'USD',
  symbol: '$',
  timezones: [],
};

/** Detecta o país pelo fuso horário do dispositivo (client-side). */
export function detectCountry(): CountryInfo {
  if (typeof window === 'undefined') return GENERIC_COUNTRY;
  try {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const found = COUNTRIES.find((c) => c.timezones.includes(tz));
    return found || GENERIC_COUNTRY;
  } catch {
    return GENERIC_COUNTRY;
  }
}

/** Resolve país a partir do perfil (campo country = código) com fallback de detecção. */
export function resolveCountry(countryCode?: string): CountryInfo {
  const byCode = COUNTRIES.find((c) => c.code === countryCode);
  if (byCode) return byCode;
  if (countryCode) {
    const byName = COUNTRIES.find(
      (c) => c.name.toLowerCase() === countryCode.toLowerCase(),
    );
    if (byName) return byName;
  }
  return detectCountry();
}

export function formatMoney(value: number, country: CountryInfo): string {
  const rounded = Math.round(value * 100) / 100;
  return `${country.symbol} ${rounded.toLocaleString('pt-PT', { maximumFractionDigits: 2 })}`;
}

// ============================================================
// 2. MARCAS ACESSÍVEIS POR PAÍS (encontradas em supermercados)
// ============================================================

export type BrandRec = {
  name: string;
  domain: 'cabelo' | 'pele' | 'ambos';
  why: string;
  priceLevel: 1 | 2; // 1 = muito acessível, 2 = acessível
};

/**
 * Marcas econômicas reais, amplamente distribuídas em farmácias e
 * supermercados de cada país. priceLevel 1 = entrada, 2 = intermediário.
 */
export const AFFORDABLE_BRANDS: Record<string, BrandRec[]> = {
  AO: [
    { name: 'Nuvel', domain: 'cabelo', why: 'Marca angolana, ampla linha de cremes de pentear e tratamento, preço de entrada', priceLevel: 1 },
    { name: 'Kanechom', domain: 'cabelo', why: 'Cremes de tratamento grandes e baratos, ótimo custo-benefício', priceLevel: 1 },
    { name: 'Seda', domain: 'cabelo', why: 'Fácil de encontrar, linhas para cada tipo de cabelo', priceLevel: 1 },
    { name: 'Niely', domain: 'cabelo', why: 'Coloração e tratamento com preço baixo', priceLevel: 1 },
    { name: 'Novex', domain: 'cabelo', why: 'Máscaras grandes com preço acessível', priceLevel: 2 },
    { name: 'Vasenol', domain: 'pele', why: 'Linha de hidratação corporal barata e comum em Angola', priceLevel: 1 },
    { name: 'Nivea', domain: 'pele', why: 'Base acessível e confiável para hidratação diária', priceLevel: 2 },
    { name: 'Dove', domain: 'ambos', why: 'Sabonetes e shampoos suaves, preço justo', priceLevel: 2 },
  ],
  MZ: [
    { name: 'Seda', domain: 'cabelo', why: 'Barata e presente nos supermercados (Shoprite/Game)', priceLevel: 1 },
    { name: 'Kanechom', domain: 'cabelo', why: 'Tratamento em tubo grande, preço de entrada', priceLevel: 1 },
    { name: 'Sunsilk', domain: 'cabelo', why: 'Shampoos econômicos para uso diário', priceLevel: 1 },
    { name: 'Dark & Lovely', domain: 'cabelo', why: 'Linha para cabelo relaxado/química, preço médio-baixo', priceLevel: 2 },
    { name: 'Nivea', domain: 'pele', why: 'Hidratantes acessíveis e fáceis de encontrar', priceLevel: 2 },
    { name: 'Vaseline', domain: 'pele', why: 'Petroleum jelly barato para corpo e lábios', priceLevel: 1 },
    { name: 'Dove', domain: 'ambos', why: 'Suave para pele e cabelo, preço justo', priceLevel: 2 },
  ],
  PT: [
    { name: 'Kanechom', domain: 'cabelo', why: 'Tubos grandes de tratamento, muito econômico', priceLevel: 1 },
    { name: 'Salon Line', domain: 'cabelo', why: 'Referência para cachos com preço baixo', priceLevel: 1 },
    { name: 'Elseve', domain: 'cabelo', why: 'Linhas completas (reparação, liso) com preço acessível', priceLevel: 2 },
    { name: 'Fructis', domain: 'cabelo', why: 'Garnier Fructis: bom preço e fácil de encontrar', priceLevel: 1 },
    { name: 'Cien', domain: 'ambos', why: 'Marca Lidl: custo mínimo para base de rotina', priceLevel: 1 },
    { name: 'Nivea', domain: 'pele', why: 'Clássico acessível de farmácia', priceLevel: 2 },
    { name: 'Simple', domain: 'pele', why: 'Limpeza facial suave com preço amigo', priceLevel: 2 },
  ],
  BR: [
    { name: 'Seda', domain: 'cabelo', why: 'Custo-benefício clássico, todas as linhas', priceLevel: 1 },
    { name: 'Niely', domain: 'cabelo', why: 'Preço baixo e boa performance', priceLevel: 1 },
    { name: 'Novex', domain: 'cabelo', why: 'Máscaras em potes grandes e baratos', priceLevel: 1 },
    { name: 'Haskell', domain: 'cabelo', why: 'Linha completa profissional com preço popular', priceLevel: 2 },
    { name: 'Salon Line', domain: 'cabelo', why: 'Curly girl acessível (cremes e ativos)', priceLevel: 1 },
    { name: 'Nivea', domain: 'pele', why: 'Hidratante facial/corporal barato', priceLevel: 1 },
    { name: 'Pond\u2019s', domain: 'pele', why: 'Cremes faciais econômicos', priceLevel: 1 },
    { name: 'Dove', domain: 'ambos', why: 'Suavidade com preço justo', priceLevel: 2 },
  ],
  NG: [
    { name: 'Sunsilk', domain: 'cabelo', why: 'Shampoos econômicos em qualquer mercado', priceLevel: 1 },
    { name: 'Darling', domain: 'cabelo', why: 'Linha popular para cabelo natural e tranças', priceLevel: 1 },
    { name: 'Nivea', domain: 'pele', why: 'Amplamente disponível e acessível', priceLevel: 2 },
    { name: 'Vaseline', domain: 'pele', why: 'Lotions baratos para o corpo', priceLevel: 1 },
    { name: 'Dove', domain: 'ambos', why: 'Suave e confiável, preço médio-baixo', priceLevel: 2 },
  ],
  ZA: [
    { name: 'TRESemmé', domain: 'cabelo', why: 'Garrafas grandes com preço justo (Clicks/PnP)', priceLevel: 2 },
    { name: 'Dark & Lovely', domain: 'cabelo', why: 'Linha completa para cabelo natural/relaxado', priceLevel: 2 },
    { name: 'Darling', domain: 'cabelo', why: 'Preço de entrada para uso diário', priceLevel: 1 },
    { name: 'Nivea', domain: 'pele', why: 'Hidratação acessível em qualquer farmácia', priceLevel: 2 },
    { name: 'Vaseline', domain: 'pele', why: 'Intensive care com preço baixo', priceLevel: 1 },
    { name: 'Pond\u2019s', domain: 'pele', why: 'Cremes faciais econômicos', priceLevel: 2 },
  ],
  XX: [
    { name: 'Seda', domain: 'cabelo', why: 'Econômica e difundida em vários países', priceLevel: 1 },
    { name: 'Dove', domain: 'ambos', why: 'Suave para pele e cabelo, preço justo', priceLevel: 2 },
    { name: 'Nivea', domain: 'pele', why: 'Hidratação básica confiável', priceLevel: 2 },
    { name: 'Vaseline', domain: 'pele', why: 'Barato para corpo e lábios', priceLevel: 1 },
    { name: 'Garnier Fructis', domain: 'cabelo', why: 'Bom preço, fácil de encontrar', priceLevel: 1 },
  ],
};

export function brandsForCountry(country: CountryInfo): BrandRec[] {
  return AFFORDABLE_BRANDS[country.code] || AFFORDABLE_BRANDS.XX;
}

// ============================================================
// 3. CATEGORIAS DE PRODUTOS E PRIORIDADE CIENTÍFICA
// ============================================================

export type ProductDomain = 'cabelo' | 'pele' | 'outro';

export type ProductCategory =
  | 'shampoo' | 'condicionador' | 'mascara' | 'creme-pentear' | 'oleo'
  | 'proteina' | 'leave-in' | 'limpeza-facial' | 'hidratante'
  | 'protetor-solar' | 'tratamento' | 'estilizacao' | 'outro';

export type ParsedProduct = {
  name: string;
  brand?: string;
  price?: number;
  category: ProductCategory;
  domain: ProductDomain;
};

const CATEGORY_PATTERNS: { category: ProductCategory; re: RegExp }[] = [
  { category: 'shampoo', re: /shampoo|champu|champô|poo|co.wash|cowash/i },
  { category: 'condicionador', re: /condicionad|condicioner|acondicionador/i },
  { category: 'mascara', re: /m[áa]scara|mascara|tratamento|reconstru|hidrata[cç][ãa]o capilar|banho de geladeira|ampola/i },
  { category: 'proteina', re: /prote[íi]na|reconstrutor|keratina|queratina|col[áa]geno|amino[áa]cido/i },
  { category: 'creme-pentear', re: /creme de pentear|creme pentear|leave.?in|leavein|modelador|day after/i },
  { category: 'oleo', re: /[óo]leo|oleo|oil|umecta|selante/i },
  { category: 'leave-in', re: /leave|sem enx[áa]guague|sem enxague|spray desembara/i },
  { category: 'estilizacao', re: /gel|pomada|cera|mousse|spray fixad|.finalizador/i },
  { category: 'protetor-solar', re: /protetor|solar|spf|fps|sunscreen/i },
  { category: 'limpeza-facial', re: /sabonete facial|limpeza|lavagem facial|micelar|[tóo]nico|esfoliante/i },
  { category: 'hidratante', re: /hidratante|moisturizer|creme facial|lo[cç][ãa]o|corporal/i },
  { category: 'tratamento', re: /s[ée]rum|serum|[áa]cido|retinol|vitamina c|niacinamida|anti.?acne/i },
];

export function detectCategory(name: string): { category: ProductCategory; domain: ProductDomain } {
  for (const { category, re } of CATEGORY_PATTERNS) {
    if (re.test(name)) {
      const domain: ProductDomain = [
        'shampoo', 'condicionador', 'mascara', 'creme-pentear', 'oleo', 'proteina', 'leave-in', 'estilizacao',
      ].includes(category) ? 'cabelo' : 'pele';
      return { category, domain };
    }
  }
  // Sem categoria clara: decide pelo nome genérico
  if (/cabelo|capilar|hair/i.test(name)) return { category: 'outro', domain: 'cabelo' };
  if (/pele|facial|rosto|skin/i.test(name)) return { category: 'outro', domain: 'pele' };
  return { category: 'outro', domain: 'outro' };
}

/**
 * Ordem científica de necessidade — o que faz diferença primeiro.
 * 1 = essencial (compra primeiro), 5 = refinamento (compra depois).
 */
export const NECESSITY: Record<ProductCategory, { rank: number; label: string }> = {
  // Cabelo: limpeza certa → selagem → tratamento → proteção diária → selante/estética
  'shampoo': { rank: 1, label: 'Base da rotina: limpeza sem agredir' },
  'condicionador': { rank: 2, label: 'Selagem e desembaraço após a limpeza' },
  'mascara': { rank: 3, label: 'Tratamento profundo que muda o jogo' },
  'proteina': { rank: 3, label: 'Reconstrução contra quebra' },
  'creme-pentear': { rank: 4, label: 'Proteção e definição no dia a dia' },
  'leave-in': { rank: 4, label: 'Proteção diária sem enxágue' },
  'oleo': { rank: 5, label: 'Selante final — refinamento' },
  'estilizacao': { rank: 5, label: 'Fixação e acabamento' },
  // Pele: limpeza → hidratação → sol → tratamento
  'limpeza-facial': { rank: 1, label: 'Começar por pele limpa' },
  'hidratante': { rank: 2, label: 'Barreira saudável antes de qualquer ativo' },
  'protetor-solar': { rank: 3, label: 'Protege o investimento de toda a rotina' },
  'tratamento': { rank: 4, label: 'Ativos só depois da base estável' },
  'outro': { rank: 4, label: 'Complemento da rotina' },
};

export type BudgetItem = {
  name: string;
  brand?: string;
  price: number;
  category: ProductCategory;
  domain: ProductDomain;
  priority: number;
  verdict: 'comprar' | 'depois';
  reason: string;
};

export type BudgetPlan = {
  items: BudgetItem[];
  totalInside: number;
  totalAll: number;
  advice: string;
  source: 'gemini' | 'zai' | 'local';
  model?: string;
};

/**
 * Heurística local (offline): ordena por necessidade científica, pondera
 * pelos problemas do perfil e pela ordem de prioridades do usuário e
 * encaixa o orçamento de forma gulosa (mais necessário primeiro).
 */
export function localPrioritize(
  products: { name: string; brand?: string; price?: number }[],
  budget: number,
  profile: { priorities?: string[]; hairType?: string; hairIssues?: string[]; skinTypes?: string[] },
  currency: CountryInfo,
): BudgetPlan {
  const priorities = profile.priorities || [];
  const domainWeight = (d: ProductDomain): number => {
    const pIdx = priorities.findIndex(
      (p) => (p === 'cabelo' && d === 'cabelo') || (p === 'pele' && d === 'pele'),
    );
    if (pIdx >= 0) return -100 * (priorities.length - pIdx); // prioridade do usuário domina
    if (d === 'outro') return 40;
    return 0;
  };

  const hairIssues = (profile.hairIssues || []).join(' ').toLowerCase();
  const issueBoost = (item: { category: ProductCategory; domain: ProductDomain }): number => {
    if (item.domain !== 'cabelo') return 0;
    if (/quebr|poro|elast/i.test(hairIssues) && item.category === 'proteina') return -12;
    if (/seco|ressec|opac/i.test(hairIssues) && (item.category === 'mascara' || item.category === 'oleo')) return -10;
    if (/cach|ond|crespo/i.test(hairIssues) && item.category === 'creme-pentear') return -10;
    if (/caspa|oleos|sebo/i.test(hairIssues) && item.category === 'shampoo') return -8;
    return 0;
  };

  const parsed = products
    .map((p) => {
      const { category, domain } = detectCategory(p.name);
      return { ...p, category, domain };
    })
    .sort((a, b) => {
      const scoreA = NECESSITY[a.category].rank + domainWeight(a.domain) + issueBoost(a);
      const scoreB = NECESSITY[b.category].rank + domainWeight(b.domain) + issueBoost(b);
      if (scoreA !== scoreB) return scoreA - scoreB;
      return (a.price ?? 0) - (b.price ?? 0);
    });

  let totalInside = 0;
  const items: BudgetItem[] = parsed.map((p, i) => {
    const price = p.price ?? 0;
    const fits = price > 0 && totalInside + price <= budget;
    if (fits) totalInside += price;
    const verdict: 'comprar' | 'depois' = fits ? 'comprar' : 'depois';
    return {
      name: p.name,
      brand: p.brand,
      price,
      category: p.category,
      domain: p.domain,
      priority: i + 1,
      verdict,
      reason: NECESSITY[p.category].label,
    };
  });

  const buyCount = items.filter((i) => i.verdict === 'comprar').length;
  const advice = buyCount === 0
    ? `Com ${formatMoney(budget, currency)} nenhum item entra agora. Priorize o mais barato dos essenciais (posição 1 e 2) ou junte mais um pouco.`
    : buyCount === items.length
      ? `Boa notícia: ${formatMoney(budget, currency)} cobre tudo, na ordem certa. Siga da posição 1 para a última.`
      : `Com ${formatMoney(budget, currency)} você garante ${buyCount} de ${items.length} itens. Comece pelas posições "comprar" — o resto entra na próxima compra, sem culpa.`;

  return { items, totalInside, totalAll: parsed.reduce((s, p) => s + (p.price ?? 0), 0), advice, source: 'local' };
}

// ============================================================
// 4. SUGESTÕES DE PRODUTOS-CHAVE POR PERFIL (quando não sabe o que ver)
// ============================================================

export const SHOPPING_LIST_HINTS: { domain: 'cabelo' | 'pele'; label: string; examples: string }[] = [
  { domain: 'cabelo', label: 'Shampoo adequado', examples: 'sem sulfato para cachos / antirresíduo' },
  { domain: 'cabelo', label: 'Condicionador', examples: 'mesma linha do shampoo' },
  { domain: 'cabelo', label: 'Máscara ou proteína', examples: 'hidratação profunda ou reconstrução' },
  { domain: 'cabelo', label: 'Creme de pentear', examples: 'definição para o dia a dia' },
  { domain: 'pele', label: 'Sabonete facial', examples: 'suave, sem sabão' },
  { domain: 'pele', label: 'Hidratante', examples: 'gel-creme para pele mista/oleosa' },
  { domain: 'pele', label: 'Protetor solar', examples: 'FPS 30+ toque seco' },
];
