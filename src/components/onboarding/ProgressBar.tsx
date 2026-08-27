'use client';

import { motion } from 'framer-motion';

const stepLabels = ['Prioridades', 'Básico', 'Rosto', 'Cabelo', 'Corpo', 'Estilo', 'Vida'];

export default function ProgressBar({ current, total = 7 }: { current: number; total?: number }) {
  const progress = ((current + 1) / total) * 100;

  return (
    <div className="w-full">
      <div className="flex items-center justify-between mb-2">
        <span className="text-xs font-medium text-muted-foreground">
          Etapa {current + 1} de {total}
        </span>
        <span className="text-xs font-medium text-aura">
          {stepLabels[current]}
        </span>
      </div>
      <div className="h-1.5 w-full rounded-full bg-surface-strong overflow-hidden">
        <motion.div
          className="h-full rounded-full bg-aura"
          initial={{ width: `${((current) / total) * 100}%` }}
          animate={{ width: `${progress}%` }}
          transition={{ type: 'spring', stiffness: 300, damping: 30 }}
        />
      </div>
      {/* Step dots */}
      <div className="flex justify-between mt-2">
        {stepLabels.map((_, i) => (
          <motion.div
            key={i}
            className={`h-1.5 rounded-full transition-all ${
              i <= current ? 'w-6 bg-aura' : 'w-1.5 bg-surface-strong'
            }`}
            layout
          />
        ))}
      </div>
    </div>
  );
}
