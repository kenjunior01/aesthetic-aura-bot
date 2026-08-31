'use client';

import React, { useEffect, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Flame, Zap, Trophy, Target, ChevronRight, Star,
  Check, Lock, TrendingUp, Gauge,
  Footprints, Crown, BookOpen, ShoppingBag, Shirt, Layers,
  Compass, CalendarCheck, Award, Gem, Wallet, Share2, type LucideIcon,
} from 'lucide-react';
import { useAura, getLevelInfo, nextStreakMilestone, STREAK_MILESTONES } from '@/lib/aura-store';
import type { DailyActivity } from '@/lib/aura-store';

/** Medalhas gravadas — sem emojis: ícone de linha em chip usinado */
const ACHIEVEMENT_ICONS: Record<string, LucideIcon> = {
  'primeira-atividade': Footprints,
  'streak-3': Flame,
  'streak-7': Zap,
  'streak-30': Crown,
  '10-atividades': Target,
  '50-atividades': BookOpen,
  '100-atividades': Trophy,
  'primeiro-look': ShoppingBag,
  'armario-10': Shirt,
  'armario-30': Layers,
  'todos-dias': Star,
  'explorador': Compass,
  'meta-semanal': CalendarCheck,
  'todas-metas': Award,
  'level-5': Gauge,
  'level-10': Award,
  'level-25': Gem,
  'orçamento-sabio': Wallet,
  'rotina-completa': CalendarCheck,
  'share-look': Share2,
};

function AchievementMedal({ id, title }: { id: string; title: string }) {
  const Icon = ACHIEVEMENT_ICONS[id];
  if (Icon) return <Icon className="h-6 w-6 mx-auto text-primary" strokeWidth={1.7} />;
  return <span className="text-lg font-display font-light text-primary">{title.charAt(0)}</span>;
}
import {
  dailyChallenges,
  weeklyGoalTemplates,
  achievementDefs,
  activityCategoryConfig,
} from '@/lib/aura-data';
import { cn } from '@/lib/utils';

function todayStr() { return new Date().toISOString().split('T')[0]; }

// ============================================================
// LEVEL BAR (XP Progress)
// ============================================================

function LevelBar() {
  const { xp, streak } = useAura();
  const { level, currentXp, xpNeeded, progress } = getLevelInfo(xp);

  return (
    <div className="glass rounded-2xl p-4">
      <div className="flex items-center justify-between mb-3">
        <div className="flex items-center gap-3">
          <div
            className="relative grid h-12 w-12 place-items-center rounded-full"
            style={{
              background:
                'conic-gradient(from 210deg, oklch(0.55 0.029 256), oklch(0.92 0.043 239) 18%, oklch(0.7 0.036 249) 38%, oklch(0.95 0.036 238) 55%, oklch(0.62 0.036 253) 74%, oklch(0.88 0.043 241) 92%, oklch(0.55 0.029 256))',
            }}
          >
            <div className="grid h-[82%] w-[82%] place-items-center rounded-full bg-[oklch(0.13_0.008_70)] shadow-[inset_0_2px_5px_oklch(0.01_0.004_70/0.85)]">
              <span className="text-base font-semibold text-primary">{level}</span>
            </div>
          </div>
          <div>
            <span className="text-sm font-bold block">Nível {level}</span>
            <span className="text-xs text-muted-foreground">
              {currentXp} / {xpNeeded} XP
            </span>
          </div>
        </div>
        <div className="flex items-center gap-1.5">
          <Flame className={cn('h-4 w-4', streak > 0 ? 'text-gold' : 'text-muted-foreground')} />
          <span className={cn('text-sm font-bold', streak > 0 ? 'text-gold' : 'text-muted-foreground')}>
            {streak}d
          </span>
        </div>
      </div>

      {/* XP Progress bar */}
      <div className="h-2.5 rounded-full bg-surface-strong overflow-hidden">
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${Math.min(progress * 100, 100)}%` }}
          transition={{ type: 'spring', stiffness: 200, damping: 30 }}
          className="h-full rounded-full bg-aura"
        />
      </div>

      {/* Escada de marcos do streak — próximo bônus visível */}
      <StreakLadder streak={streak} />

      {/* Streak banner */}
      {streak >= 3 && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-3 flex items-center gap-2 rounded-xl bg-gold/10 px-3 py-2"
        >
          <Flame className="h-4 w-4 text-gold" />
          <span className="text-xs font-medium text-gold/90">
            {streak >= 30 ? 'Mês de ouro! ' : streak >= 7 ? 'Semana perfeita! ' : ''}
            {streak} dias consecutivos de dedicação
          </span>
        </motion.div>
      )}
    </div>
  );
}

// ============================================================
// STREAK LADDER — marcos visuais com bônus XP (7d → +50…)
// ============================================================

function StreakLadder({ streak }: { streak: number }) {
  const next = nextStreakMilestone(streak);
  const last = STREAK_MILESTONES[STREAK_MILESTONES.length - 1];
  const isMax = !next;

  return (
    <div className="mt-3 rounded-xl bg-surface-strong/60 px-3 py-2.5">
      {/* Nós dos marcos: 3 · 7 · 14 · 30 · 60 · 100 */}
      <div className="flex items-center justify-between mb-2">
        {STREAK_MILESTONES.map((m) => {
          const reached = streak >= m.days;
          const isNext = next?.days === m.days;
          return (
            <div key={m.days} className="flex flex-col items-center gap-0.5">
              <motion.div
                initial={{ scale: 0 }}
                animate={{ scale: 1 }}
                transition={{ delay: m.days * 0.01, type: 'spring', stiffness: 300, damping: 20 }}
                className={cn(
                  'grid h-6 w-6 place-items-center rounded-full border text-[9px] font-bold',
                  reached
                    ? 'border-gold bg-gold/20 text-gold'
                    : isNext
                      ? 'border-primary bg-primary/15 text-primary glow'
                      : 'border-border text-muted-foreground/50',
                )}
              >
                {reached ? <Flame className="h-3 w-3" /> : m.days}
              </motion.div>
              <span className={cn('text-[8px] uppercase tracking-wide', reached ? 'text-gold/80' : 'text-muted-foreground/50')}>
                {m.days}d
              </span>
            </div>
          );
        })}
      </div>

      {/* Barra até o próximo marco */}
      {!isMax && next ? (
        <>
          <div className="h-1.5 rounded-full bg-background/60 overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${Math.min((streak / next.days) * 100, 100)}%` }}
              transition={{ type: 'spring', stiffness: 200, damping: 30 }}
              className="h-full rounded-full bg-gradient-to-r from-gold/70 to-gold"
            />
          </div>
          <span className="mt-1.5 block text-[10px] text-muted-foreground">
            Faltam <b className="text-gold">{next.days - streak} dia{next.days - streak > 1 ? 's' : ''}</b> para{' '}
            <b className="text-primary">{next.label}</b> → <b className="text-gold">+{next.xp} XP</b>
          </span>
        </>
      ) : (
        <span className="block text-[10px] text-gold font-semibold">
          {last.label} atingido — {streak} dias de lendário! {last.xp} XP já é teu
        </span>
      )}
    </div>
  );
}

// ============================================================
// DAILY ACTIVITY CARD
// ============================================================

function ActivityCard({ activity, onComplete }: { activity: DailyActivity; onComplete: () => void }) {
  const catConfig = activityCategoryConfig[activity.category] || activityCategoryConfig['bem-estar'];
  const CatIcon = catConfig.icon;

  return (
    <motion.div
      layout
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, scale: 0.95 }}
      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
      className={cn(
        'glass rounded-2xl p-4 flex gap-3 items-start transition-all',
        activity.completed && 'opacity-60',
      )}
    >
      <div className='machined flex h-11 w-11 shrink-0 items-center justify-center rounded-xl'>
        <CatIcon className={cn('h-5 w-5', catConfig.tint)} strokeWidth={1.9} />
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2">
          <span className={cn(
            'text-sm font-semibold block',
            activity.completed && 'line-through text-muted-foreground',
          )}>
            {activity.title}
          </span>
          <span className="text-xs text-gold font-semibold shrink-0 flex items-center gap-0.5">
            <Zap className="h-3 w-3" />{activity.xp}
          </span>
        </div>
        <span className="text-xs text-muted-foreground leading-relaxed block mt-0.5">
          {activity.description}
        </span>
        <div className="flex items-center justify-between mt-2.5">
          <span className="text-[10px] uppercase tracking-wider text-muted-foreground">
            {catConfig.label}
          </span>
          {!activity.completed ? (
            <motion.button
              whileTap={{ scale: 0.9 }}
              onClick={onComplete}
              className="flex items-center gap-1 rounded-full bg-surface-strong px-3 py-1 text-xs font-medium text-primary hover:bg-aura hover:text-primary-foreground transition-all"
            >
              <Check className="h-3 w-3" /> Feito
            </motion.button>
          ) : (
            <span className="flex items-center gap-1 text-xs text-primary font-medium">
              <Check className="h-3 w-3" /> Completo!
            </span>
          )}
        </div>
      </div>
    </motion.div>
  );
}

// ============================================================
// DAILY CHALLENGES SECTION
// ============================================================

function DailyChallengesSection() {
  const { profile, dailyActivities, setDailyActivities, completeActivity } = useAura();
  const [showConfetti, setShowConfetti] = useState(false);

  // Generate daily activities on mount / new day
  useEffect(() => {
    const today = todayStr();
    const lastDate = dailyActivities.length > 0 ? dailyActivities[0].date : null;
    if (lastDate !== today) {
      // Smart selection: prioridades do usuário primeiro, depois perfil
      const priorityCategories: string[] = [];
      const userPriorities: string[] = (profile as { priorities?: string[] }).priorities || [];
      for (const p of userPriorities) {
        if (p === 'cabelo' && !priorityCategories.includes('cabelo')) priorityCategories.push('cabelo');
        else if (p === 'pele' && !priorityCategories.includes('pele')) priorityCategories.push('pele');
        else if (p === 'estilo' && !priorityCategories.includes('estilo')) priorityCategories.push('estilo');
        else if ((p === 'rotina' || p === 'corpo') && !priorityCategories.includes('bem-estar')) priorityCategories.push('bem-estar');
        else if (p === 'compras' && !priorityCategories.includes('desafio')) priorityCategories.push('desafio');
      }
      // Fallback pelo perfil estético
      if (profile.skinTypes.length > 0 && !priorityCategories.includes('pele')) priorityCategories.push('pele');
      if (profile.hairType && !priorityCategories.includes('cabelo')) priorityCategories.push('cabelo');
      if (profile.styles.length > 0 && !priorityCategories.includes('estilo')) priorityCategories.push('estilo');
      if (!priorityCategories.includes('bem-estar')) priorityCategories.push('bem-estar');
      if (Math.random() > 0.5 && !priorityCategories.includes('desafio')) priorityCategories.push('desafio');

      const prioritized = [...dailyChallenges].sort((a, b) => {
        const aIdx = priorityCategories.indexOf(a.category);
        const bIdx = priorityCategories.indexOf(b.category);
        return (aIdx === -1 ? 99 : aIdx) - (bIdx === -1 ? 99 : bIdx);
      });

      // Pick 5, at least 1 from top 3 priority categories
      const selected: typeof dailyChallenges = [];
      const usedCategories = new Set<string>();
      const remaining = [...prioritized];

      // First pass: one per priority category
      for (const cat of priorityCategories.slice(0, 3)) {
        const idx = remaining.findIndex((c) => c.category === cat && !usedCategories.has(c.category));
        if (idx >= 0) {
          selected.push(remaining.splice(idx, 1)[0]);
          usedCategories.add(cat);
        }
      }

      // Fill remaining slots randomly
      while (selected.length < 5 && remaining.length > 0) {
        const idx = Math.floor(Math.random() * remaining.length);
        selected.push(remaining.splice(idx, 1)[0]);
      }

      const newActivities: DailyActivity[] = selected.map((ch) => ({
        id: crypto.randomUUID(),
        title: ch.title,
        description: ch.description,
        category: ch.category,
        xp: ch.xp,
        completed: false,
        completedAt: null,
        date: today,
      }));
      setDailyActivities(newActivities);
    }
  }, [profile, dailyActivities, setDailyActivities]);

  const doneCount = dailyActivities.filter((a) => a.completed).length;
  const allDone = doneCount === dailyActivities.length && dailyActivities.length > 0;

  const handleComplete = (id: string) => {
    completeActivity(id);
    // Check if this completes all
    const willBeAllDone = dailyActivities.filter((a) => !a.completed && a.id !== id).length === 0;
    if (willBeAllDone) {
      // Award bonus XP for completing all daily activities
      const { xp } = useAura.getState();
      useAura.setState({ xp: xp + 150 });
      setShowConfetti(true);
      setTimeout(() => setShowConfetti(false), 2500);
    }
  };

  return (
    <section className="mb-8">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
            Desafios de Hoje
          </h2>
          <span className="text-xs text-muted-foreground/70 mt-0.5 block">
            {doneCount}/{dailyActivities.length} completos
          </span>
        </div>
        <div className="flex items-center gap-1.5">
          {allDone && <span className="text-xs text-primary font-semibold">Perfeito!</span>}
          <Star className="h-4 w-4 text-gold" />
        </div>
      </div>

      {/* Progress ring */}
      <div className="flex items-center gap-4 mb-4">
        <div className="relative h-14 w-14 shrink-0">
          <svg className="h-14 w-14 -rotate-90" viewBox="0 0 56 56">
            <circle cx="28" cy="28" r="24" fill="none" stroke="var(--color-surface-strong)" strokeWidth="4" />
            <motion.circle
              cx="28" cy="28" r="24" fill="none" stroke="var(--color-primary)" strokeWidth="4" strokeLinecap="round"
              strokeDasharray={`${2 * Math.PI * 24}`}
              initial={{ strokeDashoffset: 2 * Math.PI * 24 }}
              animate={{ strokeDashoffset: 2 * Math.PI * 24 * (1 - doneCount / Math.max(dailyActivities.length, 1)) }}
              transition={{ type: 'spring', stiffness: 200, damping: 30 }}
            />
          </svg>
          <span className="absolute inset-0 flex items-center justify-center text-xs font-bold">
            {Math.round((doneCount / Math.max(dailyActivities.length, 1)) * 100)}%
          </span>
        </div>
        <div className="flex-1">
          <div className="h-2.5 rounded-full bg-surface-strong overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${(doneCount / Math.max(dailyActivities.length, 1)) * 100}%` }}
              transition={{ type: 'spring', stiffness: 200, damping: 30 }}
              className="h-full rounded-full bg-gradient-to-r from-primary to-primary-glow"
            />
          </div>
        </div>
      </div>

      {/* Activity cards */}
      <div className="flex flex-col gap-3">
        <AnimatePresence>
          {dailyActivities.map((activity) => (
            <ActivityCard
              key={activity.id}
              activity={activity}
              onComplete={() => handleComplete(activity.id)}
            />
          ))}
        </AnimatePresence>
      </div>

      {/* Confetti overlay */}
      <AnimatePresence>
        {showConfetti && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 pointer-events-none flex items-center justify-center"
          >
            <motion.div
              initial={{ scale: 0, rotate: -10 }}
              animate={{ scale: 1, rotate: 0 }}
              exit={{ scale: 0, rotate: 10 }}
              className="glass-deep rounded-3xl p-8 text-center"
            >
              <Trophy className="h-12 w-12 mx-auto mb-3 text-gold" strokeWidth={1.6} />
              <h3 className="font-display text-xl font-light mb-1">Dia perfeito</h3>
              <p className="text-sm text-muted-foreground">
                Todos os desafios concluídos · +150 XP bônus
              </p>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </section>
  );
}

// ============================================================
// WEEKLY GOALS SECTION
// ============================================================

function WeeklyGoalsSection() {
  const { profile, weeklyGoals, setWeeklyGoals, updateWeeklyGoal } = useAura();

  useEffect(() => {
    if (weeklyGoals.length > 0) {
      // Check if goals need refreshing (new week)
      const weekStart = getWeekStart();
      // Simple heuristic: if all completed or first creation
      return;
    }
    // Initialize weekly goals based on profile
    const relevantTemplates = weeklyGoalTemplates
      .filter((t) => {
        if (t.category === 'pele' && profile.skinTypes.length === 0) return Math.random() > 0.5;
        if (t.category === 'cabelo' && !profile.hairType) return Math.random() > 0.5;
        return true;
      })
      .slice(0, 4);

    setWeeklyGoals(relevantTemplates.map((t) => ({
      id: t.id,
      title: t.title,
      target: t.target,
      current: 0,
      unit: t.unit,
      xp: t.xp,
      completed: false,
    })));
  }, [profile, weeklyGoals, setWeeklyGoals]);

  if (weeklyGoals.length === 0) return null;

  return (
    <section className="mb-8">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
            Metas da Semana
          </h2>
          <span className="text-xs text-muted-foreground/70 mt-0.5 block">
            {weeklyGoals.filter((g) => g.completed).length}/{weeklyGoals.length} alcançadas
          </span>
        </div>
        <Target className="h-4 w-4 text-primary" />
      </div>

      <div className="flex flex-col gap-3">
        {weeklyGoals.map((goal) => {
          const progress = goal.target > 0 ? goal.current / goal.target : 0;
          return (
            <motion.div
              key={goal.id}
              layout
              className={cn(
                'glass rounded-2xl p-4 transition-all',
                goal.completed && 'opacity-60',
              )}
            >
              <div className="flex items-start justify-between mb-2">
                <div>
                  <span className={cn(
                    'text-sm font-semibold block',
                    goal.completed && 'line-through text-muted-foreground',
                  )}>
                    {goal.title}
                  </span>
                  <span className="text-xs text-muted-foreground">
                    {goal.current}/{goal.target} {goal.unit}
                  </span>
                </div>
                <span className="text-xs text-gold font-semibold flex items-center gap-0.5">
                  <Zap className="h-3 w-3" />{goal.xp} XP
                </span>
              </div>
              <div className="h-2 rounded-full bg-surface-strong overflow-hidden mb-2">
                <motion.div
                  initial={{ width: 0 }}
                  animate={{ width: `${Math.min(progress * 100, 100)}%` }}
                  transition={{ type: 'spring', stiffness: 200, damping: 30 }}
                  className={cn(
                    'h-full rounded-full transition-colors',
                    goal.completed
                      ? 'bg-green-500'
                      : 'bg-gradient-to-r from-primary to-primary-glow',
                  )}
                />
              </div>
              {!goal.completed && (
                <motion.button
                  whileTap={{ scale: 0.95 }}
                  onClick={() => updateWeeklyGoal(goal.id, 1)}
                  className="text-xs text-primary font-medium flex items-center gap-1 hover:text-foreground transition-colors"
                >
                  <Check className="h-3 w-3" /> Registrar progresso
                </motion.button>
              )}
            </motion.div>
          );
        })}
      </div>
    </section>
  );
}

// ============================================================
// ACHIEVEMENTS SECTION
// ============================================================

function AchievementsSection() {
  const { achievements, initAchievements } = useAura();
  const [showAll, setShowAll] = useState(false);

  useEffect(() => {
    if (achievements.length === 0) {
      initAchievements(achievementDefs.map((a) => ({
        id: a.id,
        title: a.title,
        description: a.description,
        icon: a.icon,
        xp: a.xp,
        unlockedAt: null,
      })));
    }
  }, [achievements, initAchievements]);

  const unlocked = achievements.filter((a) => a.unlockedAt);
  const displayAchievements = showAll ? achievements : achievements.slice(0, 6);

  return (
    <section className="mb-8">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
            Conquistas
          </h2>
          <span className="text-xs text-muted-foreground/70 mt-0.5 block">
            {unlocked.length}/{achievements.length} desbloqueadas
          </span>
        </div>
        <Trophy className="h-4 w-4 text-gold" />
      </div>

      <div className="grid grid-cols-3 gap-2.5">
        {displayAchievements.map((achievement) => {
          const isUnlocked = !!achievement.unlockedAt;
          return (
            <motion.div
              key={achievement.id}
              whileTap={{ scale: 0.95 }}
              className={cn(
                'glass rounded-2xl p-3 text-center transition-all',
                isUnlocked ? 'border-primary/30' : 'opacity-50',
              )}
            >
              <span className="mb-1.5 mx-auto grid h-9 w-9 place-items-center rounded-full machined">
                {isUnlocked ? <AchievementMedal id={achievement.id} title={achievement.title} /> : <Lock className="h-4 w-4 mx-auto text-muted-foreground" />}
              </span>
              <span className="text-[10px] font-semibold block leading-tight">
                {achievement.title}
              </span>
              <span className="text-[9px] text-gold font-medium block mt-0.5">+{achievement.xp} XP</span>
            </motion.div>
          );
        })}
      </div>

      {achievements.length > 6 && (
        <button
          onClick={() => setShowAll(!showAll)}
          className="mt-3 text-xs text-primary font-medium flex items-center gap-1 mx-auto"
        >
          {showAll ? 'Ver menos' : 'Ver todas'}
          <ChevronRight className={cn('h-3 w-3 transition-transform', showAll && 'rotate-90')} />
        </button>
      )}
    </section>
  );
}

// ============================================================
// STATS SECTION
// ============================================================

function StatsSection() {
  const { xp, streak, totalCompletedActivities, closet, achievements } = useAura();
  const { level } = getLevelInfo(xp);
  const unlockedCount = achievements.filter((a) => a.unlockedAt).length;

  const stats = [
    { label: 'Nível', value: level, icon: Gauge, color: 'text-primary' },
    { label: 'XP Total', value: xp, icon: Zap, color: 'text-gold' },
    { label: 'Streak', value: `${streak}d`, icon: Flame, color: 'text-gold' },
    { label: 'Atividades', value: totalCompletedActivities, icon: TrendingUp, color: 'text-green-400' },
    { label: 'Conquistas', value: unlockedCount, icon: Trophy, color: 'text-yellow-400' },
    { label: 'Peças', value: closet.length, icon: Star, color: 'text-accent' },
  ];

  return (
    <section>
      <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-4">
        Suas Estatísticas
      </h2>
      <div className="grid grid-cols-3 gap-2.5">
        {stats.map((stat) => {
          const Icon = stat.icon;
          return (
            <div key={stat.label} className="glass rounded-2xl p-3 text-center">
              <Icon className={cn('h-4 w-4 mx-auto mb-1', stat.color)} />
              <span className="text-base font-bold block">{stat.value}</span>
              <span className="text-[10px] text-muted-foreground uppercase tracking-wider block">
                {stat.label}
              </span>
            </div>
          );
        })}
      </div>
    </section>
  );
}

// ============================================================
// HELPER
// ============================================================

function getWeekStart(): string {
  const now = new Date();
  const day = now.getDay();
  const diff = now.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(now.setDate(diff));
  return monday.toISOString().split('T')[0];
}

// ============================================================
// MAIN SCREEN
// ============================================================

export default function ActivitiesScreen() {
  const { checkAndUpdateStreak } = useAura();

  useEffect(() => {
    checkAndUpdateStreak();
  }, [checkAndUpdateStreak]);

  return (
    <div className="relative z-10 px-4 pt-6 pb-24 max-w-lg mx-auto">
      <motion.div initial={{ y: -20, opacity: 0 }} animate={{ y: 0, opacity: 1 }}>
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold">Atividades</h1>
            <p className="text-sm text-muted-foreground mt-0.5">Desafios, metas e evolução</p>
          </div>
          <div className="flex h-10 w-10 items-center justify-center rounded-xl glass">
            <Gauge className="h-5 w-5 text-primary" strokeWidth={1.8} />
          </div>
        </div>

        <div className="flex flex-col gap-6">
          <LevelBar />
          <DailyChallengesSection />
          <WeeklyGoalsSection />
          <AchievementsSection />
          <StatsSection />
        </div>
      </motion.div>
    </div>
  );
}
