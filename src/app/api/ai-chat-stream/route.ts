import { NextRequest } from 'next/server';
import { callGroqStream, callZai, buildAuraSystemPrompt, type AISource } from '@/lib/ai-providers';

export const runtime = 'nodejs';
export const maxDuration = 60;

/**
 * POST /api/ai-chat-stream — Chat "Aura" com streaming SSE
 *
 * Fluxo: Groq (stream: true, token a token) → se falhar, z-ai (bloco único) →
 * se falhar, regras locais (bloco único). O cliente lê SSE:
 *   data: {"delta":"texto"}   (parcial)
 *   data: {"done":true,"source":"groq","model":"..."}   (fim)
 *   data: {"error":"..."}     (falha total)
 */
export async function POST(request: NextRequest) {
  const body = (await request.json().catch(() => ({}))) as {
    message?: string;
    profile?: Record<string, unknown>;
    history?: { role: 'user' | 'assistant'; content: string }[];
  };

  const message = body.message;
  if (!message || typeof message !== 'string') {
    return new Response(JSON.stringify({ error: 'message is required' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const systemPrompt = buildAuraSystemPrompt(body.profile);
  const turns = [
    ...(Array.isArray(body.history) ? body.history.slice(-10) : []),
    { role: 'user' as const, content: message },
  ];

  const encoder = new TextEncoder();
  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (obj: Record<string, unknown>) => {
        controller.enqueue(encoder.encode(`data: ${JSON.stringify(obj)}\n\n`));
      };

      let settled = false;

      // 1) Groq streaming
      try {
        const groq = await callGroqStream({
          systemPrompt,
          turns,
          onChunk: (delta) => {
            send({ delta });
          },
        });
        if (groq.ok) {
          send({ done: true, source: 'groq', model: groq.model });
          settled = true;
        } else {
          console.error('[ai-chat-stream] Groq indisponível:', groq.error);
        }
      } catch (err) {
        console.error('[ai-chat-stream] Groq erro:', err);
      }

      // 2) z-ai (bloco único)
      if (!settled) {
        const zai = await callZai({ systemPrompt, turns });
        if (zai.ok) {
          send({ delta: zai.text });
          send({ done: true, source: 'zai', model: zai.model });
          settled = true;
        } else {
          console.error('[ai-chat-stream] z-ai indisponível:', zai.error);
        }
      }

      // 3) Local (bloco único)
      if (!settled) {
        const reply = generateLocalResponse(message, body.profile);
        const source: AISource = 'local';
        send({ delta: reply });
        send({ done: true, source });
      }

      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream; charset=utf-8',
      'Cache-Control': 'no-cache, no-transform',
      Connection: 'keep-alive',
      'X-Accel-Buffering': 'no',
    },
  });
}

function generateLocalResponse(message: string, profile: Record<string, any> | undefined): string {
  const msg = message.toLowerCase();
  const p = profile || {};

  if (msg.includes('cabelo')) {
    return `Para o seu cabelo ${p.hairType || 'não definido'}: produtos sem sulfato, hidratação 2-3x por semana e proteção térmica. Aba Mercado prioriza compras pelo teu orçamento.`;
  }
  if (msg.includes('pele')) {
    return `Para pele ${Array.isArray(p.skinTypes) && p.skinTypes.length ? p.skinTypes.join(' e ') : 'não definida'}: limpeza, hidratante e FPS diários. Reaplique o protetor a cada 2h ao ar livre.`;
  }
  if (msg.includes('mercado') || msg.includes('comprar') || msg.includes('orçamento')) {
    return 'No Mercado: entra teu orçamento, lista os produtos com preços e eu devolvo a ordem de compra certa — e marcas acessíveis do teu país.';
  }
  if (msg.includes('olá') || msg.includes('oi')) {
    return `Olá${p.name ? `, ${p.name.split(' ')[0]}` : ''}! Sou o Aura. Pergunta sobre cabelo, pele, estilo ou compras — respondo com base no teu perfil.`;
  }

  return 'Sou o Aura, teu concierge de estilo ✨ Pergunta sobre cabelo, pele, looks, produtos ou compras — adapto tudo ao teu perfil e à tua região.';
}
