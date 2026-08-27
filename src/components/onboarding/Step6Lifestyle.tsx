'use client';

import { motion } from 'framer-motion';
import { useAura } from '@/lib/aura-store';
import { climates, climateByRegion, professions } from '@/lib/aura-data';
import { Chip, SectionTitle, GlowButton, FloatingInput } from '@/components/aura/ui';

const activityLevels = [
  { value: 1, label: 'Sedentário', emoji: '🛋️' },
  { value: 2, label: 'Leve', emoji: '🚶' },
  { value: 3, label: 'Moderado', emoji: '🏃' },
  { value: 4, label: 'Ativo', emoji: '🏋️' },
  { value: 5, label: 'Intenso', emoji: '🔥' },
];

export default function Step6Lifestyle({ onNext, onBack }: { onNext: () => void; onBack: () => void }) {
  const { profile, update } = useAura();

  const detectedClimate = climateByRegion[profile.region] || '';
  const climateLabels: Record<string, string> = {
    tropical: 'Tropical',
    temperado: 'Temperado',
    frio: 'Frio',
    arido: 'Árido',
  };

  const handleComplete = () => {
    update({
      climate: profile.climate || detectedClimate,
    });
    useAura.getState().complete();
    onNext();
  };

  return (
    <motion.div
      initial={{ x: 60, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      className="flex min-h-[calc(100vh-140px)] flex-col gap-6"
    >
      {/* Activity Level */}
      <section>
        <SectionTitle title="Nível de atividade física" />
        <div className="glass rounded-2xl p-4">
          <div className="flex items-center justify-between mb-3">
            {activityLevels.map((a) => (
              <span
                key={a.value}
                className={`text-center transition-all ${
                  profile.activity >= a.value ? 'opacity-100' : 'opacity-40'
                }`}
              >
                <span className="text-xl block">{a.emoji}</span>
                <span className="text-[10px] text-muted-foreground">{a.label}</span>
              </span>
            ))}
          </div>
          <input
            type="range"
            min={1}
            max={5}
            step={1}
            value={profile.activity}
            onChange={(e) => update({ activity: Number(e.target.value) })}
            className="w-full h-2 rounded-full appearance-none cursor-pointer bg-surface-strong [&::-webkit-slider-thumb]:appearance-none [&::-webkit-slider-thumb]:h-5 [&::-webkit-slider-thumb]:w-5 [&::-webkit-slider-thumb]:rounded-full [&::-webkit-slider-thumb]:bg-aura"
          />
        </div>
      </section>

      {/* Profession */}
      <section>
        <SectionTitle title="Profissão / Área" hint="Para personalizar recomendações" />
        <FloatingInput
          label="Sua profissão ou área de atuação"
          value={profile.profession}
          onChange={(v) => update({ profession: v })}
          list="professions-list"
        />
        <datalist id="professions-list">
          {professions.map((p) => (
            <option key={p} value={p} />
          ))}
        </datalist>
      </section>

      {/* Climate */}
      <section>
        <SectionTitle
          title="Clima predominante"
          hint={detectedClimate ? `Detectado pela sua região: ${climateLabels[detectedClimate] || detectedClimate}` : 'Selecione manualmente'}
        />
        <div className="flex flex-wrap gap-2">
          {climates.map((c) => (
            <Chip
              key={c}
              selected={profile.climate === c}
              onClick={() => update({ climate: c })}
            >
              {climateLabels[c] || c}
            </Chip>
          ))}
        </div>
      </section>

      {/* Notes */}
      <section>
        <SectionTitle title="Observações" hint="Tudo que achar relevante" />
        <textarea
          value={profile.notes}
          onChange={(e) => update({ notes: e.target.value })}
          placeholder="Alguma alergia? Restrição? Conta pra gente..."
          rows={4}
          className="glass w-full rounded-2xl border border-border bg-transparent px-4 py-3 text-sm text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong resize-none placeholder:text-muted-foreground/60"
        />
      </section>

      {/* Navigation */}
      <div className="flex gap-3 mt-auto pt-4">
        <GlowButton variant="ghost" onClick={onBack} className="flex-1">
          Voltar
        </GlowButton>
        <GlowButton onClick={handleComplete} className="flex-1">
          Finalizar ✨
        </GlowButton>
      </div>
    </motion.div>
  );
}
