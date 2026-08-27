import { NextRequest, NextResponse } from 'next/server';

/**
 * POST /api/auth/login
 * Server-side auth proxy for Firebase Auth.
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, password } = body;

    if (!email || !password) {
      return NextResponse.json({ error: 'Email e senha são obrigatórios' }, { status: 400 });
    }

    return NextResponse.json({
      success: true,
      message: 'Auth handled client-side',
      demo: true,
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Internal server error' }, { status: 500 });
  }
}
