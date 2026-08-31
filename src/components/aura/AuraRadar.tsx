'use client';

import React from 'react';
import { motion, useTransform } from 'framer-motion';
import { useAura, getLevelInfo } from '@/lib/aura-store';
import { getGoal } from '@/lib/goals';
import { useTiltSource } from '@/hooks/useTiltSource';
import type { Tab } from '@/components/dashboard/BottomNav';

/**
 * AuraRadar — instrumento orbital 3D das tuas prioridades.
 *
 * Um disco inclinado em perspectiva real (rotateX) com anéis concêntricos;
 * as metas ficam de pé sobre o plano como pinos de precisão. O núcleo é
 * uma coroa usinada com mostrador preto — relógio, não "IA brilhante".
 * O instrumento inteiro responde à mão (ponteiro) e ao aparelho real
 * (giroscópio via Capacitor) — como um objeto físico na mesa.
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
const NODE_RADIUS = 40; // % do raio
const TILT = 54; // inclinação do plano orbital

export default function AuraRadar({ onNavigate }: { onNavigate: (tab: Tab) => void }) {
  const { profile, xp } = useAura();
  const { level, progress } = getLevelInfo(xp);
  const priorities = (profile.priorities || []).slice(0, 3);

  // O instrumento reage à mão / ao aparelho — montagem inteira inclina
  const stage = useTiltSource();
  const asmRotX = useTransform(stage.y, [-0.5, 0.5], [5.5, -5.5]);
  const asmRotY = useTransform(stage.x, [-0.5, 0.5], [-8, 8]);

  return (
    <div className='glass relative overflow-hidden rounded-3xl px-4 pb-6 pt-4'>
      {/* Cabeçalho */}
      <div className='mb-1 flex items-center justify-between'>
        <div>
          <h2 className='text-[11px] font-bold uppercase tracking-[0.22em] text-foreground/80'>
            Aura Radar
          </h2>
          <p className='mt-0.5 text-[11px] text-muted-foreground'>
            As tuas metas em órbita — toca para abrir
          </p>
        </div>
        <span className='machined rounded-full px-2.5 py-1 text-[9px] font-bold uppercase tracking-widest text-primary'>
          Nível {level}
        </span>
      </div>

      {/* Palco 3D — responde ao ponteiro/giroscópio */}
      <div
        className='relative mx-auto mt-3 aspect-square w-full max-w-[280px] touch-pan-y'
        style={{ perspective: '900px', perspectiveOrigin: '50% 38%', ...stage.pointerHandlers }}
      >
        {/* Montagem inclinável — plano + pinos movem-se como um só objeto */}
        <motion.div
          className='absolute inset-0'
          style={{ rotateX: asmRotX, rotateY: asmRotY, transformStyle: 'preserve-3d' }}
        >
        {/* Plano orbital inclinado */}
        <div
          className='absolute inset-[4%]'
          style={{ transform: `rotateX(${TILT}deg)`, transformStyle: 'preserve-3d' }}
        >
          {/* Anéis concêntricos — gravações no disco */}
          <div className='absolute inset-0 rounded-full border border-primary/[0.14] shadow-[inset_0_0_24px_oklch(0.87_0.07_72/0.05)]' />
          <div className='absolute inset-[14%] rounded-full border border-dashed border-primary/[0.12]' />
          <div className='absolute inset-[28%] rounded-full border border-foreground/[0.05]' />

          {/* Esfera-cometa na órbita externa — sombreamento radial = volume real */}
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ repeat: Infinity, duration: 26, ease: 'linear' }}
            className='absolute inset-0'
          >
            <div
              className='absolute left-1/2 top-0 h-2 w-2 -translate-x-1/2 -translate-y-1/2 rounded-full'
              style={{
                background:
                  'radial-gradient(circle at 32% 28%, oklch(0.97 0.02 85), oklch(0.87 0.07 72) 45%, oklch(0.62 0.08 55) 100%)',
                boxShadow: '0 0 8px 1px oklch(0.87 0.07 72 / 0.45)',
              }}
            />
          </motion.div>

          {/* Pinos das prioridades — de pé sobre o plano inclinado */}
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
                initial={{ opacity: 0 }}
                animate={{ opacity: 1 }}
                transition={{ delay: 0.15 + i * 0.12 }}
                onClick={() => onNavigate(tab)}
                className='absolute w-16 -translate-x-1/2 -translate-y-1/2'
                style={{
                  left: `${x}%`,
                  top: `${y}%`,
                  transform: `translate(-50%, -50%) rotateX(-${TILT}deg)`,
                  transformStyle: 'preserve-3d',
                }}
                aria-label={`${goal.label} — prioridade ${i + 1}`}
              >
                <motion.div
                  animate={{ y: [0, -3, 0] }}
                  transition={{ repeat: Infinity, duration: 3.4 + i * 0.7, ease: 'easeInOut' }}
                  className={
                    isFirst
                      ? 'mx-auto grid h-12 w-12 place-items-center rounded-[0.95rem] bg-aura shadow-[0_8px_18px_-8px_oklch(0.87_0.07_72/0.55),inset_0_1px_0_oklch(0.99_0.01_85/0.35)]'
                      : 'machined mx-auto grid h-11 w-11 place-items-center rounded-[0.9rem]'
                  }
                >
                  <Icon
                    className={isFirst ? 'h-5 w-5 text-primary-foreground' : 'h-[1.1rem] w-[1.1rem] text-primary'}
                    strokeWidth={2}
                  />
                </motion.div>
                {/* Sombra projetada do pino no disco */}
                <div className='mx-auto mt-1.5 h-1 w-8 rounded-full bg-black/35 blur-[3px]' />
                <span
                  className={
                    isFirst
                      ? 'mt-1 inline-block rounded-full bg-aura px-1.5 py-0.5 text-[8px] font-bold uppercase tracking-wider text-primary-foreground'
                      : 'mt-1 inline-block rounded-full bg-surface-strong px-1.5 py-0.5 text-[8px] font-semibold uppercase tracking-wider text-muted-foreground'
                  }
                >
                  {i + 1}º · {goal.label.split(' ')[0]}
                </span>
              </motion.button>
            );
          })}
        </div>
        </motion.div>

        {/* Núcleo — coroa usinada + mostrador (fora da montagem: sempre de frente) */}
        <button
          onClick={() => onNavigate('profile')}
          className='absolute left-1/2 top-1/2 h-[34%] w-[34%] -translate-x-1/2 -translate-y-1/2'
          aria-label='Ver perfil e nível'
        >
          {/* Bezel metálico — cone de luz como torneamento real */}
          <div
            className='absolute inset-0 rounded-full'
            style={{
              background:
                'conic-gradient(from 210deg, oklch(0.55 0.04 75), oklch(0.92 0.06 78) 18%, oklch(0.70 0.05 72) 38%, oklch(0.95 0.05 82) 55%, oklch(0.62 0.05 68) 74%, oklch(0.88 0.06 76) 92%, oklch(0.55 0.04 75))',
              boxShadow: '0 14px 30px -12px oklch(0.01 0.004 70 / 85%)',
            }}
          />
          {/* Mostrador preto afundado */}
          <div className='absolute inset-[7%] rounded-full bg-[oklch(0.12_0.008_70)] shadow-[inset_0_3px_10px_oklch(0.01_0.004_70/0.9),inset_0_-1px_0_oklch(0.98_0.01_85/0.06)]' />
          {/* Arco de progresso */}
          <svg viewBox='0 0 100 100' className='absolute inset-[7%] h-[86%] w-[86%] -rotate-90'>
            <circle cx='50' cy='50' r='44' fill='none' stroke='oklch(0.95 0.02 80 / 8%)' strokeWidth='4' />
            <motion.circle
              cx='50' cy='50' r='44' fill='none'
              stroke='oklch(0.87 0.07 72)' strokeWidth='4' strokeLinecap='round'
              strokeDasharray={2 * Math.PI * 44}
              initial={{ strokeDashoffset: 2 * Math.PI * 44 }}
              animate={{ strokeDashoffset: 2 * Math.PI * 44 * (1 - Math.min(progress, 1)) }}
              transition={{ type: 'spring', stiffness: 60, damping: 20 }}
            />
          </svg>
          {/* Nível gravado */}
          <div className='absolute inset-0 grid place-items-center'>
            <span
              className='font-display text-[1.35rem] font-semibold text-primary'
              style={{ textShadow: '0 1px 0 oklch(0.01 0.004 70 / 0.8), 0 0 14px oklch(0.87 0.07 72 / 0.25)' }}
            >
              {level}
            </span>
          </div>
        </button>

        {/* Estado vazio */}
        {priorities.length === 0 && (
          <p className='absolute left-1/2 top-[72%] w-44 -translate-x-1/2 text-center text-[10px] text-muted-foreground'>
            Define prioridades no perfil para ativar o teu radar
          </p>
        )}
      </div>
    </div>
  );
}
