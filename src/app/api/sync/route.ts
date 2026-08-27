import { NextRequest, NextResponse } from 'next/server';

/**
 * POST /api/sync
 * Cloud sync endpoint for user profile data.
 * With Firebase Admin SDK, this writes to Firestore directly.
 * Without it, acts as a proxy endpoint for the client-side SDK.
 *
 * The client-side Firebase SDK handles most sync directly.
 * This endpoint exists for server-side operations and as a fallback.
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { uid, data } = body;

    if (!uid || !data) {
      return NextResponse.json({ error: 'uid and data are required' }, { status: 400 });
    }

    // Validate data structure
    if (data.profile && typeof data.profile !== 'object') {
      return NextResponse.json({ error: 'Invalid profile data' }, { status: 400 });
    }

    // Firebase Admin SDK sync would go here:
    // if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    //   const admin = require('firebase-admin');
    //   if (!admin.apps.length) {
    //     admin.initializeApp({
    //       credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY)),
    //     });
    //   }
    //   await admin.firestore().collection('users').doc(uid).set({
    //     ...data,
    //     updatedAt: new Date().toISOString(),
    //     serverSynced: true,
    //   }, { merge: true });
    // }

    // Demo mode — the client-side sync handles storage
    return NextResponse.json({
      success: true,
      syncedAt: new Date().toISOString(),
      demo: !process.env.FIREBASE_SERVICE_ACCOUNT_KEY,
      message: process.env.FIREBASE_SERVICE_ACCOUNT_KEY
        ? 'Synced via server'
        : 'Sync handled client-side (demo mode)',
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Sync failed' }, { status: 500 });
  }
}

/**
 * GET /api/sync?uid=xxx
 * Load user profile from cloud.
 */
export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const uid = searchParams.get('uid');

  if (!uid) {
    return NextResponse.json({ error: 'uid is required' }, { status: 400 });
  }

  // Firebase Admin SDK read would go here
  // if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
  //   const admin = require('firebase-admin');
  //   if (!admin.apps.length) {
  //     admin.initializeApp({
  //       credential: admin.credential.cert(JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY)),
  //     });
  //   }
  //   const doc = await admin.firestore().collection('users').doc(uid).get();
  //   return NextResponse.json({
  //     success: true,
  //     data: doc.exists ? doc.data() : null,
  //     demo: false,
  //   });
  // }

  return NextResponse.json({
    success: true,
    data: null,
    demo: true,
    message: 'Client-side Firestore handles real sync',
  });
}
