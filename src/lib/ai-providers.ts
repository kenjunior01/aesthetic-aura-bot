import 'server-only';

/**
 * AuraStyle — Provedores de IA (server-side only)
 *
 * Estratégia em cadeia:
 *  1. Gemini (Google Cloud) — quando GEMINI_API_KEY está configurada e a
 *     Generative Language API está habilitada no projeto do usuário.
 *  2. z-ai-web-dev-sdk — fallback de IA sempre disponível neste ambiente.
 *
 * A chave NUNCA chega ao cliente: todas as chamadas saem das rotas /api.
 */

const GEMINI_MODELS = ['gemini-2.5-flash', 'gemini-2.0-flash', 'gemini-1.5-flash'];

export type GeminiPart = { text: string } | { inline_data: { mime_type: string; data: string } };

export type GeminiResult = {
  ok: boolean;
  text: string;
  model?: string;
  error?: string;
};

function withTimeout(ms: number): { signal: AbortSignal; clear: () => void } {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), ms);
  return { signal: controller.signal, clear: () => clearTimeout(timer) };
}

/**
 * Tenta gerar conteúdo via Gemini percorrendo a cadeia de modelos.
 * Retorna ok=false se nenhum modelo responder (fallback no chamador).
 */
export async function callGemini(options: {
  systemPrompt: string;
  contents: { role: 'user' | 'model'; parts: GeminiPart[] }[];
  jsonMode?: boolean;
  maxOutputTokens?: number;
  temperature?: number;
}): Promise<GeminiResult> {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return { ok: false, text: '', error: 'GEMINI_API_KEY não configurada' };
  }

  let lastError = '';
  for (const model of GEMINI_MODELS) {
    const { signal, clear } = withTimeout(20_000);
    try {
      const body: Record<string, unknown> = {
        system_instruction: { parts: [{ text: options.systemPrompt }] },
        contents: options.contents,
        generationConfig: {
          temperature: options.temperature ?? 0.8,
          maxOutputTokens: options.maxOutputTokens ?? 700,
          ...(options.jsonMode ? { responseMimeType: 'application/json' } : {}),
        },
      };

      const res = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body),
          signal,
        },
      );
      clear();

      if (!res.ok) {
        const errText = await res.text().catch(() => '');
        lastError = `${model}: HTTP ${res.status} — ${errText.slice(0, 160)}`;
        continue; // tenta o próximo modelo
      }

      const data = await res.json();
      const text: string | undefined =
        data?.candidates?.[0]?.content?.parts?.map((p: { text?: string }) => p.text || '').join('') ||
        undefined;

      if (!text || !text.trim()) {
        lastError = `${model}: resposta vazia`;
        continue;
      }

      return { ok: true, text: text.trim(), model };
    } catch (err: unknown) {
      clear();
      lastError = `${model}: ${err instanceof Error ? err.message : String(err)}`;
    }
  }

  return { ok: false, text: '', error: lastError };
}

/**
 * Fallback universal: z-ai-web-dev-sdk (backend only).
 */
export async function callZai(options: {
  systemPrompt: string;
  turns: { role: 'user' | 'assistant'; content: string }[];
  maxTokens?: number;
}): Promise<GeminiResult> {
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
    return { ok: true, text: text.trim(), model: 'z-ai' };
  } catch (err: unknown) {
    return { ok: false, text: '', error: `z-ai: ${err instanceof Error ? err.message : String(err)}` };
  }
}

/**
 * Prompt de sistema do "Aura" — o JARVIS da beleza.
 * Personaliza com o perfil estético completo do usuário.
 */
export function buildAuraSystemPrompt(profile: Record<string, unknown> | null | undefined): string {
  const p = profile || {};
  const lista = (v: unknown) => (Array.isArray(v) && v.length ? v.join(', ') : 'não informado');
  const val = (v: unknown) => (v === null || v === undefined || v === '' ? 'não informado' : String(v));

  return [
    'Você é o Aura, o "JARVIS da beleza" do app AuraStyle — um concierge de estética e estilo premium.',
    'Estilo de resposta: sofisticado, caloroso e direto, como um consultor de um balcão de beleza de luxo. Exatamente em português do Brasil.',
    'REGRAS:',
    '- Responda em no máximo 3 parágrafos curtos (ou uma lista de até 5 itens). Seja específico e prático.',
    '- Use SEMPRE os dados do perfil abaixo para personalizar. Nunca peça dados que já tem.',
    '- Quando fizer sentido, indique um recurso do app: Armário (montar looks), Atividades (desafios com XP), Explorar (tendências e produtos), Rotina (skincare diária).',
    '- Nunca julgue a aparência. Nunca dão conselhos médicos; para doenças de pele, sugira dermatologista.',
    '- No máximo 1 emoji por resposta.',
    '',
    'PERFIL DO USUÁRIO:',
    `- nome: ${val(p.name)} | gênero: ${val(p.gender)} | idade: ${val(p.age)} | região: ${val(p.region)} | clima: ${val(p.climate)}`,
    `- rosto: ${val(p.faceShape)} | tom de pele: ${val(p.skinTone)}/14 | subtom: ${val(p.undertone)} | olhos: ${val(p.eyeColor)} | pele: ${lista(p.skinTypes)}`,
    `- cabelo: ${val(p.hairType)}, cor ${val(p.hairColor)}, comprimento ${val(p.hairLength)}, espessura ${val(p.hairThickness)} | problemas capilares: ${lista(p.hairIssues)}`,
    `- corpo: ${val(p.bodyType)} | altura: ${val(p.height)}cm | estilos: ${lista(p.styles)} | ocasiões: ${lista(p.occasions)}`,
    `- orçamento: ${val(p.budget)} | cores favoritas: ${lista(p.colors)} | atividade física: ${val(p.activity)}/5 | profissão: ${val(p.profession)}`,
    `- observações: ${val(p.notes)}`,
  ].join('\n');
}
