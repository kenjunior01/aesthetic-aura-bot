'use client';

import { motion } from 'framer-motion';
import { useAura } from '@/lib/aura-store';
import { genders, regions } from '@/lib/aura-data';
import { GenderIllustration } from '@/components/aura/Illustrations';
import { FloatingInput, GlowButton, SectionTitle, SelectCard } from '@/components/aura/ui';
import { Search } from 'lucide-react';
import { useMemo, useState } from 'react';

export default function Step1Basic({ onNext }: { onNext: () => void }) {
  const { profile, update } = useAura();
  const [regionSearch, setRegionSearch] = useState('');
  const [regionOpen, setRegionOpen] = useState(false);

  const filteredRegions = useMemo(
    () => regions.filter((r) => r.toLowerCase().includes(regionSearch.toLowerCase())),
    [regionSearch],
  );

  return (
    <motion.div
      initial={{ x: 60, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ duration: 0.35, ease: 'easeOut' }}
      className="flex min-h-full flex-col"
    >
      <div className="flex-1 overflow-y-auto px-1 pb-6">
        <div className="flex flex-col gap-6 py-2">
          {/* Nome */}
          <section>
            <SectionTitle title="Nome" hint="Como podemos te chamar?" />
            <FloatingInput
              label="Seu nome"
              value={profile.name}
              onChange={(v) => update({ name: v })}
            />
          </section>

          {/* Gênero */}
          <section>
            <SectionTitle title="Gênero" />
            <div className="grid grid-cols-2 gap-3">
              {genders.map((g) => (
                <SelectCard
                  key={g.id}
                  selected={profile.gender === g.id}
                  onClick={() => update({ gender: g.id })}
                >
                  <GenderIllustration id={g.id} active={profile.gender === g.id} />
                  <span className="text-xs text-muted-foreground">{g.label}</span>
                </SelectCard>
              ))}
            </div>
          </section>

          {/* Idade */}
          <section>
            <SectionTitle title="Idade" />
            <div className="flex flex-col gap-3 rounded-2xl border border-border bg-surface p-4">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted-foreground">18</span>
                <span className="text-2xl font-bold tabular-nums text-foreground">
                  {profile.age}
                </span>
                <span className="text-sm text-muted-foreground">80</span>
              </div>
              <input
                type="range"
                min={18}
                max={80}
                value={profile.age}
                onChange={(e) => update({ age: Number(e.target.value) })}
                className="w-full accent-primary"
              />
              <p className="text-center text-xs text-muted-foreground">
                {profile.age} anos
              </p>
            </div>
          </section>

          {/* Região */}
          <section>
            <SectionTitle title="Região" hint="Para recomendações de clima e estilo" />
            <div className="relative">
              <button
                type="button"
                onClick={() => setRegionOpen(!regionOpen)}
                className="flex h-16 w-full items-center gap-3 rounded-2xl border border-border bg-surface px-4 text-base transition-all focus:border-primary/70 focus:bg-surface-strong"
              >
                <Search className="h-4 w-4 shrink-0 text-muted-foreground" />
                <span className={profile.region ? 'text-foreground' : 'text-muted-foreground'}>
                  {profile.region || 'Buscar região...'}
                </span>
              </button>

              {regionOpen && (
                <motion.div
                  initial={{ opacity: 0, y: -4 }}
                  animate={{ opacity: 1, y: 0 }}
                  className="glass absolute left-0 right-0 top-full z-50 mt-2 max-h-56 overflow-y-auto rounded-2xl border border-border p-2"
                >
                  <input
                    type="text"
                    placeholder="Buscar região..."
                    value={regionSearch}
                    onChange={(e) => setRegionSearch(e.target.value)}
                    className="mb-2 h-10 w-full rounded-xl bg-surface px-3 text-sm outline-none"
                    autoFocus
                  />
                  {filteredRegions.length === 0 && (
                    <p className="px-3 py-2 text-xs text-muted-foreground">
                      Nenhuma região encontrada
                    </p>
                  )}
                  {filteredRegions.map((r) => (
                    <button
                      key={r}
                      type="button"
                      onClick={() => {
                        update({ region: r });
                        setRegionOpen(false);
                        setRegionSearch('');
                      }}
                      className={`flex w-full items-center rounded-xl px-3 py-2.5 text-left text-sm transition-colors ${
                        profile.region === r
                          ? 'bg-aura/20 text-foreground font-medium'
                          : 'text-muted-foreground hover:bg-surface-strong hover:text-foreground'
                      }`}
                    >
                      {r}
                    </button>
                  ))}
                </motion.div>
              )}
            </div>
          </section>
        </div>
      </div>

      {/* Botão Próximo */}
      <div className="pt-4">
        <GlowButton onClick={onNext} className="w-full">
          Próximo
        </GlowButton>
      </div>
    </motion.div>
  );
}
