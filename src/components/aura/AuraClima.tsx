'use client';

import React, { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import { CloudSun, Loader2, MapPin } from 'lucide-react';
import { useAura } from '@/lib/aura-store';
import { fetchWeather } from '@/lib/services';
import type { WeatherInfo } from '@/lib/services';

/**
 * Aura Clima — o ritual do dia adapta-se ao clima REAL da cidade.
 * Dados: Open-Meteo (gratuito, sem chave). Some graciosamente se
 * não houver coordenadas ou se a rede falhar.
 */
export default function AuraClima() {
  const { profile } = useAura();
  const [weather, setWeather] = useState<WeatherInfo | null>(null);
  const lat = profile.geoLat;
  const lon = profile.geoLon;
  // loading já nasce true quando há coordenadas a consultar
  const [loading, setLoading] = useState(() => profile.geoLat != null && profile.geoLon != null);

  useEffect(() => {
    if (lat == null || lon == null) return;
    let cancelled = false;
    fetchWeather(lat, lon)
      .then((w) => { if (!cancelled) setWeather(w); })
      .catch(() => {})
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [lat, lon]);

  if (lat == null || lon == null) return null;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      className='glass rounded-2xl border border-gold/15 p-4'
    >
      <div className='mb-2 flex items-center justify-between'>
        <div className='flex items-center gap-2'>
          <CloudSun className='h-4 w-4 text-gold' />
          <span className='text-sm font-semibold'>Aura Clima</span>
        </div>
        {profile.city && (
          <span className='inline-flex items-center gap-1 text-[10px] text-muted-foreground'>
            <MapPin className='h-3 w-3' /> {profile.city}
          </span>
        )}
      </div>

      {loading && (
        <div className='flex items-center gap-2 py-1 text-xs text-muted-foreground'>
          <Loader2 className='h-3.5 w-3.5 animate-spin text-primary' />
          A consultar o céu da tua cidade...
        </div>
      )}

      {weather && (
        <>
          <div className='flex items-center gap-3'>
            <span className='text-3xl'>{weather.emoji}</span>
            <div className='min-w-0 flex-1'>
              <p className='text-sm font-semibold leading-tight'>
                {weather.temp}°C · {weather.label}
              </p>
              <p className='text-[11px] text-muted-foreground'>
                Humidade {weather.humidity}% · UV {weather.uv} · Vento {weather.wind} km/h
              </p>
            </div>
          </div>
          <ul className='mt-2.5 space-y-1.5'>
            {weather.tips.map((tip) => (
              <li key={tip} className='flex items-start gap-1.5 text-xs leading-relaxed text-muted-foreground'>
                <span className='mt-1.5 h-1 w-1 shrink-0 rounded-full bg-primary' />
                {tip}
              </li>
            ))}
          </ul>
          <p className='mt-2 text-[9px] text-muted-foreground/60'>
            Dados meteorológicos: Open-Meteo (gratuito) — atualizado agora para as tuas coordenadas.
          </p>
        </>
      )}

      {!loading && !weather && (
        <p className='text-xs text-muted-foreground'>
          Clima indisponível agora — as dicas adaptativas voltam em breve.
        </p>
      )}
    </motion.div>
  );
}
