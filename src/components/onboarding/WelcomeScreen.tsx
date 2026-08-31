'use client';

/**
 * WelcomeScreen — herói cinematográfico: um instrumento de precisão
 * suspenso em profundidade real (perspective + translateZ).
 *
 * Camadas: órbita profunda com satélite → aro usinado com marcas de
 * minuto → mostrador elevado gravado. A luz de estúdio segue o tilt
 * (ponteiro no desktop, giroscópio no aparelho real via Capacitor).
 */

import { motion, useTransform, useMotionTemplate } from 'framer-motion';
import { AuroraBackground } from '@/components/aura/AuroraBackground';
import { GlowButton } from '@/components/aura/ui';
import { useTiltSource } from '@/hooks/useTiltSource';

export default function WelcomeScreen({ onStart, onSkip }: { onStart: () => void; onSkip: () => void }) {
  const { x, y, pointerHandlers } = useTiltSource();

  // O instrumento responde à mão / ao aparelho
  const rotX = useTransform(y, [-0.5, 0.5], [9, -9]);
  const rotY = useTransform(x, [-0.5, 0.5], [-11, 11]);
  const lightX = useTransform(x, (v) => 50 + v * 150);
  const lightY = useTransform(y, (v) => 40 + v * 150);
  const studioLight = useMotionTemplate`radial-gradient(circle at ${lightX}% ${lightY}%, oklch(0.97 0.02 85 / 0.15), transparent 56%)`;

  return (
    <div className="relative flex min-h-screen flex-col items-center justify-center px-6 text-center">
      <AuroraBackground />

      {/* Skip link */}
      <button
        onClick={onSkip}
        className="absolute top-6 right-6 z-10 text-sm text-muted-foreground transition-colors hover:text-foreground"
      >
        Já tenho conta
      </button>

      {/* ── Herói 3D ─────────────────────────────────────────────── */}
      <motion.div
        initial={{ opacity: 0, scale: 0.86 }}
        animate={{ opacity: 1, scale: 1 }}
        transition={{ duration: 0.9, ease: [0.22, 1, 0.36, 1] }}
        className="relative z-10 mb-10 h-[13.5rem] w-[13.5rem] touch-pan-y"
        style={{ perspective: 1100, ...pointerHandlers }}
      >
        <motion.div
          className="absolute inset-0"
          style={{ rotateX: rotX, rotateY: rotY, transformStyle: 'preserve-3d' }}
        >
          {/* Camada profunda — órbita fina + satélite esférico */}
          <div
            className="absolute inset-[5%] rounded-full border border-dashed border-primary/[0.14]"
            style={{ transform: 'translateZ(-46px)' }}
          />
          <motion.div
            animate={{ rotate: 360 }}
            transition={{ repeat: Infinity, duration: 24, ease: 'linear' }}
            className="absolute inset-[5%]"
            style={{ transform: 'translateZ(-46px)', transformStyle: 'preserve-3d' }}
          >
            <div
              className="absolute left-1/2 top-0 h-1.5 w-1.5 -translate-x-1/2 -translate-y-1/2 rounded-full"
              style={{
                background:
                  'radial-gradient(circle at 32% 28%, oklch(0.97 0.02 85), oklch(0.87 0.07 72) 45%, oklch(0.6 0.08 55) 100%)',
                boxShadow: '0 0 9px 1px oklch(0.87 0.07 72 / 0.5)',
              }}
            />
          </motion.div>

          {/* Aro usinado com marcas de minuto — plano de referência */}
          <motion.div
            initial={{ opacity: 0, scale: 0.78 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.22, type: 'spring', stiffness: 170, damping: 20 }}
            className="absolute inset-0"
          >
            <div
              className="absolute inset-0 rounded-full border border-primary/[0.22]"
              style={{
                background:
                  'conic-gradient(from 200deg, oklch(0.58 0.04 75), oklch(0.95 0.055 78) 20%, oklch(0.70 0.045 72) 42%, oklch(0.97 0.045 82) 58%, oklch(0.64 0.045 68) 78%, oklch(0.90 0.055 76) 92%, oklch(0.58 0.04 75))',
                WebkitMask: 'radial-gradient(circle, transparent 66.5%, black 67%)',
                mask: 'radial-gradient(circle, transparent 66.5%, black 67%)',
                filter: 'drop-shadow(0 22px 34px oklch(0.01 0.004 70 / 0.8))',
              }}
            />
            {/* Marcas de minuto gravadas no aro */}
            <div
              className="absolute inset-0 rounded-full"
              style={{
                background:
                  'repeating-conic-gradient(from 0deg, oklch(0.16 0.01 70 / 0.85) 0deg 0.7deg, transparent 0.7deg 6deg)',
                WebkitMask: 'radial-gradient(circle, transparent 63%, black 63.5%, black 71%, transparent 71.5%)',
                mask: 'radial-gradient(circle, transparent 63%, black 63.5%, black 71%, transparent 71.5%)',
              }}
            />
          </motion.div>

          {/* Mostrador elevado — flutua acima do aro */}
          <motion.div
            initial={{ y: 40, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            transition={{ delay: 0.42, type: 'spring', stiffness: 150, damping: 17 }}
            className="absolute inset-[19%] rounded-full"
            style={{ transform: 'translateZ(36px)' }}
          >
            <div
              className="absolute inset-0 rounded-full"
              style={{
                background:
                  'conic-gradient(from 160deg, oklch(0.55 0.04 75), oklch(0.92 0.06 78) 22%, oklch(0.68 0.05 72) 46%, oklch(0.95 0.05 82) 62%, oklch(0.60 0.045 68) 82%, oklch(0.55 0.04 75))',
                boxShadow: '0 26px 46px -18px oklch(0.01 0.004 70 / 92%)',
              }}
            />
            <div
              className="absolute inset-[6%] grid place-items-center rounded-full bg-[oklch(0.12_0.008_70)]"
              style={{
                boxShadow:
                  'inset 0 4px 12px oklch(0.01 0.004 70 / 0.92), inset 0 -1px 0 oklch(0.98 0.01 85 / 8%)',
              }}
            >
              <motion.span
                initial={{ opacity: 0, filter: 'blur(6px)', letterSpacing: '0.35em' }}
                animate={{ opacity: 1, filter: 'blur(0px)', letterSpacing: '0em' }}
                transition={{ delay: 0.72, duration: 0.85, ease: [0.22, 1, 0.36, 1] }}
                className="font-display text-4xl font-light text-primary"
                style={{ textShadow: '0 1px 0 oklch(0.01 0.004 70 / 0.9), 0 0 20px oklch(0.87 0.07 72 / 0.32)' }}
              >
                A
              </motion.span>
            </div>
          </motion.div>

          {/* Luz de estúdio que acompanha o tilt — o metal responde */}
          <motion.div
            aria-hidden
            className="pointer-events-none absolute inset-[-14%] rounded-full"
            style={{ background: studioLight }}
          />

          {/* Varrimento de luz único na entrada — como um selo a ser revelado */}
          <div className="absolute inset-0 overflow-hidden rounded-full">
            <motion.div
              aria-hidden
              initial={{ x: '-150%' }}
              animate={{ x: '280%' }}
              transition={{ delay: 1.05, duration: 1.15, ease: [0.3, 0, 0.2, 1] }}
              className="absolute inset-y-[-20%] w-[38%] -skew-x-12"
              style={{
                background:
                  'linear-gradient(90deg, transparent, oklch(0.97 0.02 85 / 0.2) 45%, oklch(0.97 0.02 85 / 0.26) 55%, transparent)',
                mixBlendMode: 'screen',
              }}
            />
          </div>
        </motion.div>
      </motion.div>

      {/* ── Mensagem ─────────────────────────────────────────────── */}
      <div className="relative z-10 flex max-w-sm flex-col items-center gap-7">
        <motion.h1
          initial={{ y: 22, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.62, duration: 0.65, ease: [0.22, 1, 0.36, 1] }}
          className="font-display text-[2.6rem] font-light leading-[1.08] tracking-tight"
        >
          {'Seu estilo,'}
          <br />
          <span className="text-aura font-medium">{'com precisão'}</span>
        </motion.h1>

        <motion.p
          initial={{ y: 22, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.78, duration: 0.65, ease: [0.22, 1, 0.36, 1] }}
          className="max-w-[19rem] text-[15px] leading-relaxed text-muted-foreground"
        >
          Análise do teu rosto, cabelo e corpo. Rotinas que se adaptam a ti — e
          compras inteligentes com preços do teu país.
        </motion.p>

        <motion.div
          initial={{ y: 22, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          transition={{ delay: 0.92, duration: 0.65, ease: [0.22, 1, 0.36, 1] }}
          className="mt-2 w-full"
        >
          <GlowButton onClick={onStart} className="w-full py-5 text-base tracking-wide">
            Começar minha transformação
          </GlowButton>
        </motion.div>
      </div>
    </div>
  );
}
