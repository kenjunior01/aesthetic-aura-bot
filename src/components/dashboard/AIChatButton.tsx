'use client';

import { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  MessageCircle, X, Send, Sparkles, Bot, Brain, Zap,
} from 'lucide-react';
import { useAura, getLevelInfo, type AuraState } from '@/lib/aura-store';
import { API_BASE } from '@/lib/api-base';
import { cn } from '@/lib/utils';
import { logEvent } from '@/lib/services';

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  source?: 'groq' | 'zai' | 'local';
  streaming?: boolean;
}

const SOURCE_META: Record<string, { label: string; title: string }> = {
  groq: { label: 'via Groq · Llama', title: 'Groq (Llama 3.3 70B) respondeu esta mensagem' },
  zai: { label: 'via Aura IA', title: 'Motor de IA Aura (fallback) respondeu esta mensagem' },
  local: { label: 'modo offline', title: 'Resposta gerada localmente no dispositivo' },
};

/** Resposta local de emergência (sem rede) */
function generateContextualResponse(message: string, profile: AuraState['profile']): string {
  const msg = message.toLowerCase();

  if (msg.includes('cabelo') && profile.hairType) {
    return `Baseado no seu cabelo ${profile.hairType}${profile.hairIssues.length > 0 ? ` com ${profile.hairIssues.join(', ')}` : ''}, recomendo: produtos sem sulfato, hidratação 2-3x por semana e proteção do calor. No Mercado, eu priorizo as compras pelo teu orçamento!`;
  }
  if (msg.includes('pele') && profile.skinTypes.length > 0) {
    return `Para sua pele ${profile.skinTypes.join(' e ')}, a rotina ideal é: limpeza matinal, hidratante com FPS e esfoliação semanal. ${profile.climate === 'tropical' ? 'No clima tropical, reaplique o FPS a cada 2h.' : ''}`;
  }
  if (msg.includes('look') || msg.includes('roupa') || msg.includes('estilo')) {
    const styleHint = profile.styles.length > 0 ? `Seu estilo é ${profile.styles.join(', ')}` : 'Seu perfil está sendo construído';
    return `${styleHint}. Invista em peças versáteis (camiseta branca, jeans escuro, tênis minimalista) — formam a base de qualquer look.`;
  }
  if (msg.includes('produto') || msg.includes('recomend') || msg.includes('comprar') || msg.includes('mercado')) {
    return profile.country
      ? `No Mercado eu priorizo tuas compras pelo orçamento e recomendo marcas acessíveis do teu país — tudo na ordem certa para o teu dinheiro render.`
      : 'Define teu país no perfil para recomendações com preços e marcas locais!';
  }
  if (msg.includes('rotina') || msg.includes('atividade')) {
    return 'Visite a aba "Atividades" para ver seus desafios diários personalizados! Complete desafios para ganhar XP, subir de nível e desbloquear conquistas.';
  }
  if (msg.includes('olá') || msg.includes('oi') || msg.includes('hey')) {
    const firstName = profile.name?.split(' ')[0] || '';
    return `Olá${firstName ? `, ${firstName}` : ''}! Sou o Aura, teu concierge de estilo. Posso ajudar com cabelo, pele, looks, produtos e compras inteligentes.`;
  }
  return 'Posso ajudar com dicas personalizadas sobre cabelo, pele, estilo, produtos e rotinas! Pergunte-me qualquer coisa relacionada ao teu perfil estético.';
}

/** Lê o stream SSE do /api/ai-chat-stream token a token */
async function streamAuraChat(
  message: string,
  profile: AuraState['profile'],
  history: { role: string; content: string }[],
  onDelta: (text: string) => void,
): Promise<{ source: 'groq' | 'zai' | 'local'; full: string } | null> {
  try {
    const res = await fetch(`${API_BASE}/api/ai-chat-stream`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message, profile, history }),
    });
    if (!res.ok || !res.body) return null;

    const reader = res.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';
    let full = '';
    let source: 'groq' | 'zai' | 'local' = 'local';

    for (;;) {
      const { done, value } = await reader.read();
      if (done) break;
      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';
      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed.startsWith('data:')) continue;
        try {
          const evt = JSON.parse(trimmed.slice(5)) as {
            delta?: string; done?: boolean; source?: 'groq' | 'zai' | 'local'; error?: string;
          };
          if (evt.delta) {
            full += evt.delta;
            onDelta(evt.delta);
          }
          if (evt.source) source = evt.source;
          if (evt.error) return null;
        } catch { /* fragmento inválido */ }
      }
    }
    return full.trim() ? { source, full: full.trim() } : null;
  } catch {
    return null;
  }
}

export default function AIChatButton() {
  const { profile, xp } = useAura();
  const { level } = getLevelInfo(xp);
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [aiSource, setAiSource] = useState<'groq' | 'zai' | 'local'>('local');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll on new messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim()) return;

    const question = input.trim();
    const userMsg: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'user',
      content: question,
      timestamp: new Date(),
    };

    const assistantId = crypto.randomUUID();
    setMessages((prev) => [
      ...prev,
      userMsg,
      { id: assistantId, role: 'assistant', content: '', timestamp: new Date(), streaming: true },
    ]);
    setInput('');
    logEvent('ai_chat_message', { source: 'user' });

    // Streaming: Groq token a token (fallback z-ai/local no mesmo stream)
    const result = await streamAuraChat(
      question,
      profile,
      messages.slice(-10).map((m) => ({ role: m.role, content: m.content })),
      (delta) => {
        setMessages((prev) =>
          prev.map((m) => (m.id === assistantId ? { ...m, content: m.content + delta } : m)),
        );
      },
    );

    if (result) {
      setAiSource(result.source);
      setMessages((prev) =>
        prev.map((m) =>
          m.id === assistantId
            ? { ...m, content: result.full, source: result.source, streaming: false }
            : m,
        ),
      );
      logEvent('ai_chat_message', { source: result.source });
    } else {
      // Fallback local imediato
      const localReply = generateContextualResponse(question, profile);
      setAiSource('local');
      setMessages((prev) =>
        prev.map((m) =>
          m.id === assistantId
            ? { ...m, content: localReply, source: 'local', streaming: false }
            : m,
        ),
      );
    }
  };

  const firstName = profile.name?.split(' ')[0] || '';

  return (
    <>
      {/* FAB Button */}
      <motion.button
        whileTap={{ scale: 0.9 }}
        whileHover={{ scale: 1.05 }}
        onClick={() => setOpen(!open)}
        className='fixed bottom-20 right-4 z-50 h-14 w-14 rounded-full bg-aura flex items-center justify-center glow shadow-2xl'
        aria-label='Abrir chat do Aura'
      >
        <AnimatePresence mode='wait'>
          {open ? (
            <motion.div key='close' initial={{ rotate: -90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: 90, opacity: 0 }}>
              <X className='h-6 w-6 text-primary-foreground' />
            </motion.div>
          ) : (
            <motion.div key='open' initial={{ rotate: 90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: -90, opacity: 0 }}>
              <MessageCircle className='h-6 w-6 text-primary-foreground' />
            </motion.div>
          )}
        </AnimatePresence>
      </motion.button>

      {/* Chat Panel */}
      <AnimatePresence>
        {open && (
          <motion.div
            initial={{ opacity: 0, y: 20, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={{ opacity: 0, y: 20, scale: 0.95 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className='fixed bottom-36 right-4 left-4 z-50 max-w-lg mx-auto glass rounded-3xl flex flex-col overflow-hidden'
            style={{ height: 'min(480px, 70vh)' }}
          >
            {/* Header */}
            <div className='flex items-center justify-between p-4 border-b border-border shrink-0'>
              <div className='flex items-center gap-3'>
                <div className='h-10 w-10 rounded-full bg-aura flex items-center justify-center'>
                  <Sparkles className='h-5 w-5 text-primary-foreground' />
                </div>
                <div>
                  <div className='flex items-center gap-2'>
                    <span className='text-sm font-bold block'>Aura AI</span>
                    <span title={`Fonte atual: ${aiSource}`} className='inline-flex'>
                      <Brain className='h-3 w-3 text-primary' />
                    </span>
                  </div>
                  <span className='text-[10px] text-muted-foreground'>
                    Seu concierge de estilo · Groq ultrarrápido
                  </span>
                </div>
              </div>
              <div className='flex items-center gap-1.5'>
                <Zap className='h-3 w-3 text-gold' />
                <span className='text-[10px] font-semibold text-gold'>Turbo</span>
              </div>
            </div>

            {/* Messages */}
            <div className='flex-1 overflow-y-auto no-scrollbar p-4 space-y-3'>
              {messages.length === 0 && (
                <div className='h-full flex flex-col items-center justify-center text-center gap-3'>
                  <Bot className='h-12 w-12 text-muted-foreground/30' />
                  <div>
                    <p className='text-sm font-semibold'>Olá{firstName ? `, ${firstName}` : ''}!</p>
                    <p className='text-xs text-muted-foreground mt-1 max-w-[240px]'>
                      Pergunte sobre cabelo, pele, estilo, produtos ou compras. Respostas em tempo real!
                    </p>
                  </div>
                  <div className='flex flex-wrap gap-2 mt-2 justify-center'>
                    {['Estou no mercado, o que compro primeiro?', 'Dica de cabelo', 'Sugestão de look', 'Rotina de pele', 'Marcas baratas no meu país'].map((suggestion) => (
                      <button
                        key={suggestion}
                        onClick={() => { setInput(suggestion); }}
                        className='rounded-full border border-border bg-surface px-3 py-1.5 text-xs text-muted-foreground hover:text-foreground hover:border-primary/30 transition-all'
                      >
                        {suggestion}
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {messages.map((msg) => (
                <motion.div
                  key={msg.id}
                  initial={{ opacity: 0, y: 10 }}
                  animate={{ opacity: 1, y: 0 }}
                  className={cn('flex', msg.role === 'user' ? 'justify-end' : 'justify-start')}
                >
                  <div
                    className={cn(
                      'max-w-[85%] rounded-2xl px-4 py-2.5 text-sm leading-relaxed',
                      msg.role === 'user'
                        ? 'bg-aura text-primary-foreground rounded-br-md'
                        : 'bg-surface-strong text-foreground rounded-bl-md',
                    )}
                  >
                    {msg.content}
                    {msg.streaming && !msg.content && (
                      <span className='flex gap-1 py-1'>
                        <motion.span className='h-2 w-2 rounded-full bg-muted-foreground' animate={{ y: [0, -6, 0] }} transition={{ repeat: Infinity, duration: 0.6 }} />
                        <motion.span className='h-2 w-2 rounded-full bg-muted-foreground' animate={{ y: [0, -6, 0] }} transition={{ repeat: Infinity, duration: 0.6, delay: 0.15 }} />
                        <motion.span className='h-2 w-2 rounded-full bg-muted-foreground' animate={{ y: [0, -6, 0] }} transition={{ repeat: Infinity, duration: 0.6, delay: 0.3 }} />
                      </span>
                    )}
                    {msg.streaming && msg.content && (
                      <motion.span
                        animate={{ opacity: [1, 0.2, 1] }}
                        transition={{ repeat: Infinity, duration: 0.9 }}
                        className='ml-0.5 inline-block h-3.5 w-[2px] translate-y-0.5 rounded-full bg-primary'
                      />
                    )}
                    {msg.source && SOURCE_META[msg.source] && !msg.streaming && (
                      <span
                        className='block text-[8px] uppercase tracking-wider text-primary/60 mt-1'
                        title={SOURCE_META[msg.source].title}
                      >
                        {SOURCE_META[msg.source].label}
                      </span>
                    )}
                  </div>
                </motion.div>
              ))}
              <div ref={messagesEndRef} />
            </div>

            {/* Input */}
            <div className='p-3 border-t border-border shrink-0'>
              <div className='flex items-center gap-2'>
                <input
                  type='text'
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && handleSend()}
                  placeholder='Pergunte sobre estilo...'
                  className='flex-1 h-10 rounded-xl border border-border bg-surface px-3 text-sm outline-none transition-all focus:border-primary/50 placeholder:text-muted-foreground/50'
                />
                <motion.button
                  whileTap={{ scale: 0.9 }}
                  onClick={handleSend}
                  disabled={!input.trim()}
                  className='h-10 w-10 rounded-xl bg-aura flex items-center justify-center disabled:opacity-40'
                  aria-label='Enviar mensagem'
                >
                  <Send className='h-4 w-4 text-primary-foreground' />
                </motion.button>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
