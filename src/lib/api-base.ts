/**
 * Base URL das rotas de API do AuraStyle.
 *
 * - Web / Vercel: string vazia (mesma origem) — funciona sem configurar nada.
 * - Capacitor / mobile estático: defina NEXT_PUBLIC_API_BASE no .env do build
 *   (ex.: NEXT_PUBLIC_API_BASE=https://aurastyle.vercel.app) para o WebView
 *   falar com o backend hospedado em vez de "localhost" do dispositivo.
 */
export const API_BASE = process.env.NEXT_PUBLIC_API_BASE || '';
