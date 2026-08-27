import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { syncProfileToCloud } from './services';
import { FEATURES } from './firebase-config';

export type Profile = {
  name: string;
  email: string;
  phone: string;
  gender: string;
  age: number;
  region: string;
  country: string;
  city: string;
  geoLat: number | null;
  geoLon: number | null;
  priorities: string[];
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
  email: '',
  phone: '',
  gender: '',
  age: 27,
  region: '',
  country: '',
  city: '',
  geoLat: null,
  geoLon: null,
  priorities: [],
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

  // Auth & Referral
  authUid: string | null;
  authEmail: string | null;
  referralCode: string | null;
  referralCount: number;
  referredBy: string | null;
  lastSyncAt: string | null;

  // Notifications
  notificationsEnabled: boolean;
  routineReminders: { id: string; time: string; label: string; enabled: boolean }[];

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

  // Auth & Cloud actions
  setAuth: (uid: string, email: string) => void;
  clearAuth: () => void;
  setReferralCode: (code: string) => void;
  incrementReferralCount: () => void;
  setReferredBy: (code: string) => void;
  syncToCloud: () => Promise<void>;

  // Notification actions
  setNotificationsEnabled: (enabled: boolean) => void;
  addRoutineReminder: (reminder: { id: string; time: string; label: string; enabled: boolean }) => void;
  removeRoutineReminder: (id: string) => void;
  toggleRoutineReminder: (id: string) => void;
};

let syncTimeout: ReturnType<typeof setTimeout> | null = null;

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

      // Auth & Referral defaults
      authUid: null,
      authEmail: null,
      referralCode: null,
      referralCount: 0,
      referredBy: null,
      lastSyncAt: null,

      // Notifications defaults
      notificationsEnabled: false,
      routineReminders: [],

      update: (patch) => set((s) => ({ profile: { ...s.profile, ...patch } })),
      toggleIn: (key, value, max) =>
        set((s) => {
          const current = s.profile[key] as string[];
          const has = current.includes(value);
          let next = has ? current.filter((v) => v !== value) : [...current, value];
          if (!has && max && next.length > max) next = next.slice(next.length - max);
          return { profile: { ...s.profile, [key]: next } };
        }),
      complete: () => set((s) => ({
        onboarded: true,
        xp: s.xp + 100,
      })),
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
        authUid: null,
        authEmail: null,
        referralCode: null,
        referralCount: 0,
        referredBy: null,
        lastSyncAt: null,
        notificationsEnabled: false,
        routineReminders: [],
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

        const dailyLoginXp = 5;
        const yesterday = new Date();
        yesterday.setDate(yesterday.getDate() - 1);
        const yesterdayStr = yesterday.toISOString().split('T')[0];

        const newStreak = state.lastActiveDate === yesterdayStr
          ? state.streak + 1
          : 1;

        set({
          xp: state.xp + dailyLoginXp,
          streak: newStreak,
          lastActiveDate: todayStr,
        });
      },

      // Auth & Cloud actions
      setAuth: (uid, email) => set({ authUid: uid, authEmail: email }),
      clearAuth: () => set({ authUid: null, authEmail: null }),
      setReferralCode: (code) => set({ referralCode: code }),
      incrementReferralCount: () => set((s) => ({ referralCount: s.referralCount + 1 })),
      setReferredBy: (code) => set({ referredBy: code }),

      syncToCloud: async () => {
        const state = get();
        if (!state.authUid) return;

        try {
          const dataToSync = {
            profile: state.profile,
            xp: state.xp,
            streak: state.streak,
            totalCompletedActivities: state.totalCompletedActivities,
            achievements: state.achievements,
            referralCode: state.referralCode,
            referralCount: state.referralCount,
            closetCount: state.closet.length,
          };

          await syncProfileToCloud(state.authUid, dataToSync);
          set({ lastSyncAt: new Date().toISOString() });
        } catch (err) {
          console.error('Cloud sync failed:', err);
        }
      },

      // Notification actions
      setNotificationsEnabled: (enabled) => set({ notificationsEnabled: enabled }),
      addRoutineReminder: (reminder) => set((s) => ({
        routineReminders: [...s.routineReminders, reminder],
      })),
      removeRoutineReminder: (id) => set((s) => ({
        routineReminders: s.routineReminders.filter((r) => r.id !== id),
      })),
      toggleRoutineReminder: (id) => set((s) => ({
        routineReminders: s.routineReminders.map((r) =>
          r.id === id ? { ...r, enabled: !r.enabled } : r
        ),
      })),
    }),
    {
      name: 'aurastyle-profile',
      // Auto-sync to cloud on state changes (debounced)
      partialize: (state) => state,
      // After rehydration, trigger cloud sync
      onRehydrateStorage: () => (state) => {
        if (state && FEATURES.firestoreSync && state.authUid) {
          // Trigger sync after 2 seconds to avoid blocking UI
          setTimeout(() => {
            state.syncToCloud();
          }, 2000);
        }
      },
    },
  ),
);

// Debounced auto-sync hook
export function useAutoSync() {
  const { syncToCloud, authUid } = useAura();

  // This is called by components on important state changes
  const triggerSync = () => {
    if (!authUid) return;
    if (syncTimeout) clearTimeout(syncTimeout);
    syncTimeout = setTimeout(() => {
      syncToCloud();
    }, 5000);
  };

  return { triggerSync };
}
