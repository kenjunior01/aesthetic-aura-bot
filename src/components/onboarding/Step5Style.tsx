'use client';

import { motion } from 'framer-motion';
import { Camera, Upload } from 'lucide-react';
import { useAura } from '@/lib/aura-store';
import { styles, occasions, budgets, favoriteColors } from '@/lib/aura-data';
import { Chip, SelectCard, SectionTitle, GlowButton } from '@/components/aura/ui';

export default function Step5Style({ onNext, onBack }: { onNext: () => void; onBack: () => void }) {
  const { profile, toggleIn, update } = useAura();

  return (
    <motion.div
      initial={{ x: 60, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      className="flex min-h-[calc(100vh-140px)] flex-col gap-6"
    >
      {/* Style Preferences */}
      <section>
        <SectionTitle title="Estilos preferidos" hint={
          profile.styles.length > 0
            ? `${profile.styles.length}/3 selecionados`
            : 'Escolha até 3 estilos'
        } />
        <div className="flex flex-wrap gap-2">
          {styles.map((s) => (
            <Chip
              key={s.id}
              selected={profile.styles.includes(s.id)}
              onClick={() => toggleIn('styles', s.id, 3)}
            >
              <span>{s.emoji}</span>
              <span>{s.label}</span>
            </Chip>
          ))}
        </div>
      </section>

      {/* Occasions */}
      <section>
        <SectionTitle title="Ocasiões de uso" hint="Selecione todas que se aplicam" />
        <div className="flex flex-wrap gap-2">
          {occasions.map((occ) => (
            <Chip
              key={occ}
              selected={profile.occasions.includes(occ)}
              onClick={() => toggleIn('occasions', occ)}
            >
              {occ}
            </Chip>
          ))}
        </div>
      </section>

      {/* Budget */}
      <section>
        <SectionTitle title="Orçamento" hint="Sua faixa de investimento em moda" />
        <div className="grid grid-cols-2 gap-3">
          {budgets.map((b) => (
            <SelectCard
              key={b.id}
              selected={profile.budget === b.id}
              onClick={() => update({ budget: b.id })}
              className="py-5"
            >
              <span className="text-2xl font-bold text-aura">{b.hint}</span>
              <span className="text-sm font-medium">{b.label}</span>
            </SelectCard>
          ))}
        </div>
      </section>

      {/* Favorite Colors */}
      <section>
        <SectionTitle title="Cores favoritas" hint="Toque nas cores que você mais gosta" />
        <div className="flex flex-wrap gap-3">
          {favoriteColors.map((color, i) => (
            <motion.button
              key={i}
              type="button"
              whileTap={{ scale: 0.9 }}
              onClick={() => toggleIn('colors', color)}
              className={`w-10 h-10 rounded-full transition-all ${
                profile.colors.includes(color)
                  ? 'ring-2 ring-primary ring-offset-2 ring-offset-background scale-110'
                  : 'opacity-70 hover:opacity-100'
              }`}
              style={{ backgroundColor: color }}
            />
          ))}
        </div>
      </section>

      {/* Reference Uploads */}
      <section>
        <SectionTitle title="Referências de estilo" hint="Fotos de looks que você admira (opcional)" />
        <label className="flex flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed border-border p-8 cursor-pointer hover:border-primary/40 transition-colors">
          <div className="flex h-12 w-12 items-center justify-center rounded-full bg-surface-strong">
            <Camera className="h-6 w-6 text-muted-foreground" />
          </div>
          <div className="text-center">
            <p className="text-sm font-medium text-foreground">Toque para enviar fotos</p>
            <p className="text-xs text-muted-foreground mt-1">Máximo 5 referências</p>
          </div>
          <input type="file" accept="image/*" multiple className="hidden" />
        </label>
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
