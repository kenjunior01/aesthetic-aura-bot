import { NextRequest, NextResponse } from 'next/server';
import { callGemini, callZai, buildAuraSystemPrompt } from '@/lib/ai-providers';

/**
 * POST /api/ai-chat — Chat "Aura" (JARVIS da beleza)
 *
 * Cadeia de provedores:
 *  1. Gemini (GEMINI_API_KEY) — persona concierge com perfil completo
 *  2. z-ai-web-dev-sdk — fallback de IA sempre disponível
 *  3. Regras determinísticas — último recurso offline
 *
 * Resposta: { reply, source: 'gemini' | 'zai' | 'local', model? }
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { message, profile, history } = body as {
      message?: string;
      profile?: Record<string, unknown>;
      history?: { role: 'user' | 'assistant'; content: string }[];
    };

    if (!message || typeof message !== 'string') {
      return NextResponse.json({ error: 'message is required' }, { status: 400 });
    }

    const systemPrompt = buildAuraSystemPrompt(profile);
    const turns = [
      ...(Array.isArray(history) ? history.slice(-10) : []),
      { role: 'user' as const, content: message },
    ];

    // 1) Gemini (Google Cloud)
    const gemini = await callGemini({
      systemPrompt,
      contents: turns.map((t) => ({ role: t.role, parts: [{ text: t.content }] })),
      temperature: 0.85,
      maxOutputTokens: 700,
    });
    if (gemini.ok) {
      return NextResponse.json({ reply: gemini.text, source: 'gemini', model: gemini.model });
    }
    console.error('[ai-chat] Gemini indisponível:', gemini.error);

    // 2) z-ai SDK
    const zai = await callZai({ systemPrompt, turns });
    if (zai.ok) {
      return NextResponse.json({ reply: zai.text, source: 'zai', model: zai.model });
    }
    console.error('[ai-chat] z-ai indisponível:', zai.error);

    // 3) Regras locais
    return NextResponse.json({ reply: generateServerResponse(message, profile), source: 'local' });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'AI chat failed';
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}

function generateServerResponse(message: string, profile: Record<string, any> | undefined): string {
  const msg = message.toLowerCase();
  const p = profile || {};

  if (msg.includes('cabelo')) {
    return `Para o seu cabelo ${p.hairType || 'não definido'}${p.hairIssues?.length > 0 ? ` com ${p.hairIssues.join(', ')}` : ''}: produtos sem sulfato, hidratação 2-3x por semana e proteção térmica são a base. Quer sugestões de produtos para ${p.region || 'sua região'}?`;
  }
  if (msg.includes('pele')) {
    return `Para pele ${Array.isArray(p.skinTypes) && p.skinTypes.length ? p.skinTypes.join(' e ') : 'não definida'}, a rotina ideal é limpeza, hidratante com FPS e esfoliação semanal.${p.climate === 'tropical' ? ' No clima tropical, reaplique FPS a cada 2h.' : ''} Detalho cada passo se quiser!`;
  }
  if (msg.includes('look') || msg.includes('roupa') || msg.includes('estilo')) {
    return `Seu estilo: ${Array.isArray(p.styles) && p.styles.length ? p.styles.join(', ') : 'em construção'}. Invista em peças versáteis (camiseta branca, jeans escuro, tênis minimalista) — formam a base de qualquer look. Veja também a aba Explorar!`;
  }
  if (msg.includes('produto') || msg.includes('comprar')) {
    return p.region
      ? `Na aba Explorar você encontra produtos em ${p.region}, filtrados pelo seu orçamento (${p.budget || 'não definido'}) e pelo seu tipo de pele/cabelo.`
      : 'Selecione sua região no perfil para recomendações com preços locais!';
  }
  if (msg.includes('rotina') || msg.includes('atividade')) {
    return 'Visite a aba Atividades: desafios diários personalizados com XP e níveis. Consistência é o segredo da transformação!';
  }

  return 'Sou o Aura, seu concierge de estilo ✨ Posso ajudar com cabelo, pele, looks, produtos e rotinas — com base no seu perfil. O que você quer saber hoje?';
}
