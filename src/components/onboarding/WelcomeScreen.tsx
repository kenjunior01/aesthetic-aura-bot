'use client';

import { motion } from 'framer-motion';
import { Sparkles } from 'lucide-react';
import { AuroraBackground } from '@/components/aura/AuroraBackground';
import { GlowButton } from '@/components/aura/ui';

export default function WelcomeScreen({ onStart, onSkip }: { onStart: () => void; onSkip: () => void }) {
  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center px-6 text-center">
      <AuroraBackground dense />

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
        className="relative z-10 flex flex-col items-center gap-6 max-w-sm"
      >
        {/* Logo / Icon */}
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ delay: 0.2, type: 'spring', stiffness: 200 }}
          className="flex h-20 w-20 items-center justify-center rounded-3xl glass glow"
        >
          <Sparkles className="h-10 w-10 text-aura" />
        </motion.div>

        {/* Title */}
        <motion.h1
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.4, duration: 0.6 }}
          className="text-4xl font-bold leading-tight"
        >
          {'Seu estilo,'}
          <br />
          <span className="text-aura">{'reinventado'}</span>
          <br />
          {'pela inteligência'}
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.6, duration: 0.6 }}
          className="text-base text-muted-foreground leading-relaxed"
        >
          Descubra o que combina perfeitamente com você
        </motion.p>

        {/* CTA Button */}
        <motion.div
          initial={{ y: 20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.8, duration: 0.6 }}
          className="w-full mt-4"
        >
          <GlowButton onClick={onStart} className="w-full text-lg py-5">
            Começar minha transformação
          </GlowButton>
        </motion.div>
      </motion.div>
    </div>
  );
}
