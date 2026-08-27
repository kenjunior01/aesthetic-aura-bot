import { NextRequest, NextResponse } from 'next/server';
import { callGroq } from '@/lib/ai-providers';

export const runtime = 'nodejs';
export const maxDuration = 30;

/**
 * POST /api/analyze-selfie — Análise estética da selfie
 *
 * Cadeia:
 *  1. Groq Vision (Llama 4 Scout, gratuito) com saída JSON estruturada
 *  2. Heurística local real: análise de pixels com sharp
 *     (luminância média → tom de pele 1-14; razão R/B → subtom)
 *
 * Resposta: { skinTone, skinType, dominantColors, faceShape, hairColor, undertone, confidence, source, observations }
 */
export async function POST(request: NextRequest) {
  try {
    const { imageBase64 } = (await request.json()) as { imageBase64?: string };
    if (!imageBase64) {
      return NextResponse.json({ error: 'imageBase64 is required' }, { status: 400 });
    }

    const dataUrl = imageBase64.startsWith('data:')
      ? imageBase64
      : `data:image/jpeg;base64,${imageBase64.includes(',') ? imageBase64.split(',')[1] : imageBase64}`;
    const base64 = imageBase64.includes(',') ? imageBase64.split(',')[1] : imageBase64;

    // 1) Groq Vision (Llama 4 Scout — multimodal, gratuito)
    const groq = await callGroq({
      systemPrompt:
        'Você é um consultor de imagem do AuraStyle. Analise selfies e retorne APENAS JSON válido, sem texto fora do JSON.',
      turns: [
        {
          role: 'user',
          content:
            'Analise esta selfie e estime os atributos estéticos. Responda somente com JSON no formato exato: {"skinTone": <inteiro 1-14, 1=mais claro, 14=mais escuro>, "undertone": "quente"|"frio"|"neutro"|"oliva", "skinType": "oleosa"|"seca"|"mista"|"sensivel"|"normal", "faceShape": "oval"|"redondo"|"quadrado"|"retangular"|"coracao"|"diamante"|"losango", "hairColor": "loiro-claro"|"loiro-escuro"|"castanho-medio"|"castanho-escuro"|"ruivo"|"preto"|"grisalho"|"colorido", "confidence": <0-1>, "observations": "<1 frase em pt-BR>"}. Se não conseguir ver rosto, use confidence baixo e estime pelos dados visíveis.',
        },
      ],
      images: [dataUrl],
      jsonMode: true,
      temperature: 0.3,
      maxTokens: 400,
    });

    if (groq.ok) {
      const parsed = safeParseAnalysis(groq.text);
      if (parsed) {
        return NextResponse.json({ ...parsed, source: 'groq', model: groq.model });
      }
    } else {
      console.error('[analyze-selfie] Groq Vision indisponível:', groq.error);
    }

    // 2) Heurística local (análise real de pixels)
    const heuristic = await analyzePixelsLocally(base64);
    return NextResponse.json(heuristic);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Selfie analysis failed';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

function safeParseAnalysis(text: string) {
  try {
    const jsonText = text.replace(/^```(?:json)?\s*/i, '').replace(/```$/, '').trim();
    const raw = JSON.parse(jsonText) as Record<string, unknown>;

    const clampTone = (v: unknown) => Math.min(14, Math.max(1, Math.round(Number(v) || 5)));
    const validShape = ['oval', 'redondo', 'quadrado', 'retangular', 'coracao', 'diamante', 'losango'];
    const validHair = ['loiro-claro', 'loiro-escuro', 'castanho-medio', 'castanho-escuro', 'ruivo', 'preto', 'grisalho', 'colorido'];
    const validSkin = ['oleosa', 'seca', 'mista', 'sensivel', 'normal'];

    return {
      skinTone: clampTone(raw.skinTone),
      undertone: ['quente', 'frio', 'neutro', 'oliva'].includes(String(raw.undertone))
        ? String(raw.undertone)
        : 'neutro',
      skinType: validSkin.includes(String(raw.skinType)) ? String(raw.skinType) : 'normal',
      faceShape: validShape.includes(String(raw.faceShape)) ? String(raw.faceShape) : 'oval',
      hairColor: validHair.includes(String(raw.hairColor)) ? String(raw.hairColor) : 'castanho-escuro',
      dominantColors: [],
      confidence: Math.min(0.98, Math.max(0.3, Number(raw.confidence) || 0.75)),
      observations: String(raw.observations || ''),
    };
  } catch {
    return null;
  }
}

type HeuristicResult = {
  skinTone: number;
  undertone: string;
  skinType: string;
  faceShape: string;
  hairColor: string;
  dominantColors: string[];
  confidence: number;
  source: string;
  observations: string;
};

/**
 * Análise REAL de pixels com sharp: recorte central (região do rosto em
 * selfies), média de luminância → tom 1-14; razão R/B e G → subtom.
 */
async function analyzePixelsLocally(base64: string): Promise<HeuristicResult> {
  try {
    const sharp = (await import('sharp')).default;
    const img = sharp(Buffer.from(base64, 'base64'), { failOn: 'none' });

    const { width, height } = await img.metadata();
    const w = width ?? 800;
    const h = height ?? 800;

    // Região central-vertical (rosto costuma estar no terço superior/central)
    const cropW = Math.round(w * 0.5);
    const cropH = Math.round(h * 0.45);
    const cropX = Math.round((w - cropW) / 2);
    const cropY = Math.round(h * 0.12);

    const { data } = await img
      .extract({ left: cropX, top: cropY, width: cropW, height: cropH })
      .resize(48, 48, { fit: 'inside' })
      .removeAlpha()
      .raw()
      .toBuffer({ resolveWithObject: true });

    // Coleta pixels "pele-like" (exclui extremos: muito claros/escuros/saturados)
    const pixels: { r: number; g: number; b: number }[] = [];
    for (let i = 0; i < data.length; i += 3) {
      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];
      const max = Math.max(r, g, b);
      const min = Math.min(r, g, b);
      const skinish =
        r > 40 && r > b * 0.9 && r >= g && max - min < 120 && r < 250 && b < 245;
      if (skinish) pixels.push({ r, g, b });
    }

    const sample = pixels.length > 40 ? pixels : fallbackSample(data);
    const avg = sample.reduce(
      (acc, p) => ({ r: acc.r + p.r, g: acc.g + p.g, b: acc.b + p.b }),
      { r: 0, g: 0, b: 0 },
    );
    avg.r /= sample.length;
    avg.g /= sample.length;
    avg.b /= sample.length;

    // Luminância relativa → tom 1-14
    const luminance = (0.2126 * avg.r + 0.7152 * avg.g + 0.0722 * avg.b) / 255;
    const tone = Math.min(14, Math.max(1, Math.round(15 - luminance * 14)));

    // Subtom: aquecimento da amostra
    const warmth = (avg.r - avg.b) / 255;
    const undertone = warmth > 0.09 ? 'quente' : warmth < -0.02 ? 'frio' : warmth > 0.04 ? 'oliva' : 'neutro';

    return {
      skinTone: tone,
      undertone,
      skinType: 'normal',
      faceShape: 'oval',
      hairColor: 'castanho-escuro',
      dominantColors: [
        `${Math.round(avg.r)},${Math.round(avg.g)},${Math.round(avg.b)}`,
      ],
      confidence: 0.52,
      source: 'local-pixels',
      observations: `Análise local estimada: tom ${tone}, subtom ${undertone}. Ajuste manualmente se necessário.`,
    };
  } catch {
    return {
      skinTone: 5,
      undertone: 'neutro',
      skinType: 'normal',
      faceShape: 'oval',
      hairColor: 'castanho-escuro',
      dominantColors: [],
      confidence: 0.3,
      source: 'local-fallback',
      observations: 'Não foi possível analisar a imagem com precisão. Defina manualmente.',
    };
  }
}

function fallbackSample(data: Buffer): { r: number; g: number; b: number }[] {
  const out: { r: number; g: number; b: number }[] = [];
  for (let i = 0; i < data.length; i += 3 * 7) {
    out.push({ r: data[i], g: data[i + 1], b: data[i + 2] });
  }
  return out.length ? out : [{ r: 190, g: 150, b: 120 }];
}
