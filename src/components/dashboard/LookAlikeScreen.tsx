'use client';

/**
 * LookAlikeScreen — "A quem a tua cara se aproxima?"
 *
 * Compara os traços medidos da selfie com o banco de referências
 * (arquétipos originais em Prisma), mostra o pódio de proximidade,
 * a comparação traço a traço e o plano de upgrade personalizado.
 */

import { useEffect, useRef, useState } from 'react';
import { motion } from 'framer-motion';
import { ChevronLeft, Camera, Fingerprint, ArrowRight, ScanFace } from 'lucide-react';
import { useAura } from '@/lib/aura-store';
import { API_BASE } from '@/lib/api-base';
import { GlowButton } from '@/components/aura/ui';
import type { LookMatch, TraitCompare } from '@/lib/references';

const SCAN_STEPS = [
  'Medindo a tua estrutura',
  'Consultando o banco de referências',
  'Comparando traço a traço',
  'A escrever o teu upgrade',
];

type PlanItem = { area: string; action: string; why: string; trait: string };
type RefPreview = { slug: string; name: string; tagline: string; image: string };

type ApiResponse = {
  matches: LookMatch[];
  verdict: { headline: string; detail: string };
  plan: PlanItem[];
  signatures: string[];
  total: number;
  source: 'vision' | 'profile';
  error?: string;
};

type Stage = 'ask' | 'scanning' | 'result';

export default function LookAlikeScreen({
  onClose,
  initialImage,
}: {
  onClose: () => void;
  initialImage?: string | null;
}) {
  const { profile } = useAura();
  const fileRef = useRef<HTMLInputElement>(null);
  const [stage, setStage] = useState<Stage>(initialImage ? 'scanning' : 'ask');
  const [img, setImg] = useState<string | null>(initialImage || null);
  const [data, setData] = useState<ApiResponse | null>(null);
  const [gallery, setGallery] = useState<RefPreview[]>([]);
  const [step, setStep] = useState(0);
  const [error, setError] = useState('');

  // Galeria do banco (GET) — pré-visualização no estágio de pedido
  useEffect(() => {
    fetch(`${API_BASE}/api/look-alike`)
      .then((r) => r.json())
      .then((g: { references?: RefPreview[] }) => setGallery(g.references || []))
      .catch(() => {});
  }, []);

  const run = async (image: string | null) => {
    setStage('scanning');
    setStep(0);
    setError('');
    try {
      const res = await fetch(`${API_BASE}/api/look-alike`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          imageBase64: image,
          profile: {
            faceShape: profile.faceShape,
            skinTone: profile.skinTone,
            hairType: profile.hairType,
          },
        }),
      });
      const json = (await res.json()) as ApiResponse;
      if (!res.ok) throw new Error(json.error || 'Falha na comparação');
      setData(json);
      setStage('result');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Falha na comparação');
      setStage('ask');
    }
  };

  // Ticker durante a comparação
  useEffect(() => {
    if (stage !== 'scanning') return;
    const id = setInterval(() => setStep((s) => (s + 1) % SCAN_STEPS.length), 1400);
    return () => clearInterval(id);
  }, [stage]);

  // Arranque automático quando vem de uma análise
  useEffect(() => {
    if (initialImage && stage === 'scanning' && !data) run(initialImage);
  }, []);

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      const base64 = reader.result as string;
      setImg(base64);
      run(base64);
    };
    reader.readAsDataURL(file);
  };

  const top = data?.matches?.[0];
  const rest = data?.matches?.slice(1) ?? [];

  return (
    <div className='relative z-10 mx-auto min-h-screen max-w-lg px-4 pb-10 pt-6'>
      {/* Cabeçalho */}
      <div className='mb-6 flex items-center gap-3'>
        <button onClick={onClose} className='glass flex h-10 w-10 items-center justify-center rounded-xl'>
          <ChevronLeft className='h-5 w-5' />
        </button>
        <div className='flex-1'>
          <h1 className='text-xl font-bold'>Referências</h1>
          <p className='text-xs text-muted-foreground'>A quem a tua cara se aproxima — e como subir de nível</p>
        </div>
        <span className='machined rounded-full px-2.5 py-1 text-[9px] font-bold uppercase tracking-widest text-primary'>
          Banco · {gallery.length || 8}
        </span>
      </div>

      {/* ── Pedido de selfie ── */}
      {stage === 'ask' && (
        <div className='flex flex-col gap-4'>
          <div
            className='relative h-52 overflow-hidden rounded-xl bg-[oklch(0.10_0.007_258)] shadow-[inset_0_2px_14px_oklch(0.01_0.004_258/0.85)]'
            style={{ cursor: 'pointer' }}
            onClick={() => fileRef.current?.click()}
          >
            {(['left-2 top-2 border-l-2 border-t-2', 'right-2 top-2 border-r-2 border-t-2', 'bottom-2 left-2 border-b-2 border-l-2', 'bottom-2 right-2 border-b-2 border-r-2'] as const).map(
              (pos) => (
                <span key={pos} className={`absolute h-5 w-5 rounded-[3px] border-primary/60 ${pos}`} />
              ),
            )}
            <div className='absolute inset-0 flex flex-col items-center justify-center gap-2.5'>
              <div className='relative grid h-14 w-14 place-items-center'>
                <span className='absolute h-px w-5 bg-primary/50' />
                <span className='absolute h-5 w-px bg-primary/50' />
                <span className='absolute h-10 w-10 rounded-full border border-primary/25' />
              </div>
              <p className='text-xs font-medium text-foreground/85'>Enquadra o rosto no visor</p>
              <p className='flex items-center gap-1 text-[10px] text-muted-foreground'>
                <Camera className='h-3 w-3' />
                A foto é processada e não é armazenada
              </p>
            </div>
          </div>

          {profile.selfie && (
            <GlowButton onClick={() => run(profile.selfie as string)} className='w-full'>
              <ScanFace className='mr-2 h-5 w-5' />
              Usar a última selfie
            </GlowButton>
          )}
          {error && <p className='text-center text-xs text-destructive'>{error}</p>}

          <p className='px-2 text-[10px] leading-relaxed text-muted-foreground'>
            O banco tem arquétipos originais do AuraStyle — rostos de estúdio
            com traços canónicos, não pessoas reais. A comparação é traço a
            traço: estrutura, maxilar, maçãs, olhos, sobrancelhas, textura e tom.
          </p>

          {/* Galeria do banco */}
          {gallery.length > 0 && (
            <div>
              <span className='text-[10px] font-bold uppercase tracking-[0.22em] text-foreground/80'>
                O banco de referências
              </span>
              <div className='no-scrollbar -mx-4 mt-2.5 flex gap-3 overflow-x-auto px-4 pb-1'>
                {gallery.map((g) => (
                  <div key={g.slug} className='w-24 shrink-0'>
                    <img
                      src={g.image}
                      alt={g.name}
                      className='aspect-[3/4] w-full rounded-lg object-cover'
                      style={{ boxShadow: '0 10px 22px -12px oklch(0.01 0.005 258 / 0.9)' }}
                    />
                    <span className='mt-1.5 block truncate text-center text-[10px] font-semibold text-foreground/80'>{g.name}</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* ── Comparação em curso ── */}
      {stage === 'scanning' && (
        <div className='relative h-52 overflow-hidden rounded-xl bg-[oklch(0.10_0.007_258)] shadow-[inset_0_2px_14px_oklch(0.01_0.004_258/0.85)]'>
          {img && <img src={img} alt='A comparar' className='absolute inset-0 h-full w-full object-cover' />}
          <motion.div
            aria-hidden
            initial={{ top: '-18%' }}
            animate={{ top: '104%' }}
            transition={{ repeat: Infinity, duration: 1.8, ease: 'easeInOut' }}
            className='pointer-events-none absolute inset-x-3 h-16'
            style={{
              background:
                'linear-gradient(180deg, transparent, oklch(0.87 0.05 242 / 0.28) 45%, oklch(0.97 0.012 238 / 0.5) 50%, oklch(0.87 0.05 242 / 0.28) 55%, transparent)',
              mixBlendMode: 'screen',
            }}
          />
          <div
            className='absolute inset-x-0 bottom-0 flex items-center justify-between px-3 pb-2.5 pt-6'
            style={{ background: 'linear-gradient(0deg, oklch(0.06 0.005 258 / 0.92) 0%, transparent 100%)' }}
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
                <span key={i} className={`h-1 w-1 rounded-full ${i === step ? 'bg-primary' : 'bg-primary/25'}`} />
              ))}
            </span>
          </div>
        </div>
      )}

      {/* ── Resultado ── */}
      {stage === 'result' && data && top && (
        <motion.div initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} className='flex flex-col gap-5'>
          {/* Veredito */}
          <div className='glass rounded-2xl p-4'>
            <span className='text-[10px] font-bold uppercase tracking-[0.22em] text-primary'>Veredito</span>
            <h2 className='mt-1 font-display text-lg font-medium leading-snug'>{data.verdict.headline}</h2>
            <p className='mt-1 text-xs leading-relaxed text-muted-foreground'>{data.verdict.detail}</p>
          </div>

          {/* Match nº1 — retrato + anel de proximidade */}
          <div className='glass-deep overflow-hidden rounded-2xl'>
            <div className='flex gap-4 p-4'>
              <div className='relative w-[38%] shrink-0'>
                <img
                  src={top.image}
                  alt={top.name}
                  className='aspect-[3/4] w-full rounded-xl object-cover'
                  style={{ boxShadow: '0 14px 30px -14px oklch(0.01 0.005 258 / 0.9), inset 0 1px 0 oklch(0.98 0.008 238 / 0.14)' }}
                />
                <span className='machined absolute left-2 top-2 rounded-full px-2 py-0.5 text-[8px] font-bold uppercase tracking-widest text-primary'>
                  1º mais próximo
                </span>
              </div>
              <div className='flex min-w-0 flex-1 flex-col'>
                <div className='flex items-start justify-between gap-2'>
                  <div className='min-w-0'>
                    <h3 className='font-display text-lg font-semibold leading-tight'>{top.name}</h3>
                    <p className='mt-0.5 text-[11px] italic leading-snug text-muted-foreground'>“{top.tagline}”</p>
                  </div>
                  {/* Anel de proximidade */}
                  <div className='relative h-14 w-14 shrink-0'>
                    <svg viewBox='0 0 100 100' className='absolute inset-0 h-full w-full -rotate-90'>
                      <circle cx='50' cy='50' r='42' fill='none' stroke='oklch(0.95 0.012 240 / 10%)' strokeWidth='8' />
                      <motion.circle
                        cx='50' cy='50' r='42' fill='none'
                        stroke='oklch(0.87 0.05 242)' strokeWidth='8' strokeLinecap='round'
                        strokeDasharray={2 * Math.PI * 42}
                        initial={{ strokeDashoffset: 2 * Math.PI * 42 }}
                        animate={{ strokeDashoffset: 2 * Math.PI * 42 * (1 - top.score / 100) }}
                        transition={{ duration: 1, ease: [0.22, 1, 0.36, 1], delay: 0.2 }}
                      />
                    </svg>
                    <span className='absolute inset-0 grid place-items-center text-xs font-bold text-primary'>
                      {top.score}%
                    </span>
                  </div>
                </div>
                <p className='mt-2 text-[11px] leading-relaxed text-foreground/80'>{data.source === 'vision' ? 'Comparação feita a partir da tua selfie.' : 'Comparação feita a partir do teu perfil — captura uma selfie para medir todos os traços.'}</p>
                <button
                  onClick={() => fileRef.current?.click()}
                  className='machined mt-auto inline-flex w-fit items-center gap-1.5 rounded-full px-3 py-1.5 text-[10px] font-semibold uppercase tracking-widest text-primary'
                >
                  <Camera className='h-3 w-3' />
                  Nova comparação
                </button>
              </div>
            </div>
          </div>

          {/* Traço a traço */}
          <div className='glass rounded-2xl p-4'>
            <span className='text-[10px] font-bold uppercase tracking-[0.22em] text-foreground/80'>
              Traço a traço · tu ↔ {top.name}
            </span>
            <div className='mt-3 flex flex-col gap-2.5'>
              {top.traits.map((t: TraitCompare) => (
                <div key={t.key}>
                  <div className='flex items-baseline justify-between gap-2'>
                    <span className='text-[11px] font-semibold text-foreground/85'>{t.label}</span>
                    <span className='text-[10px] text-muted-foreground'>
                      <span className='capitalize'>{t.yours === 'não medido' ? '—' : t.yours}</span>
                      {' ↔ '}
                      <span className='capitalize text-primary/90'>{t.theirs}</span>
                    </span>
                  </div>
                  <div className='mt-1 h-1 w-full overflow-hidden rounded-full bg-surface-strong'>
                    <motion.div
                      className='h-full rounded-full'
                      initial={{ width: 0 }}
                      animate={{ width: `${Math.round(t.closeness * 100)}%` }}
                      transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
                      style={{
                        background:
                          t.closeness >= 0.99
                            ? 'linear-gradient(90deg, oklch(0.78 0.043 246), oklch(0.9 0.047 240))'
                            : 'oklch(0.87 0.05 242 / 0.45)',
                      }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Plano de upgrade */}
          {data.plan.length > 0 && (
            <div className='glass rounded-2xl p-4'>
              <span className='text-[10px] font-bold uppercase tracking-[0.22em] text-foreground/80'>
                Teu upgrade · o que {top.name} te ensina
              </span>
              <div className='mt-3 flex flex-col gap-3'>
                {data.plan.map((p, i) => (
                  <motion.div
                    key={i}
                    initial={{ opacity: 0, x: -10 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.15 + i * 0.1 }}
                    className='machined rounded-xl p-3'
                  >
                    <div className='flex items-center gap-2'>
                      <span className='grid h-5 w-5 place-items-center rounded-full bg-aura text-[10px] font-bold text-primary-foreground'>
                        {i + 1}
                      </span>
                      <span className='text-[9px] font-bold uppercase tracking-widest text-primary'>{p.area}</span>
                      {p.trait.toLowerCase() !== p.area.toLowerCase() && (
                        <span className='text-[9px] uppercase tracking-wider text-muted-foreground'>· {p.trait}</span>
                      )}
                    </div>
                    <p className='mt-1.5 text-xs font-medium leading-snug text-foreground'>{p.action}</p>
                    <p className='mt-1 text-[10px] leading-relaxed text-muted-foreground'>{p.why}</p>
                  </motion.div>
                ))}
              </div>
            </div>
          )}

          {/* Restantes matches */}
          {rest.length > 0 && (
            <div className='glass rounded-2xl p-4'>
              <span className='text-[10px] font-bold uppercase tracking-[0.22em] text-foreground/80'>
                Também no teu radar
              </span>
              <div className='mt-3 flex flex-col gap-2'>
                {rest.map((m, i) => (
                  <div key={m.slug} className='flex items-center gap-3'>
                    <img src={m.image} alt={m.name} className='h-11 w-11 rounded-lg object-cover' />
                    <div className='min-w-0 flex-1'>
                      <span className='text-xs font-semibold text-foreground'>
                        {i + 2}º · {m.name}
                      </span>
                      <p className='truncate text-[10px] text-muted-foreground'>{m.tagline}</p>
                    </div>
                    <span className='machined rounded-full px-2 py-1 text-[10px] font-bold text-primary'>{m.score}%</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Ficha do arquétipo */}
          {data.signatures.length > 0 && (
            <div className='glass rounded-2xl p-4'>
              <span className='flex items-center gap-1.5 text-[10px] font-bold uppercase tracking-[0.22em] text-foreground/80'>
                <Fingerprint className='h-3 w-3 text-primary' />
                Assinaturas de {top.name}
              </span>
              <ul className='mt-2.5 flex flex-col gap-2'>
                {data.signatures.map((s, i) => (
                  <li key={i} className='flex items-start gap-2 text-[11px] leading-relaxed text-foreground/80'>
                    <ArrowRight className='mt-0.5 h-3 w-3 shrink-0 text-primary/70' />
                    {s}
                  </li>
                ))}
              </ul>
            </div>
          )}

          <p className='px-2 text-center text-[9px] leading-relaxed text-muted-foreground/70'>
            Referências são arquétipos originais AuraStyle (estúdio, traços
            canónicos) — não retratos de pessoas reais. A comparação mede
            estrutura e traços, nunca identidade.
          </p>
        </motion.div>
      )}

      <input ref={fileRef} type='file' accept='image/*' capture='user' onChange={handleFile} className='hidden' disabled={stage === 'scanning'} />
    </div>
  );
}
