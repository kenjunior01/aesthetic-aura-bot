'use client';

import { useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  Sparkles, MapPin, Check,
} from 'lucide-react';
import { useAura } from '@/lib/aura-store';
import { GlowButton, SectionTitle } from '@/components/aura/ui';
import { detectCountry } from '@/lib/shopping';
import { GOAL_OPTIONS } from '@/lib/goals';
import { cn } from '@/lib/utils';

const MAX_PRIORITIES = 3;

export default function StepGoals({ onNext }: { onNext: () => void }) {
  const { profile, update } = useAura();

  // Detecta o país automaticamente (o app "sabe" onde o usuário está)
  useEffect(() => {
    if (!profile.country) {
      const detected = detectCountry();
      if (detected.code !== 'XX') update({ country: detected.code });
    }
  }, [profile.country, update]);

  const togglePriority = (id: string) => {
    const current = profile.priorities || [];
    if (current.includes(id)) {
      update({ priorities: current.filter((p) => p !== id) });
    } else if (current.length < MAX_PRIORITIES) {
      update({ priorities: [...current, id] });
    }
  };

  const canContinue = profile.priorities.length >= 1;
  const detected = detectCountry();

  return (
    <motion.div
      initial={{ x: 60, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="flex min-h-full flex-col"
    >
      <div className="flex-1 overflow-y-auto px-1 pb-6">
        <div className="flex flex-col gap-5 py-2">
          <div className="text-center pt-4">
            <div className="mx-auto mb-3 grid h-14 w-14 place-items-center rounded-2xl bg-aura glow">
              <Sparkles className="h-7 w-7 text-primary-foreground" />
            </div>
            <h2 className="text-xl font-bold">O que você quer alcançar primeiro?</h2>
            <p className="mx-auto mt-2 max-w-[300px] text-sm text-muted-foreground">
              Toque na sua prioridade nº 1, depois na nº 2 e na nº 3. O app inteiro se adapta a essa ordem.
            </p>
          </div>

          {/* País detectado */}
          {detected.code !== 'XX' && (
            <div className="flex items-center justify-center gap-1.5 text-xs text-muted-foreground">
              <MapPin className="h-3.5 w-3.5 text-primary" />
              Detectei que você está em <span className="font-semibold text-foreground">{detected.name}</span> — preços e marcas serão locais
            </div>
          )}

          <section>
            <SectionTitle
              title="Suas prioridades"
              hint={`${profile.priorities.length}/${MAX_PRIORITIES} selecionadas — a ordem em que você toca define a prioridade`}
            />
            <div className="grid grid-cols-2 gap-3">
              {GOAL_OPTIONS.map((goal) => {
                const Icon = goal.icon;
                const idx = profile.priorities.indexOf(goal.id);
                const selected = idx >= 0;
                return (
                  <motion.button
                    key={goal.id}
                    type="button"
                    whileTap={{ scale: 0.95 }}
                    animate={{ scale: selected ? 1.02 : 1 }}
                    transition={{ type: 'spring', stiffness: 400, damping: 24 }}
                    onClick={() => togglePriority(goal.id)}
                    className={cn(
                      'glass relative flex flex-col items-center justify-center gap-1.5 rounded-2xl p-4 text-center transition-colors',
                      selected && 'border-primary/70 bg-surface-strong glow',
                    )}
                  >
                    {selected && (
                      <motion.span
                        initial={{ scale: 0, opacity: 0 }}
                        animate={{ scale: 1, opacity: 1 }}
                        className="absolute right-2 top-2 grid h-6 w-6 place-items-center rounded-full bg-aura text-[10px] font-bold text-primary-foreground"
                      >
                        {idx + 1}º
                      </motion.span>
                    )}
                    <Icon className={cn('h-6 w-6', selected ? 'text-primary' : 'text-muted-foreground')} />
                    <span className="text-sm font-semibold">{goal.label}</span>
                    <span className="text-[11px] text-muted-foreground leading-tight">{goal.desc}</span>
                  </motion.button>
                );
              })}
            </div>
          </section>

          {/* Resumo do plano adaptativo */}
          {canContinue && (
            <motion.div
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              className="glass rounded-2xl border border-primary/20 p-4"
            >
              <div className="mb-2 flex items-center gap-2">
                <Check className="h-4 w-4 text-primary" />
                <span className="text-sm font-semibold">O app vai se adaptar assim:</span>
              </div>
              <ul className="space-y-1.5 text-xs text-muted-foreground">
                {profile.priorities.map((p, i) => {
                  const goal = GOAL_OPTIONS.find((g) => g.id === p);
                  return (
                    <li key={p} className="flex items-center gap-2">
                      <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full bg-aura/20 text-[10px] font-bold text-primary">{i + 1}º</span>
                      <span><span className="font-medium text-foreground">{goal?.label}</span> aparece primeiro na sua tela inicial</span>
                    </li>
                  );
                })}
              </ul>
            </motion.div>
          )}
        </div>
      </div>

      {/* Botão Próximo */}
      <div className="pt-4">
        <GlowButton onClick={onNext} disabled={!canContinue} className="w-full">
          {canContinue ? 'Continuar com meu foco' : 'Escolha ao menos 1 prioridade'}
        </GlowButton>
      </div>
    </motion.div>
  );
}
