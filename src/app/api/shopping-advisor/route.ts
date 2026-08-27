import { NextRequest, NextResponse } from 'next/server';
import { callGemini, callZai } from '@/lib/ai-providers';
import {
  localPrioritize, brandsForCountry, detectCategory, NECESSITY, resolveCountry,
} from '@/lib/shopping';
import type { CountryInfo } from '@/lib/shopping';

/**
 * POST /api/shopping-advisor — Consultor de Compras do Aura
 *
 * Modos:
 *  - prioritize: lista de produtos + orçamento → ordem de prioridade para comprar
 *  - brands: país → marcas acessíveis recomendadas por categoria
 *  - photo: foto da prateleira → produtos detectados (IA vision) + priorização
 *
 * Cadeia de provedores: Gemini → z-ai → heurística local (shopping.ts)
 */

type ProductIn = { name: string; brand?: string; price?: number };

function profileSummary(p: Record<string, unknown> | null | undefined): string {
  const v = (k: string) => (p?.[k] ? String(p[k]) : 'não informado');
  const list = (k: string) => {
    const arr = p?.[k];
    return Array.isArray(arr) && arr.length ? arr.join(', ') : 'não informado';
  };
  return [
    `- tipo de cabelo: ${v('hairType')} | problemas capilares: ${list('hairIssues')}`,
    `- tipo de pele: ${list('skinTypes')} | clima: ${v('climate')} | região: ${v('region')}`,
    `- prioridades declaradas: ${list('priorities') || 'não informado'}`,
  ].join('\n');
}

function parseJsonLoose(text: string): Record<string, unknown> | null {
  try {
    return JSON.parse(text);
  } catch {
    const match = text.match(/\{[\s\S]*\}/);
    if (match) {
      try {
        return JSON.parse(match[0]);
      } catch {
        return null;
      }
    }
    return null;
  }
}

function prioritizePrompt(
  products: ProductIn[],
  budget: number,
  country: CountryInfo,
  profile: Record<string, unknown> | null | undefined,
): string {
  const list = products
    .map((p) => `- ${p.name}${p.brand ? ` (marca: ${p.brand})` : ''}${p.price ? ` — preço: ${p.price} ${country.currency}` : ' — sem preço'}`)
    .join('\n');
  return `Usuário está numa loja com ${budget} ${country.currency} de orçamento (${country.name}).
Produtos que ele está considerando:
${list}

Perfil estético:
${profileSummary(profile)}

Responda APENAS JSON:
{"ranking":[{"name":"nome exato do produto","priority":1,"verdict":"comprar|depois","reason":"frase curta (máx 18 palavras) explicando por que esta posição, citando a necessidade científica e o perfil"}],"totalInsideBudget":0,"advice":"conselho final prático (máx 30 palavras)"}

Regras de ciência capilar/pele:
- Ordem de necessidade: limpeza adequada → selagem (condicionador) → tratamento (máscara/proteína conforme o problema) → proteção diária (creme de pentear/leave-in) → selantes e estética (óleos, gel).
- Pele: limpeza → hidratação → protetor solar → ativos de tratamento.
- Considere os problemas capilares do perfil para escolher o tipo de tratamento (porosidade → proteína; ressecamento → umectação; definição → creme de pentear).
- "comprar" = cabe no orçamento e é necessário. "depois" = não cabe ou é refinamento.
- "totalInsideBudget" = soma dos preços dos itens "comprar".`;
}

function brandsPrompt(country: CountryInfo, profile: Record<string, unknown> | null | undefined): string {
  return `Recomende marcas ACESSÍVEIS de cuidados de cabelo e pele disponíveis em supermercados/farmácias de ${country.name} (moeda ${country.currency}).
Perfil do usuário:
${profileSummary(profile)}

Responda APENAS JSON:
{"brands":[{"name":"marca","domain":"cabelo|pele|ambos","why":"por que vale a pena (máx 20 palavras)","priceLevel":1}],"advice":"dica prática de compra no país (máx 30 palavras)"}

priceLevel: 1 = entrada/muito barato, 2 = intermediário acessível. Máximo 8 marcas, priorize as realmente comuns no país.`;
}

function photoPrompt(country: CountryInfo, budget?: number): string {
  return `Você é um assistente de compras de beleza. Analise esta foto de prateleira/vitrine de produtos capilares ou de skincare tirada pelo usuário numa loja${budget ? ` com orçamento de ${budget} ${country.currency}` : ''} em ${country.name}.
Extraia os produtos VISÍVEIS com nome e marca (e preço se estiver legível na etiqueta).

Responda APENAS JSON:
{"products":[{"name":"nome do produto","brand":"marca","price":0,"category":"shampoo|condicionador|mascara|creme-pentear|oleo|proteina|limpeza-facial|hidratante|protetor-solar|tratamento|estilizacao|outro"}],"observations":"o que você notou na prateleira (máx 25 palavras)"}

price = número na moeda local (0 se ilegível). Máximo 12 produtos.`;
}

function normalizePlan(
  data: Record<string, unknown> | null,
  products: ProductIn[],
  budget: number,
  _country: CountryInfo,
): {
  items: { name: string; brand?: string; price: number; category: string; domain: string; priority: number; verdict: 'comprar' | 'depois'; reason: string }[];
  totalInside: number;
  advice: string;
} | null {
  if (!data || !Array.isArray(data.ranking)) return null;
  let totalInside = 0;
  const items = data.ranking.slice(0, 20).map((raw: Record<string, unknown>, i: number) => {
    const name = String(raw.name || products[i]?.name || `Produto ${i + 1}`);
    const found = products.find((p) => p.name.toLowerCase() === name.toLowerCase());
    const price = Number(found?.price ?? raw.price ?? 0) || 0;
    const { category, domain } = detectCategory(name);
    const verdict = raw.verdict === 'depois' ? 'depois' : 'comprar';
    if (verdict === 'comprar' && price > 0) totalInside += price;
    return {
      name,
      brand: found?.brand || (raw.brand ? String(raw.brand) : undefined),
      price,
      category,
      domain,
      priority: Number(raw.priority) || i + 1,
      verdict: verdict as 'comprar' | 'depois',
      reason: String(raw.reason || NECESSITY[category].label),
    };
  });
  if (!items.length) return null;
  return {
    items,
    totalInside: Number(data.totalInsideBudget) || Math.min(totalInside, budget),
    advice: String(data.advice || ''),
  };
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const mode = (body.mode || 'prioritize') as 'prioritize' | 'brands' | 'photo';
    const profile = (body.profile || {}) as Record<string, unknown>;
    const country = resolveCountry(body.country);
    const budget = Math.max(0, Number(body.budget) || 0);
    const products: ProductIn[] = Array.isArray(body.products) ? body.products.slice(0, 20) : [];

    // ---------- MODO PRIORITIZE ----------
    if (mode === 'prioritize') {
      if (!products.length) {
        return NextResponse.json({ error: 'Envie pelo menos um produto' }, { status: 400 });
      }

      const prompt = prioritizePrompt(products, budget, country, profile);
      const systemPrompt = 'Você é o Aura, consultor de compras de beleza. Responde em português, apenas JSON válido, sem markdown.';

      const gemini = await callGemini({
        systemPrompt,
        contents: [{ role: 'user' as const, parts: [{ text: prompt }] }],
        jsonMode: true,
        temperature: 0.4,
        maxOutputTokens: 1200,
      });
      if (gemini.ok) {
        const plan = normalizePlan(parseJsonLoose(gemini.text), products, budget, country);
        if (plan) {
          return NextResponse.json({ ...plan, source: 'gemini', model: gemini.model, currency: country });
        }
      } else {
        console.error('[shopping-advisor] Gemini indisponível:', gemini.error);
      }

      const zai = await callZai({ systemPrompt, turns: [{ role: 'user', content: prompt }], maxTokens: 1200 });
      if (zai.ok) {
        const plan = normalizePlan(parseJsonLoose(zai.text), products, budget, country);
        if (plan) {
          return NextResponse.json({ ...plan, source: 'zai', model: zai.model, currency: country });
        }
      } else {
        console.error('[shopping-advisor] z-ai indisponível:', zai.error);
      }

      const local = localPrioritize(products, budget, profile as never, country);
      return NextResponse.json({
        items: local.items,
        totalInside: local.totalInside,
        advice: local.advice,
        source: 'local',
        currency: country,
      });
    }

    // ---------- MODO BRANDS ----------
    if (mode === 'brands') {
      const fallback = brandsForCountry(country);
      const prompt = brandsPrompt(country, profile);
      const systemPrompt = 'Você é o Aura, consultor de compras de beleza. Responde em português, apenas JSON válido, sem markdown.';

      const gemini = await callGemini({
        systemPrompt,
        contents: [{ role: 'user' as const, parts: [{ text: prompt }] }],
        jsonMode: true,
        temperature: 0.4,
        maxOutputTokens: 900,
      });
      if (gemini.ok) {
        const parsed = parseJsonLoose(gemini.text);
        if (parsed && Array.isArray(parsed.brands) && parsed.brands.length) {
          return NextResponse.json({
            country,
            brands: parsed.brands.slice(0, 10),
            advice: String(parsed.advice || ''),
            source: 'gemini',
            model: gemini.model,
          });
        }
      } else {
        console.error('[shopping-advisor] Gemini indisponível:', gemini.error);
      }

      const zai = await callZai({ systemPrompt, turns: [{ role: 'user', content: prompt }], maxTokens: 900 });
      if (zai.ok) {
        const parsed = parseJsonLoose(zai.text);
        if (parsed && Array.isArray(parsed.brands) && parsed.brands.length) {
          return NextResponse.json({
            country,
            brands: parsed.brands.slice(0, 10),
            advice: String(parsed.advice || ''),
            source: 'zai',
            model: zai.model,
          });
        }
      } else {
        console.error('[shopping-advisor] z-ai indisponível:', zai.error);
      }

      return NextResponse.json({
        country,
        brands: fallback,
        advice: `Em ${country.name}, comece pelas marcas de nível 1 — cobrem a base da rotina com pouco dinheiro.`,
        source: 'local',
      });
    }

    // ---------- MODO PHOTO ----------
    const imageBase64: string | undefined = body.imageBase64;
    if (!imageBase64) {
      return NextResponse.json({ error: 'imageBase64 é obrigatório no modo photo' }, { status: 400 });
    }

    const mime = (body.mimeType as string) || 'image/jpeg';
    const visionContents = [{ role: 'user' as const, parts: [{ text: photoPrompt(country, budget || undefined) }, { inline_data: { mime_type: mime, data: imageBase64 } }] }];

    const gemini = await callGemini({
      systemPrompt: 'Você é o Aura, consultor de compras de beleza com visão computacional. Responde em português, apenas JSON válido.',
      contents: visionContents,
      jsonMode: true,
      temperature: 0.3,
      maxOutputTokens: 1200,
    });
    if (gemini.ok) {
      const parsed = parseJsonLoose(gemini.text);
      if (parsed && Array.isArray(parsed.products)) {
        return NextResponse.json({
          products: parsed.products.slice(0, 12).map((p: Record<string, unknown>) => {
            const name = String(p.name || 'Produto');
            const { category, domain } = detectCategory(name);
            return { name, brand: p.brand ? String(p.brand) : undefined, price: Number(p.price) || 0, category, domain };
          }),
          observations: String(parsed.observations || ''),
          source: 'gemini',
          model: gemini.model,
          currency: country,
        });
      }
    } else {
      console.error('[shopping-advisor] Gemini vision indisponível:', gemini.error);
    }

    // z-ai não tem visão neste ambiente — heurística: pedir digitação manual
    return NextResponse.json({
      products: [],
      observations: 'A leitura da foto não está disponível agora. Digite os produtos e preços manualmente — a priorização funciona igual.',
      source: 'local',
      currency: country,
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'shopping advisor failed';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
