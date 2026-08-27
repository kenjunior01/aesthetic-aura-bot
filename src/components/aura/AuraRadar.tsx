'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { useAura, getLevelInfo } from '@/lib/aura-store';
import { getGoal } from '@/lib/goals';
import type { Tab } from '@/components/dashboard/BottomNav';

/**
 * AuraRadar — o mapa orbital das tuas prioridades.
 *
 * As metas escolhidas no registo orbitam o teu nível atual: a nº 1 fica
 * no topo, mais perto do núcleo. Toca num nó para saltar direto para
 * a área do app que trabalha essa meta.
 */

const GOAL_TAB: Record<string, Tab> = {
  cabelo: 'explore',
  pele: 'activities',
  compras: 'market',
  estilo: 'closet',
  rotina: 'activities',
  corpo: 'activities',
};

// Ângulos (graus) dos nós: 1º em cima, 2º e 3º nas laterais
const NODE_ANGLES = [-90, 150, 30];
const NODE_RADIUS = 37; // % do raio

export default function AuraRadar({ onNavigate }: { onNavigate: (tab: Tab) => void }) {
  const { profile, xp } = useAura();
  const { level, progress } = getLevelInfo(xp);
  const priorities = (profile.priorities || []).slice(0, 3);

  return (
    <div className="glass relative overflow-hidden rounded-3xl border border-primary/15 px-4 pb-5 pt-4">
      {/* Cabeçalho */}
      <div className="mb-1 flex items-center justify-between">
        <div>
          <h2 className='text-sm font-semibold uppercase tracking-widest text-muted-foreground'>Aura Radar</h2>
          <p className='text-[11px] text-muted-foreground mt-0.5'>As tuas metas em órbita — toca para abrir</p>
        </div>
        <span className='rounded-full bg-gold/15 px-2.5 py-1 text-[10px] font-bold text-gold'>
          Nível {level}
        </span>
      </div>

      {/* Órbita */}
      <div className="relative mx-auto mt-2 aspect-square w-full max-w-[270px]">
        {/* Anéis orbitais */}
        <div className='absolute inset-[9%] rounded-full border border-dashed border-primary/15' />
        <div className='absolute inset-[22%] rounded-full border border-primary/10' />

        {/* Cometa orbitando */}
        <motion.div
          animate={{ rotate: 360 }}
          transition={{ repeat: Infinity, duration: 24, ease: 'linear' }}
          className='absolute inset-[9%]'
        >
          <div className='absolute left-1/2 top-0 h-1.5 w-1.5 -translate-x-1/2 rounded-full bg-primary-glow shadow-[0_0_10px_2px_oklch(0.82_0.095_55/0.7)]' />
        </motion.div>

        {/* Núcleo: nível + progresso */}
        <button
          onClick={() => onNavigate('profile')}
          className='absolute left-1/2 top-1/2 h-[31%] w-[31%] -translate-x-1/2 -translate-y-1/2'
          aria-label='Ver perfil e nível'
        >
          <svg viewBox='0 0 100 100' className='h-full w-full -rotate-90'>
            <circle cx='50' cy='50' r='44' fill='none' stroke='oklch(0.95 0.02 80 / 10%)' strokeWidth='5' />
            <motion.circle
              cx='50' cy='50' r='44' fill='none'
              stroke='url(#radarGrad)' strokeWidth='5' strokeLinecap='round'
              strokeDasharray={2 * Math.PI * 44}
              initial={{ strokeDashoffset: 2 * Math.PI * 44 }}
              animate={{ strokeDashoffset: 2 * Math.PI * 44 * (1 - Math.min(progress, 1)) }}
              transition={{ type: 'spring', stiffness: 60, damping: 20 }}
            />
            <defs>
              <linearGradient id='radarGrad' x1='0' y1='0' x2='1' y2='1'>
                <stop offset='0%' stopColor='#E8C39E' />
                <stop offset='100%' stopColor='#D4A574' />
              </linearGradient>
            </defs>
          </svg>
          <div className='absolute inset-0 grid place-items-center'>
            <div className='grid h-[72%] w-[72%] place-items-center rounded-full bg-aura glow'>
              <span className='text-lg font-bold text-primary-foreground'>{level}</span>
            </div>
          </div>
        </button>

        {/* Nós das prioridades */}
        {priorities.map((goalId, i) => {
          const goal = getGoal(goalId);
          if (!goal) return null;
          const Icon = goal.icon;
          const angle = (NODE_ANGLES[i] * Math.PI) / 180;
          const x = 50 + NODE_RADIUS * Math.cos(angle);
          const y = 50 + NODE_RADIUS * Math.sin(angle);
          const tab = GOAL_TAB[goalId] || 'home';
          const isFirst = i === 0;

          return (
            <motion.button
              key={goalId}
              initial={{ opacity: 0, scale: 0.4 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.15 + i * 0.12, type: 'spring', stiffness: 260, damping: 20 }}
              onClick={() => onNavigate(tab)}
              className='absolute flex w-16 -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-1'
              style={{ left: `${x}%`, top: `${y}%` }}
              aria-label={`${goal.label} — prioridade ${i + 1}`}
            >
              <motion.div
                animate={{ y: [0, -4, 0] }}
                transition={{ repeat: Infinity, duration: 3 + i * 0.7, ease: 'easeInOut' }}
                className={isFirst
                  ? 'grid h-12 w-12 place-items-center rounded-2xl bg-aura glow'
                  : 'glass grid h-11 w-11 place-items-center rounded-2xl border border-primary/25'}
              >
                <Icon className={isFirst ? 'h-5 w-5 text-primary-foreground' : 'h-4.5 w-4.5 text-primary'} />
              </motion.div>
              <span className={cnRadar(isFirst)}>
                {i + 1}º · {goal.label.split(' ')[0]}
              </span>
            </motion.button>
          );
        })}

        {/* Estado vazio */}
        {priorities.length === 0 && (
          <p className='absolute left-1/2 top-[68%] w-40 -translate-x-1/2 text-center text-[10px] text-muted-foreground'>
            Define prioridades no perfil para ativar o teu radar
          </p>
        )}
      </div>
    </div>
  );
}

function cnRadar(isFirst: boolean): string {
  return isFirst
    ? 'rounded-full bg-aura px-1.5 py-0.5 text-[8px] font-bold uppercase tracking-wider text-primary-foreground'
    : 'rounded-full bg-surface px-1.5 py-0.5 text-[8px] font-semibold uppercase tracking-wider text-muted-foreground';
}
