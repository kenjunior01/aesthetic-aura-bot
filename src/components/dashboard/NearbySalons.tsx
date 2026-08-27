'use client';

import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  MapPin, Star, Clock, DollarSign, Navigation,
  Loader2, RefreshCw, ExternalLink,
} from 'lucide-react';
import { searchNearbySalons, requestNotificationPermission, logEvent } from '@/lib/services';
import { useAura } from '@/lib/aura-store';
import { FEATURES, FIREBASE_FREE_TIER_LIMITS } from '@/lib/firebase-config';
import type { NearbyPlace } from '@/lib/services';

export default function NearbySalons() {
  const { profile } = useAura();
  const [places, setPlaces] = useState<NearbyPlace[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [filterType, setFilterType] = useState<string | null>(null);

  const regionCoords: Record<string, [number, number]> = {
    'São Paulo, BR': [-23.5505, -46.6333],
    'Rio de Janeiro, BR': [-22.9068, -43.1729],
    'Salvador, BR': [-12.9714, -38.5124],
    'Brasília, BR': [-15.7975, -47.8919],
    'Lisboa, PT': [38.7223, -9.1393],
    'Porto, PT': [41.1579, -8.6291],
    'Luanda, AO': [-8.8390, 13.2894],
    'Maputo, MZ': [-25.9692, 32.5732],
  };

  const loadPlaces = async () => {
    setLoading(true);
    setError('');
    try {
      const coords = regionCoords[profile.region] || [-23.5505, -46.6333];
      const results = await searchNearbySalons(coords[0], coords[1]);
      setPlaces(results);
      logEvent('places_search', { region: profile.region, count: results.length });
    } catch (err: any) {
      setError('Erro ao buscar locais próximos');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPlaces();
  }, [profile.region]);

  const types = ['Todos', 'Salão', 'Cabelo', 'Spa', 'Shopping'];
  const filtered = filterType && filterType !== 'Todos'
    ? places.filter((p) => p.types.some((t) => t.toLowerCase().includes(filterType.toLowerCase())))
    : places;

  const priceLabel = (level?: number) => {
    if (!level) return '';
    return '$'.repeat(level);
  };

  return (
    <div>
      <div className='flex items-center justify-between mb-3'>
        <div>
          <h2 className='text-sm font-semibold uppercase tracking-widest text-muted-foreground'>
            Perto de você
          </h2>
          <p className='text-[10px] text-muted-foreground mt-0.5'>
            {profile.region || 'São Paulo, BR'}
          </p>
        </div>
        <motion.button
          whileTap={{ scale: 0.95 }}
          onClick={loadPlaces}
          disabled={loading}
          className='h-8 w-8 rounded-lg glass flex items-center justify-center'
        >
          <RefreshCw className={`h-3.5 w-3.5 ${loading ? 'animate-spin' : ''}`} />
        </motion.button>
      </div>

      {/* Type filters */}
      <div className='flex gap-2 mb-4 overflow-x-auto no-scrollbar -mx-1 px-1'>
        {types.map((t) => (
          <button
            key={t}
            onClick={() => setFilterType(t === 'Todos' ? null : t)}
            className={`shrink-0 rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
              (!filterType && t === 'Todos') || filterType === t
                ? 'border-transparent bg-aura text-primary-foreground'
                : 'border-border bg-surface text-muted-foreground'
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {loading && (
        <div className='flex items-center justify-center py-12 gap-2'>
          <Loader2 className='h-5 w-5 animate-spin text-primary' />
          <span className='text-sm text-muted-foreground'>Buscando locais...</span>
        </div>
      )}

      {error && (
        <div className='glass rounded-2xl p-4 text-center'>
          <p className='text-sm text-destructive'>{error}</p>
          <button onClick={loadPlaces} className='text-xs text-primary mt-2'>Tentar novamente</button>
        </div>
      )}

      {!loading && !error && filtered.length > 0 && (
        <div className='flex flex-col gap-3'>
          {filtered.map((place, i) => (
            <motion.div
              key={place.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: i * 0.05 }}
              className='glass rounded-2xl p-4'
            >
              <div className='flex items-start gap-3'>
                {place.photoUrl ? (
                  <div className='h-14 w-14 rounded-xl overflow-hidden shrink-0'>
                    <img src={place.photoUrl} alt={place.name} className='h-full w-full object-cover' />
                  </div>
                ) : (
                  <div className='h-14 w-14 rounded-xl bg-surface-strong flex items-center justify-center shrink-0'>
                    <MapPin className='h-5 w-5 text-primary' />
                  </div>
                )}
                <div className='flex-1 min-w-0'>
                  <div className='flex items-start justify-between gap-2'>
                    <span className='text-sm font-semibold block truncate'>{place.name}</span>
                    {place.priceLevel && (
                      <span className='text-xs text-gold shrink-0'>{priceLabel(place.priceLevel)}</span>
                    )}
                  </div>
                  <div className='flex items-center gap-3 mt-1'>
                    <div className='flex items-center gap-1'>
                      <Star className='h-3 w-3 text-gold fill-gold' />
                      <span className='text-xs font-medium'>{place.rating}</span>
                      <span className='text-[10px] text-muted-foreground'>({place.totalRatings})</span>
                    </div>
                    <span className='text-[10px] text-muted-foreground'>{place.distance}</span>
                    <div className={`flex items-center gap-1 ${place.openNow ? 'text-green-400' : 'text-red-400'}`}>
                      <Clock className='h-3 w-3' />
                      <span className='text-[10px]'>{place.openNow ? 'Aberto' : 'Fechado'}</span>
                    </div>
                  </div>
                  <p className='text-[10px] text-muted-foreground mt-1 truncate'>{place.address}</p>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      )}

      {!loading && !error && filtered.length === 0 && (
        <div className='text-center py-8'>
          <Navigation className='h-8 w-8 text-muted-foreground/30 mx-auto mb-2' />
          <p className='text-sm text-muted-foreground'>Nenhum local encontrado</p>
        </div>
      )}

      {/* Info footer */}
      <div className='glass rounded-2xl p-3 mt-4'>
        <p className='text-[10px] text-muted-foreground text-center leading-relaxed'>
          {FEATURES.placesSearch
            ? `Google Places API: ${FIREBASE_FREE_TIER_LIMITS.places.credit} crédito gratuito/mês. `
            : 'Modo demo — dados ilustrativos. Adicione Google Places API key para resultados reais. '
          }
          Ative localização para resultados mais precisos.
        </p>
      </div>
    </div>
  );
}
