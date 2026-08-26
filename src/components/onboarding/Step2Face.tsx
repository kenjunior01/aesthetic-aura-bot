'use client';

import { useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { useAura } from '@/lib/aura-store';
import { faceShapes, skinTones, undertones, eyeColors, skinTypes } from '@/lib/aura-data';
import { FaceShape } from '@/components/aura/Illustrations';
import { SelectCard, Chip, SectionTitle, GlowButton } from '@/components/aura/ui';
import { Droplets, Wind, Blend, HeartPulse, Sparkles, Camera, X } from 'lucide-react';

const skinTypeIcons: Record<string, typeof Droplets> = {
  Droplets,
  Wind,
  Blend,
  HeartPulse,
  Sparkles,
};

export default function Step2Face({
  onNext,
  onBack,
}: {
  onNext: () => void;
  onBack: () => void;
}) {
  const { profile, update, toggleIn } = useAura();

  const fileRef = useRef<HTMLInputElement>(null);
  const [selfie, setSelfie] = useState<string | null>(profile.selfie);

  const handleSelfie = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      const result = reader.result as string;
      setSelfie(result);
      update({ selfie: result });
    };
    reader.readAsDataURL(file);
  };

  return (
    <motion.div
      initial={{ x: 60, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="flex min-h-full flex-col"
    >
      <div className="flex-1 overflow-y-auto px-1 pb-6">
        <div className="flex flex-col gap-6 py-2">
          {/* Selfie upload */}
          <section>
            <SectionTitle title="Selfie (opcional)" hint="Nos ajuda a personalizar ainda mais" />
            {selfie ? (
              <div className="relative h-48 rounded-2xl overflow-hidden">
                <img src={selfie} alt="Sua selfie" className="h-full w-full object-cover" />
                {/* Face guide overlay */}
                <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                  <div className="h-36 w-28 rounded-full border-2 border-dashed border-white/40" />
                </div>
                <button
                  onClick={() => { setSelfie(null); update({ selfie: null }); }}
                  className="absolute top-2 right-2 h-8 w-8 rounded-full bg-black/50 flex items-center justify-center"
                >
                  <X className="h-4 w-4 text-white" />
                </button>
              </div>
            ) : (
              <label className="relative flex flex-col items-center justify-center gap-3 h-48 rounded-2xl border-2 border-dashed border-border cursor-pointer hover:border-primary/40 transition-colors overflow-hidden">
                {/* Face guide frame */}
                <div className="absolute inset-0 flex items-center justify-center pointer-events-none">
                  <div className="h-36 w-28 rounded-full border-2 border-dashed border-muted-foreground/30" />
                </div>
                <div className="relative z-10 flex flex-col items-center gap-2">
                  <div className="h-12 w-12 rounded-full bg-surface-strong flex items-center justify-center">
                    <Camera className="h-6 w-6 text-muted-foreground" />
                  </div>
                  <span className="text-sm font-medium">Tirar selfie</span>
                  <span className="text-[10px] text-muted-foreground">Enquadre o rosto no guia</span>
                </div>
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/*"
                  capture="user"
                  onChange={handleSelfie}
                  className="hidden"
                />
              </label>
            )}
          </section>

          {/* Formato do rosto */}
          <section>
            <SectionTitle title="Formato do rosto" hint="Escolha o que mais se aproxima" />
            <div className="grid grid-cols-3 gap-3 md:grid-cols-4">
              {faceShapes.map((f) => (
                <SelectCard
                  key={f.id}
                  selected={profile.faceShape === f.id}
                  onClick={() => update({ faceShape: f.id })}
                >
                  <FaceShape id={f.id} active={profile.faceShape === f.id} />
                  <span className="text-xs text-muted-foreground">{f.label}</span>
                </SelectCard>
              ))}
            </div>
          </section>

          {/* Tom de pele */}
          <section>
            <SectionTitle title="Tom de pele" hint="Toque na cor mais próxima" />
            <div className="flex flex-wrap gap-2.5">
              {skinTones.map((color, i) => (
                <button
                  key={i}
                  type="button"
                  onClick={() => update({ skinTone: i })}
                  className={`relative h-10 w-10 shrink-0 rounded-full transition-transform active:scale-90 ${
                    profile.skinTone === i
                      ? 'ring-2 ring-primary ring-offset-2 ring-offset-background'
                      : ''
                  }`}
                  style={{ backgroundColor: color }}
                  aria-label={`Tom de pele ${i + 1}`}
                />
              ))}
            </div>
          </section>

          {/* Subtom */}
          <section>
            <SectionTitle title="Subtom da pele" />
            <div className="flex gap-4">
              {undertones.map((u) => (
                <button
                  key={u.id}
                  type="button"
                  onClick={() => update({ undertone: u.id })}
                  className={`flex flex-col items-center gap-2 transition-transform active:scale-95 ${
                    profile.undertone === u.id ? 'scale-105' : 'opacity-70 hover:opacity-100'
                  }`}
                >
                  <span
                    className={`h-8 w-8 rounded-full ${
                      profile.undertone === u.id
                        ? 'ring-2 ring-primary ring-offset-2 ring-offset-background'
                        : ''
                    }`}
                    style={{ backgroundColor: u.color }}
                  />
                  <span className="text-[11px] text-muted-foreground">{u.label}</span>
                </button>
              ))}
            </div>
          </section>

          {/* Cor dos olhos */}
          <section>
            <SectionTitle title="Cor dos olhos" />
            <div className="flex flex-wrap gap-4">
              {eyeColors.map((e) => (
                <button
                  key={e.id}
                  type="button"
                  onClick={() => update({ eyeColor: e.id })}
                  className={`flex flex-col items-center gap-2 transition-transform active:scale-95 ${
                    profile.eyeColor === e.id ? 'scale-105' : 'opacity-70 hover:opacity-100'
                  }`}
                >
                  <span
                    className={`h-10 w-10 rounded-full ${
                      profile.eyeColor === e.id
                        ? 'ring-2 ring-primary ring-offset-2 ring-offset-background'
                        : ''
                    }`}
                    style={{ backgroundColor: e.color }}
                  />
                  <span className="text-xs text-muted-foreground">{e.label}</span>
                </button>
              ))}
            </div>
          </section>

          {/* Tipo de pele */}
          <section>
            <SectionTitle title="Tipo de pele" hint="Pode selecionar mais de um" />
            <div className="flex flex-wrap gap-2">
              {skinTypes.map((s) => {
                const Icon = skinTypeIcons[s.icon];
                return (
                  <Chip
                    key={s.id}
                    selected={profile.skinTypes.includes(s.id)}
                    onClick={() => toggleIn('skinTypes', s.id)}
                  >
                    {Icon && <Icon className="h-4 w-4" />}
                    {s.label}
                  </Chip>
                );
              })}
            </div>
          </section>
        </div>
      </div>

      {/* Botões */}
      <div className="flex gap-3 pt-4">
        <GlowButton variant="ghost" onClick={onBack} className="w-full">
          Voltar
        </GlowButton>
        <GlowButton onClick={onNext} className="w-full">
          Próximo
        </GlowButton>
      </div>
    </motion.div>
  );
}
