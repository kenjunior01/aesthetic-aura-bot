/**
 * Motor de comparação com o banco de Referências.
 *
 * Compara os traços medidos do utilizador com os traços canónicos de cada
 * arquétipo e devolve um score 0-100 + comparação traço a traço.
 * Funciona 100% offline (determinístico) — o refinamento narrativo é
 * feito por visão computacional na API, mas nunca é obrigatório.
 */

export const TRAIT_KEYS = [
  'faceShape',
  'jawline',
  'cheekbones',
  'eyeShape',
  'browType',
  'hairTexture',
  'facialHair',
] as const;

export type TraitKey = (typeof TRAIT_KEYS)[number];

export const TRAIT_LABELS: Record<TraitKey, string> = {
  faceShape: 'Formato do rosto',
  jawline: 'Maxilar',
  cheekbones: 'Maçãs do rosto',
  eyeShape: 'Olhos',
  browType: 'Sobrancelhas',
  hairTexture: 'Textura do cabelo',
  facialHair: 'Barba',
};

/** Pesos do matching — somam 100 com o tom de pele (10) */
const WEIGHTS: Record<TraitKey, number> = {
  faceShape: 28,
  jawline: 14,
  cheekbones: 10,
  eyeShape: 8,
  browType: 6,
  hairTexture: 16,
  facialHair: 8,
};

/** Parentesco entre valores — 1 ponto de distância = crédito parcial */
const LADDERS: Record<TraitKey, string[]> = {
  faceShape: ['redondo', 'oval', 'coracao', 'losango', 'quadrado', 'retangular', 'oblongo'],
  jawline: ['suave', 'equilibrado', 'marcado'],
  cheekbones: ['discretos', 'presentes', 'altos'],
  eyeShape: ['amendoados', 'redondos', 'fundos', 'expressivos'],
  browType: ['finos', 'naturais', 'marcados'],
  hairTexture: ['liso', 'ondulado', 'cacheado', 'crespo'],
  facialHair: ['nenhum', 'cavanhaque-suave', 'barba-curta', 'barba-cheia'],
};

/** Traços que o utilizador pode não ter medidos — ganham crédito neutro */
export type MeasuredTraits = Partial<Record<TraitKey, string>> & { skinTone?: number };

function traitScore(key: TraitKey, mine: string | undefined, theirs: string): number {
  const w = WEIGHTS[key];
  if (!mine) return w * 0.55; // desconhecido: crédito neutro parcial
  if (mine === theirs) return w;
  const ladder = LADDERS[key];
  const a = ladder.indexOf(mine);
  const b = ladder.indexOf(theirs);
  if (a === -1 || b === -1) return 0;
  const d = Math.abs(a - b);
  if (d === 1) return w * 0.6;
  if (d === 2) return w * 0.25;
  return 0;
}

function toneScore(mine: number | undefined, center: number): number {
  if (!mine) return 10 * 0.55;
  const d = Math.abs(mine - center);
  return Math.max(0, 10 - d * 1.6);
}

export type RefLook = {
  slug: string;
  name: string;
  tagline: string;
  image: string;
  styleVibe: string;
  signature: string[];
  upgrades: Record<string, { area: string; action: string; why: string }>;
} & Record<TraitKey, string> & { skinToneCenter: number };

export type TraitCompare = {
  key: TraitKey | 'skinTone';
  label: string;
  yours: string;
  theirs: string;
  closeness: number; // 0-1
};

export type LookMatch = {
  slug: string;
  name: string;
  tagline: string;
  image: string;
  score: number; // 0-100
  traits: TraitCompare[];
};

/** Compara o utilizador com todos os arquétipos e devolve o ranking */
export function rankReferences(
  mine: MeasuredTraits,
  refs: RefLook[],
): { matches: LookMatch[]; traits: TraitCompare[] } {
  const scored = refs.map((ref) => {
    let total = 0;
    const traits: TraitCompare[] = TRAIT_KEYS.map((key) => {
      const s = traitScore(key, mine[key], ref[key]);
      total += s;
      const yours = mine[key] || 'não medido';
      return {
        key,
        label: TRAIT_LABELS[key],
        yours,
        theirs: ref[key],
        closeness: WEIGHTS[key] ? s / WEIGHTS[key] : 0,
      };
    });
    const tone = toneScore(mine.skinTone, ref.skinToneCenter);
    total += tone;
    traits.push({
      key: 'skinTone',
      label: 'Tom de pele',
      yours: mine.skinTone ? `Tom ${Math.round(mine.skinTone)}` : 'não medido',
      theirs: `Tom ${ref.skinToneCenter}`,
      closeness: tone / 10,
    });
    return {
      slug: ref.slug,
      name: ref.name,
      tagline: ref.tagline,
      image: ref.image,
      score: Math.round((total / 110) * 100),
      traits,
    };
  });

  scored.sort((a, b) => b.score - a.score);
  const traits = scored[0]?.traits ?? [];
  return { matches: scored, traits };
}

/**
 * Plano de upgrade personalizado: para o arquétipo mais próximo,
 * lista os traços que mais diferem e o que o arquétipo "ensina" sobre eles.
 */
export function buildUpgradePlan(
  match: LookMatch,
  ref: RefLook,
  max = 4,
): { area: string; action: string; why: string; trait: string }[] {
  const differing = match.traits
    .filter((t) => t.key !== 'skinTone')
    .sort((a, b) => a.closeness - b.closeness)
    .slice(0, max);

  const plan: { area: string; action: string; why: string; trait: string }[] = [];
  const seen = new Set<string>();
  for (const t of differing) {
    const specific = ref.upgrades?.[t.key];
    const u = specific || ref.upgrades?.geral;
    if (!u || seen.has(u.action)) continue;
    seen.add(u.action);
    plan.push({ area: u.area, action: u.action, why: u.why, trait: specific ? t.label : 'Base' });
  }
  if (plan.length === 0 && ref.upgrades?.geral) {
    const u = ref.upgrades.geral;
    plan.push({ area: u.area, action: u.action, why: u.why, trait: 'Base' });
  }
  return plan;
}
