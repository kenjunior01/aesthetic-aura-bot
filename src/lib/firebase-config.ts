/**
 * AuraStyle — Firebase & Google Cloud Configuration
 * 
 * GRATUITO (Free Tier) APIs used:
 * 1. Firebase Authentication — Email/Password + Google Sign-In
 * 2. Cloud Firestore — User profile & data sync across devices
 * 3. Firebase Analytics — Event tracking (user engagement, feature usage)
 * 4. Firebase Cloud Messaging (FCM) — Push notifications for routine reminders
 * 5. Google Cloud Vision API — Skin/hair analysis from selfies (1,000 calls/mo free)
 * 6. Google Places API — Nearby salons/stores (200$/month free credit)
 * 
 * To activate: create a Firebase project at https://console.firebase.google.com
 * and replace the placeholder config below with your real firebaseConfig.
 */

export const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || 'demo-api-key',
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'aurastyle.firebaseapp.com',
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'aurastyle',
  storageBucket: process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET || 'aurastyle.appspot.com',
  messagingSenderId: process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID || '000000000000',
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || '1:000000000000:web:0000000000000000',
};

/**
 * Google Cloud Vision API — for skin/hair analysis from selfies
 * Free tier: 1,000 units/month
 * Enable at: https://console.cloud.google.com/apis/library/vision.googleapis.com
 */
export const VISION_API_KEY = process.env.GOOGLE_VISION_API_KEY || '';

/**
 * Google Places API — for nearby salons/stores
 * Free tier: $200/month credit (~65,000 requests)
 * Enable at: https://console.cloud.google.com/apis/library/places.googleapis.com
 */
export const PLACES_API_KEY = process.env.GOOGLE_PLACES_API_KEY || '';

/**
 * Lovable AI — AI chat integration
 * Replace with your Lovable AI endpoint when ready
 */
export const LOVABLE_AI_ENDPOINT = process.env.LOVABLE_AI_ENDPOINT || '';
export const LOVABLE_AI_API_KEY = process.env.LOVABLE_AI_API_KEY || '';

// Feature flags — toggle integrations on/off
export const FEATURES = {
  firebaseAuth: !!process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  firestoreSync: !!process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  analytics: !!process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  pushNotifications: !!process.env.NEXT_PUBLIC_FIREBASE_API_KEY,
  visionAnalysis: !!process.env.GOOGLE_VISION_API_KEY,
  placesSearch: !!process.env.GOOGLE_PLACES_API_KEY,
  lovableAI: !!process.env.LOVABLE_AI_ENDPOINT,
};

export const FIREBASE_FREE_TIER_LIMITS = {
  auth: { 
    emailPassword: true, 
    googleSignIn: true, 
    maxUsers: 'Unlimited',
  },
  firestore: {
    storage: '1 GB',
    reads: '50,000/day',
    writes: '20,000/day',
    deletes: '20,000/day',
  },
  analytics: {
    events: '500 distinct events',
    users: 'Unlimited',
  },
  fcm: {
    messages: 'Unlimited',
    devices: 'Unlimited',
  },
  vision: {
    calls: '1,000/month free',
  },
  places: {
    credit: '$200/month free',
    requests: '~65,000/month',
  },
};
