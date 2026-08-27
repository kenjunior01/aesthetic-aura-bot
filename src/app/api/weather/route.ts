import { NextRequest, NextResponse } from 'next/server';

export const runtime = 'nodejs';
export const maxDuration = 15;

/**
 * GET /api/weather?lat=X&lon=Y — Clima ao vivo (gratuito, sem chave)
 * Cadeia de fontes abertas: Open-Meteo → wttr.in.
 * O plano de cuidado adapta-se ao clima REAL da cidade do usuário.
 *
 * Resposta: { ok, temp, humidity, uv, wind, code, label, emoji, tips: string[] }
 */

type Wx = {
  current?: {
    temperature_2m?: number;
    relative_humidity_2m?: number;
    weather_code?: number;
    wind_speed_10m?: number;
  };
  hourly?: { uv_index?: number[] };
};

type Wttr = {
  current_condition?: {
    temp_C?: string;
    humidity?: string;
    weatherCode?: string;
    windspeedKmph?: string;
    uvIndex?: string;
  }[];
};

const WMO: Record<number, { label: string; emoji: string }> = {
  0: { label: 'céu limpo', emoji: '☀️' },
  1: { label: 'predominantemente limpo', emoji: '🌤️' },
  2: { label: 'parcialmente nublado', emoji: '⛅' },
  3: { label: 'nublado', emoji: '☁️' },
  45: { label: 'nevoeiro', emoji: '🌫️' },
  48: { label: 'nevoeiro com geada', emoji: '🌫️' },
  51: { label: 'chuvisco leve', emoji: '🌦️' },
  53: { label: 'chuvisco', emoji: '🌦️' },
  55: { label: 'chuvisco intenso', emoji: '🌧️' },
  61: { label: 'chuva leve', emoji: '🌦️' },
  63: { label: 'chuva', emoji: '🌧️' },
  65: { label: 'chuva forte', emoji: '🌧️' },
  71: { label: 'neve leve', emoji: '🌨️' },
  73: { label: 'neve', emoji: '🌨️' },
  75: { label: 'neve forte', emoji: '❄️' },
  80: { label: 'pancadas de chuva', emoji: '🌦️' },
  81: { label: 'pancadas fortes', emoji: '🌧️' },
  82: { label: 'pancadas violentas', emoji: '⛈️' },
  95: { label: 'trovoada', emoji: '⛈️' },
  96: { label: 'trovoada com granizo', emoji: '⛈️' },
  99: { label: 'trovoada severa', emoji: '⛈️' },
};

/** Código wttr.in (3 dígitos) → WMO aproximado para as dicas */
const WTTR_TO_WMO: Record<number, number> = {
  113: 0, 116: 2, 119: 3, 122: 3, 143: 45, 248: 45, 260: 45,
  176: 61, 263: 51, 266: 51, 281: 53, 284: 55, 293: 61, 296: 61,
  299: 63, 302: 63, 305: 65, 308: 65, 350: 65, 374: 65,
  200: 95, 386: 95, 389: 99,
  179: 71, 182: 71, 185: 71, 323: 71, 326: 71, 329: 73, 332: 73, 335: 75, 338: 75,
  227: 73, 230: 75,
  320: 75,
};

function buildTips(temp: number, humidity: number, uv: number, code: number, wind: number): string[] {
  const tips: string[] = [];

  if (uv >= 8) tips.push('UV muito alto: FPS 50 e reaplicação a cada 2h é inegociável hoje.');
  else if (uv >= 5) tips.push('UV moderado-alto: protetor solar no rosto e nuca antes de sair.');
  else if (uv > 0 && uv < 5) tips.push('UV suave: ótimo momento para vitamina D com moderação.');

  if (humidity >= 75) tips.push('Ar húmido: texturas gel-creme e leave-in leves evitam peso e oleosidade.');
  else if (humidity <= 35) tips.push('Ar seco: reforça hidratante com ureia/glicerina e umectação capilar noturna.');

  if (temp >= 30) tips.push('Calor: água extra, bruma facial na bolsa e penteado protegido do sol.');
  else if (temp <= 12) tips.push('Frio: barreira lipídica (creme mais rico) e óleo nas pontas contra o vento.');

  if (code >= 61 && code <= 82) tips.push('Chuva: anti-frizz ou penteado de emergência guardado na mochila.');
  if (wind >= 30) tips.push('Vento forte: penteado preso ou leave-in com proteção mecânica.');

  if (!tips.length) tips.push('Clima equilibrado: dia perfeito para manter a rotina e brilhar.');

  return tips.slice(0, 3);
}

async function fetchJson<T>(url: string, ua: string, timeoutMs = 8000): Promise<T | null> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(url, {
      headers: { 'User-Agent': ua },
      signal: controller.signal,
      next: { revalidate: 900 },
    });
    if (!res.ok) return null;
    return (await res.json()) as T;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);
  const lat = Number(searchParams.get('lat'));
  const lon = Number(searchParams.get('lon'));

  if (!Number.isFinite(lat) || !Number.isFinite(lon) || Math.abs(lat) > 90 || Math.abs(lon) > 180) {
    return NextResponse.json({ ok: false, error: 'lat/lon inválidos' }, { status: 400 });
  }

  // ---------- 1) Open-Meteo ----------
  const wx = await fetchJson<Wx>(
    `https://api.open-meteo.com/v1/forecast?latitude=${lat.toFixed(3)}&longitude=${lon.toFixed(3)}` +
    '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m' +
    '&hourly=uv_index&forecast_days=1&timezone=auto',
    'AuraStyle/1.0',
  );

  if (wx?.current) {
    const temp = Math.round(wx.current.temperature_2m ?? 0);
    const humidity = Math.round(wx.current.relative_humidity_2m ?? 0);
    const code = wx.current.weather_code ?? 0;
    const wind = Math.round(wx.current.wind_speed_10m ?? 0);
    const uvs = wx.hourly?.uv_index || [];
    const nowHour = new Date().getHours();
    const uv = Math.round(uvs[nowHour] ?? uvs[Math.min(nowHour, uvs.length - 1)] ?? 0);
    const wmo = WMO[code] || { label: 'tempo estável', emoji: '🌤️' };

    return NextResponse.json({
      ok: true, temp, humidity, uv, wind, code,
      label: wmo.label, emoji: wmo.emoji,
      tips: buildTips(temp, humidity, uv, code, wind),
      source: 'open-meteo',
    });
  }

  // ---------- 2) wttr.in (fallback) ----------
  const wttr = await fetchJson<Wttr>(
    `https://wttr.in/${lat.toFixed(2)},${lon.toFixed(2)}?format=j1`,
    'AuraStyle/1.0 (beauty assistant)',
  );
  const cc = wttr?.current_condition?.[0];
  if (cc && cc.temp_C !== undefined) {
    const temp = Math.round(Number(cc.temp_C) || 0);
    const humidity = Math.round(Number(cc.humidity) || 0);
    const uv = Math.round(Number(cc.uvIndex) || 0);
    const wind = Math.round(Number(cc.windspeedKmph) || 0);
    const rawCode = Number(cc.weatherCode) || 113;
    const code = WTTR_TO_WMO[rawCode] ?? 1;
    const wmo = WMO[code] || { label: 'tempo estável', emoji: '🌤️' };

    return NextResponse.json({
      ok: true, temp, humidity, uv, wind, code,
      label: wmo.label, emoji: wmo.emoji,
      tips: buildTips(temp, humidity, uv, code, wind),
      source: 'wttr-in',
    });
  }

  return NextResponse.json(
    { ok: false, error: 'nenhuma fonte de clima disponível' },
    { status: 502 },
  );
}
