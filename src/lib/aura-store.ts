import { create } from 'zustand';
import { persist } from 'zustand/middleware';

export type Profile = {
  name: string;
  gender: string;
  age: number;
  region: string;
  selfie: string | null;
  faceShape: string;
  skinTone: number;
  undertone: string;
  eyeColor: string;
  skinTypes: string[];
  hairType: string;
  hairColor: string;
  hairLength: string;
  hairThickness: string;
  hairIssues: string[];
  bodyType: string;
  height: number;
  heightUnit: 'cm' | 'ft';
  weight: number;
  styles: string[];
  occasions: string[];
  budget: string;
  colors: string[];
  references: string[];
  activity: number;
  profession: string;
  climate: string;
  notes: string;
};

export type ClosetItem = {
  id: string;
  name: string;
  category: string;
  color: string;
  photo: string | null;
};

export type DailyActivity = {
  id: string;
  title: string;
  description: string;
  category: 'pele' | 'cabelo' | 'estilo' | 'bem-estar' | 'desafio';
  xp: number;
  completed: boolean;
  completedAt: string | null;
  date: string;
};

export type WeeklyGoal = {
  id: string;
  title: string;
  target: number;
  current: number;
  unit: string;
  xp: number;
  completed: boolean;
};

export type Achievement = {
  id: string;
  title: string;
  description: string;
  icon: string;
  unlockedAt: string | null;
  xp: number;
};

export const emptyProfile: Profile = {
  name: '',
  gender: '',
  age: 27,
  region: '',
  selfie: null,
  faceShape: '',
  skinTone: 5,
  undertone: '',
  eyeColor: '',
  skinTypes: [],
  hairType: '',
  hairColor: '',
  hairLength: '',
  hairThickness: '',
  hairIssues: [],
  bodyType: '',
  height: 170,
  heightUnit: 'cm',
  weight: 68,
  styles: [],
  occasions: [],
  budget: '',
  colors: [],
  references: [],
  activity: 2,
  profession: '',
  climate: '',
  notes: '',
};

export function calculateLevel(xp: number): number {
  return Math.floor(Math.sqrt(xp / 50)) + 1;
}

export function xpForLevel(level: number): number {
  return (level - 1) * (level - 1) * 50;
}

export function xpForNextLevel(level: number): number {
  return level * level * 50;
}

export function getLevelInfo(xp: number) {
  const level = calculateLevel(xp);
  const currentLevelXp = xpForLevel(level);
  const nextLevelXp = xpForNextLevel(level);
  const currentXp = xp - currentLevelXp;
  const xpNeeded = nextLevelXp - currentLevelXp;
  const progress = xpNeeded > 0 ? currentXp / xpNeeded : 1;
  return { level, currentXp, xpNeeded, progress };
}

type AuraState = {
  profile: Profile;
  onboarded: boolean;
  closet: ClosetItem[];
  favorites: string[];
  routineDone: string[];

  // Gamification
  xp: number;
  streak: number;
  lastActiveDate: string | null;
  dailyActivities: DailyActivity[];
  weeklyGoals: WeeklyGoal[];
  achievements: Achievement[];
  totalCompletedActivities: number;

  // Actions
  update: (patch: Partial<Profile>) => void;
  toggleIn: (key: 'skinTypes' | 'hairIssues' | 'styles' | 'occasions' | 'colors', value: string, max?: number) => void;
  complete: () => void;
  reset: () => void;
  addClosetItem: (item: ClosetItem) => void;
  removeClosetItem: (id: string) => void;
  toggleFavorite: (id: string) => void;
  toggleRoutine: (id: string) => void;

  // Gamification actions
  setDailyActivities: (activities: DailyActivity[]) => void;
  completeActivity: (id: string) => void;
  setWeeklyGoals: (goals: WeeklyGoal[]) => void;
  updateWeeklyGoal: (id: string, increment: number) => void;
  initAchievements: (achievements: Achievement[]) => void;
  unlockAchievement: (id: string) => void;
  checkAndUpdateStreak: () => void;
};

export const useAura = create<AuraState>()(
  persist(
    (set, get) => ({
      profile: emptyProfile,
      onboarded: false,
      closet: [],
      favorites: [],
      routineDone: [],

      // Gamification defaults
      xp: 0,
      streak: 0,
      lastActiveDate: null,
      dailyActivities: [],
      weeklyGoals: [],
      achievements: [],
      totalCompletedActivities: 0,

      update: (patch) => set((s) => ({ profile: { ...s.profile, ...patch } })),
      toggleIn: (key, value, max) =>
        set((s) => {
          const current = s.profile[key] as string[];
          const has = current.includes(value);
          let next = has ? current.filter((v) => v !== value) : [...current, value];
          if (!has && max && next.length > max) next = next.slice(next.length - max);
          return { profile: { ...s.profile, [key]: next } };
        }),
      complete: () => set({ onboarded: true }),
      reset: () => set({
        profile: emptyProfile,
        onboarded: false,
        closet: [],
        favorites: [],
        routineDone: [],
        xp: 0,
        streak: 0,
        lastActiveDate: null,
        dailyActivities: [],
        weeklyGoals: [],
        achievements: [],
        totalCompletedActivities: 0,
      }),
      addClosetItem: (item) => set((s) => ({ closet: [item, ...s.closet] })),
      removeClosetItem: (id) => set((s) => ({ closet: s.closet.filter((i) => i.id !== id) })),
      toggleFavorite: (id) =>
        set((s) => ({
          favorites: s.favorites.includes(id)
            ? s.favorites.filter((f) => f !== id)
            : [...s.favorites, id],
        })),
      toggleRoutine: (id) =>
        set((s) => ({
          routineDone: s.routineDone.includes(id)
            ? s.routineDone.filter((f) => f !== id)
            : [...s.routineDone, id],
        })),

      // Gamification actions
      setDailyActivities: (activities) => set({ dailyActivities: activities }),

      completeActivity: (id) =>
        set((s) => {
          const activity = s.dailyActivities.find((a) => a.id === id);
          if (!activity || activity.completed) return s;
          const newXp = s.xp + activity.xp;
          return {
            xp: newXp,
            totalCompletedActivities: s.totalCompletedActivities + 1,
            dailyActivities: s.dailyActivities.map((a) =>
              a.id === id
                ? { ...a, completed: true, completedAt: new Date().toISOString() }
                : a,
            ),
          };
        }),

      setWeeklyGoals: (goals) => set({ weeklyGoals: goals }),

      updateWeeklyGoal: (id, increment) =>
        set((s) => {
          const goal = s.weeklyGoals.find((g) => g.id === id);
          if (!goal || goal.completed) return s;
          const newCurrent = Math.min(goal.current + increment, goal.target);
          const completed = newCurrent >= goal.target;
          const newXp = completed ? s.xp + goal.xp : s.xp;
          return {
            xp: newXp,
            weeklyGoals: s.weeklyGoals.map((g) =>
              g.id === id
                ? { ...g, current: newCurrent, completed }
                : g,
            ),
          };
        }),

      initAchievements: (achievements) => set((s) => {
        // Merge: keep existing unlocked state, add new ones
        const existingMap = new Map(s.achievements.map((a) => [a.id, a]));
        const merged = achievements.map((a) => {
          const existing = existingMap.get(a.id);
          return existing ? { ...a, unlockedAt: existing.unlockedAt } : a;
        });
        return { achievements: merged };
      }),

      unlockAchievement: (id) =>
        set((s) => {
          const achievement = s.achievements.find((a) => a.id === id);
          if (!achievement || achievement.unlockedAt) return s;
          return {
            xp: s.xp + (achievement.xp || 0),
            achievements: s.achievements.map((a) =>
              a.id === id ? { ...a, unlockedAt: new Date().toISOString() } : a,
            ),
          };
        }),

      checkAndUpdateStreak: () => {
        const state = get();
        const todayStr = new Date().toISOString().split('T')[0];
        if (state.lastActiveDate === todayStr) return;

        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = yesterday.toISOString().split('T')[0];

        const newStreak = state.lastActiveDate === yesterdayStr
          ? state.streak + 1
          : 1;

        set({
          streak: newStreak,
          lastActiveDate: todayStr,
        });
      },
    }),
    { name: 'aurastyle-profile' },
  ),
);
