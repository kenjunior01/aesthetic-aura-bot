import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'nodejs';
export const maxDuration = 20;

/**
 * GET /api/product-lookup — Produtos REAIS de qualquer lugar do mundo
 * Fonte: Open Beauty Facts + Open Products Facts (open data, gratuito, sem chave).
 *
 * ?barcode=5601234567890  → produto por código de barras (EAN-13/EAN-8/UPC)
 * ?search=shampoo+seda    → busca por nome (opcional &brands=Seda para filtrar marca)
 *
 * Resposta normalizada:
 * { found: boolean, source: 'openbeautyfacts'|'openproductsfacts', products: [{
 *     barcode, name, brand, quantity, image, ingredients?, NovaGroup? }] }
 */

type OffProduct = {
  code?: string;
  product_name?: string;
  product_name_pt?: string;
  product_name_en?: string;
  generic_name?: string;
  brands?: string;
  quantity?: string;
  image_front_small_url?: string;
  image_url?: string;
  ingredients_text?: string;
  nutriscore_data?: { grade?: string };
};

export type NormalizedProduct = {
  barcode: string;
  name: string;
  brand: string;
  quantity: string;
  image: string | null;
  ingredients: string;
};

function normalize(p: OffProduct, fallbackCode = ''): NormalizedProduct | null {
  const name = (p.product_name_pt || p.product_name_en || p.product_name || p.generic_name || '').trim();
  if (!name) return null;
  return {
    barcode: String(p.code || fallbackCode || ''),
    name: name.slice(0, 120),
    brand: (p.brands || '').split(',').map((b) => b.trim()).filter(Boolean)[0] || '',
    quantity: (p.quantity || '').trim().slice(0, 40),
    image: p.image_front_small_url || p.image_url || null,
    ingredients: (p.ingredients_text || '').slice(0, 400),
  };
}

async function fetchJson(url: string, timeoutMs = 9000): Promise<Record<string, unknown> | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      headers: {
        'User-Agent': 'AuraStyle/1.0 (aesthetic assistant app)',
        Accept: 'application/json',
      },
      signal: controller.signal,
      // Open data APIs — sem segredo; cache curto no edge
      next: { revalidate: 300 },
    });
    if (!res.ok) return null;
    return (await res.json()) as Record<string, unknown>;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

function pickProducts(data: Record<string, unknown> | null): NormalizedProduct[] {
  if (!data) return [];
  const arr = (data.products as OffProduct[] | undefined) || [];
  const out: NormalizedProduct[] = [];
  const seen = new Set<string>();
  for (const p of arr) {
    const n = normalize(p, String(p.code || ''));
    if (!n) continue;
    const key = `${n.barcode}|${n.name.toLowerCase()}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(n);
    if (out.length >= 10) break;
  }
  return out;
}

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const barcode = (searchParams.get('barcode') || '').replace(/\D/g, '');
  const search = (searchParams.get('search') || '').trim().slice(0, 80);
  const brand = (searchParams.get('brands') || '').trim().slice(0, 60);

  if (!barcode && !search) {
    return NextResponse.json({ error: 'Passe barcode ou search' }, { status: 400 });
  }

  // 1) Código de barras — Open Beauty Facts primeiro, depois Open Products Facts
  if (barcode) {
    const obf = await fetchJson(`https://world.openbeautyfacts.org/api/v2/product/${barcode}.json?fields=code,product_name,product_name_pt,product_name_en,generic_name,brands,quantity,image_front_small_url,image_url,ingredients_text`);
    const raw = obf && Number(obf.status) === 1 ? obf : null;
    const product = raw ? normalize(raw.product as OffProduct, barcode) : null;
    if (product) {
      return NextResponse.json({ found: true, source: 'openbeautyfacts', products: [product] });
    }

    const opf = await fetchJson(`https://world.openproductsfacts.org/api/v2/product/${barcode}.json?fields=code,product_name,product_name_pt,product_name_en,generic_name,brands,quantity,image_front_small_url,image_url,ingredients_text`);
    const rawOpf = opf && Number(opf.status) === 1 ? opf : null;
    const productOpf = rawOpf ? normalize(rawOpf.product as OffProduct, barcode) : null;
    if (productOpf) {
      return NextResponse.json({ found: true, source: 'openproductsfacts', products: [productOpf] });
    }

    return NextResponse.json({
      found: false,
      source: 'openbeautyfacts',
      products: [],
      hint: 'Produto não catalogado ainda — escreve o nome e o preço manualmente.',
    });
  }

  // 2) Busca por nome (opcionalmente filtrada por marca)
  const params = new URLSearchParams({
    search_terms: search,
    search_simple: '1',
    action: 'process',
    json: '1',
    page_size: '12',
  });
  if (brand) params.set('brands', brand);
  const data = await fetchJson(`https://world.openbeautyfacts.org/cgi/search.pl?${params.toString()}`);
  const products = pickProducts(data);

  return NextResponse.json({
    found: products.length > 0,
    source: 'openbeautyfacts',
    products,
  });
}
