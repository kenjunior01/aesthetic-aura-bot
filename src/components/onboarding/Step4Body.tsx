'use client';

import { motion } from 'framer-motion';
import { useAura } from '@/lib/aura-store';
import { bodyTypes } from '@/lib/aura-data';
import { BodyShape } from '@/components/aura/Illustrations';
import { SelectCard, SectionTitle, GlowButton } from '@/components/aura/ui';

export default function Step4Body({ onNext, onBack }: { onNext: () => void; onBack: () => void }) {
  const { profile, update } = useAura();

  const toggleHeightUnit = () => {
    if (profile.heightUnit === 'cm') {
      update({ height: Math.round(profile.height / 2.54), heightUnit: 'ft' as const });
    } else {
      update({ height: Math.round(profile.height * 2.54), heightUnit: 'cm' as const });
    }
  };

  return (
    <motion.div
      initial={{ x: 60, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      className="flex min-h-[calc(100vh-140px)] flex-col gap-6"
    >
      {/* Body Type */}
      <section>
        <SectionTitle title="Tipo de corpo" hint="Selecione o que mais se parece com você" />
        <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
          {bodyTypes.map((bt) => (
            <SelectCard
              key={bt.id}
              selected={profile.bodyType === bt.id}
              onClick={() => update({ bodyType: bt.id })}
              className="p-4"
            >
              <BodyShape id={bt.id} active={profile.bodyType === bt.id} />
              <span className="text-sm font-medium mt-1">{bt.label}</span>
              <span className="text-[10px] text-muted-foreground leading-tight">{bt.desc}</span>
            </SelectCard>
          ))}
        </div>
      </section>

      {/* Height */}
      <section>
        <SectionTitle title="Altura" />
        <div className="glass rounded-2xl p-4 flex items-center gap-4">
          <input
            type="number"
            value={profile.height}
            onChange={(e) => update({ height: Number(e.target.value) })}
            className="flex-1 bg-transparent text-2xl font-semibold text-foreground outline-none w-full [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
          />
          <button
            type="button"
            onClick={toggleHeightUnit}
            className="rounded-xl border border-border px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground transition-colors"
          >
            {profile.heightUnit === 'cm' ? 'cm' : 'ft'}
          </button>
        </div>
      </section>

      {/* Weight (optional) */}
      <section>
        <SectionTitle title="Peso (opcional)" hint="Usado apenas para recomendações de estilo" />
        <div className="glass rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            <span className="text-sm text-muted-foreground">40 kg</span>
            <span className="text-lg font-semibold text-aura">{profile.weight} kg</span>
            <span className="text-sm text-muted-foreground">150 kg</span>
          </div>
          <input
            type="range"
            min={40}
            max={150}
            value={profile.weight}
            onChange={(e) => update({ weight: Number(e.target.value) })}
            className="w-full h-2 rounded-full appearance-none cursor-pointer bg-surface-strong [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:h-5 [&::-webkit-slider-thumb]:w-5 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-aura [&::-webkit-slider-thumb]:glow"
          />
        </div>
      </section>

      {/* Navigation */}
      <div className="flex gap-3 mt-auto pt-4">
        <GlowButton variant="ghost" onClick={onBack} className="flex-1">
          Voltar
        </GlowButton>
        <GlowButton onClick={onNext} className="flex-1">
          Próximo
        </GlowButton>
      </div>
    </motion.div>
  );
}
