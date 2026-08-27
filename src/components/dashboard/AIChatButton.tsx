'use client';

import { useState, useRef, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  MessageCircle, X, Send, Sparkles, Bot,
  Brain, Wifi, WifiOff,
} from 'lucide-react';
import { useAura, getLevelInfo } from '@/lib/aura-store';
import { cn } from '@/lib/utils';
import { sendToLovableAI, logEvent } from '@/lib/services';
import { FEATURES } from '@/lib/firebase-config';

interface ChatMessage {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  source?: 'local' | 'lovable' | 'gcloud';
}

function generateContextualResponse(message: string, profile: ReturnType<typeof useAura>['profile']): string {
  const msg = message.toLowerCase();

  if (msg.includes('cabelo') && profile.hairType) {
    return `Baseado no seu cabelo ${profile.hairType}${profile.hairIssues.length > 0 ? ` com ${profile.hairIssues.join(', ')}` : ''}, recomendo: usar produtos sem sulfato, hidratar 2-3x por semana e proteger do calor. Quer que eu sugira produtos específicos para a sua região?`;
  }

  if (msg.includes('pele') && profile.skinTypes.length > 0) {
    return `Para sua pele ${profile.skinTypes.join(' e ')}, a rotina ideal é: limpeza matinal, hidratante com FPS e esfoliação semanal. ${profile.climate === 'tropical' ? 'No clima tropical, reaplique o FPS a cada 2h.' : ''} Posso detalhar cada passo!`;
  }

  if (msg.includes('look') || msg.includes('roupa') || msg.includes('estilo')) {
    const styleHint = profile.styles.length > 0 ? `Seu estilo é ${profile.styles.join(', ')}` : 'Seu perfil está sendo construído';
    return `${styleHint}. Dica: invista em peças versáteis (camiseta branca, jeans escuro, tênis minimalista) que formam a base de qualquer look. Verifique a aba Explorar para tendências atualizadas!`;
  }

  if (msg.includes('produto') || msg.includes('recomend') || msg.includes('comprar')) {
    if (profile.region) {
      return `Confira a aba Explorar -> "Produtos na sua Região" para recomendações personalizadas em ${profile.region} com preços e onde encontrar! Os produtos são filtrados pelo seu orçamento (${profile.budget || 'não definido'}) e tipo de pele/cabelo.`;
    }
    return 'Para recomendações de produtos com preços da sua região, selecione sua região no perfil! Vá em Perfil > editar para configurar.';
  }

  if (msg.includes('rotina') || msg.includes('atividade')) {
    return 'Visite a aba "Atividades" para ver seus desafios diários personalizados! Complete desafios para ganhar XP, subir de nível e desbloquear conquistas. A consistência é o segredo!';
  }

  if (msg.includes('olá') || msg.includes('oi') || msg.includes('hey')) {
    const firstName = profile.name?.split(' ')[0] || '';
    return `Olá${firstName ? `, ${firstName}` : ''}! Sou seu assistente de estilo pessoal. Posso ajudar com dicas de cabelo, pele, looks, produtos e rotinas. O que você quer saber?`;
  }

  return 'Posso ajudar com dicas personalizadas sobre cabelo, pele, estilo, produtos e rotinas de cuidados! Pergunte-me qualquer coisa relacionada ao seu perfil estético.';
}

export default function AIChatButton() {
  const { profile, xp } = useAura();
  const { level } = getLevelInfo(xp);
  const [open, setOpen] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [aiSource, setAiSource] = useState<'local' | 'lovable'>('local');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll on new messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isTyping]);

  const handleSend = async () => {
    if (!input.trim()) return;

    const userMsg: ChatMessage = {
      id: crypto.randomUUID(),
      role: 'user',
      content: input.trim(),
      timestamp: new Date(),
    };

    setMessages((prev) => [...prev, userMsg]);
    const question = input.trim();
    setInput('');
    setIsTyping(true);
    logEvent('ai_chat_message', { source: 'user' });

    // Try Lovable AI first, fall back to local
    try {
      const aiReply = await sendToLovableAI(
        question,
        profile,
        messages.map((m) => ({ role: m.role, content: m.content })),
      );

      if (aiReply) {
        const aiMsg: ChatMessage = {
          id: crypto.randomUUID(),
          role: 'assistant',
          content: aiReply,
          timestamp: new Date(),
          source: 'lovable',
        };
        setMessages((prev) => [...prev, aiMsg]);
        setAiSource('lovable');
        logEvent('ai_chat_message', { source: 'lovable' });
      } else {
        throw new Error('fallback');
      }
    } catch {
      // Local fallback
      const response = generateContextualResponse(question, profile);
      const aiMsg: ChatMessage = {
        id: crypto.randomUUID(),
        role: 'assistant',
        content: response,
        timestamp: new Date(),
        source: 'local',
      };
      setMessages((prev) => [...prev, aiMsg]);
      setAiSource('local');
    }

    setIsTyping(false);
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
                    {FEATURES.lovableAI ? (
                      <Brain className='h-3 w-3 text-primary' title='Lovable AI' />
                    ) : (
                      <WifiOff className='h-3 w-3 text-muted-foreground' title='Modo local' />
                    )}
                  </div>
                  <span className='text-[10px] text-muted-foreground'>
                    {FEATURES.lovableAI ? 'Powered by Lovable AI' : 'Seu assistente de estilo pessoal'}
                  </span>
                </div>
              </div>
              <div className='flex items-center gap-1.5'>
                <div className='h-2 w-2 rounded-full bg-green-400 animate-pulse' />
                <span className='text-[10px] text-muted-foreground'>Online</span>
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
                      Pergunte sobre cabelo, pele, estilo, produtos ou rotinas. Estou aqui para ajudar!
                    </p>
                  </div>
                  <div className='flex flex-wrap gap-2 mt-2 justify-center'>
                    {['Dica de cabelo', 'Recomendar produto', 'Sugestão de look', 'Rotina de pele', 'Análise de selfie'].map((suggestion) => (
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
                    {msg.source === 'lovable' && (
                      <span className='block text-[8px] text-primary/60 mt-1'>via Lovable AI</span>
                    )}
                  </div>
                </motion.div>
              ))}

              {isTyping && (
                <div className='flex justify-start'>
                  <div className='bg-surface-strong rounded-2xl rounded-bl-md px-4 py-3 flex gap-1'>
                    <motion.span className='h-2 w-2 rounded-full bg-muted-foreground' animate={{ y: [0, -6, 0] }} transition={{ repeat: Infinity, duration: 0.6, delay: 0 }} />
                    <motion.span className='h-2 w-2 rounded-full bg-muted-foreground' animate={{ y: [0, -6, 0] }} transition={{ repeat: Infinity, duration: 0.6, delay: 0.15 }} />
                    <motion.span className='h-2 w-2 rounded-full bg-muted-foreground' animate={{ y: [0, -6, 0] }} transition={{ repeat: Infinity, duration: 0.6, delay: 0.3 }} />
                  </div>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Input */}
            <div className='p-3 border-t border-border shrink-0'>
              <div className='flex items-center gap-2'>
                <input
                  type='text'
                  value={input}
                  onChange={(e) => setInput(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && handleSend()}
                  placeholder='Pergunte sobre estilo...'
                  className='flex-1 h-10 rounded-xl border border-border bg-surface px-3 text-sm outline-none transition-all focus:border-primary/50 placeholder:text-muted-foreground/50'
                />
                <motion.button
                  whileTap={{ scale: 0.9 }}
                  onClick={handleSend}
                  disabled={!input.trim()}
                  className='h-10 w-10 rounded-xl bg-aura flex items-center justify-center disabled:opacity-40'
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
