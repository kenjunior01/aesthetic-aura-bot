/**
 * museum.ts — cliente do The Met Collection API (gratuito, sem chave, domínio público).
 *
 * O Met expõe 470 mil+ obras; apenas as de DOMÍNIO PÚBLICO devolvem primaryImage.
 * Estratégia de resiliência (a API do Met é famosa por picos de instabilidade):
 *  1. requisições educadas: UA de navegador, concorrência baixa, retries com backoff;
 *  2. cache em memória por tema (6 h) + cache negativo curto (10 min) para falhas;
 *  3. se tudo falhar, devolvemos a RESERVA embutida (met-fallback.ts) — a galeria
 *     nunca amanhece vazia.
 */

import { MET_RESERVA, type MetItem } from './met-fallback';

const BASE = 'https://collectionapi.metmuseum.org/public/collection/v1';
const UA =
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36';

const OBJECTS_CONCURRENCY = 5;
const CACHE_TTL = 6 * 60 * 60 * 1000; // 6 h
const NEG_TTL = 10 * 60 * 1000; // falha → não insistir por 10 min
const SEARCH_TIMEOUT = 12_000;
const OBJECT_TIMEOUT = 12_000;

export type AcervoTheme = {
  key: string;
  label: string;
  hint: string;
  /** consultas ao search do Met — combinadas e desduplicadas */
  queries: { q: string; dept?: number }[];
};

export const ACERVO_THEMES: AcervoTheme[] = [
  {
    key: 'vestidos',
    label: 'Vestidos & silhuetas',
    hint: 'Costume Institute do Met',
    queries: [{ q: 'dress', dept: 8 }, { q: 'gown', dept: 8 }],
  },
  {
    key: 'padroes',
    label: 'Têxteis & padrões',
    hint: 'tapeçarias, azulejos e ornamentação',
    queries: [{ q: 'textile pattern' }, { q: 'tile panel', dept: 14 }],
  },
  {
    key: 'joalharia',
    label: 'Joalharia',
    hint: 'peças e adornos',
    queries: [{ q: 'jewelry' }, { q: 'tiara' }],
  },
  {
    key: 'armaduras',
    label: 'Armaduras & formas',
    hint: 'estudo de superfície e forma',
    queries: [{ q: 'armor', dept: 4 }],
  },
  {
    key: 'retratos',
    label: 'Retratos & poses',
    hint: 'linguagem corporal e enquadramento',
    queries: [{ q: 'portrait', dept: 11 }, { q: 'portrait photograph', dept: 19 }],
  },
  {
    key: 'fotografias',
    label: 'Fotografia & luz',
    hint: 'claro-escuro e atmosfera',
    queries: [{ q: 'photograph', dept: 19 }],
  },
];

const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function getJson(url: string, timeout: number, tries = 3): Promise<unknown | null> {
  for (let a = 0; a < tries; a++) {
    try {
      const res = await fetch(url, {
        headers: { 'User-Agent': UA, Accept: 'application/json' },
        signal: AbortSignal.timeout(timeout),
      });
      const text = await res.text();
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      if (text.startsWith('<')) throw new Error('bloqueio HTML'); // rate-limit do Met
      return JSON.parse(text);
    } catch {
      if (a === tries - 1) return null;
      await sleep(900 * (a + 1) * (a + 1));
    }
  }
  return null;
}

async function searchIds(q: string, dept?: number): Promise<number[]> {
  const params = new URLSearchParams({ hasImages: 'true', q });
  if (dept) params.set('departmentId', String(dept));
  const data = (await getJson(`${BASE}/search?${params}`, SEARCH_TIMEOUT)) as
    | { objectIDs?: number[] }
    | null;
  return data?.objectIDs ?? [];
}

function toItem(o: Record<string, unknown>): MetItem | null {
  const image = (o.primaryImageSmall as string) || (o.primaryImage as string) || '';
  if (!image) return null;
  const id = o.objectID as number;
  return {
    objectID: id,
    title: String(o.title || 'Sem título').slice(0, 120),
    artist: String(o.artistDisplayName || o.culture || 'Artista desconhecido').slice(0, 90),
    date: String(o.objectDate || ''),
    culture: String(o.culture || ''),
    medium: String(o.medium || '').slice(0, 140),
    department: String(o.department || ''),
    image,
    objectURL:
      (o.objectURL as string) || `https://www.metmuseum.org/art/collection/search/${id}`,
  };
}

async function poolMapped(ids: number[], want: number): Promise<MetItem[]> {
  const out: MetItem[] = [];
  const seen = new Set<number>();
  for (let i = 0; i < ids.length && out.length < want; i += OBJECTS_CONCURRENCY) {
    const chunk = ids.slice(i, i + OBJECTS_CONCURRENCY);
    const results = await Promise.all(
      chunk.map((id) => getJson(`${BASE}/objects/${id}`, OBJECT_TIMEOUT, 2)),
    );
    for (const o of results) {
      if (!o || typeof o !== 'object') continue;
      const rec = o as Record<string, unknown>;
      if (!rec.isPublicDomain) continue; // sem imagem aberta, sem lugar no acervo
      const item = toItem(rec);
      if (item && !seen.has(item.objectID)) {
        seen.add(item.objectID);
        out.push(item);
      }
    }
  }
  return out;
}

// ---------------- cache em memória (sobrevive entre requests do serverless quente) ----------------

type CacheEntry = { at: number; items: MetItem[] | null };
const memCache = new Map<string, CacheEntry>();

function fromCache(key: string): { items?: MetItem[]; stale?: boolean } | null {
  const e = memCache.get(key);
  if (!e) return null;
  const fresh = Date.now() - e.at < CACHE_TTL;
  if (!fresh && e.items) return { items: e.items, stale: true };
  if (!fresh) return null;
  return e.items ? { items: e.items } : { items: undefined, stale: false };
}

function toCache(key: string, items: MetItem[] | null) {
  memCache.set(key, { at: Date.now(), items });
}

// ---------------- API pública ----------------

export async function getAcervoForTheme(
  themeKey: string,
  count = 12,
): Promise<{ items: MetItem[]; source: 'met' | 'reserva' }> {
  const theme = ACERVO_THEMES.find((t) => t.key === themeKey) ?? ACERVO_THEMES[0];

  const cached = fromCache(`tema:${theme.key}:${count}`);
  if (cached?.items?.length) return { items: cached.items, source: 'met' };

  // 1. consulta educada ao Met (busca → objetos → domínio público c/ imagem)
  try {
    const idLists = await Promise.all(theme.queries.map((c) => searchIds(c.q, c.dept)));
    const ids: number[] = [];
    const seen = new Set<number>();
    for (const list of idLists) {
      for (const id of list) {
        if (!seen.has(id)) {
          seen.add(id);
          ids.push(id);
        }
      }
    }
    // mistura determinística simples para variar entre visitas sem PRNG por request
    const step = ids.length > 40 ? 7 : 1;
    const spread = ids.filter((_, i) => i % step === 0).concat(ids.filter((_, i) => i % step !== 0));

    const items = await poolMapped(spread, count);
    if (items.length >= Math.min(6, count)) {
      toCache(`tema:${theme.key}:${count}`, items);
      return { items, source: 'met' };
    }
    throw new Error('acervo magro');
  } catch {
    // cache negativo curto para não martelar o Met
    if (!cached?.stale) toCache(`tema:${theme.key}:${count}`, null);
  }

  // 2. reserva embutida — sempre válida
  const reserva = MET_RESERVA[theme.key] ?? [];
  const fallback = Object.values(MET_RESERVA).flat().slice(0, Math.max(6, count - reserva.length));
  const items = [...reserva, ...fallback.filter((f) => !reserva.some((r) => r.objectID === f.objectID))];
  return { items: items.slice(0, Math.max(6, count)), source: 'reserva' };
}
