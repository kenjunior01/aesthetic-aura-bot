'use client';

import { useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Camera, Sparkles, Loader2, CheckCircle2, RotateCcw, Info } from 'lucide-react';
import { useAura } from '@/lib/aura-store';
import { analyzeSelfie, logEvent } from '@/lib/services';
import { GlowButton } from '@/components/aura/ui';
import { FEATURES, FIREBASE_FREE_TIER_LIMITS } from '@/lib/firebase-config';
import type { VisionAnalysisResult } from '@/lib/services';

export default function SelfieAnalysis({
  onResult,
  onBack,
}: {
  onResult: (result: VisionAnalysisResult) => void;
  onBack: () => void;
}) {
  const { update } = useAura();
  const fileRef = useRef<HTMLInputElement>(null);
  const [image, setImage] = useState<string | null>(null);
  const [analyzing, setAnalyzing] = useState(false);
  const [result, setResult] = useState<VisionAnalysisResult | null>(null);

  const handleCapture = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      setImage(reader.result as string);
      setResult(null);
    };
    reader.readAsDataURL(file);
  };

  const handleAnalyze = async () => {
    if (!image) return;
    setAnalyzing(true);
    logEvent('selfie_analysis_started');
    try {
      const analysis = await analyzeSelfie(image);
      setResult(analysis);
      onResult(analysis);

      // Auto-apply results to profile
      update({
        skinTone: analysis.skinTone,
        faceShape: analysis.faceShape,
        selfie: image,
      });

      logEvent('selfie_analysis_complete', {
        skinTone: analysis.skinTone,
        confidence: analysis.confidence,
      });
    } catch (err) {
      console.error('Analysis failed:', err);
    } finally {
      setAnalyzing(false);
    }
  };

  const handleReset = () => {
    setImage(null);
    setResult(null);
  };

  return (
    <div className='flex flex-col gap-6'>
      <div>
        <h2 className='text-lg font-bold mb-1'>Análise por IA</h2>
        <p className='text-xs text-muted-foreground'>
          Tire uma selfie para a IA detectar seu tom de pele, formato do rosto e cor do cabelo.
          {FEATURES.visionAnalysis
            ? ' Powered by Google Cloud Vision (gratuito).'
            : ' Modo demo — ative com Google Cloud Vision API key.'}
        </p>
      </div>

      {/* Photo capture */}
      {!image ? (
        <label className='flex flex-col items-center justify-center gap-3 h-52 rounded-2xl border-2 border-dashed border-border cursor-pointer hover:border-primary/40 transition-colors'>
          <Camera className='h-10 w-10 text-muted-foreground' />
          <span className='text-sm text-muted-foreground'>Tire uma selfie ou escolha uma foto</span>
          <span className='text-[10px] text-muted-foreground/60'>A foto é processada e não é armazenada</span>
          <input
            ref={fileRef}
            type='file'
            accept='image/*'
            capture='user'
            onChange={handleCapture}
            className='hidden'
          />
        </label>
      ) : (
        <div className='relative rounded-2xl overflow-hidden h-52'>
          <img src={image} alt='Selfie' className='h-full w-full object-cover' />
          <button
            onClick={handleReset}
            className='absolute top-3 right-3 h-8 w-8 rounded-full bg-black/50 flex items-center justify-center'
          >
            <RotateCcw className='h-4 w-4 text-white' />
          </button>
        </div>
      )}

      {/* Analyze button */}
      {image && !result && (
        <GlowButton onClick={handleAnalyze} disabled={analyzing} className='w-full'>
          {analyzing ? (
            <>
              <Loader2 className='h-5 w-5 animate-spin mr-2' />
              Analisando...
            </>
          ) : (
            <>
              <Sparkles className='h-5 w-5 mr-2' />
              Analisar com IA
            </>
          )}
        </GlowButton>
      )}

      {/* Results */}
      <AnimatePresence>
        {result && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            className='glass rounded-2xl p-4'
          >
            <div className='flex items-center gap-2 mb-3'>
              <CheckCircle2 className='h-5 w-5 text-green-400' />
              <span className='text-sm font-bold'>Resultado da análise</span>
              <span className='text-[10px] text-muted-foreground ml-auto'>
                {Math.round(result.confidence * 100)}% confiança
              </span>
            </div>
            <div className='grid grid-cols-2 gap-3'>
              <div className='rounded-xl bg-surface p-3'>
                <span className='text-[10px] uppercase tracking-wider text-muted-foreground block'>Tom de pele</span>
                <span className='text-sm font-medium capitalize mt-0.5 block'>Tom {result.skinTone}</span>
              </div>
              <div className='rounded-xl bg-surface p-3'>
                <span className='text-[10px] uppercase tracking-wider text-muted-foreground block'>Tipo de pele</span>
                <span className='text-sm font-medium capitalize mt-0.5 block'>{result.skinType}</span>
              </div>
              <div className='rounded-xl bg-surface p-3'>
                <span className='text-[10px] uppercase tracking-wider text-muted-foreground block'>Formato do rosto</span>
                <span className='text-sm font-medium capitalize mt-0.5 block'>{result.faceShape}</span>
              </div>
              <div className='rounded-xl bg-surface p-3'>
                <span className='text-[10px] uppercase tracking-wider text-muted-foreground block'>Cor do cabelo</span>
                <span className='text-sm font-medium capitalize mt-0.5 block'>{result.hairColor.replace('-', ' ')}</span>
              </div>
            </div>
            <p className='text-[10px] text-muted-foreground mt-3 text-center'>
              Resultados aplicados ao seu perfil automaticamente
            </p>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Info */}
      <div className='glass rounded-2xl p-3'>
        <div className='flex items-start gap-2'>
          <Info className='h-3.5 w-3.5 text-primary shrink-0 mt-0.5' />
          <p className='text-[10px] text-muted-foreground leading-relaxed'>
            Google Cloud Vision API: {FIREBASE_FREE_TIER_LIMITS.vision.calls} no plano gratuito.
            Sua foto é processada em tempo real e não é armazenada em nossos servidores.
          </p>
        </div>
      </div>
    </div>
  );
}
