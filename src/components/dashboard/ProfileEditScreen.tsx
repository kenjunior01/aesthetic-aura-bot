'use client';

import { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  User, Mail, Phone, ChevronLeft, Save, Camera,
  Scissors, Loader2, CheckCircle2, RotateCcw, Info, Gem,
} from 'lucide-react';
import { useAura, type Profile } from '@/lib/aura-store';
import { GlowButton } from '@/components/aura/ui';
import { analyzeSelfie, syncFullProfileOnComplete, logEvent } from '@/lib/services';
import { FEATURES, FIREBASE_FREE_TIER_LIMITS } from '@/lib/firebase-config';
import type { VisionAnalysisResult } from '@/lib/services';

const genderOptions = ['Feminino', 'Masculino', 'Não-binário', 'Prefiro não dizer'];
const budgetOptions = ['Econômico (até R$50)', 'Moderado (R$50-150)', 'Premium (R$150-400)', 'Luxo (R$400+)'];
const climateOptions = ['Tropical úmido', 'Tropical seco', 'Subtropical', 'Temperado', 'Frio', 'Árido'];
const faceShapeOptions = ['Oval', 'Redondo', 'Quadrado', 'Retangular', 'Coração', 'Losango'];
const skinToneOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
const undertoneOptions = ['Quente', 'Frio', 'Neutro', 'Olivado'];
const eyeColorOptions = ['Castanho', 'Preto', 'Verde', 'Azul', 'Mel', 'Cinza', 'Ambar'];
const skinTypeOptions = ['Oleosa', 'Mista', 'Seca', 'Normal', 'Sensível'];
const hairTypeOptions = ['Liso', 'Ondulado', 'Cacheado', 'Crespo', 'Cabelo com quimica'];
const hairColorOptions = ['Preto', 'Castanho-escuro', 'Castanho-médio', 'Castanho-claro', 'Loiro-escuro', 'Loiro-médio', 'Loiro-claro', 'Ruivo', 'Grisalho', 'Branco', 'Colorido'];
const hairLengthOptions = ['Raspar', 'Muito curto', 'Curto', 'Médio', 'Longo', 'Muito longo'];
const hairThicknessOptions = ['Fino', 'Médio', 'Grosso'];
const bodyTypeOptions = ['Magro', 'Atlético', 'Médio', 'Plus size', 'Curvilíneo', 'Triângulo invertido', 'Retangular', 'Ampulheta'];
const styleOptions = ['Casual', 'Streetwear', 'Minimalista', 'Elegante', 'Boho', 'Esportivo', 'Vintage', 'Grunge', 'Preppy', 'Sexy', 'Romântico', 'Corporate', 'Techwear', 'Y2K', 'Dark academia', 'Coastal', 'Scandinavo'];
const occasionOptions = ['Trabalho', 'Festa', 'Casual', 'Praia', 'Balada', 'Encontro', 'Casamento', 'Entrevista', 'Academia', 'Viagem'];

export default function ProfileEditScreen({
  onClose,
}: {
  onClose: () => void;
}) {
  const { profile, update, authUid, syncToCloud } = useAura();
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);
  const [section, setSection] = useState<'basic' | 'face' | 'hair' | 'body' | 'style' | 'lifestyle'>('basic');
  const fileRef = useRef<HTMLInputElement>(null);
  const [analyzing, setAnalyzing] = useState(false);

  const sections = [
    { key: 'basic' as const, label: 'Básico', icon: User },
    { key: 'face' as const, label: 'Rosto', icon: Camera },
    { key: 'hair' as const, label: 'Cabelo', icon: Scissors },
    { key: 'body' as const, label: 'Corpo', icon: User },
    { key: 'style' as const, label: 'Estilo', icon: Gem },
    { key: 'lifestyle' as const, label: 'Vida', icon: User },
  ];

  const handleSave = async () => {
    setSaving(true);
    logEvent('profile_edit_saved', { section });
    if (authUid) {
      await syncToCloud();
    }
    setSaving(false);
    setSaved(true);
    setTimeout(() => {
      setSaved(false);
      onClose();
    }, 1200);
  };

  const handleSelfieAnalysis = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = async () => {
      const base64 = reader.result as string;
      setAnalyzing(true);
      try {
        const result: VisionAnalysisResult = await analyzeSelfie(base64);
        update({
          skinTone: result.skinTone,
          faceShape: result.faceShape,
          selfie: base64,
        });
        logEvent('profile_edit_selfie', { confidence: result.confidence });
      } catch (err) {
        console.error('Analysis failed:', err);
      } finally {
        setAnalyzing(false);
      }
    };
    reader.readAsDataURL(file);
  };

  return (
    <div className="relative z-10 px-4 pt-6 pb-8 max-w-lg mx-auto min-h-screen">
      <div className="flex items-center gap-3 mb-6">
        <button
          onClick={onClose}
          className="h-10 w-10 rounded-xl glass flex items-center justify-center"
        >
          <ChevronLeft className="h-5 w-5" />
        </button>
        <div className="flex-1">
          <h1 className="text-xl font-bold">Editar Perfil</h1>
          <p className="text-xs text-muted-foreground">Alterações sincronizam automaticamente</p>
        </div>
        <GlowButton onClick={handleSave} disabled={saving} className="h-10 px-5">
          {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : saved ? <CheckCircle2 className="h-4 w-4" /> : <Save className="h-4 w-4" />}
        </GlowButton>
      </div>

      {/* Section tabs */}
      <div className="flex gap-2 overflow-x-auto no-scrollbar mb-6 -mx-1 px-1">
        {sections.map((s) => {
          const Icon = s.icon;
          return (
            <button
              key={s.key}
              onClick={() => setSection(s.key)}
              className={`shrink-0 rounded-xl border px-3 py-2 text-xs font-medium flex items-center gap-1.5 transition-all ${
                section === s.key
                  ? 'border-transparent bg-aura text-primary-foreground'
                  : 'border-border bg-surface text-muted-foreground'
              }`}
            >
              <Icon className="h-3 w-3" />
              {s.label}
            </button>
          );
        })}
      </div>

      <AnimatePresence mode="wait">
        <motion.div
          key={section}
          initial={{ opacity: 0, x: 30 }}
          animate={{ opacity: 1, x: 0 }}
          exit={{ opacity: 0, x: -30 }}
          transition={{ duration: 0.2 }}
          className="flex flex-col gap-5"
        >
          {section === 'basic' && (
            <>
              <EditField label="Nome completo" icon={User}>
                <input
                  type="text"
                  value={profile.name}
                  onChange={(e) => update({ name: e.target.value })}
                  className="w-full h-12 rounded-xl border border-border bg-surface px-4 text-sm text-foreground outline-none focus:border-primary/70"
                />
              </EditField>
              <EditField label="Email" icon={Mail}>
                <input
                  type="email"
                  value={profile.email}
                  onChange={(e) => update({ email: e.target.value })}
                  className="w-full h-12 rounded-xl border border-border bg-surface px-4 text-sm text-foreground outline-none focus:border-primary/70"
                />
              </EditField>
              <EditField label="Telefone" icon={Phone}>
                <input
                  type="tel"
                  value={profile.phone}
                  onChange={(e) => update({ phone: e.target.value })}
                  placeholder="+55 (11) 99999-9999"
                  className="w-full h-12 rounded-xl border border-border bg-surface px-4 text-sm text-foreground outline-none focus:border-primary/70 placeholder:text-muted-foreground/50"
                />
              </EditField>
              <EditField label="Idade">
                <input
                  type="number"
                  value={profile.age}
                  onChange={(e) => update({ age: Number(e.target.value) })}
                  min={10}
                  max={100}
                  className="w-full h-12 rounded-xl border border-border bg-surface px-4 text-sm text-foreground outline-none focus:border-primary/70"
                />
              </EditField>
              <EditField label="Gênero">
                <div className="flex flex-wrap gap-2">
                  {genderOptions.map((g) => (
                    <button
                      key={g}
                      onClick={() => update({ gender: g })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                        profile.gender === g ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {g}
                    </button>
                  ))}
                </div>
              </EditField>
              <EditField label="Orçamento">
                <div className="flex flex-col gap-2">
                  {budgetOptions.map((b) => (
                    <button
                      key={b}
                      onClick={() => update({ budget: b })}
                      className={`rounded-xl border p-3 text-left text-sm transition-all ${
                        profile.budget === b ? 'border-primary/50 bg-primary/5' : 'border-border bg-surface'
                      }`}
                    >
                      {b}
                    </button>
                  ))}
                </div>
              </EditField>
            </>
          )}

          {section === 'face' && (
            <>
              {/* Selfie analysis */}
              <div className="glass rounded-2xl p-4">
                <div className="flex items-center justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <Camera className="h-4 w-4 text-primary" />
                    <span className="text-sm font-semibold">Análise por IA</span>
                  </div>
                  {analyzing && <Loader2 className="h-4 w-4 animate-spin text-primary" />}
                </div>
                <p className="text-[10px] text-muted-foreground mb-3">
                  {FEATURES.visionAnalysis
                    ? `Google Cloud Vision: ${FIREBASE_FREE_TIER_LIMITS.vision.calls} grátis/mês`
                    : 'Modo demo — ative com API key do Google Cloud Vision'}
                </p>
                <label className="flex flex-col items-center justify-center gap-2 h-32 rounded-xl border-2 border-dashed border-border cursor-pointer hover:border-primary/40 transition-colors">
                  <Camera className="h-8 w-8 text-muted-foreground" />
                  <span className="text-xs text-muted-foreground">Tire uma selfie para análise automática</span>
                  <input
                    ref={fileRef}
                    type="file"
                    accept="image/*"
                    capture="user"
                    onChange={handleSelfieAnalysis}
                    className="hidden"
                    disabled={analyzing}
                  />
                </label>
                {profile.selfie && (
                  <div className="relative mt-3 rounded-xl overflow-hidden h-32">
                    <img src={profile.selfie} alt="Selfie" className="h-full w-full object-cover" />
                  </div>
                )}
              </div>

              <EditField label="Formato do rosto">
                <div className="flex flex-wrap gap-2">
                  {faceShapeOptions.map((f) => (
                    <button
                      key={f}
                      onClick={() => update({ faceShape: f })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium capitalize transition-all ${
                        profile.faceShape === f ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {f}
                    </button>
                  ))}
                </div>
              </EditField>

              <EditField label="Tom de pele (1-10)">
                <div className="flex gap-1.5 flex-wrap">
                  {skinToneOptions.map((t) => (
                    <button
                      key={t}
                      onClick={() => update({ skinTone: t })}
                      className={`h-10 w-10 rounded-lg border-2 transition-all ${
                        profile.skinTone === t ? 'border-primary scale-110' : 'border-transparent'
                      }`}
                      style={{
                        background: `oklch(${0.25 + (t - 1) * 0.06} 0.05 ${t % 2 === 0 ? 30 : 60})`,
                      }}
                    >
                      <span className="text-[10px] font-bold drop-shadow">{t}</span>
                    </button>
                  ))}
                </div>
              </EditField>

              <EditField label="Subtom">
                <div className="flex flex-wrap gap-2">
                  {undertoneOptions.map((u) => (
                    <button
                      key={u}
                      onClick={() => update({ undertone: u })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                        profile.undertone === u ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {u}
                    </button>
                  ))}
                </div>
              </EditField>

              <EditField label="Cor dos olhos">
                <div className="flex flex-wrap gap-2">
                  {eyeColorOptions.map((c) => (
                    <button
                      key={c}
                      onClick={() => update({ eyeColor: c })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium capitalize transition-all ${
                        profile.eyeColor === c ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {c}
                    </button>
                  ))}
                </div>
              </EditField>

              <EditField label="Tipo de pele (pode marcar mais de um)">
                <div className="flex flex-wrap gap-2">
                  {skinTypeOptions.map((s) => (
                    <button
                      key={s}
                      onClick={() => useAura.getState().toggleIn('skinTypes', s)}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium capitalize transition-all ${
                        profile.skinTypes.includes(s) ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {s}
                    </button>
                  ))}
                </div>
              </EditField>
            </>
          )}

          {section === 'hair' && (
            <>
              <EditField label="Tipo de cabelo">
                <div className="flex flex-wrap gap-2">
                  {hairTypeOptions.map((h) => (
                    <button
                      key={h}
                      onClick={() => update({ hairType: h })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                        profile.hairType === h ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {h}
                    </button>
                  ))}
                </div>
              </EditField>
              <EditField label="Cor do cabelo">
                <div className="flex flex-wrap gap-2">
                  {hairColorOptions.map((h) => (
                    <button
                      key={h}
                      onClick={() => update({ hairColor: h })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium capitalize transition-all ${
                        profile.hairColor === h ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {h}
                    </button>
                  ))}
                </div>
              </EditField>
              <EditField label="Comprimento">
                <div className="flex flex-wrap gap-2">
                  {hairLengthOptions.map((h) => (
                    <button
                      key={h}
                      onClick={() => update({ hairLength: h })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                        profile.hairLength === h ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {h}
                    </button>
                  ))}
                </div>
              </EditField>
              <EditField label="Espessura">
                <div className="flex flex-wrap gap-2">
                  {hairThicknessOptions.map((h) => (
                    <button
                      key={h}
                      onClick={() => update({ hairThickness: h })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                        profile.hairThickness === h ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {h}
                    </button>
                  ))}
                </div>
              </EditField>
            </>
          )}

          {section === 'body' && (
            <>
              <EditField label="Tipo de corpo">
                <div className="flex flex-wrap gap-2">
                  {bodyTypeOptions.map((b) => (
                    <button
                      key={b}
                      onClick={() => update({ bodyType: b })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium capitalize transition-all ${
                        profile.bodyType === b ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {b}
                    </button>
                  ))}
                </div>
              </EditField>
              <EditField label="Altura (cm)">
                <input
                  type="number"
                  value={profile.height}
                  onChange={(e) => update({ height: Number(e.target.value) })}
                  min={100}
                  max={250}
                  className="w-full h-12 rounded-xl border border-border bg-surface px-4 text-sm text-foreground outline-none focus:border-primary/70"
                />
              </EditField>
              <EditField label="Peso (kg)">
                <input
                  type="number"
                  value={profile.weight}
                  onChange={(e) => update({ weight: Number(e.target.value) })}
                  min={30}
                  max={250}
                  className="w-full h-12 rounded-xl border border-border bg-surface px-4 text-sm text-foreground outline-none focus:border-primary/70"
                />
              </EditField>
            </>
          )}

          {section === 'style' && (
            <>
              <EditField label="Estilos preferidos (até 3)">
                <div className="flex flex-wrap gap-2">
                  {styleOptions.map((s) => (
                    <button
                      key={s}
                      onClick={() => useAura.getState().toggleIn('styles', s, 3)}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                        profile.styles.includes(s) ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {s}
                    </button>
                  ))}
                </div>
              </EditField>
              <EditField label="Ocasiões frequentes (até 3)">
                <div className="flex flex-wrap gap-2">
                  {occasionOptions.map((o) => (
                    <button
                      key={o}
                      onClick={() => useAura.getState().toggleIn('occasions', o, 3)}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                        profile.occasions.includes(o) ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {o}
                    </button>
                  ))}
                </div>
              </EditField>
            </>
          )}

          {section === 'lifestyle' && (
            <>
              <EditField label="Nível de atividade física (1=sedentário, 5=muito ativo)">
                <div className="flex gap-2">
                  {[1, 2, 3, 4, 5].map((n) => (
                    <button
                      key={n}
                      onClick={() => update({ activity: n })}
                      className={`flex-1 h-12 rounded-xl border text-sm font-bold transition-all ${
                        profile.activity === n ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {n}
                    </button>
                  ))}
                </div>
              </EditField>
              <EditField label="Clima da sua região">
                <div className="flex flex-wrap gap-2">
                  {climateOptions.map((c) => (
                    <button
                      key={c}
                      onClick={() => update({ climate: c })}
                      className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                        profile.climate === c ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                      }`}
                    >
                      {c}
                    </button>
                  ))}
                </div>
              </EditField>
              <EditField label="Profissão">
                <input
                  type="text"
                  value={profile.profession}
                  onChange={(e) => update({ profession: e.target.value })}
                  placeholder="Ex: Desenvolvedor, Estudante..."
                  className="w-full h-12 rounded-xl border border-border bg-surface px-4 text-sm text-foreground outline-none focus:border-primary/70 placeholder:text-muted-foreground/50"
                />
              </EditField>
              <EditField label="Notas adicionais">
                <textarea
                  value={profile.notes}
                  onChange={(e) => update({ notes: e.target.value })}
                  placeholder="Alguma preferência, alergia, ou informação extra..."
                  rows={4}
                  className="w-full rounded-xl border border-border bg-surface px-4 py-3 text-sm text-foreground outline-none focus:border-primary/70 placeholder:text-muted-foreground/50 resize-none"
                />
              </EditField>
            </>
          )}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}

function EditField({ label, icon: Icon, children }: { label: string; icon?: any; children: React.ReactNode }) {
  return (
    <div>
      <label className="text-xs font-semibold uppercase tracking-widest text-muted-foreground flex items-center gap-1.5 mb-2 block">
        {Icon && <Icon className="h-3 w-3" />}
        {label}
      </label>
      {children}
    </div>
  );
}
