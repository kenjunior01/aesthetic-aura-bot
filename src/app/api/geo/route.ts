import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'nodejs';
export const maxDuration = 10;

/**
 * GET /api/geo — Detecção de região SEM chaves e SEM custo.
 *
 * Camadas (a melhor que responder ganha):
 *  1. Headers da plataforma de deploy (Vercel/Cloudflare/Netlify) — instantâneo
 *  2. ip-api.co / ipwho.is do IP do request — fallback servidor
 *  3. Cliente envia ?tz=<timezone> — resolução offline pelo fuso horário
 *
 * Resposta: { ok, country, countryCode, city, lat, lon, via }
 */

const TZ_MAP: Record<string, { code: string; city: string; lat: number; lon: number }> = {
  'Africa/Luanda': { code: 'AO', city: 'Luanda', lat: -8.84, lon: 13.23 },
  'Africa/Maputo': { code: 'MZ', city: 'Maputo', lat: -25.97, lon: 32.57 },
  'Africa/Johannesburg': { code: 'ZA', city: 'Joanesburgo', lat: -26.2, lon: 28.05 },
  'Africa/Lagos': { code: 'NG', city: 'Lagos', lat: 6.52, lon: 3.37 },
  'Africa/Nairobi': { code: 'KE', city: 'Nairóbi', lat: -1.29, lon: 36.82 },
  'Africa/Accra': { code: 'GH', city: 'Acra', lat: 5.6, lon: -0.19 },
  'Africa/Douala': { code: 'CM', city: 'Douala', lat: 4.05, lon: 9.7 },
  'Africa/Abidjan': { code: 'CI', city: 'Abidjã', lat: 5.36, lon: -4.01 },
  'Africa/Dakar': { code: 'SN', city: 'Dacar', lat: 14.72, lon: -17.47 },
  'Africa/Windhoek': { code: 'NA', city: 'Windhoek', lat: -22.56, lon: 17.08 },
  'Africa/Sao_Tome': { code: 'ST', city: 'São Tomé', lat: 0.34, lon: 6.73 },
  'Africa/Bissau': { code: 'GW', city: 'Bissau', lat: 11.86, lon: -15.6 },
  'Africa/Cairo': { code: 'EG', city: 'Cairo', lat: 30.04, lon: 31.24 },
  'Africa/Casablanca': { code: 'MA', city: 'Casablanca', lat: 33.57, lon: -7.59 },
  'Europe/Lisbon': { code: 'PT', city: 'Lisboa', lat: 38.72, lon: -9.14 },
  'Atlantic/Azores': { code: 'PT', city: 'Ponta Delgada', lat: 37.74, lon: -25.67 },
  'Atlantic/Madeira': { code: 'PT', city: 'Funchal', lat: 32.66, lon: -16.91 },
  'America/Sao_Paulo': { code: 'BR', city: 'São Paulo', lat: -23.55, lon: -46.63 },
  'America/Bahia': { code: 'BR', city: 'Salvador', lat: -12.97, lon: -38.5 },
  'America/Fortaleza': { code: 'BR', city: 'Fortaleza', lat: -3.73, lon: -38.52 },
  'America/Recife': { code: 'BR', city: 'Recife', lat: -8.05, lon: -34.9 },
  'America/Manaus': { code: 'BR', city: 'Manaus', lat: -3.12, lon: -60.02 },
  'America/New_York': { code: 'US', city: 'Nova Iorque', lat: 40.71, lon: -74.01 },
  'America/Chicago': { code: 'US', city: 'Chicago', lat: 41.88, lon: -87.63 },
  'America/Denver': { code: 'US', city: 'Denver', lat: 39.74, lon: -104.99 },
  'America/Los_Angeles': { code: 'US', city: 'Los Angeles', lat: 34.05, lon: -118.24 },
  'America/Cape_Verde': { code: 'CV', city: 'Praia', lat: 14.93, lon: -23.51 },
  'Atlantic/Cape_Verde': { code: 'CV', city: 'Praia', lat: 14.93, lon: -23.51 },
  'Europe/Paris': { code: 'FR', city: 'Paris', lat: 48.86, lon: 2.35 },
  'Europe/Madrid': { code: 'ES', city: 'Madri', lat: 40.42, lon: -3.7 },
  'Atlantic/Canary': { code: 'ES', city: 'Las Palmas', lat: 28.12, lon: -15.43 },
  'Europe/London': { code: 'GB', city: 'Londres', lat: 51.51, lon: -0.13 },
  'Europe/Berlin': { code: 'DE', city: 'Berlim', lat: 52.52, lon: 13.4 },
  'Europe/Rome': { code: 'IT', city: 'Roma', lat: 41.9, lon: 12.5 },
  'Europe/Amsterdam': { code: 'NL', city: 'Amsterdã', lat: 52.37, lon: 4.9 },
  'Europe/Brussels': { code: 'BE', city: 'Bruxelas', lat: 50.85, lon: 4.35 },
  'Europe/Zurich': { code: 'CH', city: 'Zurique', lat: 47.38, lon: 8.54 },
  'Europe/Vienna': { code: 'AT', city: 'Viena', lat: 48.21, lon: 16.37 },
  'Europe/Luxembourg': { code: 'LU', city: 'Luxemburgo', lat: 49.61, lon: 6.13 },
  'America/Toronto': { code: 'CA', city: 'Toronto', lat: 43.65, lon: -79.38 },
  'America/Vancouver': { code: 'CA', city: 'Vancouver', lat: 49.28, lon: -123.12 },
  'America/Mexico_City': { code: 'MX', city: 'Cidade do México', lat: 19.43, lon: -99.13 },
  'America/Bogota': { code: 'CO', city: 'Bogotá', lat: 4.71, lon: -74.07 },
  'America/Lima': { code: 'PE', city: 'Lima', lat: -12.05, lon: -77.04 },
  'America/Santiago': { code: 'CL', city: 'Santiago', lat: -33.45, lon: -70.67 },
  'America/Buenos_Aires': { code: 'AR', city: 'Buenos Aires', lat: -34.6, lon: -58.38 },
  'America/Caracas': { code: 'VE', city: 'Caracas', lat: 10.48, lon: -66.9 },
  'America/Guayaquil': { code: 'EC', city: 'Guayaquil', lat: -2.19, lon: -79.89 },
  'Asia/Dubai': { code: 'AE', city: 'Dubai', lat: 25.2, lon: 55.27 },
  'Asia/Riyadh': { code: 'SA', city: 'Riade', lat: 24.71, lon: 46.68 },
  'Asia/Kolkata': { code: 'IN', city: 'Mumbai', lat: 19.08, lon: 72.88 },
  'Asia/Shanghai': { code: 'CN', city: 'Xangai', lat: 31.23, lon: 121.47 },
  'Asia/Hong_Kong': { code: 'HK', city: 'Hong Kong', lat: 22.32, lon: 114.17 },
  'Asia/Macau': { code: 'MO', city: 'Macau', lat: 22.20, lon: 113.55 },
  'Asia/Seoul': { code: 'KR', city: 'Seul', lat: 37.57, lon: 126.98 },
  'Asia/Bangkok': { code: 'TH', city: 'Bangkok', lat: 13.76, lon: 100.5 },
  'Asia/Jakarta': { code: 'ID', city: 'Jacarta', lat: -6.21, lon: 106.85 },
  'Asia/Istanbul': { code: 'TR', city: 'Istambul', lat: 41.01, lon: 28.98 },
  'Asia/Tokyo': { code: 'JP', city: 'Tóquio', lat: 35.68, lon: 139.69 },
  'Asia/Singapore': { code: 'SG', city: 'Singapura', lat: 1.35, lon: 103.82 },
  'Australia/Sydney': { code: 'AU', city: 'Sydney', lat: -33.87, lon: 151.21 },
  'Pacific/Auckland': { code: 'NZ', city: 'Auckland', lat: -36.85, lon: 174.76 },
};

function headerCountry(req: NextRequest): { code: string; city?: string; lat?: number; lon?: number; via: string } | null {
  const h = req.headers;
  // Vercel
  const vc = h.get('x-vercel-ip-country');
  if (vc) {
    return {
      code: vc,
      city: h.get('x-vercel-ip-city') || undefined,
      lat: Number(h.get('x-vercel-ip-latitude')) || undefined,
      lon: Number(h.get('x-vercel-ip-longitude')) || undefined,
      via: 'vercel-headers',
    };
  }
  // Cloudflare
  const cf = h.get('cf-ipcountry');
  if (cf) {
    return { code: cf, city: h.get('cf-ipcity') || undefined, via: 'cloudflare-headers' };
  }
  return null;
}

async function ipApiLookup(req: NextRequest): Promise<{ code: string; city?: string; lat?: number; lon?: number; via: string } | null> {
  // IP real do cliente (atrás de proxy) ou do request
  const forwarded = req.headers.get('x-forwarded-for');
  const ip = forwarded?.split(',')[0]?.trim();
  const url = ip ? `http://ip-api.com/json/${ip}?fields=status,countryCode,city,lat,lon` : 'http://ip-api.com/json/?fields=status,countryCode,city,lat,lon';
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 4000);
    const res = await fetch(url, { signal: controller.signal });
    clearTimeout(timer);
    if (!res.ok) return null;
    const data = (await res.json()) as { status?: string; countryCode?: string; city?: string; lat?: number; lon?: number };
    if (data.status !== 'success' || !data.countryCode) return null;
    return { code: data.countryCode, city: data.city, lat: data.lat, lon: data.lon, via: 'ip-api' };
  } catch {
    return null;
  }
}

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const tz = searchParams.get('tz') || '';

  // 1) Headers da plataforma
  const viaHeaders = headerCountry(request);
  if (viaHeaders) {
    return NextResponse.json({ ok: true, ...viaHeaders });
  }

  // 2) IP do request
  const viaIp = await ipApiLookup(request);
  if (viaIp) {
    return NextResponse.json({ ok: true, ...viaIp });
  }

  // 3) Fuso horário do cliente
  if (tz && TZ_MAP[tz]) {
    const t = TZ_MAP[tz];
    return NextResponse.json({ ok: true, code: t.code, city: t.city, lat: t.lat, lon: t.lon, via: 'timezone' });
  }

  return NextResponse.json({ ok: false, via: 'none' }, { status: 200 });
}
