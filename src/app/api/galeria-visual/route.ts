import { NextResponse } from 'next/server';

export const dynamic = 'force-dynamic';

/**
 * GET /api/galeria-visual?q=cabelo+cacheado&count=12
 *
 * Banco de imagens visuais reais (fotografia de pessoas reais) para o
 * Espelho — cabelo, estilo, silhueta. DOIS bancos intercalados:
 *  • Pexels  (PEXELS_API_KEY)    — licença aberta, uso comercial OK
 *  • Unsplash (UNSPLASH_ACCESS_KEY) — editorial de retrato (licença Unsplash)
 * As chaves vivem APENAS no servidor; o cliente nunca as vê.
 *
 * Sem nenhuma chave configurada → fonte: 'reserva' (o app mostra a reserva
 * pública em vez de partir).
 */

type VisualItem = {
  id: string;
  url: string; // imagem grande
  thumb: string; // miniatura para grelhas
  alt: string;
  autor: string;
};

const cacheMem = new Map<
  string,
  { items: VisualItem[]; expira: number; fonte: string }
>();
const TTL_MS = 6 * 60 * 60 * 1000; // 6h

const RESERVA: VisualItem[] = [
  {
    id: 'reserva-cacheados',
    url: 'https://images.pexels.com/photos/2709388/pexels-photo-2709388.jpeg?auto=compress&cs=tinysrgb&w=800',
    thumb:
      'https://images.pexels.com/photos/2709388/pexels-photo-2709388.jpeg?auto=compress&cs=tinysrgb&w=300',
    alt: 'Cabelos cacheados ao sol',
    autor: 'Pexels',
  },
  {
    id: 'reserva-ondulado',
    url: 'https://images.pexels.com/photos/3034705/pexels-photo-3034705.jpeg?auto=compress&cs=tinysrgb&w=800',
    thumb:
      'https://images.pexels.com/photos/3034705/pexels-photo-3034705.jpeg?auto=compress&cs=tinysrgb&w=300',
    alt: 'Ondas naturais',
    autor: 'Pexels',
  },
  {
    id: 'reserva-liso',
    url: 'https://images.pexels.com/photos/3993449/pexels-photo-3993449.jpeg?auto=compress&cs=tinysrgb&w=800',
    thumb:
      'https://images.pexels.com/photos/3993449/pexels-photo-3993449.jpeg?auto=compress&cs=tinysrgb&w=300',
    alt: 'Liso espelhado',
    autor: 'Pexels',
  },
  {
    id: 'reserva-trancas',
    url: 'https://images.pexels.com/photos/2065195/pexels-photo-2065195.jpeg?auto=compress&cs=tinysrgb&w=800',
    thumb:
      'https://images.pexels.com/photos/2065195/pexels-photo-2065195.jpeg?auto=compress&cs=tinysrgb&w=300',
    alt: 'Tranças clássicas',
    autor: 'Pexels',
  },
  {
    id: 'reserva-afro',
    url: 'https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=800',
    thumb:
      'https://images.pexels.com/photos/1858175/pexels-photo-1858175.jpeg?auto=compress&cs=tinysrgb&w=300',
    alt: 'Volume afro natural',
    autor: 'Pexels',
  },
  {
    id: 'reserva-coque',
    url: 'https://images.pexels.com/photos/1036623/pexels-photo-1036623.jpeg?auto=compress&cs=tinysrgb&w=800',
    thumb:
      'https://images.pexels.com/photos/1036623/pexels-photo-1036623.jpeg?auto=compress&cs=tinysrgb&w=300',
    alt: 'Coque alto minimal',
    autor: 'Pexels',
  },
];

async function buscarPexels(q: string, count: number): Promise<VisualItem[]> {
  const key = process.env.PEXELS_API_KEY;
  if (!key) return [];
  const r = await fetch(
    `https://api.pexels.com/v1/search?query=${encodeURIComponent(q)}&per_page=${count}&orientation=portrait`,
    {
      headers: { Authorization: key },
      cache: 'no-store',
    },
  );
  if (!r.ok) throw new Error(`pexels ${r.status}`);
  const j = (await r.json()) as {
    photos?: Array<{
      id: number;
      alt?: string;
      photographer?: string;
      src?: Record<string, string>;
    }>;
  };
  return (j.photos ?? []).map((p) => ({
    id: `pexels-${p.id}`,
    url: p.src?.large ?? p.src?.medium ?? '',
    thumb: p.src?.medium ?? p.src?.small ?? '',
    alt: p.alt || q,
    autor: p.photographer || 'Pexels',
  }));
}

async function buscarUnsplash(q: string, count: number): Promise<VisualItem[]> {
  const key = process.env.UNSPLASH_ACCESS_KEY;
  if (!key) return [];
  const r = await fetch(
    `https://api.unsplash.com/search/photos?query=${encodeURIComponent(q)}&per_page=${count}&orientation=portrait&content_filter=high`,
    {
      headers: { Authorization: `Client-ID ${key}` },
      cache: 'no-store',
    },
  );
  if (!r.ok) throw new Error(`unsplash ${r.status}`);
  const j = (await r.json()) as {
    results?: Array<{
      id: string;
      alt_description?: string | null;
      description?: string | null;
      urls?: Record<string, string>;
      user?: { name?: string };
    }>;
  };
  return (j.results ?? []).map((p) => ({
    id: `unsplash-${p.id}`,
    url: p.urls?.regular ?? '',
    thumb: p.urls?.small ?? '',
    alt: p.alt_description || p.description || q,
    autor: p.user?.name || 'Unsplash',
  }));
}

/** Intercala os dois bancos preservando a relevância de cada um. */
function intercalar(a: VisualItem[], b: VisualItem[]): VisualItem[] {
  if (a.length === 0) return b;
  if (b.length === 0) return a;
  const out: VisualItem[] = [];
  const max = Math.max(a.length, b.length);
  for (let i = 0; i < max; i++) {
    if (a[i]) out.push(a[i]);
    if (b[i]) out.push(b[i]);
  }
  return out;
}

export async function GET(req: Request) {
  const url = new URL(req.url);
  const q = (url.searchParams.get('q') || 'estilo cabelo retrato').trim();
  const countRaw = Number(url.searchParams.get('count') || '12');
  const count = Number.isFinite(countRaw) ? Math.min(24, Math.max(4, countRaw)) : 12;

  const temPexels = Boolean(process.env.PEXELS_API_KEY);
  const temUnsplash = Boolean(process.env.UNSPLASH_ACCESS_KEY);
  if (!temPexels && !temUnsplash) {
    // Sem chaves ainda: devolve a reserva para o app continuar bonito.
    return NextResponse.json({
      fonte: 'reserva',
      q,
      total: RESERVA.length,
      items: RESERVA,
      dica: 'Adiciona PEXELS_API_KEY e/ou UNSPLASH_ACCESS_KEY ao ambiente para os bancos completos',
    });
  }

  const cacheKey = `${q}::${count}::${temPexels ? 'p' : ''}${temUnsplash ? 'u' : ''}`;
  const hit = cacheMem.get(cacheKey);
  if (hit && hit.expira > Date.now()) {
    return NextResponse.json({ fonte: hit.fonte, q, total: hit.items.length, items: hit.items });
  }

  try {
    // Os DOIS bancos em paralelo; quem falhar, devolve vazio (allSettled).
    const [pexels, unsplash] = await Promise.allSettled([
      temPexels ? buscarPexels(q, Math.ceil(count / 2) + 1) : Promise.resolve([]),
      temUnsplash ? buscarUnsplash(q, Math.ceil(count / 2) + 1) : Promise.resolve([]),
    ]);
    const itemsP = pexels.status === 'fulfilled' ? pexels.value : [];
    const itemsU = unsplash.status === 'fulfilled' ? unsplash.value : [];
    const items = intercalar(itemsP, itemsU).slice(0, count);

    if (items.length === 0) {
      return NextResponse.json({ fonte: 'reserva', q, total: RESERVA.length, items: RESERVA });
    }

    const fontes = new Set<string>();
    if (itemsP.length) fontes.add('pexels');
    if (itemsU.length) fontes.add('unsplash');
    const fonte = [...fontes].join('+') || 'reserva';

    cacheMem.set(cacheKey, { items, expira: Date.now() + TTL_MS, fonte });
    return NextResponse.json({ fonte, q, total: items.length, items });
  } catch (err) {
    console.error('[api/galeria-visual]', err);
    return NextResponse.json({
      fonte: 'reserva',
      q,
      total: RESERVA.length,
      items: RESERVA,
      error: 'banco visual indisponível, reserva activa',
    });
  }
}
