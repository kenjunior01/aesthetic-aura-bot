'use client';

import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import {
  Sparkles, Scissors, TrendingUp,
  Droplets, Sun, Moon, Palette, ArrowRight,
  Flame, Zap, Share2, Star, Cloud, CloudOff,
  Bell, BellOff, Settings, LogOut, Download, Upload, ShoppingBag,
} from 'lucide-react';
import { useAura, getLevelInfo } from '@/lib/aura-store';
import { AuroraBackground } from '@/components/aura/AuroraBackground';
import AuraRadar from '@/components/aura/AuraRadar';
import AuraClima from '@/components/aura/AuraClima';
import BottomNav from './BottomNav';
import type { Tab } from './BottomNav';
import ClosetScreen from './ClosetScreen';
import ExploreScreen from './ExploreScreen';
import ActivitiesScreen from './ActivitiesScreen';
import ShoppingScreen from './ShoppingScreen';
import AIChatButton from './AIChatButton';
import ReferralSection from './ReferralSection';
import NearbySalons from './NearbySalons';
import { useAchievements } from '@/hooks/use-achievements';
import { signOut, logEvent, requestNotificationPermission, scheduleRoutineReminder, exportAllData, downloadJSON, importData, loadFullProfileFromCloud } from '@/lib/services';
import ProfileEditScreen from './ProfileEditScreen';
import { GOAL_OPTIONS, getGoal } from '@/lib/goals';
import { COUNTRIES } from '@/lib/shopping';

const dailyRecs = [
  {
    id: '1',
    title: 'Look do dia',
    desc: 'Baseado no seu estilo casual + clima tropical',
    icon: Sparkles,
    domain: 'estilo',
    gradient: 'from-primary/15 to-gold/10',
  },
  {
    id: '2',
    title: 'Corte de cabelo',
    desc: 'Sugestão para rosto oval com cabelo cacheado',
    icon: Scissors,
    domain: 'cabelo',
    gradient: 'from-gold/20 to-primary-glow/15',
  },
  {
    id: '3',
    title: 'Cuidado com a pele',
    desc: 'Rotina matinal para pele mista',
    icon: Droplets,
    domain: 'pele',
    gradient: 'from-accent/15 to-gold/10',
  },
  {
    id: '4',
    title: 'Plano de compras',
    desc: 'O que comprar primeiro com o teu orçamento',
    icon: ShoppingBag,
    domain: 'compras',
    gradient: 'from-gold/15 to-primary/10',
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

/** Reordena as recomendações do dia conforme as prioridades do usuário */
function priorityOrder(items: typeof dailyRecs, priorities: string[]): typeof dailyRecs {
  const rank = (domain: string) => {
    const idx = priorities.indexOf(domain);
    return idx >= 0 ? idx : 99;
  };
  return [...items].sort((a, b) => rank(a.domain) - rank(b.domain));
}

/** Cartão do foco nº 1 — o coração do design adaptativo */
function PriorityFocusCard({ onGoToMarket }: { onGoToMarket?: () => void }) {
  const { profile } = useAura();
  const top = profile.priorities?.[0];
  const goal = top ? getGoal(top) : undefined;
  const Icon = goal?.icon || Sparkles;
  const isShopping = top === 'compras';

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      className="glass rounded-2xl border border-primary/25 bg-gradient-to-br from-primary/10 to-transparent p-4"
    >
      <div className="mb-2 flex items-center gap-2">
        <span className="rounded-full bg-aura px-2 py-0.5 text-[9px] font-bold uppercase tracking-widest text-primary-foreground">
          Prioridade nº 1
        </span>
        <span className="text-xs font-semibold text-primary">{goal?.label || 'Seu foco'}</span>
      </div>
      <div className="flex items-start gap-3">
        <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-aura/20">
          <Icon className="h-5 w-5 text-primary" />
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-sm leading-relaxed">{goal?.focusLine || 'Define tuas prioridades para o app se adaptar a ti.'}</p>
          {isShopping && onGoToMarket && (
            <button
              onClick={onGoToMarket}
              className="mt-2 inline-flex items-center gap-1.5 rounded-xl bg-aura px-3.5 py-2 text-xs font-semibold text-primary-foreground glow"
            >
              <ShoppingBag className="h-3.5 w-3.5" />
              Abrir Consultor de Compras
            </button>
          )}
        </div>
      </div>
    </motion.div>
  );
}

function ProfileSummaryCard() {
  const { profile } = useAura();

  const items = [
    { label: 'Cabelo', value: profile.hairType || '—' },
    { label: 'Pele', value: profile.skinTypes[0] || '—' },
    { label: 'Corpo', value: profile.bodyType || '—' },
    { label: 'Estilo', value: profile.styles[0] || '—' },
  ];

  return (
    <div className='glass rounded-2xl p-4'>
      <div className='flex items-center gap-2 mb-3'>
        <Palette className='h-4 w-4 text-primary' />
        <span className='text-sm font-semibold'>Seu Perfil Estético</span>
      </div>
      <div className='grid grid-cols-2 gap-2'>
        {items.map((item) => (
          <div key={item.label} className='rounded-xl bg-surface p-3 text-center'>
            <span className='text-[10px] uppercase tracking-wider text-muted-foreground block'>
              {item.label}
            </span>
            <span className='text-sm font-medium capitalize mt-0.5 block'>
              {item.value}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

function StreakAndLevelBar() {
  const { xp, streak, checkAndUpdateStreak, lastSyncAt, authUid } = useAura();
  const { level, progress } = getLevelInfo(xp);

  useEffect(() => {
    checkAndUpdateStreak();
  }, [checkAndUpdateStreak]);

  return (
    <motion.div
      initial={{ opacity: 0, y: -10 }}
      animate={{ opacity: 1, y: 0 }}
      className='glass rounded-2xl p-3 flex items-center gap-3'
    >
      <div className='h-10 w-10 rounded-full bg-aura flex items-center justify-center shrink-0'>
        <span className='text-sm font-bold text-primary-foreground'>{level}</span>
      </div>

      <div className='flex-1 min-w-0'>
        <div className='flex items-center justify-between mb-1'>
          <span className='text-[10px] text-muted-foreground'>Nível {level}</span>
          <span className='text-[10px] text-gold font-medium'>{xp} XP</span>
        </div>
        <div className='h-1.5 rounded-full bg-surface-strong overflow-hidden'>
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${Math.min(progress * 100, 100)}%` }}
            transition={{ type: 'spring', stiffness: 200, damping: 30 }}
            className='h-full rounded-full bg-aura'
          />
        </div>
      </div>

      {streak > 0 && (
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          className='flex items-center gap-1 rounded-full bg-gold/15 px-2.5 py-1.5 shrink-0'
        >
          <Flame className='h-3.5 w-3.5 text-gold' />
          <span className='text-xs font-bold text-gold'>{streak}</span>
        </motion.div>
      )}

      {authUid && (
        <div className='shrink-0' title={lastSyncAt ? `Sincronizado: ${new Date(lastSyncAt).toLocaleTimeString()}` : 'Aguardando sync'}>
          {lastSyncAt
            ? <Cloud className='h-4 w-4 text-green-400' />
            : <CloudOff className='h-4 w-4 text-muted-foreground' />
          }
        </div>
      )}
    </motion.div>
  );
}

function DailyRecs({ priorities }: { priorities: string[] }) {
  const ordered = priorityOrder(dailyRecs, priorities);
  return (
    <div>
      <div className='flex items-center justify-between mb-3'>
        <h2 className='text-sm font-semibold uppercase tracking-widest text-muted-foreground'>
          Recomendações do Dia
        </h2>
        <span className='text-xs text-primary'>Na tua ordem</span>
      </div>
      <div className='flex flex-col gap-3'>
        {ordered.map((rec, i) => {
          const Icon = rec.icon;
          return (
            <motion.div
              key={rec.id}
              initial={{ x: 40, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              transition={{ delay: i * 0.1, type: 'spring', stiffness: 300, damping: 30 }}
              className={`glass rounded-2xl p-4 flex items-center gap-4 bg-gradient-to-r ${rec.gradient}`}
            >
              <div className='flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-surface-strong'>
                <Icon className='h-5 w-5 text-primary' />
              </div>
              <div className='flex-1 min-w-0'>
                <span className='text-sm font-semibold block'>{rec.title}</span>
                <span className='text-xs text-muted-foreground block mt-0.5'>{rec.desc}</span>
              </div>
              <ArrowRight className='h-4 w-4 text-muted-foreground shrink-0' />
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
      <div className='flex items-center justify-between mb-3'>
        <h2 className='text-sm font-semibold uppercase tracking-widest text-muted-foreground'>
          Tendências para seu tipo
        </h2>
        <TrendingUp className='h-4 w-4 text-primary' />
      </div>
      <div className='flex gap-3 overflow-x-auto no-scrollbar pb-2 -mx-1 px-1'>
        {trends.map((t) => (
          <motion.div
            key={t.id}
            whileTap={{ scale: 0.96 }}
            className='glass rounded-2xl p-4 min-w-[160px] flex-shrink-0 cursor-pointer hover:border-primary/30 transition-colors'
          >
            <span className='text-[10px] uppercase tracking-wider text-primary font-medium'>
              {t.tag}
            </span>
            <span className='text-sm font-semibold block mt-1'>{t.title}</span>
          </motion.div>
        ))}
      </div>
    </div>
  );
}

function RoutineSection() {
  const { profile, toggleRoutine, routineDone, notificationsEnabled, setNotificationsEnabled, addRoutineReminder } = useAura();
  const done = routineDone;

  const handleToggleNotification = async () => {
    if (!notificationsEnabled) {
      const granted = await requestNotificationPermission();
      if (granted) {
        setNotificationsEnabled(true);
        // Schedule all routine reminders
        routineItems.forEach((item) => {
          addRoutineReminder({ id: item.id, time: item.time, label: item.label, enabled: true });
          scheduleRoutineReminder(item.time, item.label);
        });
        logEvent('notifications_enabled');
      }
    } else {
      setNotificationsEnabled(false);
      logEvent('notifications_disabled');
    }
  };

  return (
    <div>
      <div className='flex items-center justify-between mb-3'>
        <h2 className='text-sm font-semibold uppercase tracking-widest text-muted-foreground'>
          Rotina de Cuidados
        </h2>
        <div className='flex items-center gap-3'>
          <motion.button
            whileTap={{ scale: 0.95 }}
            onClick={handleToggleNotification}
            className='flex items-center gap-1'
            title={notificationsEnabled ? 'Desativar notificações' : 'Ativar lembretes'}
          >
            {notificationsEnabled
              ? <Bell className='h-4 w-4 text-primary' />
              : <BellOff className='h-4 w-4 text-muted-foreground' />
            }
          </motion.button>
          <span className='text-xs text-gold'>{done.length}/{routineItems.length}</span>
        </div>
      </div>
      <div className='flex flex-col gap-2'>
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
              <div className='flex-1'>
                <span className={`text-sm font-medium ${isDone ? 'line-through text-muted-foreground' : ''}`}>
                  {item.label}
                </span>
                <span className='text-xs text-muted-foreground block'>{item.time}</span>
              </div>
              {isDone && (
                <motion.span
                  initial={{ scale: 0 }}
                  animate={{ scale: 1 }}
                  className='text-xs text-primary font-medium'
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

function ShareSection() {
  const { profile, xp, streak, referralCode } = useAura();
  const { level } = getLevelInfo(xp);
  const firstName = profile.name?.split(' ')[0] || 'Estilista';

  const handleShare = async () => {
    const shareText = referralCode
      ? `${firstName} está no nível ${level} no AuraStyle! Use meu código ${referralCode} para ganhar bônus. Baixe agora!`
      : `${firstName} está no nível ${level} no AuraStyle! ${streak} dias de streak. Baixe agora e descubra seu estilo!`;

    logEvent('share_app', { method: 'native_share', hasReferral: !!referralCode });

    if (navigator.share) {
      try {
        await navigator.share({ title: 'AuraStyle - Seu estilo, reinventado', text: shareText });
      } catch {
        // User cancelled
      }
    } else {
      await navigator.clipboard.writeText(shareText);
    }
  };

  return (
    <motion.button
      whileTap={{ scale: 0.98 }}
      onClick={handleShare}
      className='glass rounded-2xl p-4 flex items-center gap-3 bg-gradient-to-r from-primary/10 to-gold/10 w-full text-left'
    >
      <div className='flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-aura'>
        <Share2 className='h-5 w-5 text-primary-foreground' />
      </div>
      <div className='flex-1'>
        <span className='text-sm font-semibold block'>Convidar amigos</span>
        <span className='text-xs text-muted-foreground block mt-0.5'>Ganhe XP e recompensas por cada convite</span>
      </div>
      <ArrowRight className='h-4 w-4 text-muted-foreground' />
    </motion.button>
  );
}

/** Editor compacto de prioridades + país (aba Perfil) */
function PrioritiesEditor() {
  const { profile, update } = useAura();
  const priorities = profile.priorities || [];

  const toggle = (id: string) => {
    if (priorities.includes(id)) {
      update({ priorities: priorities.filter((p) => p !== id) });
    } else if (priorities.length < 3) {
      update({ priorities: [...priorities, id] });
    }
  };

  return (
    <div className='glass rounded-2xl p-4'>
      <h3 className='text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-3'>
        Minhas Prioridades
      </h3>
      <p className='text-xs text-muted-foreground mb-3'>
        A ordem define o que o app mostra primeiro. Toque para adicionar/remover (máx. 3).
      </p>
      <div className='flex flex-wrap gap-2'>
        {GOAL_OPTIONS.map((g) => {
          const idx = priorities.indexOf(g.id);
          const selected = idx >= 0;
          return (
            <button
              key={g.id}
              onClick={() => toggle(g.id)}
              className={
                selected
                  ? 'inline-flex items-center gap-1.5 rounded-full bg-aura px-3 py-1.5 text-xs font-semibold text-primary-foreground'
                  : 'inline-flex items-center gap-1.5 rounded-full border border-border bg-surface px-3 py-1.5 text-xs text-muted-foreground hover:text-foreground'
              }
            >
              {selected && <span className="text-[10px] font-bold">{idx + 1}º</span>}
              {g.label}
            </button>
          );
        })}
      </div>

      {/* País — usado pelo Consultor de Compras */}
      <div className='mt-4 flex items-center justify-between gap-3 py-2 border-t border-border'>
        <span className='text-sm text-muted-foreground'>País (preços locais)</span>
        <select
          value={profile.country || ''}
          onChange={(e) => update({ country: e.target.value })}
          className='h-10 max-w-[190px] rounded-xl border border-border bg-surface px-2 text-sm capitalize outline-none focus:border-primary/50'
        >
          <option value=''>Detectar automaticamente</option>
          {COUNTRIES.map((c) => (
            <option key={c.code} value={c.code}>
              {c.name} ({c.currency})
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}

function ProfileTab() {
  const {
    profile, xp, streak, totalCompletedActivities, achievements,
    reset, authUid, authEmail, referralCode, referralCount,
    lastSyncAt, notificationsEnabled, syncToCloud, clearAuth,
    closet, favorites, routineDone, weeklyGoals, dailyActivities,
  } = useAura();
  const [showResetConfirm, setShowResetConfirm] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [editing, setEditing] = useState(false);
  const [importMsg, setImportMsg] = useState('');
  const { level } = getLevelInfo(xp);
  const unlockedCount = achievements.filter((a) => a.unlockedAt).length;
  const importRef = React.useRef<HTMLInputElement>(null);

  const handleSync = async () => {
    setSyncing(true);
    await syncToCloud();
    setSyncing(false);
  };

  const handleSignOut = async () => {
    await signOut();
    clearAuth();
    logEvent('sign_out');
  };

  const handleExport = () => {
    const state = useAura.getState();
    const json = exportAllData(state);
    const filename = `aurastyle-backup-${new Date().toISOString().split('T')[0]}.json`;
    downloadJSON(json, filename);
    logEvent('data_exported');
  };

  const handleImport = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => {
      const data = importData(reader.result as string);
      if (!data) {
        setImportMsg('Arquivo inválido');
        setTimeout(() => setImportMsg(''), 3000);
        return;
      }
      const store = useAura.getState();
      if (data.profile) store.update(data.profile as any);
      if (data.gamification) {
        // XP and achievements are read-only via actions, but we can trigger them
      }
      setImportMsg('Dados importados com sucesso!');
      logEvent('data_imported');
      setTimeout(() => setImportMsg(''), 3000);
    };
    reader.readAsText(file);
  };

  const handleLoadFromCloud = async () => {
    if (!authUid) return;
    setSyncing(true);
    try {
      const cloudData = await loadFullProfileFromCloud(authUid);
      if (cloudData?.profile) {
        const store = useAura.getState();
        store.update(cloudData.profile);
        setImportMsg('Perfil carregado da nuvem!');
        logEvent('profile_loaded_from_cloud');
        setTimeout(() => setImportMsg(''), 3000);
      } else {
        setImportMsg('Nenhum dado encontrado na nuvem');
        setTimeout(() => setImportMsg(''), 3000);
      }
    } catch {
      setImportMsg('Erro ao carregar da nuvem');
      setTimeout(() => setImportMsg(''), 3000);
    }
    setSyncing(false);
  };

  if (editing) {
    return <ProfileEditScreen onClose={() => setEditing(false)} />;
  }

  return (
    <div className='flex flex-col gap-6 py-4'>
      {/* Avatar + stats */}
      <div className='glass rounded-2xl p-6 text-center'>
        <div className='mx-auto h-20 w-20 rounded-full bg-aura flex items-center justify-center text-3xl mb-3'>
          {profile.name ? profile.name.charAt(0).toUpperCase() : '?'}
        </div>
        <h2 className='text-xl font-bold'>{profile.name || 'Seu Nome'}</h2>
        <p className='text-sm text-muted-foreground mt-1'>
          {authEmail ? `Perfil Estético · ${authEmail}` : 'Perfil Estético'}
        </p>
        <div className='flex items-center justify-center gap-4 mt-3'>
          <div className='text-center'>
            <span className='text-lg font-bold text-primary block'>{level}</span>
            <span className='text-[10px] text-muted-foreground uppercase'>Nível</span>
          </div>
          <div className='h-8 w-px bg-border' />
          <div className='text-center'>
            <span className='text-lg font-bold text-gold block'>{streak}d</span>
            <span className='text-[10px] text-muted-foreground uppercase'>Streak</span>
          </div>
          <div className='h-8 w-px bg-border' />
          <div className='text-center'>
            <span className='text-lg font-bold text-gold block'>{xp}</span>
            <span className='text-[10px] text-muted-foreground uppercase'>XP</span>
          </div>
        </div>
      </div>

      {/* Stats grid */}
      <div className='grid grid-cols-3 gap-2.5'>
        <div className='glass rounded-2xl p-3 text-center'>
          <Star className='h-4 w-4 text-gold mx-auto mb-1' />
          <span className='text-base font-bold block'>{unlockedCount}</span>
          <span className='text-[10px] text-muted-foreground uppercase tracking-wider'>Conquistas</span>
        </div>
        <div className='glass rounded-2xl p-3 text-center'>
          <Zap className='h-4 w-4 text-primary mx-auto mb-1' />
          <span className='text-base font-bold block'>{totalCompletedActivities}</span>
          <span className='text-[10px] text-muted-foreground uppercase tracking-wider'>Atividades</span>
        </div>
        <div className='glass rounded-2xl p-3 text-center'>
          <Flame className='h-4 w-4 text-gold mx-auto mb-1' />
          <span className='text-base font-bold block'>{streak}d</span>
          <span className='text-[10px] text-muted-foreground uppercase tracking-wider'>Melhor streak</span>
        </div>
      </div>

      {/* Prioridades + país */}
      <PrioritiesEditor />

      {/* Referral Section */}
      <ReferralSection />

      {/* Cloud sync & account */}
      <div className='glass rounded-2xl p-4'>
        <h3 className='text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-3'>
          Conta & Sincronização
        </h3>
        <div className='flex flex-col gap-2 text-sm'>
          <div className='flex justify-between py-1.5 border-b border-border'>
            <span className='text-muted-foreground'>Status</span>
            <span className={authUid ? 'text-green-400' : 'text-muted-foreground'}>
              {authUid ? 'Conectado' : 'Conta local'}
            </span>
          </div>
          {authEmail && (
            <div className='flex justify-between py-1.5 border-b border-border'>
              <span className='text-muted-foreground'>Email</span>
              <span className='truncate max-w-[180px]'>{authEmail}</span>
            </div>
          )}
          <div className='flex justify-between py-1.5 border-b border-border'>
            <span className='text-muted-foreground'>Último sync</span>
            <span>{lastSyncAt ? new Date(lastSyncAt).toLocaleString() : 'Nunca'}</span>
          </div>
          <div className='flex justify-between py-1.5 border-b border-border'>
            <span className='text-muted-foreground'>Notificações</span>
            <span>{notificationsEnabled ? 'Ativas' : 'Desativadas'}</span>
          </div>
          {referralCode && (
            <div className='flex justify-between py-1.5 border-b border-border'>
              <span className='text-muted-foreground'>Convites</span>
              <span>{referralCount} amigo{referralCount !== 1 ? 's' : ''}</span>
            </div>
          )}
        </div>

        {/* Actions */}
        <div className='flex flex-col gap-2 mt-4'>
          {authUid && (
            <motion.button
              whileTap={{ scale: 0.98 }}
              onClick={handleSync}
              disabled={syncing}
              className='rounded-xl border border-border bg-surface p-3 flex items-center gap-3 text-left hover:border-primary/30 transition-colors'
            >
              {syncing
                ? <Sparkles className='h-4 w-4 text-primary animate-pulse' />
                : <Cloud className='h-4 w-4 text-primary' />
              }
              <span className='text-sm font-medium'>{syncing ? 'Sincronizando...' : 'Sincronizar agora'}</span>
            </motion.button>
          )}

          <motion.button
            whileTap={{ scale: 0.98 }}
            onClick={() => setEditing(true)}
            className='rounded-xl border border-border bg-surface p-3 flex items-center gap-3 text-left hover:border-primary/30 transition-colors'
          >
            <Settings className='h-4 w-4 text-primary' />
            <span className='text-sm font-medium'>Editar Perfil</span>
          </motion.button>

          <motion.button
            whileTap={{ scale: 0.98 }}
            onClick={handleExport}
            className='rounded-xl border border-border bg-surface p-3 flex items-center gap-3 text-left hover:border-primary/30 transition-colors'
          >
            <Download className='h-4 w-4 text-muted-foreground' />
            <span className='text-sm font-medium'>Exportar dados (JSON)</span>
          </motion.button>

          <label className='rounded-xl border border-border bg-surface p-3 flex items-center gap-3 text-left hover:border-primary/30 transition-colors cursor-pointer'>
            <Upload className='h-4 w-4 text-muted-foreground' />
            <span className='text-sm font-medium'>Importar backup</span>
            <input
              ref={importRef}
              type='file'
              accept='.json'
              onChange={handleImport}
              className='hidden'
            />
          </label>

          {authUid && (
            <motion.button
              whileTap={{ scale: 0.98 }}
              onClick={handleLoadFromCloud}
              disabled={syncing}
              className='rounded-xl border border-border bg-surface p-3 flex items-center gap-3 text-left hover:border-primary/30 transition-colors'
            >
              {syncing
                ? <Sparkles className='h-4 w-4 text-primary animate-pulse' />
                : <Cloud className='h-4 w-4 text-primary' />
              }
              <span className='text-sm font-medium'>{syncing ? 'Carregando...' : 'Restaurar da nuvem'}</span>
            </motion.button>
          )}

          {importMsg && (
            <motion.p
              initial={{ opacity: 0, y: -4 }}
              animate={{ opacity: 1, y: 0 }}
              className='text-xs text-center py-1 font-medium text-primary'
            >
              {importMsg}
            </motion.p>
          )}

          {authUid && (
            <motion.button
              whileTap={{ scale: 0.98 }}
              onClick={handleSignOut}
              className='rounded-xl border border-border bg-surface p-3 flex items-center gap-3 text-left hover:border-destructive/30 transition-colors'
            >
              <LogOut className='h-4 w-4 text-destructive' />
              <span className='text-sm font-medium text-destructive'>Sair da conta</span>
            </motion.button>
          )}
        </div>
      </div>

      {/* Full profile details */}
      <div className='glass rounded-2xl p-4'>
        <h3 className='text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-3'>
          Resumo Completo
        </h3>
        <div className='flex flex-col gap-2 text-sm'>
          {profile.email && (
            <div className='flex justify-between py-1 border-b border-border'>
              <span className='text-muted-foreground'>Email</span>
              <span className='truncate max-w-[180px]'>{profile.email}</span>
            </div>
          )}
          {profile.phone && (
            <div className='flex justify-between py-1 border-b border-border'>
              <span className='text-muted-foreground'>Telefone</span>
              <span>{profile.phone}</span>
            </div>
          )}
          {profile.gender && (
            <div className='flex justify-between py-1 border-b border-border'>
              <span className='text-muted-foreground'>Gênero</span>
              <span className='capitalize'>{profile.gender}</span>
            </div>
          )}
          {profile.faceShape && (
            <div className='flex justify-between py-1 border-b border-border'>
              <span className='text-muted-foreground'>Rosto</span>
              <span className='capitalize'>{profile.faceShape}</span>
            </div>
          )}
          {profile.hairType && (
            <div className='flex justify-between py-1 border-b border-border'>
              <span className='text-muted-foreground'>Cabelo</span>
              <span className='capitalize'>{profile.hairType}</span>
            </div>
          )}
          {profile.bodyType && (
            <div className='flex justify-between py-1 border-b border-border'>
              <span className='text-muted-foreground'>Corpo</span>
              <span className='capitalize'>{profile.bodyType}</span>
            </div>
          )}
          {profile.budget && (
            <div className='flex justify-between py-1 border-b border-border'>
              <span className='text-muted-foreground'>Orçamento</span>
              <span className='capitalize'>{profile.budget}</span>
            </div>
          )}
          {profile.region && (
            <div className='flex justify-between py-1 border-b border-border'>
              <span className='text-muted-foreground'>Região</span>
              <span>{profile.region}</span>
            </div>
          )}
          {profile.styles.length > 0 && (
            <div className='flex justify-between py-1 border-b border-border'>
              <span className='text-muted-foreground'>Estilos</span>
              <span className='capitalize text-right'>{profile.styles.join(', ')}</span>
            </div>
          )}
        </div>
      </div>

      {/* Reset */}
      {!showResetConfirm ? (
        <button
          onClick={() => setShowResetConfirm(true)}
          className='text-sm text-destructive hover:underline text-center py-2'
        >
          Resetar tudo e recomeçar
        </button>
      ) : (
        <div className='glass rounded-2xl p-4 text-center'>
          <p className='text-sm font-semibold mb-1'>Tem certeza?</p>
          <p className='text-xs text-muted-foreground mb-3'>Isso apagará seu perfil, XP, conquistas e progresso.</p>
          <div className='flex gap-3'>
            <button
              onClick={() => setShowResetConfirm(false)}
              className='flex-1 h-10 rounded-xl border border-border text-sm font-medium hover:bg-surface-strong transition-colors'
            >
              Cancelar
            </button>
            <button
              onClick={() => { reset(); setShowResetConfirm(false); }}
              className='flex-1 h-10 rounded-xl bg-destructive text-destructive-foreground text-sm font-medium'
            >
              Resetar
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

export default function DashboardScreen() {
  const { profile } = useAura();
  const [activeTab, setActiveTab] = useAuraTab('home');

  useAchievements();

  const firstName = profile.name?.split(' ')[0] || 'Estilista';
  const topGoal = profile.priorities?.[0] ? getGoal(profile.priorities[0]) : undefined;

  return (
    <div className='relative min-h-screen'>
      <AuroraBackground />

      {activeTab !== 'activities' && activeTab !== 'closet' && activeTab !== 'explore' && activeTab !== 'market' && (
        <div className='relative z-10 px-4 pt-6 max-w-lg mx-auto'>
          <motion.div
            initial={{ y: -20, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            className='mb-4'
          >
            <h1 className='text-2xl font-bold'>
              Olá, {firstName}! <Sparkles className='inline h-6 w-6 text-gold' />
            </h1>
            <p className='text-sm text-muted-foreground mt-1'>
              {topGoal
                ? `Foco de hoje: ${topGoal.label}`
                : 'Suas recomendações personalizadas estão prontas'}
            </p>
          </motion.div>

          <div className='mb-6'>
            <StreakAndLevelBar />
          </div>
        </div>
      )}

      {activeTab === 'home' && (
        <div className='relative z-10 px-4 max-w-lg mx-auto'>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className='flex flex-col gap-6 pb-24'
          >
            <PriorityFocusCard onGoToMarket={() => setActiveTab('market')} />
            <AuraRadar onNavigate={setActiveTab} />
            <DailyRecs priorities={profile.priorities || []} />
            <AuraClima />
            <TrendsSection />
            <RoutineSection />
            <NearbySalons />
            <ShareSection />
          </motion.div>
        </div>
      )}

      {activeTab === 'activities' && <ActivitiesScreen />}
      {activeTab === 'market' && <ShoppingScreen />}
      {activeTab === 'closet' && <ClosetScreen />}
      {activeTab === 'explore' && <ExploreScreen />}
      {activeTab === 'profile' && (
        <div className='relative z-10 px-4 max-w-lg mx-auto'>
          <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className='pb-24'>
            <ProfileTab />
          </motion.div>
        </div>
      )}

      <BottomNav active={activeTab} onChange={setActiveTab} />
      <AIChatButton />
    </div>
  );
}

function useAuraTab(defaultTab: Tab) {
  const [tab, setTab] = React.useState<Tab>(defaultTab);
  return [tab, setTab] as const;
}
