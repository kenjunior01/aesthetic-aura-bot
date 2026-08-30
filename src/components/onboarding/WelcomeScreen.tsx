'use client';

import { motion } from 'framer-motion';
import { AuroraBackground } from '@/components/aura/AuroraBackground';
import { GlowButton } from '@/components/aura/ui';

export default function WelcomeScreen({ onStart, onSkip }: { onStart: () => void; onSkip: () => void }) {
  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center px-6 text-center">
      <AuroraBackground />

      {/* Skip link */}
      <button
        onClick={onSkip}
        className="absolute top-6 right-6 text-sm text-muted-foreground hover:text-foreground transition-colors z-10"
      >
        Já tenho conta
      </button>

      {/* Content */}
      <motion.div
        initial={{ y: 30, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
        className="relative z-10 flex flex-col items-center gap-7 max-w-sm"
      >
        {/* Monograma — coroa usinada, como a coroa de um relógio de luxo */}
        <motion.div
          initial={{ scale: 0.85, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.15, type: 'spring', stiffness: 200 }}
          className="grid h-24 w-24 place-items-center rounded-full"
          style={{
            background:
              'conic-gradient(from 200deg, oklch(0.52 0.035 75), oklch(0.93 0.055 78) 20%, oklch(0.66 0.045 72) 42%, oklch(0.96 0.045 82) 58%, oklch(0.60 0.045 68) 78%, oklch(0.88 0.055 76) 92%, oklch(0.52 0.035 75))',
            boxShadow: '0 26px 50px -20px oklch(0.01 0.004 70 / 90%), 0 0 0 1px oklch(0.98 0.01 85 / 6%)',
          }}
        >
          <div
            className="grid h-[80%] w-[80%] place-items-center rounded-full bg-[oklch(0.12_0.008_70)]"
            style={{ boxShadow: 'inset 0 3px 10px oklch(0.01 0.004 70 / 0.9), inset 0 -1px 0 oklch(0.98 0.01 85 / 7%)' }}
          >
            <span
              className="font-display text-4xl font-light text-primary"
              style={{ textShadow: '0 1px 0 oklch(0.01 0.004 70 / 0.9), 0 0 18px oklch(0.87 0.07 72 / 0.3)' }}
            >
              A
            </span>
          </div>
        </motion.div>

        {/* Título */}
        <motion.h1
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.35, duration: 0.6 }}
          className="font-display text-[2.6rem] font-light leading-[1.08] tracking-tight"
        >
          {'Seu estilo,'}
          <br />
          <span className="text-aura font-medium">{'com precisão'}</span>
        </motion.h1>

        {/* Subtítulo */}
        <motion.p
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.55, duration: 0.6 }}
          className="text-[15px] text-muted-foreground leading-relaxed max-w-[19rem]"
        >
          Análise do teu rosto, cabelo e corpo. Rotinas que se adaptam a ti —
          e compras inteligentes com preços do teu país.
        </motion.p>

        {/* CTA Button */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.75, duration: 0.6 }}
          className="w-full mt-2"
        >
          <GlowButton onClick={onStart} className="w-full text-base py-5 tracking-wide">
            Começar minha transformação
          </GlowButton>
        </motion.div>
      </motion.div>
    </div>
  );
}
