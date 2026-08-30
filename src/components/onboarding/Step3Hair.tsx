'use client';

import { motion } from 'framer-motion';
import { useAura } from '@/lib/aura-store';
import {
  hairTypes,
  hairColors,
  hairLengths,
  hairThickness,
  hairIssues,
} from '@/lib/aura-data';
import {
  HairIllustration,
  LengthIllustration,
  ThicknessIllustration,
} from '@/components/aura/Illustrations';
import { SelectCard, Chip, SectionTitle, GlowButton } from '@/components/aura/ui';

export default function Step3Hair({
  onNext,
  onBack,
}: {
  onNext: () => void;
  onBack: () => void;
}) {
  const { profile, update, toggleIn } = useAura();

  return (
    <motion.div
      initial={false}
      className="flex min-h-full flex-col"
    >
      <div className="flex-1 overflow-y-auto px-1 pb-6">
        <div className="flex flex-col gap-6 py-2">
          {/* Tipo de cabelo */}
          <section>
            <SectionTitle title="Tipo de cabelo" hint="Escolha o que mais se parece com o seu" />
            <div className="grid grid-cols-3 gap-3 md:grid-cols-5">
              {hairTypes.map((h) => (
                <SelectCard
                  key={h.id}
                  selected={profile.hairType === h.id}
                  onClick={() => update({ hairType: h.id })}
                >
                  <HairIllustration id={h.id} active={profile.hairType === h.id} />
                  <span className="text-xs text-muted-foreground">{h.label}</span>
                </SelectCard>
              ))}
            </div>
          </section>

          {/* Cor do cabelo */}
          <section>
            <SectionTitle title="Cor do cabelo" />
            <div className="flex flex-wrap gap-4">
              {hairColors.map((c) => (
                <button
                  key={c.id}
                  type="button"
                  onClick={() => update({ hairColor: c.id })}
                  className={`flex flex-col items-center gap-2 transition-transform active:scale-95 ${
                    profile.hairColor === c.id ? 'scale-105' : 'opacity-70 hover:opacity-100'
                  }`}
                >
                  <span
                    className={`h-10 w-10 rounded-full ${
                      profile.hairColor === c.id
                        ? 'ring-2 ring-primary ring-offset-2 ring-offset-background'
                        : ''
                    }`}
                    style={{ backgroundColor: c.color }}
                  />
                  <span className="text-xs text-muted-foreground">{c.label}</span>
                </button>
              ))}
            </div>
          </section>

          {/* Comprimento */}
          <section>
            <SectionTitle title="Comprimento" />
            <div className="grid grid-cols-4 gap-3">
              {hairLengths.map((l) => (
                <SelectCard
                  key={l.id}
                  selected={profile.hairLength === l.id}
                  onClick={() => update({ hairLength: l.id })}
                >
                  <LengthIllustration id={l.id} active={profile.hairLength === l.id} />
                  <span className="text-xs text-muted-foreground">{l.label}</span>
                </SelectCard>
              ))}
            </div>
          </section>

          {/* Espessura */}
          <section>
            <SectionTitle title="Espessura" />
            <div className="grid grid-cols-3 gap-3">
              {hairThickness.map((t) => (
                <SelectCard
                  key={t.id}
                  selected={profile.hairThickness === t.id}
                  onClick={() => update({ hairThickness: t.id })}
                >
                  <ThicknessIllustration id={t.id} active={profile.hairThickness === t.id} />
                  <span className="text-xs text-muted-foreground">{t.label}</span>
                </SelectCard>
              ))}
            </div>
          </section>

          {/* Problemas capilares (opcional) */}
          <section>
            <SectionTitle title="Problemas capilares" hint="Opcional — selecione os que se aplicam" />
            <div className="flex flex-wrap gap-2">
              {hairIssues.map((issue) => (
                <Chip
                  key={issue}
                  selected={profile.hairIssues.includes(issue)}
                  onClick={() => toggleIn('hairIssues', issue)}
                >
                  {issue}
                </Chip>
              ))}
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
