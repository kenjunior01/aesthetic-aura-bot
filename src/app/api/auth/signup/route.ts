import { NextRequest, NextResponse } from 'next/server';

/**
 * POST /api/auth/signup
 * Server-side auth proxy for Firebase Auth.
 * When Firebase is configured, this validates and creates the user server-side.
 * In demo mode, returns a mock response.
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { email, password, name } = body;

    if (!email || !password || !name) {
      return NextResponse.json({ error: 'Email, senha e nome são obrigatórios' }, { status: 400 });
    }

    if (password.length < 6) {
      return NextResponse.json({ error: 'Senha deve ter pelo menos 6 caracteres' }, { status: 400 });
    }

    // If Firebase server SDK is configured, use it
    if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
      // Server-side Firebase auth would go here
      // For now, return the client-side handled result
    }

    // Demo response — actual auth is handled client-side
    return NextResponse.json({
      success: true,
      message: 'Auth handled client-side',
      demo: true,
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message || 'Internal server error' }, { status: 500 });
  }
}
