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

type AuraState = {
  profile: Profile;
  onboarded: boolean;
  closet: ClosetItem[];
  favorites: string[];
  routineDone: string[];
  update: (patch: Partial<Profile>) => void;
  toggleIn: (key: 'skinTypes' | 'hairIssues' | 'styles' | 'occasions' | 'colors', value: string, max?: number) => void;
  complete: () => void;
  reset: () => void;
  addClosetItem: (item: ClosetItem) => void;
  removeClosetItem: (id: string) => void;
  toggleFavorite: (id: string) => void;
  toggleRoutine: (id: string) => void;
};

export const useAura = create<AuraState>()(
  persist(
    (set) => ({
      profile: emptyProfile,
      onboarded: false,
      closet: [],
      favorites: [],
      routineDone: [],
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
      reset: () => set({ profile: emptyProfile, onboarded: false, closet: [], favorites: [], routineDone: [] }),
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
    }),
    { name: 'aurastyle-profile' },
  ),
);
