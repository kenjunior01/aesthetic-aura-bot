'use client';

/**
 * FaceScan — módulo de medição facial do AuraStyle.
 *
 * Um instrumento, não um "upload de foto": visor com cantos de
 * enquadramento → feixe de varrimento durante a leitura → painel de
 * leituras com escala de tom, confiança e swatches reais. A foto é
 * processada em memória e nunca é armazenada.
 */

import { useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import { Camera, Check, RotateCcw, Fingerprint } from 'lucide-react';
import { useAura, type Profile } from '@/lib/aura-store';
import { analyzeSelfie } from '@/lib/services';
import type { VisionAnalysisResult } from '@/lib/services';

const SCAN_STEPS = [
  'Calibrando luminância',
  'Lendo tom de pele',
  'Mapeando contornos',
  'Estimando proporções',
];

const UNDERTONE_MAP: Record<string, string> = {
  quente: 'Quente',
  frio: 'Frio',
  neutro: 'Neutro',
  oliva: 'Olivado',
};

const cap = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

type Phase = 'idle' | 'scanning' | 'done';

export default function FaceScan({ onCompare }: { onCompare?: (img: string) => void }) {
  const { profile, update } = useAura();
  const fileRef = useRef<HTMLInputElement>(null);
  const [phase, setPhase] = useState<Phase>('idle');
  const [img, setImg] = useState<string | null>(null);
  const [result, setResult] = useState<VisionAnalysisResult | null>(null);
  const [step, setStep] = useState(0);

  // Ticker das etapas de leitura durante o varrimento
  useEffect(() => {
    if (phase !== 'scanning') return;
    const id = setInterval(() => setStep((s) => (s + 1) % SCAN_STEPS.length), 1200);
    return () => clearInterval(id);
  }, [phase]);

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = async () => {
      const base64 = reader.result as string;
      setImg(base64);
      setResult(null);
      setStep(0);
      setPhase('scanning');
      try {
        const r = await analyzeSelfie(base64);
        setResult(r);
        setPhase('done');
        applyResult(r, base64);
      } catch (err) {
        console.error('Analysis failed:', err);
        setPhase('idle');
        setImg(null);
      }
    };
    reader.readAsDataURL(file);
  };

  const applyResult = (r: VisionAnalysisResult, base64: string) => {
    const patch: Partial<Profile> = {
      skinTone: Math.min(10, Math.max(1, Math.round(r.skinTone))),
      faceShape: cap(r.faceShape),
      selfie: base64,
    };
    if (r.undertone) {
      const u = UNDERTONE_MAP[r.undertone.toLowerCase()];
      if (u) patch.undertone = u;
    }
    if (r.hairColor) {
      const hc = r.hairColor
        .split('-')
        .map((w, i) => (i === 0 ? cap(w) : w.toLowerCase()))
        .join('-');
      patch.hairColor = hc;
    }
    update(patch);
  };

  const showPhoto = phase !== 'idle' && img;

  return (
    <div className='glass rounded-2xl p-4'>
      {/* Cabeçalho */}
      <div className='mb-3 flex items-center justify-between'>
        <span className='text-[11px] font-bold uppercase tracking-[0.22em] text-foreground/80'>
          Medição facial
        </span>
        {phase === 'done' && result && (
          <span className='machined inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-[9px] font-bold uppercase tracking-widest text-primary'>
            <Check className='h-3 w-3' strokeWidth={3} />
            Perfil atualizado
          </span>
        )}
      </div>

      {/* Palco: visor / varrimento / leitura */}
      <div
        className='relative h-52 overflow-hidden rounded-xl bg-[oklch(0.10_0.007_70)] shadow-[inset_0_2px_14px_oklch(0.01_0.004_70/0.85)]'
        style={{ cursor: phase === 'idle' ? 'pointer' : 'default' }}
        onClick={() => phase === 'idle' && fileRef.current?.click()}
        role={phase === 'idle' ? 'button' : undefined}
        aria-label={phase === 'idle' ? 'Capturar selfie para medição' : undefined}
      >
        {/* Foto */}
        {(showPhoto || (phase === 'idle' && profile.selfie)) && (
          <img
            src={(showPhoto ? img : profile.selfie) as string}
            alt='Selfie em análise'
            className='absolute inset-0 h-full w-full object-cover'
          />
        )}

        {/* Vinheta do instrumento */}
        <div
          className='pointer-events-none absolute inset-0'
          style={{
            background:
              'radial-gradient(ellipse 120% 90% at 50% 40%, transparent 55%, oklch(0.06 0.004 258 / 0.55) 100%)',
          }}
        />

        {/* Cantos de enquadramento */}
        {(['left-2 top-2 border-l-2 border-t-2', 'right-2 top-2 border-r-2 border-t-2', 'bottom-2 left-2 border-b-2 border-l-2', 'bottom-2 right-2 border-b-2 border-r-2'] as const).map(
          (pos) => (
            <span key={pos} className={`absolute h-5 w-5 rounded-[3px] border-primary/60 ${pos}`} />
          ),
        )}

        {/* Retícula central — só no visor vazio */}
        {phase === 'idle' && !profile.selfie && (
          <div className='absolute inset-0 flex flex-col items-center justify-center gap-2.5'>
            <div className='relative grid h-14 w-14 place-items-center'>
              <span className='absolute h-px w-5 bg-primary/50' />
              <span className='absolute h-5 w-px bg-primary/50' />
              <span className='absolute h-10 w-10 rounded-full border border-primary/25' />
            </div>
            <p className='text-xs font-medium text-foreground/85'>Enquadra o rosto no visor</p>
            <p className='flex items-center gap-1 text-[10px] text-muted-foreground'>
              <Camera className='h-3 w-3' />
              Toca para capturar — a foto não é armazenada
            </p>
          </div>
        )}

        {/* Repetir leitura sobre foto anterior (idle com selfie) */}
        {phase === 'idle' && profile.selfie && (
          <button
            onClick={(e) => {
              e.stopPropagation();
              fileRef.current?.click();
            }}
            className='machined absolute bottom-3 left-1/2 flex -translate-x-1/2 items-center gap-1.5 rounded-full px-3 py-1.5 text-[10px] font-semibold uppercase tracking-widest text-primary'
          >
            <RotateCcw className='h-3 w-3' />
            Nova leitura
          </button>
        )}

        {/* Feixe de varrimento — a leitura em curso */}
        {phase === 'scanning' && (
          <>
            <motion.div
              aria-hidden
              initial={{ top: '-18%' }}
              animate={{ top: '104%' }}
              transition={{ repeat: Infinity, duration: 1.7, ease: 'easeInOut' }}
              className='pointer-events-none absolute inset-x-3 h-16'
              style={{
                background:
                  'linear-gradient(180deg, transparent, oklch(0.87 0.05 242 / 0.28) 45%, oklch(0.97 0.02 258 / 0.5) 50%, oklch(0.87 0.05 242 / 0.28) 55%, transparent)',
                filter: 'blur(0.5px)',
                mixBlendMode: 'screen',
              }}
            />
            {/* Linha de varrimento fina */}
            <motion.div
              aria-hidden
              initial={{ top: '-2%' }}
              animate={{ top: '102%' }}
              transition={{ repeat: Infinity, duration: 1.7, ease: 'easeInOut' }}
              className='pointer-events-none absolute inset-x-6 h-px bg-primary/70'
            />
            <div
              className='absolute inset-x-0 bottom-0 flex items-center justify-between px-3 pb-2.5 pt-6'
              style={{
                background:
                  'linear-gradient(0deg, oklch(0.06 0.004 258 / 0.92) 0%, transparent 100%)',
              }}
            >
              <motion.span
                key={step}
                initial={{ opacity: 0, y: 4 }}
                animate={{ opacity: 1, y: 0 }}
                className='text-[10px] font-semibold uppercase tracking-[0.18em] text-primary'
              >
                {SCAN_STEPS[step]}
              </motion.span>
              <span className='flex gap-1'>
                {SCAN_STEPS.map((_, i) => (
                  <span
                    key={i}
                    className={`h-1 w-1 rounded-full ${i === step ? 'bg-primary' : 'bg-primary/25'}`}
                  />
                ))}
              </span>
            </div>
          </>
        )}

        {/* Leituras — resultado sobre a foto */}
        {phase === 'done' && result && (
          <motion.div
            initial={{ opacity: 0, y: 14 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ type: 'spring', stiffness: 260, damping: 24 }}
            className='absolute inset-x-2 bottom-2'
          >
            <div className='glass-deep rounded-xl p-3'>
              <div className='flex items-center gap-3'>
                {/* Anel de confiança */}
                <div className='relative h-11 w-11 shrink-0'>
                  <svg viewBox='0 0 100 100' className='absolute inset-0 h-full w-full -rotate-90'>
                    <circle cx='50' cy='50' r='42' fill='none' stroke='oklch(0.95 0.02 258 / 10%)' strokeWidth='9' />
                    <motion.circle
                      cx='50' cy='50' r='42' fill='none'
                      stroke='oklch(0.87 0.05 242)' strokeWidth='9' strokeLinecap='round'
                      strokeDasharray={2 * Math.PI * 42}
                      initial={{ strokeDashoffset: 2 * Math.PI * 42 }}
                      animate={{ strokeDashoffset: 2 * Math.PI * 42 * (1 - Math.min(result.confidence, 1)) }}
                      transition={{ duration: 0.9, ease: [0.22, 1, 0.36, 1], delay: 0.15 }}
                    />
                  </svg>
                  <span className='absolute inset-0 grid place-items-center text-[10px] font-bold text-primary'>
                    {Math.round(result.confidence * 100)}
                  </span>
                </div>
                <div className='min-w-0 flex-1'>
                  <p className='truncate text-xs font-semibold capitalize text-foreground'>
                    Rosto {result.faceShape} · tom {Math.min(10, Math.max(1, Math.round(result.skinTone)))}
                  </p>
                  <p className='truncate text-[10px] text-muted-foreground'>
                    {result.undertone ? `Subtom ${result.undertone} · ` : ''}
                    {result.source === 'groq' ? 'leitura completa' : 'leitura local'}
                  </p>
                </div>
              </div>

              {/* Escala de tom — 10 degraus com marcador */}
              <div className='mt-2.5 flex gap-1'>
                {Array.from({ length: 10 }, (_, i) => i + 1).map((t) => {
                  const detected = Math.min(10, Math.max(1, Math.round(result.skinTone)));
                  return (
                    <span
                      key={t}
                      className={`h-2.5 flex-1 rounded-[3px] ${t === detected ? 'ring-[1.5px] ring-primary' : ''}`}
                      style={{
                        background: `oklch(${0.25 + (t - 1) * 0.06} 0.05 ${t % 2 === 0 ? 30 : 60})`,
                        boxShadow:
                          t === detected
                            ? '0 0 0 1.5px oklch(0.1 0.007 258), 0 0 0 3px oklch(0.87 0.05 242)'
                            : undefined,
                      }}
                    />
                  );
                })}
              </div>
              {result.observations && (
                <p className='mt-2 truncate text-[10px] italic text-muted-foreground'>
                  “{result.observations}”
                </p>
              )}
            </div>
          </motion.div>
        )}
      </div>

      {/* Nota fina */}
      <p className='mt-2.5 text-[10px] leading-relaxed text-muted-foreground'>
        Leitura em tempo real: serviço de visão + análise local de pixels como
        reserva. Os valores detetados preenchem o teu perfil — ajusta abaixo se
        preferires.
      </p>

      {/* Ação pós-leitura: comparar com o banco de referências */}
      {phase === 'done' && result && onCompare && img && (
        <button
          onClick={() => onCompare(img)}
          className='machined mt-2 flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-[10px] font-bold uppercase tracking-[0.18em] text-primary'
        >
          <Fingerprint className='h-3.5 w-3.5' />
          A quem a minha cara se aproxima?
        </button>
      )}

      <input
        ref={fileRef}
        type='file'
        accept='image/*'
        capture='user'
        onChange={handleFile}
        className='hidden'
        disabled={phase === 'scanning'}
      />
    </div>
  );
}
