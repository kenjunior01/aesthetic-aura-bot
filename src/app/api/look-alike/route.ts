import { NextRequest, NextResponse } from 'next/server';
import { callGroq } from '@/lib/ai-providers';
import { db } from '@/lib/db';
import type { RefLook, MeasuredTraits } from '@/lib/references';
import { rankReferences, buildUpgradePlan } from '@/lib/references';
import { REFERENCE_LOOKS } from '../../../../prisma/references-data';

export const runtime = 'nodejs';
export const maxDuration = 30;

/**
 * POST /api/look-alike — "A quem a minha cara se aproxima?"
 *
 * 1. Lê o banco de referências (Prisma)
 * 2. Mede traços da selfie via visão computacional (se houver imagem);
 *    sem imagem, deriva os traços do perfil
 * 3. Ranking determinístico traço a traço (motor em lib/references)
 * 4. Veredito + plano de upgrade personalizado
 */

const TRAIT_SCHEMA = `{"faceShape":"oval|redondo|quadrado|retangular|coracao|losango|oblongo","jawline":"suave|equilibrado|marcado","cheekbones":"discretos|presentes|altos","eyeShape":"amendoados|redondos|fundos|expressivos","browType":"finos|naturais|marcados","hairTexture":"liso|ondulado|cacheado|crespo","facialHair":"nenhum|cavanhaque-suave|barba-curta|barba-cheia","skinTone":<1-14>,"confidence":<0-1>}`;

/** Converte um seed para o formato do motor (reserva sem banco) */
function seedToRefLook(s: (typeof REFERENCE_LOOKS)[number]): RefLook {
  return {
    slug: s.slug, name: s.name, tagline: s.tagline, image: s.image,
    styleVibe: s.styleVibe, signature: s.signature, upgrades: s.upgrades,
    faceShape: s.faceShape, jawline: s.jawline, cheekbones: s.cheekbones,
    eyeShape: s.eyeShape, browType: s.browType, hairTexture: s.hairTexture,
    facialHair: s.facialHair, skinToneCenter: s.skinToneCenter,
  };
}

function safeJson<T>(text: string): T | null {
  try {
    return JSON.parse(text) as T;
  } catch {
    /* tenta extrair o bloco JSON embutido */
  }
  try {
    const m = text.match(/[\[{][\s\S]*[}\]]/);
    return m ? (JSON.parse(m[0]) as T) : null;
  } catch {
    return null;
  }
}

/** Deriva traços do perfil quando não há visão (fallback offline) */
function traitsFromProfile(profile: Record<string, unknown>): MeasuredTraits {
  const faceMap: Record<string, string> = {
    oval: 'oval', redondo: 'redondo', quadrado: 'quadrado', retangular: 'retangular',
    'coração': 'coracao', coracao: 'coracao', losango: 'losango', diamante: 'losango',
  };
  const hairMap: Record<string, string> = {
    liso: 'liso', ondulado: 'ondulado', cacheado: 'cacheado', crespo: 'crespo',
  };
  const faceShape = faceMap[String(profile.faceShape || '').toLowerCase()];
  const hairTexture = hairMap[String(profile.hairType || '').toLowerCase()];
  const tone10 = Number(profile.skinTone) || 0;
  return {
    faceShape,
    hairTexture,
    // perfil usa escala 1-10 → normaliza para 1-14 do banco
    skinTone: tone10 ? Math.round(tone10 * 1.4) : undefined,
  };
}

/** Limpa traços vindos da visão para os canónicos do motor */
function normalizeVisionTraits(v: Record<string, unknown>): MeasuredTraits {
  const pick = (allowed: string[], value: unknown) =>
    allowed.includes(String(value)) ? String(value) : undefined;
  return {
    faceShape: pick(
      ['oval', 'redondo', 'quadrado', 'retangular', 'coracao', 'losango', 'oblongo'], v.faceShape),
    jawline: pick(['suave', 'equilibrado', 'marcado'], v.jawline),
    cheekbones: pick(['discretos', 'presentes', 'altos'], v.cheekbones),
    eyeShape: pick(['amendoados', 'redondos', 'fundos', 'expressivos'], v.eyeShape),
    browType: pick(['finos', 'naturais', 'marcados'], v.browType),
    hairTexture: pick(['liso', 'ondulado', 'cacheado', 'crespo'], v.hairTexture),
    facialHair: pick(['nenhum', 'cavanhaque-suave', 'barba-curta', 'barba-cheia'], v.facialHair),
    skinTone: Math.min(14, Math.max(1, Math.round(Number(v.skinTone) || 0))) || undefined,
  };
}

export async function GET() {
  try {
    let rows = await db.referenceLook.findMany({ orderBy: { order: 'asc' } });
    if (rows.length === 0) rows = REFERENCE_LOOKS.map((s, i) => ({
      id: s.slug, slug: s.slug, name: s.name, tagline: s.tagline, image: s.image,
      order: s.order ?? i, faceShape: s.faceShape, jawline: s.jawline,
      cheekbones: s.cheekbones, eyeShape: s.eyeShape, browType: s.browType,
      hairTexture: s.hairTexture, facialHair: s.facialHair,
      skinToneCenter: s.skinToneCenter, styleVibe: s.styleVibe,
      signature: JSON.stringify(s.signature), upgrades: JSON.stringify(s.upgrades),
      createdAt: new Date(),
    }));
    return NextResponse.json({
      total: rows.length,
      references: rows.map((r) => ({
        slug: r.slug,
        name: r.name,
        tagline: r.tagline,
        image: r.image,
      })),
    });
  } catch {
    return NextResponse.json({ total: 0, references: [] });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = (await request.json()) as {
      imageBase64?: string;
      profile?: Record<string, unknown>;
    };

    // 1) Banco de referências (Prisma → reserva estática se vazio)
    let rows = await db.referenceLook.findMany({ orderBy: { order: 'asc' } });
    if (rows.length === 0) rows = REFERENCE_LOOKS.map((s, i) => ({
      id: s.slug, slug: s.slug, name: s.name, tagline: s.tagline, image: s.image,
      order: s.order ?? i, faceShape: s.faceShape, jawline: s.jawline,
      cheekbones: s.cheekbones, eyeShape: s.eyeShape, browType: s.browType,
      hairTexture: s.hairTexture, facialHair: s.facialHair,
      skinToneCenter: s.skinToneCenter, styleVibe: s.styleVibe,
      signature: JSON.stringify(s.signature), upgrades: JSON.stringify(s.upgrades),
      createdAt: new Date(),
    }));
    const refs: RefLook[] = rows.map((r) => ({
      slug: r.slug,
      name: r.name,
      tagline: r.tagline,
      image: r.image,
      styleVibe: r.styleVibe,
      signature: safeJson<string[]>(r.signature) || [],
      upgrades: safeJson<Record<string, { area: string; action: string; why: string }>>(r.upgrades) || {},
      faceShape: r.faceShape,
      jawline: r.jawline,
      cheekbones: r.cheekbones,
      eyeShape: r.eyeShape,
      browType: r.browType,
      hairTexture: r.hairTexture,
      facialHair: r.facialHair,
      skinToneCenter: r.skinToneCenter,
    }));

    // 2) Medição dos traços — visão → fallback perfil
    let measured: MeasuredTraits = traitsFromProfile(body.profile || {});
    let source: 'vision' | 'profile' = 'profile';

    const base64 = body.imageBase64?.includes(',')
      ? body.imageBase64.split(',')[1]
      : body.imageBase64;

    if (base64) {
      const dataUrl = `data:image/jpeg;base64,${base64}`;
      const groq = await callGroq({
        systemPrompt:
          'És um analista facial do AuraStyle. Medes traços com neutralidade e rigor. Responde APENAS com JSON válido.',
        turns: [
          {
            role: 'user',
            content: `Analisa esta selfie e mede APENAS estes traços. Responde somente com JSON no formato exato: ${TRAIT_SCHEMA}`,
          },
        ],
        images: [dataUrl],
        jsonMode: true,
        temperature: 0.2,
        maxTokens: 250,
      });
      if (groq.ok) {
        const parsed = safeJson<Record<string, unknown>>(groq.text);
        if (parsed) {
          const normalized = normalizeVisionTraits(parsed);
          // visão preenche; perfil continua como base para o que faltar
          measured = {
            ...measured,
            ...Object.fromEntries(
              Object.entries(normalized).filter(([, v]) => v !== undefined),
            ),
          };
          source = 'vision';
        }
      }
    }

    // 3) Ranking determinístico contra o banco
    const { matches, traits } = rankReferences(measured, refs);
    const top = matches[0];
    const topRef = refs.find((r) => r.slug === top?.slug);

    // 4) Veredito + plano personalizado
    const strong = top?.traits.filter((t) => t.closeness >= 0.99) ?? [];
    const close = top?.traits.filter((t) => t.closeness >= 0.6 && t.closeness < 0.99) ?? [];
    const headline = top
      ? `Tua estrutura aproxima-se de ${top.name}`
      : 'Sem referências suficientes';
    const detail = top
      ? `${strong.length} de ${top.traits.length} traços batem direto${
          strong.length
            ? ` (${strong
                .slice(0, 2)
                .map((t) => t.label.toLowerCase())
                .join(', ')})`
            : ''
        }` +
        `${close.length ? ` · ${close[0].label.toLowerCase()} fica a meio caminho` : ''}.` +
        ` Pontuação de proximidade: ${top.score}%.`
      : '';

    const plan = top && topRef ? buildUpgradePlan(top, topRef) : [];

    return NextResponse.json({
      matches: matches.slice(0, 3),
      verdict: { headline, detail },
      plan,
      signatures: topRef?.signature ?? [],
      total: refs.length,
      source,
    });
  } catch (err) {
    console.error('look-alike error:', err);
    return NextResponse.json(
      { error: 'Não foi possível comparar com as referências' },
      { status: 500 },
    );
  }
}
