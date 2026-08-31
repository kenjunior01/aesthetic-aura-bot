'use client';

import { motion } from 'framer-motion';

const stepLabels = ['Prioridades', 'Básico', 'Rosto', 'Cabelo', 'Corpo', 'Estilo', 'Vida'];

/**
 * ProgressBar — calibrador usinado: trilho afundado, preenchimento de
 * metal champanhe com brilho especular e um ponto de luz no bico da
 * escala — como o índice de um instrumento de medição.
 */
export default function ProgressBar({ current, total = 7 }: { current: number; total?: number }) {
  const progress = ((current + 1) / total) * 100;

  return (
    <div className='w-full'>
      <div className='mb-2 flex items-center justify-between'>
        <span className='text-xs font-medium text-muted-foreground'>
          Etapa {current + 1} de {total}
        </span>
        <span className='text-xs font-medium text-aura'>{stepLabels[current]}</span>
      </div>

      {/* Trilho do calibrador */}
      <div
        className='relative h-2 w-full overflow-visible rounded-full bg-[oklch(0.08_0.005_70)]'
        style={{ boxShadow: 'inset 0 1.5px 4px oklch(0.01 0.004 70 / 0.9), inset 0 -0.5px 0 oklch(0.98 0.01 85 / 6%)' }}
      >
        <motion.div
          className='relative h-full rounded-full'
          initial={{ width: `${(current / total) * 100}%` }}
          animate={{ width: `${progress}%` }}
          transition={{ type: 'spring', stiffness: 300, damping: 30 }}
          style={{
            background:
              'linear-gradient(180deg, oklch(0.93 0.055 78) 0%, oklch(0.87 0.07 72) 45%, oklch(0.72 0.06 62) 100%)',
            boxShadow: 'inset 0 1px 0 oklch(0.99 0.01 85 / 0.45)',
          }}
        >
          {/* Índice luminoso no bico da escala */}
          <span
            className='absolute -right-1 top-1/2 h-2.5 w-2.5 -translate-y-1/2 rounded-full'
            style={{
              background:
                'radial-gradient(circle at 32% 28%, oklch(0.99 0.01 85), oklch(0.87 0.07 72) 55%, oklch(0.62 0.08 55))',
              boxShadow: '0 0 10px 2px oklch(0.87 0.07 72 / 0.55)',
            }}
          />
        </motion.div>
      </div>

      {/* Tiques usinados — decorados/pendentes */}
      <div className='mt-2 flex justify-between'>
        {stepLabels.map((label, i) => (
          <motion.div key={label} layout className='flex items-center'>
            <span
              className={`rounded-full transition-all ${
                i < current
                  ? 'h-1.5 w-6 bg-aura/80'
                  : i === current
                    ? 'h-1.5 w-6 bg-aura shadow-[0_0_8px_oklch(0.87_0.07_72/0.5)]'
                    : 'h-1.5 w-1.5 bg-surface-strong'
              }`}
            />
          </motion.div>
        ))}
      </div>
    </div>
  );
}
