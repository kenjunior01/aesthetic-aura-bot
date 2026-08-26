'use client';

import { useEffect, useRef } from 'react';
import { useAura, calculateLevel } from '@/lib/aura-store';

/**
 * Auto-unlock achievements based on current state.
 * Call this in the DashboardScreen (or any top-level component).
 */
export function useAchievements() {
  const state = useAura();
  const prevRef = useRef({
    xp: 0,
    streak: 0,
    totalCompletedActivities: 0,
    closet: 0,
    achievements: state.achievements,
    routineDone: state.routineDone,
    dailyActivities: state.dailyActivities,
    weeklyGoals: state.weeklyGoals,
  });

  useEffect(() => {
    const prev = prevRef.current;
    const s = state;
    const toUnlock: string[] = [];

    // primeira-atividade: Complete first activity
    if (s.totalCompletedActivities >= 1 && prev.totalCompletedActivities < 1) {
      toUnlock.push('primeira-atividade');
    }

    // streak-3
    if (s.streak >= 3 && prev.streak < 3) toUnlock.push('streak-3');
    // streak-7
    if (s.streak >= 7 && prev.streak < 7) toUnlock.push('streak-7');
    // streak-30
    if (s.streak >= 30 && prev.streak < 30) toUnlock.push('streak-30');

    // 10-atividades
    if (s.totalCompletedActivities >= 10 && prev.totalCompletedActivities < 10) toUnlock.push('10-atividades');
    // 50-atividades
    if (s.totalCompletedActivities >= 50 && prev.totalCompletedActivities < 50) toUnlock.push('50-atividades');
    // 100-atividades
    if (s.totalCompletedActivities >= 100 && prev.totalCompletedActivities < 100) toUnlock.push('100-atividades');

    // armario-10
    if (s.closet.length >= 10 && prev.closet < 10) toUnlock.push('armario-10');
    // armario-30
    if (s.closet.length >= 30 && prev.closet < 30) toUnlock.push('armario-30');

    // todos-dias: all daily activities completed
    if (s.dailyActivities.length > 0) {
      const allDone = s.dailyActivities.every((a) => a.completed);
      const prevAllDone = prev.dailyActivities.length > 0 && prev.dailyActivities.every((a) => a.completed);
      if (allDone && !prevAllDone) toUnlock.push('todos-dias');
    }

    // meta-semanal: any weekly goal completed
    if (s.weeklyGoals.some((g) => g.completed) && !prev.weeklyGoals.some((g) => g.completed)) {
      toUnlock.push('meta-semanal');
    }
    // todas-metas: all weekly goals completed
    if (s.weeklyGoals.length > 0 && s.weeklyGoals.every((g) => g.completed) && !prev.weeklyGoals.every((g) => g.completed)) {
      toUnlock.push('todas-metas');
    }

    // level-5, level-10, level-25
    const level = calculateLevel(s.xp);
    if (level >= 5 && calculateLevel(prev.xp) < 5) toUnlock.push('level-5');
    if (level >= 10 && calculateLevel(prev.xp) < 10) toUnlock.push('level-10');
    if (level >= 25 && calculateLevel(prev.xp) < 25) toUnlock.push('level-25');

    // Unlock all detected
    for (const id of toUnlock) {
      s.unlockAchievement(id);
    }

    // Update ref
    prevRef.current = {
      xp: s.xp,
      streak: s.streak,
      totalCompletedActivities: s.totalCompletedActivities,
      closet: s.closet.length,
      achievements: s.achievements,
      routineDone: s.routineDone,
      dailyActivities: s.dailyActivities,
      weeklyGoals: s.weeklyGoals,
    };
  }, [
    state.xp, state.streak, state.totalCompletedActivities,
    state.closet.length, state.achievements, state.dailyActivities,
    state.weeklyGoals, state.unlockAchievement,
  ]);
}
