import 'server-only';

/**
 * AuraStyle — Provedores de IA (server-side only)
 *
 * Cadeia em cascata (todas gratuitas):
 *  1. Groq (Llama 3.3 70B / Llama 4 Scout Vision) — ultrarrápido, plano free
 *  2. z-ai-web-dev-sdk — fallback sempre disponível neste ambiente
 *  3. Heurística local determinística — último recurso offline
 *
 * A chave NUNCA chega ao cliente: todas as chamadas saem das rotas /api.
 */

export const GROQ_TEXT_MODELS = [
  process.env.GROQ_TEXT_MODEL || 'llama-3.3-70b-versatile',
  'llama-3.1-8b-instant',
];

export const GROQ_VISION_MODELS = [
  process.env.GROQ_VISION_MODEL || 'meta-llama/llama-4-scout-17b-16e-instruct',
];

const GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';

export type AISource = 'groq' | 'zai' | 'local';

export type AIResult = {
  ok: boolean;
  text: string;
  model?: string;
  source?: AISource;
  error?: string;
};

export type GroqMessage = {
  role: 'system' | 'user' | 'assistant';
  content:
    | string
    | ({ type: 'text'; text: string } | { type: 'image_url'; image_url: { url: string } })[];
};

function withTimeout(ms: number): { signal: AbortSignal; clear: () => void } {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  return { signal: controller.signal, clear: () => clearTimeout(timer) };
}

// ============================================================
// 1. GROQ — provedor primário (texto + visão, JSON mode)
// ============================================================

function groqKey(): string | undefined {
  return process.env.GROQ_API_KEY || undefined;
}

type GroqBody = {
  model: string;
  messages: GroqMessage[];
  temperature?: number;
  max_tokens?: number;
  response_format?: { type: 'json_object' };
  stream?: boolean;
};

/** Chamada bruta à API Groq (OpenAI-compatible). Retorna Response ou lança. */
async function groqFetch(body: GroqBody, timeoutMs: number): Promise<Response> {
  const apiKey = groqKey();
  if (!apiKey) throw new Error('GROQ_API_KEY não configurada');
  const { signal, clear } = withTimeout(timeoutMs);
  try {
    const res = await fetch(GROQ_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify(body),
      signal,
    });
    if (!res.ok) {
      const errText = await res.text().catch(() => '');
      throw new Error(`HTTP ${res.status} — ${errText.slice(0, 200)}`);
    }
    return res;
  } finally {
    clear();
  }
}

/**
 * Groq em modo texto/vision percorrendo a cadeia de modelos.
 * images: data URLs (data:image/jpeg;base64,...) — vão como image_url.
 */
export async function callGroq(options: {
  systemPrompt: string;
  turns: { role: 'user' | 'assistant'; content: string }[];
  images?: string[];
  jsonMode?: boolean;
  maxTokens?: number;
  temperature?: number;
}): Promise<AIResult> {
  if (!groqKey()) {
    return { ok: false, text: '', error: 'GROQ_API_KEY não configurada' };
  }

  const models = options.images?.length ? GROQ_VISION_MODELS : GROQ_TEXT_MODELS;
  let lastError = '';

  for (const model of models) {
    try {
      const messages: GroqMessage[] = [{ role: 'system', content: options.systemPrompt }];

      options.turns.forEach((t, idx) => {
        const isLast = idx === options.turns.length - 1;
        if (isLast && options.images?.length && t.role === 'user') {
          messages.push({
            role: 'user',
            content: [
              { type: 'text', text: t.content },
              ...options.images.slice(0, 2).map((url) => ({
                type: 'image_url' as const,
                image_url: { url },
              })),
            ],
          });
        } else {
          messages.push({ role: t.role, content: t.content });
        }
      });

      const body: GroqBody = {
        model,
        messages,
        temperature: options.temperature ?? 0.8,
        max_tokens: options.maxTokens ?? 900,
        ...(options.jsonMode ? { response_format: { type: 'json_object' as const } } : {}),
      };

      const res = await groqFetch(body, 30_000);
      const data = await res.json();
      const text: string | undefined = data?.choices?.[0]?.message?.content;

      if (!text || !text.trim()) {
        lastError = `${model}: resposta vazia`;
        continue;
      }
      return { ok: true, text: text.trim(), model, source: 'groq' };
    } catch (err: unknown) {
      lastError = `${model}: ${err instanceof Error ? err.message : String(err)}`;
    }
  }

  return { ok: false, text: '', error: lastError };
}

/**
 * Groq com streaming SSE. onChunk é chamado a cada delta de texto.
 * Retorna o texto completo quando ok.
 */
export async function callGroqStream(options: {
  systemPrompt: string;
  turns: { role: 'user' | 'assistant'; content: string }[];
  maxTokens?: number;
  temperature?: number;
  onChunk: (delta: string) => void | Promise<void>;
}): Promise<AIResult> {
  if (!groqKey()) {
    return { ok: false, text: '', error: 'GROQ_API_KEY não configurada' };
  }

  const model = GROQ_TEXT_MODELS[0];
  try {
    const res = await groqFetch(
      {
        model,
        messages: [
          { role: 'system', content: options.systemPrompt },
          ...options.turns.map((t) => ({ role: t.role, content: t.content })),
        ],
        temperature: options.temperature ?? 0.85,
        max_tokens: options.maxTokens ?? 800,
        stream: true,
      },
      60_000,
    );

    const reader = res.body?.getReader();
    if (!reader) return { ok: false, text: '', error: 'groq stream: sem corpo' };

    const decoder = new TextDecoder();
    let buffer = '';
    let full = '';

    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        const payload = trimmed.slice(5).trim();
        if (payload === '[DONE]') continue;
        try {
          const json = JSON.parse(payload) as {
            choices?: { delta?: { content?: string } }[];
          };
          const delta = json.choices?.[0]?.delta?.content;
          if (delta) {
            full += delta;
            await options.onChunk(delta);
          }
        } catch {
          // fragmento inválido — ignora
        }
      }
    }

    if (!full.trim()) return { ok: false, text: '', error: 'groq stream: resposta vazia' };
    return { ok: true, text: full.trim(), model, source: 'groq' };
  } catch (err: unknown) {
    return { ok: false, text: '', error: `groq stream: ${err instanceof Error ? err.message : String(err)}` };
  }
}

// ============================================================
// 2. z-ai-web-dev-sdk — fallback universal
// ============================================================

export async function callZai(options: {
  systemPrompt: string;
  turns: { role: 'user' | 'assistant'; content: string }[];
  maxTokens?: number;
}): Promise<AIResult> {
  try {
    const { default: ZAI } = await import('z-ai-web-dev-sdk');
    const zai = await ZAI.create();

    const messages = [
      { role: 'assistant' as const, content: options.systemPrompt },
      ...options.turns.slice(-12), // limita contexto
    ];

    const completion = await zai.chat.completions.create({
      messages: messages as never,
      thinking: { type: 'disabled' },
    });

    const text = completion.choices?.[0]?.message?.content;
    if (!text || !text.trim()) {
      return { ok: false, text: '', error: 'z-ai: resposta vazia' };
    }
    return { ok: true, text: text.trim(), model: 'z-ai', source: 'zai' };
  } catch (err: unknown) {
    return { ok: false, text: '', error: `z-ai: ${err instanceof Error ? err.message : String(err)}` };
  }
}

// ============================================================
// 3. Persona do Aura — o JARVIS da beleza
// ============================================================

export function buildAuraSystemPrompt(profile: Record<string, unknown> | null | undefined): string {
  const p = profile || {};
  const lista = (v: unknown) => (Array.isArray(v) && v.length ? v.join(', ') : 'não informado');
  const val = (v: unknown) => (v === null || v === undefined || v === '' ? 'não informado' : String(v));
  const goals = Array.isArray(p.priorities) && p.priorities.length ? p.priorities.join(' > ') : 'não definidas';

  return [
    'Você é o Aura, o "JARVIS da beleza" do app AuraStyle — um concierge de estética e estilo premium.',
    'Estilo de resposta: sofisticado, caloroso e direto, como um consultor de um balcão de beleza de luxo. Exatamente em português.',
    'REGRAS:',
    '- Responda em no máximo 3 parágrafos curtos (ou uma lista de até 5 itens). Seja específico e prático.',
    '- Use SEMPRE os dados do perfil abaixo para personalizar. Nunca peça dados que já tem.',
    '- O usuário está em {país/cidade abaixo}: adapte marcas, preços e disponibilidade à realidade local dele. Use a moeda local.',
    '- Quando fizer sentido, indique um recurso do app: Mercado (consultor de compras), Armário (montar looks), Atividades (desafios com XP), Explorar (tendências), Rotina (skincare diária).',
    '- Respeite a ordem de prioridades declarada: o 1º objetivo domina suas sugestões.',
    '- Nunca julgue a aparência. Nunca dê conselhos médicos; para doenças de pele, sugira dermatologista.',
    '- No máximo 1 emoji por resposta.',
    '',
    'PERFIL DO USUÁRIO:',
    `- nome: ${val(p.name)} | gênero: ${val(p.gender)} | idade: ${val(p.age)}`,
    `- localização: ${val(p.city)}, ${val(p.country)} | clima: ${val(p.climate)} | região: ${val(p.region)}`,
    `- prioridades (1º → último): ${goals}`,
    `- rosto: ${val(p.faceShape)} | tom de pele: ${val(p.skinTone)}/14 | subtom: ${val(p.undertone)} | olhos: ${val(p.eyeColor)} | pele: ${lista(p.skinTypes)}`,
    `- cabelo: ${val(p.hairType)}, cor ${val(p.hairColor)}, comprimento ${val(p.hairLength)}, espessura ${val(p.hairThickness)} | problemas capilares: ${lista(p.hairIssues)}`,
    `- corpo: ${val(p.bodyType)} | altura: ${val(p.height)}cm | estilos: ${lista(p.styles)} | ocasiões: ${lista(p.occasions)}`,
    `- orçamento: ${val(p.budget)} | cores favoritas: ${lista(p.colors)} | atividade física: ${val(p.activity)}/5 | profissão: ${val(p.profession)}`,
    `- observações: ${val(p.notes)}`,
  ].join('\n');
}
