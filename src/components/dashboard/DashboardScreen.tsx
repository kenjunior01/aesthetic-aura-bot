'use client';

import React from 'react';
import { motion } from 'framer-motion';
import {
  Sparkles, Scissors, Heart, TrendingUp,
  Droplets, Sun, Moon, Palette, ArrowRight,
} from 'lucide-react';
import { useAura } from '@/lib/aura-store';
import { AuroraBackground } from '@/components/aura/AuroraBackground';
import BottomNav from './BottomNav';
import type { Tab } from './BottomNav';

const dailyRecs = [
  {
    id: '1',
    title: 'Look do dia',
    desc: 'Baseado no seu estilo casual + clima tropical',
    icon: Sparkles,
    gradient: 'from-purple-500/20 to-blue-500/20',
  },
  {
    id: '2',
    title: 'Corte de cabelo',
    desc: 'Sugestão para rosto oval com cabelo cacheado',
    icon: Scissors,
    gradient: 'from-gold/20 to-orange-500/20',
  },
  {
    id: '3',
    title: 'Cuidado com a pele',
    desc: 'Rotina matinal para pele mista',
    icon: Droplets,
    gradient: 'from-blue-500/20 to-teal-500/20',
  },
];

const trends = [
  { id: 't1', title: 'Minimalista Earth Tones', tag: 'Tendência' },
  { id: 't2', title: 'Streetwear Luxo', tag: 'Popular' },
  { id: 't3', title: 'Boho Moderno', tag: 'Novo' },
  { id: 't4', title: 'Classic Tailoring', tag: 'Atemporal' },
  { id: 't5', title: 'Athleisure Chic', tag: 'Versátil' },
];

const routineItems = [
  { id: 'r1', label: 'Limpeza facial', time: '06:00', icon: Sun },
  { id: 'r2', label: 'Hidratante com FPS', time: '06:15', icon: Sun },
  { id: 'r3', label: 'Óleo capilar', time: '07:00', icon: Droplets },
  { id: 'r4', label: 'Água micelar', time: '21:00', icon: Moon },
  { id: 'r5', label: 'Creme noturno', time: '21:10', icon: Moon },
];

function ProfileSummaryCard() {
  const { profile } = useAura();

  const items = [
    { label: 'Cabelo', value: profile.hairType || '—' },
    { label: 'Pele', value: profile.skinTypes[0] || '—' },
    { label: 'Corpo', value: profile.bodyType || '—' },
    { label: 'Estilo', value: profile.styles[0] || '—' },
  ];

  return (
    <div className="glass rounded-2xl p-4">
      <div className="flex items-center gap-2 mb-3">
        <Palette className="h-4 w-4 text-primary" />
        <span className="text-sm font-semibold">Seu Perfil Estético</span>
      </div>
      <div className="grid grid-cols-2 gap-2">
        {items.map((item) => (
          <div key={item.label} className="rounded-xl bg-surface p-3 text-center">
            <span className="text-[10px] uppercase tracking-wider text-muted-foreground block">
              {item.label}
            </span>
            <span className="text-sm font-medium capitalize mt-0.5 block">
              {item.value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

function DailyRecs() {
  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
          Recomendações do Dia
        </h2>
        <span className="text-xs text-primary">Ver tudo</span>
      </div>
      <div className="flex flex-col gap-3">
        {dailyRecs.map((rec, i) => {
          const Icon = rec.icon;
          return (
            <motion.div
              key={rec.id}
              initial={{ x: 40, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: i * 0.1, type: 'spring', stiffness: 300, damping: 30 }}
              className={`glass rounded-2xl p-4 flex items-center gap-4 bg-gradient-to-r ${rec.gradient}`}
            >
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-surface-strong">
                <Icon className="h-5 w-5 text-primary" />
              </div>
              <div className="flex-1 min-w-0">
                <span className="text-sm font-semibold block">{rec.title}</span>
                <span className="text-xs text-muted-foreground block mt-0.5">{rec.desc}</span>
              </div>
              <ArrowRight className="h-4 w-4 text-muted-foreground shrink-0" />
            </motion.div>
          );
        })}
      </div>
    </div>
  );
}

function TrendsSection() {
  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
          Tendências para seu tipo
        </h2>
        <TrendingUp className="h-4 w-4 text-primary" />
      </div>
      <div className="flex gap-3 overflow-x-auto no-scrollbar pb-2 -mx-1 px-1">
        {trends.map((t) => (
          <motion.div
            key={t.id}
            whileTap={{ scale: 0.96 }}
            className="glass rounded-2xl p-4 min-w-[160px] flex-shrink-0 cursor-pointer hover:border-primary/30 transition-colors"
          >
            <span className="text-[10px] uppercase tracking-wider text-primary font-medium">
              {t.tag}
            </span>
            <span className="text-sm font-semibold block mt-1">{t.title}</span>
          </motion.div>
        ))}
      </div>
    </div>
  );
}

function RoutineSection() {
  const { profile, toggleRoutine, routineDone } = useAura();
  const done = routineDone;

  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
          Rotina de Cuidados
        </h2>
        <span className="text-xs text-gold">{done.length}/{routineItems.length}</span>
      </div>
      <div className="flex flex-col gap-2">
        {routineItems.map((item) => {
          const Icon = item.icon;
          const isDone = done.includes(item.id);
          return (
            <motion.button
              key={item.id}
              whileTap={{ scale: 0.98 }}
              onClick={() => toggleRoutine(item.id)}
              className={`glass rounded-xl p-3 flex items-center gap-3 text-left transition-all ${
                isDone ? 'opacity-50' : ''
              }`}
            >
              <div className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${
                isDone ? 'bg-surface-strong' : 'bg-surface'
              }`}>
                <Icon className={`h-4 w-4 ${isDone ? 'text-muted-foreground' : 'text-primary'}`} />
              </div>
              <div className="flex-1">
                <span className={`text-sm font-medium ${isDone ? 'line-through text-muted-foreground' : ''}`}>
                  {item.label}
                </span>
                <span className="text-xs text-muted-foreground block">{item.time}</span>
              </div>
              {isDone && (
                <motion.span
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  className="text-xs text-primary font-medium"
                >
                  ✓
                </motion.span>
              )}
            </motion.button>
          );
        })}
      </div>
    </div>
  );
}

function ClosetPlaceholder() {
  return (
    <div className="flex flex-col items-center justify-center gap-4 py-12">
      <div className="flex h-20 w-20 items-center justify-center rounded-3xl bg-surface-strong">
        <Sparkles className="h-10 w-10 text-muted-foreground" />
      </div>
      <div className="text-center">
        <h3 className="text-lg font-semibold">Seu Armário Virtual</h3>
        <p className="text-sm text-muted-foreground mt-1 max-w-xs">
          Fotografe e organize suas roupas aqui. Em breve você poderá gerar looks automaticamente!
        </p>
      </div>
    </div>
  );
}

function ExplorePlaceholder() {
  return (
    <div className="flex flex-col items-center justify-center gap-4 py-12">
      <div className="flex h-20 w-20 items-center justify-center rounded-3xl bg-surface-strong">
        <Heart className="h-10 w-10 text-muted-foreground" />
      </div>
      <div className="text-center">
        <h3 className="text-lg font-semibold">Explorar</h3>
        <p className="text-sm text-muted-foreground mt-1 max-w-xs">
          Descubra tendências, dicas de estilo e inspirações personalizadas para você.
        </p>
      </div>
    </div>
  );
}

function ProfileTab() {
  const { profile, reset } = useAura();

  return (
    <div className="flex flex-col gap-6 py-4">
      <div className="glass rounded-2xl p-6 text-center">
        <div className="mx-auto h-20 w-20 rounded-full bg-aura flex items-center justify-center text-3xl mb-3">
          {profile.name ? profile.name.charAt(0).toUpperCase() : '?'}
        </div>
        <h2 className="text-xl font-bold">{profile.name || 'Seu Nome'}</h2>
        <p className="text-sm text-muted-foreground mt-1">Perfil Estético</p>
      </div>

      <div className="glass rounded-2xl p-4">
        <h3 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-3">
          Resumo Completo
        </h3>
        <div className="flex flex-col gap-2 text-sm">
          {profile.gender && (
            <div className="flex justify-between py-1 border-b border-border">
              <span className="text-muted-foreground">Gênero</span>
              <span className="capitalize">{profile.gender}</span>
            </div>
          )}
          {profile.faceShape && (
            <div className="flex justify-between py-1 border-b border-border">
              <span className="text-muted-foreground">Rosto</span>
              <span className="capitalize">{profile.faceShape}</span>
            </div>
          )}
          {profile.hairType && (
            <div className="flex justify-between py-1 border-b border-border">
              <span className="text-muted-foreground">Cabelo</span>
              <span className="capitalize">{profile.hairType}</span>
            </div>
          )}
          {profile.bodyType && (
            <div className="flex justify-between py-1 border-b border-border">
              <span className="text-muted-foreground">Corpo</span>
              <span className="capitalize">{profile.bodyType}</span>
            </div>
          )}
          {profile.budget && (
            <div className="flex justify-between py-1 border-b border-border">
              <span className="text-muted-foreground">Orçamento</span>
              <span className="capitalize">{profile.budget}</span>
            </div>
          )}
          {profile.styles.length > 0 && (
            <div className="flex justify-between py-1 border-b border-border">
              <span className="text-muted-foreground">Estilos</span>
              <span className="capitalize text-right">{profile.styles.join(', ')}</span>
            </div>
          )}
        </div>
      </div>

      <button
        onClick={reset}
        className="text-sm text-destructive hover:underline text-center py-2"
      >
        Resetar perfil e recomeçar
      </button>
    </div>
  );
}

export default function DashboardScreen() {
  const { profile } = useAura();
  const [activeTab, setActiveTab] = useAuraTab('home');

  const firstName = profile.name?.split(' ')[0] || 'Estilista';

  return (
    <div className="relative min-h-screen pb-20">
      <AuroraBackground />

      <div className="relative z-10 px-4 pt-6 max-w-lg mx-auto">
        {/* Header */}
        <motion.div
          initial={{ y: -20, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          className="mb-6"
        >
          <h1 className="text-2xl font-bold">
            Olá, {firstName}! <Sparkles className="inline h-6 w-6 text-gold" />
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Suas recomendações personalizadas estão prontas
          </p>
        </motion.div>

        {/* Tab Content */}
        {activeTab === 'home' && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="flex flex-col gap-6"
          >
            <ProfileSummaryCard />
            <DailyRecs />
            <TrendsSection />
            <RoutineSection />
          </motion.div>
        )}

        {activeTab === 'closet' && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            <ClosetPlaceholder />
          </motion.div>
        )}

        {activeTab === 'explore' && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            <ExplorePlaceholder />
          </motion.div>
        )}

        {activeTab === 'profile' && (
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
            <ProfileTab />
          </motion.div>
        )}
      </div>

      <BottomNav active={activeTab} onChange={setActiveTab} />
    </div>
  );
}

function useAuraTab(defaultTab: Tab) {
  const [tab, setTab] = React.useState<Tab>(defaultTab);
  return [tab, setTab] as const;
}
