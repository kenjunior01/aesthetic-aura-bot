import { NextRequest, NextResponse } from 'next/server';

/**
 * POST /api/ai-chat
 * Proxy for Lovable AI API or Google Cloud AI.
 * Falls back to contextual rule-based responses.
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { message, profile, history } = body;

    if (!message) {
      return NextResponse.json({ error: 'message is required' }, { status: 400 });
    }

    // If Lovable AI endpoint is configured, proxy the request
    if (process.env.LOVABLE_AI_ENDPOINT) {
      const response = await fetch(process.env.LOVABLE_AI_ENDPOINT, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${process.env.LOVABLE_AI_API_KEY || ''}`,
        },
        body: JSON.stringify({
          messages: [
            {
              role: 'system',
              content: `Você é o AuraStyle AI, assistente de estética pessoal. Dados: nome=${profile?.name || ''}, cabelo=${profile?.hairType || ''}, pele=${profile?.skinTypes?.join(',') || ''}, região=${profile?.region || ''}, orçamento=${profile?.budget || ''}. Responda em português.`,
            },
            ...(history || []),
            { role: 'user', content: message },
          ],
          max_tokens: 500,
        }),
      });

      const data = await response.json();
      const reply = data.choices?.[0]?.message?.content || data.content || data.reply || 'Desculpe, não consegui processar.';
      return NextResponse.json({ reply, source: 'lovable' });
    }

    // Fallback: server-side contextual response
    const reply = generateServerResponse(message, profile);
    return NextResponse.json({ reply, source: 'local' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'AI chat failed' }, { status: 500 });
  }
}

function generateServerResponse(message: string, profile: any): string {
  const msg = message.toLowerCase();

  if (msg.includes('cabelo')) {
    return `Baseado no seu cabelo ${profile?.hairType || 'não definido'}${profile?.hairIssues?.length > 0 ? ` com ${profile?.hairIssues.join(', ')}` : ''}, recomendo: produtos sem sulfato, hidratação 2-3x por semana e proteção térmica. Quer sugestões de produtos para ${profile?.region || 'sua região'}?`;
  }
  if (msg.includes('pele')) {
    return `Para sua pele ${profile?.skinTypes?.join(' e ') || 'não definida'}, a rotina ideal é: limpeza, hidratante com FPS e esfoliação semanal.${profile?.climate === 'tropical' ? ' No clima tropical, reaplique FPS a cada 2h.' : ''} Posso detalhar cada passo!`;
  }
  if (msg.includes('look') || msg.includes('roupa') || msg.includes('estilo')) {
    return `Seu estilo é ${profile?.styles?.join(', ') || 'em construção'}. Dica: invista em peças versáteis (camiseta branca, jeans escuro, tênis minimalista) que formam a base de qualquer look. Veja a aba Explorar para tendências!`;
  }
  if (msg.includes('produto') || msg.includes('comprar')) {
    return profile?.region
      ? `Confira a aba Explorar para produtos em ${profile.region} com preços e onde encontrar! Filtrados pelo seu orçamento (${profile.budget || 'não definido'}).`
      : 'Selecione sua região no perfil para recomendações com preços locais!';
  }
  if (msg.includes('rotina') || msg.includes('atividade')) {
    return 'Visite a aba "Atividades" para seus desafios diários! Complete para ganhar XP e subir de nível. Consistência é o segredo!';
  }

  return 'Posso ajudar com dicas personalizadas sobre cabelo, pele, estilo, produtos e rotinas! Pergunte-me qualquer coisa sobre seu perfil estético.';
}
