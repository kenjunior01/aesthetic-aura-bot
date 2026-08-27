/**
 * AuraStyle — Service Layer for Google Cloud / Firebase APIs
 * 
 * All services are designed to work in DEMO MODE without real API keys.
 * When you add real Firebase/Google Cloud credentials, they activate automatically.
 * 
 * API keys needed (all FREE):
 * - Firebase project config (auto-generated, free)
 * - Google Cloud Vision API key (for skin/hair photo analysis)
 * - Google Places API key (for nearby salons/stores)
 */

import { firebaseConfig, FEATURES, VISION_API_KEY, PLACES_API_KEY, LOVABLE_AI_ENDPOINT, LOVABLE_AI_API_KEY } from './firebase-config';
import type { Profile } from './aura-store';

// ============================================================
// 1. AUTH SERVICE (Firebase Auth — free, unlimited)
// ============================================================

export type AuthUser = {
  uid: string;
  email: string;
  displayName: string;
  photoURL?: string;
  createdAt: string;
};

export type AuthState = {
  user: AuthUser | null;
  loading: boolean;
  error: string | null;
};

/**
 * Demo auth — stores in localStorage.
 * Replace with Firebase Auth when credentials are configured.
 */
const AUTH_KEY = 'aurastyle-auth';

export async function signInWithGoogle(): Promise<AuthUser> {
  // Try Firebase Google Sign-In
  try {
    if (FEATURES.firebaseAuth && typeof window !== 'undefined') {
      const { GoogleAuthProvider, signInWithPopup, getAdditionalUserInfo } = await import(/* webpackIgnore: true */ 'firebase/auth');
      const { auth } = await initFirebase();
      const provider = new GoogleAuthProvider();
      provider.addScope('profile');
      provider.addScope('email');
      const cred = await signInWithPopup(auth, provider);
      const info = getAdditionalUserInfo(cred);
      const isNewUser = info?.isNewUser || false;
      const user: AuthUser = {
        uid: cred.user.uid,
        email: cred.user.email || '',
        displayName: cred.user.displayName || '',
        photoURL: cred.user.photoURL || undefined,
        createdAt: cred.user.metadata.creationTime || new Date().toISOString(),
      };
      localStorage.setItem(AUTH_KEY, JSON.stringify(user));
      if (isNewUser) {
        logEvent('signup_google', { uid: user.uid });
      } else {
        logEvent('login_google', { uid: user.uid });
      }
      return user;
    }
  } catch (err: any) {
    // Firebase popup might be blocked or cancelled
    if (err?.code === 'auth/popup-closed-by-user') {
      throw new Error('Login cancelado pelo usuário');
    }
    if (err?.code === 'auth/popup-blocked') {
      throw new Error('Pop-up bloqueado pelo navegador. Permita pop-ups para este site.');
    }
    // Firebase not available, fall through to demo
  }

  // Demo mode — simulate Google login
  await new Promise((r) => setTimeout(r, 800));
  const demoName = 'Usuário Google';
  const user: AuthUser = {
    uid: crypto.randomUUID(),
    email: `google_${Date.now()}@demo.aurastyle.app`,
    displayName: demoName,
    photoURL: undefined,
    createdAt: new Date().toISOString(),
  };
  localStorage.setItem(AUTH_KEY, JSON.stringify(user));
  logEvent('signup_google_demo');
  return user;
}

export async function resetPassword(email: string): Promise<boolean> {
  try {
    if (FEATURES.firebaseAuth && typeof window !== 'undefined') {
      const { sendPasswordResetEmail } = await import(/* webpackIgnore: true */ 'firebase/auth');
      const { auth } = await initFirebase();
      await sendPasswordResetEmail(auth, email);
      return true;
    }
  } catch {
    // Firebase not available
  }
  // Demo: always succeeds
  return true;
}

export function getStoredAuth(): AuthUser | null {
  if (typeof window === 'undefined') return null;
  try {
    const raw = localStorage.getItem(AUTH_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export async function signUpWithEmail(email: string, password: string, name: string): Promise<AuthUser> {
  // Try Firebase Auth first (if module available and configured)
  try {
    if (FEATURES.firebaseAuth && typeof window !== 'undefined') {
      const { createUserWithEmailAndPassword, updateProfile } = await import(/* webpackIgnore: true */ 'firebase/auth');
      const { getAuth, app } = await initFirebase();
      const cred = await createUserWithEmailAndPassword(getAuth(app), email, password);
      await updateProfile(cred.user, { displayName: name });
      const user: AuthUser = {
        uid: cred.user.uid,
        email: cred.user.email || email,
        displayName: name,
        photoURL: cred.user.photoURL || undefined,
        createdAt: new Date().toISOString(),
      };
      localStorage.setItem(AUTH_KEY, JSON.stringify(user));
      return user;
    }
  } catch {
    // Firebase not available, fall through to demo mode
  }

  // Demo mode — local storage auth
  const existingUsers = JSON.parse(localStorage.getItem('aurastyle-users') || '[]');
  if (existingUsers.find((u: any) => u.email === email)) {
    throw new Error('Este email já está cadastrado');
  }

  const user: AuthUser = {
    uid: crypto.randomUUID(),
    email,
    displayName: name,
    createdAt: new Date().toISOString(),
  };
  existingUsers.push({ ...user, password });
  localStorage.setItem('aurastyle-users', JSON.stringify(existingUsers));
  localStorage.setItem(AUTH_KEY, JSON.stringify(user));
  return user;
}

export async function signInWithEmail(email: string, password: string): Promise<AuthUser> {
  try {
    if (FEATURES.firebaseAuth && typeof window !== 'undefined') {
      const { signInWithEmailAndPassword } = await import(/* webpackIgnore: true */ 'firebase/auth');
      const { getAuth, app } = await initFirebase();
      const cred = await signInWithEmailAndPassword(getAuth(app), email, password);
      const user: AuthUser = {
        uid: cred.user.uid,
        email: cred.user.email || email,
        displayName: cred.user.displayName || '',
        photoURL: cred.user.photoURL || undefined,
        createdAt: cred.user.metadata.creationTime || new Date().toISOString(),
      };
      localStorage.setItem(AUTH_KEY, JSON.stringify(user));
      return user;
    }
  } catch {
    // Firebase not available
  }

  // Demo mode
  const existingUsers = JSON.parse(localStorage.getItem('aurastyle-users') || '[]');
  const found = existingUsers.find((u: any) => u.email === email && u.password === password);
  if (!found) throw new Error('Email ou senha incorretos');
  const { password: _, ...user } = found;
  localStorage.setItem(AUTH_KEY, JSON.stringify(user));
  return user;
}

export async function signOut(): Promise<void> {
  try {
    if (FEATURES.firebaseAuth && typeof window !== 'undefined') {
      const { getAuth, signOut: fbSignOut, app } = await initFirebase();
      await fbSignOut(getAuth(app));
    }
  } catch {
    // Firebase not available
  }
  localStorage.removeItem(AUTH_KEY);
}

export function getCurrentUser(): AuthUser | null {
  return getStoredAuth();
}

// ============================================================
// 2. FIRESTORE SYNC SERVICE (free: 1GB + 50k reads/day)
// ============================================================

let firebaseApp: any = null;
let firebaseAuth: any = null;

async function initFirebase() {
  if (firebaseApp) return { app: firebaseApp, auth: firebaseAuth };
  // Dynamic import with webpackIgnore — resolved at runtime only
  const fbApp = await import(/* webpackIgnore: true */ 'firebase/app');
  const fbAuth = await import(/* webpackIgnore: true */ 'firebase/auth');
  firebaseApp = fbApp.initializeApp(firebaseConfig);
  firebaseAuth = fbAuth.getAuth(firebaseApp);
  return { app: firebaseApp, auth: firebaseAuth };
}

export async function syncProfileToCloud(uid: string, data: any): Promise<void> {
  try {
    if (FEATURES.firestoreSync && typeof window !== 'undefined') {
      const { getFirestore, doc, setDoc } = await import(/* webpackIgnore: true */ 'firebase/firestore');
      const { app } = await initFirebase();
      const db = getFirestore(app);
      await setDoc(doc(db, 'users', uid), {
        ...data,
        updatedAt: new Date().toISOString(),
        syncedAt: new Date().toISOString(),
      }, { merge: true });
      return;
    }
  } catch {
    // Firebase not available
  }
  // Demo: store in localStorage with timestamp
  localStorage.setItem(`aurastyle-sync-${uid}`, JSON.stringify({
    ...data,
    syncedAt: new Date().toISOString(),
  }));
}

export async function loadProfileFromCloud(uid: string): Promise<any | null> {
  try {
    if (FEATURES.firestoreSync && typeof window !== 'undefined') {
      const { getFirestore, doc, getDoc } = await import(/* webpackIgnore: true */ 'firebase/firestore');
      const { app } = await initFirebase();
      const db = getFirestore(app);
      const snap = await getDoc(doc(db, 'users', uid));
      return snap.exists() ? snap.data() : null;
    }
  } catch {
    // Firebase not available
  }
  // Demo mode
  const raw = localStorage.getItem(`aurastyle-sync-${uid}`);
  return raw ? JSON.parse(raw) : null;
}

// ============================================================
// 3. ANALYTICS (Firebase Analytics — free, unlimited)
// ============================================================

export function logEvent(eventName: string, params?: Record<string, any>): void {
 // Analytics — only runs client-side when Firebase SDK is available
  if (typeof window !== 'undefined' && FEATURES.analytics) {
    import(/* webpackIgnore: true */ 'firebase/analytics').then(({ getAnalytics, logEvent: fbLogEvent }) => {
      return initFirebase().then(({ app }) => {
        const analytics = getAnalytics(app);
        fbLogEvent(analytics, eventName, params);
      });
    }).catch(() => { /* Firebase not installed */ });
  }
}

// ============================================================
// 4. GOOGLE CLOUD VISION — Skin/Hair Analysis (1,000/mo free)
// ============================================================

export type VisionAnalysisResult = {
  skinTone: number;
  skinType: string;
  dominantColors: string[];
  faceShape: string;
  hairColor: string;
  confidence: number;
};

export async function analyzeSelfie(imageBase64: string): Promise<VisionAnalysisResult> {
  if (FEATURES.visionAnalysis && VISION_API_KEY) {
    const response = await fetch(
      `https://vision.googleapis.com/v1/images:annotate?key=${VISION_API_KEY}`,
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          requests: [{
            image: { content: imageBase64.split(',')[1] || imageBase64 },
            features: [
              { type: 'FACE_DETECTION', maxResults: 5 },
              { type: 'IMAGE_PROPERTIES', maxResults: 5 },
              { type: 'LABEL_DETECTION', maxResults: 20 },
              { type: 'OBJECT_LOCALIZATION', maxResults: 10 },
            ],
          }],
        }),
      }
    );
    const data = await response.json();
    return parseVisionResponse(data);
  }

  // Demo mode — simulate analysis
  await new Promise((r) => setTimeout(r, 1500 + Math.random() * 1000));
  return {
    skinTone: Math.floor(Math.random() * 8) + 3,
    skinType: ['oleosa', 'mista', 'seca', 'normal'][Math.floor(Math.random() * 4)],
    dominantColors: ['warm', 'neutral', 'cool'].sort(() => Math.random() - 0.5).slice(0, 2),
    faceShape: ['oval', 'redondo', 'quadrado', 'retangular'][Math.floor(Math.random() * 4)],
    hairColor: ['castanho-escuro', 'preto', 'loiro-claro', 'ruivo'][Math.floor(Math.random() * 4)],
    confidence: 0.82 + Math.random() * 0.15,
  };
}

function parseVisionResponse(data: any): VisionAnalysisResult {
  const annotations = data.responses?.[0];
  if (!annotations) throw new Error('Não foi possível analisar a imagem');

  const faces = annotations.faceAnnotations || [];
  const props = annotations.imagePropertiesAnnotation || {};
  const labels = annotations.labelAnnotations || [];

  // Extract dominant colors
  const colors = (props.dominantColors || []).map((c: any) => c.color || {});

  return {
    skinTone: 5, // Will be calculated from color analysis
    skinType: 'mista',
    dominantColors: colors.slice(0, 3).map((c: any) => `${c.red},${c.green},${c.blue}`),
    faceShape: 'oval',
    hairColor: 'castanho-escuro',
    confidence: faces[0]?.detectionConfidence || 0.5,
  };
}

// ============================================================
// 5. GOOGLE PLACES — Nearby Salons/Stores ($200/mo free credit)
// ============================================================

export type NearbyPlace = {
  id: string;
  name: string;
  address: string;
  rating: number;
  totalRatings: number;
  types: string[];
  openNow: boolean;
  distance: string;
  photoUrl?: string;
  priceLevel?: number;
};

export async function searchNearbySalons(lat: number, lng: number, radius: number = 5000): Promise<NearbyPlace[]> {
  if (FEATURES.placesSearch && PLACES_API_KEY) {
    const response = await fetch(
      `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=${radius}&type=beauty_salon|hair_care|spa|shopping_mall&key=${PLACES_API_KEY}&language=pt-BR`
    );
    const data = await response.json();
    return (data.results || []).map((place: any) => ({
      id: place.place_id,
      name: place.name,
      address: place.vicinity || '',
      rating: place.rating || 0,
      totalRatings: place.user_ratings_total || 0,
      types: place.types || [],
      openNow: place.opening_hours?.open_now ?? true,
      distance: `${Math.round(place.geometry?.location ? 0 : 0)}m`,
      photoUrl: place.photos?.[0]
        ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${place.photos[0].photo_reference}&key=${PLACES_API_KEY}`
        : undefined,
      priceLevel: place.price_level,
    }));
  }

  // Demo data
  await new Promise((r) => setTimeout(r, 800));
  return generateDemoPlaces(lat, lng);
}

function generateDemoPlaces(lat: number, lng: number): NearbyPlace[] {
  const salons = [
    { name: 'Studio Bella', types: ['beauty_salon'], rating: 4.8, totalRatings: 234, priceLevel: 2 },
    { name: 'Espaço Cabelo & Estilo', types: ['hair_care'], rating: 4.6, totalRatings: 189, priceLevel: 1 },
    { name: 'Natura Spa', types: ['spa'], rating: 4.9, totalRatings: 312, priceLevel: 3 },
    { name: 'Shopping Center', types: ['shopping_mall'], rating: 4.3, totalRatings: 1567, priceLevel: 2 },
    { name: 'Barbearia Premium', types: ['beauty_salon'], rating: 4.7, totalRatings: 98, priceLevel: 1 },
  ];
  return salons.map((s, i) => ({
    id: `demo-${i}`,
    name: s.name,
    address: `Rua ${['Das Flores', 'Augusta', 'Paulista', 'Consolação', 'Oscar Freire'][i]}, ${Math.floor(Math.random() * 500) + 100}`,
    rating: s.rating,
    totalRatings: s.totalRatings,
    types: s.types,
    openNow: Math.random() > 0.3,
    distance: `${(Math.random() * 3 + 0.5).toFixed(1)} km`,
    priceLevel: s.priceLevel,
  }));
}

// ============================================================
// 6. LOVABLE AI CHAT INTEGRATION
// ============================================================

export async function sendToLovableAI(message: string, profile: Profile, history: { role: string; content: string }[]): Promise<string> {
  if (FEATURES.lovableAI && LOVABLE_AI_ENDPOINT) {
    const response = await fetch(LOVABLE_AI_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${LOVABLE_AI_API_KEY}`,
      },
      body: JSON.stringify({
        messages: [
          { role: 'system', content: `Você é o AuraStyle AI, um assistente de estética pessoal. Dados do usuário: nome=${profile.name}, cabelo=${profile.hairType}, pele=${profile.skinTypes.join(',')}, região=${profile.region}, orçamento=${profile.budget}. Responda em português de forma amigável e personalizada.` },
          ...history,
          { role: 'user', content: message },
        ],
        max_tokens: 500,
      }),
    });
    const data = await response.json();
    return data.choices?.[0]?.message?.content || data.content || data.reply || 'Desculpe, não consegui processar sua mensagem.';
  }

  // Fallback to local contextual responses
  return null; // Caller should use local fallback
}

// ============================================================
// 7. PUSH NOTIFICATION SERVICE (FCM — free, unlimited)
// ============================================================

export async function requestNotificationPermission(): Promise<boolean> {
  if (!('Notification' in window)) return false;
  const permission = await Notification.requestPermission();
  return permission === 'granted';
}

export async function scheduleRoutineReminder(time: string, label: string): Promise<void> {
  if (FEATURES.pushNotifications) {
    // With real FCM, this would send a scheduled push notification
    // via Firebase Cloud Functions
    console.log(`[FCM] Scheduling reminder: ${label} at ${time}`);
  }
  // Demo: use browser Notification API
  if ('Notification' in window && Notification.permission === 'granted') {
    const [hours, minutes] = time.split(':').map(Number);
    const now = new Date();
    const target = new Date(now);
    target.setHours(hours, minutes, 0, 0);
    if (target <= now) target.setDate(target.getDate() + 1);
    const delay = target.getTime() - now.getTime();
    setTimeout(() => {
      new Notification('AuraStyle - Lembrete', {
        body: `Hora do seu cuidado: ${label}`,
        icon: '✨',
        tag: `routine-${time}`,
      });
    }, delay);
  }
}

// ============================================================
// 8. REFERRAL / VIRAL SYSTEM
// ============================================================

export function generateReferralCode(uid: string, name: string): string {
  const clean = name.toLowerCase().replace(/[^a-z]/g, '').slice(0, 6);
  const short = uid.slice(0, 4);
  return `${clean}-${short}`;
}

export function getReferralLink(referralCode: string): string {
  const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'https://aurastyle.app';
  return `${baseUrl}?ref=${referralCode}`;
}

export function getReferrerFromURL(): string | null {
  if (typeof window === 'undefined') return null;
  const params = new URLSearchParams(window.location.search);
  return params.get('ref');
}

// ============================================================
// 9. DATA EXPORT / IMPORT (offline backup & restore)
// ============================================================

export type ExportData = {
  version: string;
  exportedAt: string;
  profile: Record<string, any>;
  gamification: {
    xp: number;
    streak: number;
    totalCompletedActivities: number;
    achievements: any[];
  };
  closet: any[];
  favorites: string[];
  routineDone: string[];
  referralCode: string | null;
};

export function exportAllData(state: Record<string, any>): string {
  const data: ExportData = {
    version: '1.0.0',
    exportedAt: new Date().toISOString(),
    profile: state.profile || {},
    gamification: {
      xp: state.xp || 0,
      streak: state.streak || 0,
      totalCompletedActivities: state.totalCompletedActivities || 0,
      achievements: state.achievements || [],
    },
    closet: state.closet || [],
    favorites: state.favorites || [],
    routineDone: state.routineDone || [],
    referralCode: state.referralCode || null,
  };
  return JSON.stringify(data, null, 2);
}

export function importData(jsonString: string): ExportData | null {
  try {
    const data = JSON.parse(jsonString);
    if (!data.version || !data.profile) return null;
    return data as ExportData;
  } catch {
    return null;
  }
}

export function downloadJSON(content: string, filename: string): void {
  const blob = new Blob([content], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// ============================================================
// 10. FULL PROFILE SYNC (onboarding complete → cloud)
// ============================================================

export async function syncFullProfileOnComplete(uid: string, state: Record<string, any>): Promise<void> {
  const fullData = {
    profile: state.profile || {},
    xp: state.xp || 0,
    streak: state.streak || 0,
    totalCompletedActivities: state.totalCompletedActivities || 0,
    achievements: state.achievements || [],
    weeklyGoals: state.weeklyGoals || [],
    dailyActivities: state.dailyActivities || [],
    referralCode: state.referralCode || null,
    referralCount: state.referralCount || 0,
    referredBy: state.referredBy || null,
    closetCount: (state.closet || []).length,
    favoritesCount: (state.favorites || []).length,
    onboarded: true,
  };
  await syncProfileToCloud(uid, fullData);
}

export async function loadFullProfileFromCloud(uid: string): Promise<Record<string, any> | null> {
  return loadProfileFromCloud(uid);
}