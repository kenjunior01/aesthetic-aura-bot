import { NextResponse } from 'next/server';
import { getAcervoForTheme } from '@/lib/museum';

export const dynamic = 'force-dynamic';

/**
 * GET /api/acervo?theme=vestidos&count=12
 * Galeria de imagens reais do The Metropolitan Museum of Art (API gratuita,
 * sem chave, domínio público). Cache em memória no servidor + reserva embutida.
 */
export async function GET(req: Request) {
  const url = new URL(req.url);
  const theme = url.searchParams.get('theme') || 'vestidos';
  const countRaw = Number(url.searchParams.get('count') || '12');
  const count = Number.isFinite(countRaw) ? Math.min(24, Math.max(6, countRaw)) : 12;

  try {
    const { items, source } = await getAcervoForTheme(theme, count);
    return NextResponse.json({ theme, source, total: items.length, items });
  } catch (err) {
    console.error('[api/acervo]', err);
    return NextResponse.json(
      { theme, source: 'reserva', total: 0, items: [], error: 'acervo indisponível' },
      { status: 200 },
    );
  }
}
