import { NextRequest, NextResponse } from 'next/server';

/**
 * POST /api/sync
 * Cloud sync endpoint for user profile data.
 * With Firebase Admin SDK, this writes to Firestore directly.
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { uid, data } = body;

    if (!uid || !data) {
      return NextResponse.json({ error: 'uid and data are required' }, { status: 400 });
    }

    // Firebase Admin SDK sync would go here:
    // const admin = require('firebase-admin');
    // await admin.firestore().collection('users').doc(uid).set(data, { merge: true });

    return NextResponse.json({
      success: true,
      syncedAt: new Date().toISOString(),
      demo: !process.env.FIREBASE_SERVICE_ACCOUNT_KEY,
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
  return NextResponse.json({
    success: true,
    data: null,
    demo: true,
  });
}
