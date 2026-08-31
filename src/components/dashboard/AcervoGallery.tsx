'use client';

/**
 * AcervoGallery — galeria de imagens reais do The Metropolitan Museum of Art
 * (API gratuita, sem chave, domínio público CC0).
 *
 * Materiais: vitrines de obsidiana com hairline, tilt físico (TiltCard),
 * entrada em cascata e leitor de ficha em ecrã inteiro — linguagem
 * "instrumento vivo". Cache local de 24 h por tema; reserva embutida no
 * servidor garante que o acervo nunca amanhece vazio.
 */

import { motion, AnimatePresence } from 'framer-motion';
import { Landmark, Heart, X, ExternalLink, Images, RefreshCw, ChevronRight } from 'lucide-react';
import { useEffect, useState, useCallback, useRef } from 'react';
import { TiltCard } from '@/components/aura/TiltCard';
import { cn } from '@/lib/utils';
import { logEvent } from '@/lib/services';
import type { MetItem } from '@/lib/met-fallback';

type ThemeInfo = { key: string; label: string; hint: string };

const THEMES: ThemeInfo[] = [
  { key: 'vestidos', label: 'Vestidos & silhuetas', hint: 'Costume Institute do Met' },
  { key: 'padroes', label: 'Têxteis & padrões', hint: 'tapeçarias, azulejos e ornamentação' },
  { key: 'joalharia', label: 'Joalharia', hint: 'peças e adornos' },
  { key: 'armaduras', label: 'Armaduras & formas', hint: 'estudo de superfície e forma' },
  { key: 'retratos', label: 'Retratos & poses', hint: 'linguagem corporal e enquadramento' },
  { key: 'fotografias', label: 'Fotografia & luz', hint: 'claro-escuro e atmosfera' },
];

const CACHE_KEY = 'aurastyle-acervo-v1';
const CACHE_TTL = 24 * 60 * 60 * 1000;

type CacheShape = Record<string, { at: number; items: MetItem[] }>;

function readLocal(theme: string): MetItem[] | null {
  try {
    const raw = localStorage.getItem(`${CACHE_KEY}:${theme}`);
    if (!raw) return null;
    const entry = JSON.parse(raw) as { at: number; items: MetItem[] };
    if (Date.now() - entry.at > CACHE_TTL || !entry.items?.length) return null;
    return entry.items;
  } catch {
    return null;
  }
}

function writeLocal(theme: string, items: MetItem[]) {
  try {
    localStorage.setItem(`${CACHE_KEY}:${theme}`, JSON.stringify({ at: Date.now(), items }));
  } catch {
    /* quota — ignora */
  }
}

// ---------------------------------------------------------------- vitrine

function AcervoCard({
  item,
  index,
  onOpen,
}: {
  item: MetItem;
  index: number;
  onOpen: (item: MetItem) => void;
}) {
  const [loaded, setLoaded] = useState(false);
  const [failed, setFailed] = useState(false);

  return (
    <motion.div
      initial={{ opacity: 0, y: 22, filter: 'blur(6px)' }}
      animate={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
      transition={{ delay: Math.min(index * 0.06, 0.5), duration: 0.5, ease: [0.22, 1, 0.36, 1] }}
      className={cn(index % 3 === 1 ? 'pt-5' : '')} // ritmo de colunas quebradas
    >
      <TiltCard
        max={5}
        className="glass group relative cursor-pointer overflow-hidden rounded-2xl border border-border/70"
        onClick={() => onOpen(item)}
      >
        <div
          className="relative w-full"
          style={{
            aspectRatio: index % 3 === 1 ? '3 / 4' : '4 / 5',
            background:
              'linear-gradient(to bottom, oklch(0.3 0.01 258 / 50%), oklch(0.16 0.008 258 / 65%))',
            boxShadow: 'inset 0 1px 0 oklch(0.98 0.01 258 / 9%), inset 0 -12px 20px -14px oklch(0 0 0 / 80%)',
          }}
        >
          {!failed ? (
            <img
              src={item.image}
              alt={item.title}
              loading="lazy"
              referrerPolicy="no-referrer"
              onLoad={() => setLoaded(true)}
              onError={() => setFailed(true)}
              className={cn(
                'h-full w-full object-cover transition-all duration-700 group-hover:scale-[1.03]',
                loaded ? 'opacity-100' : 'opacity-0',
              )}
            />
          ) : (
            <div className="grid h-full w-full place-items-center">
              <Images className="h-6 w-6 text-muted-foreground/40" />
            </div>
          )}

          {/* fio especular no topo */}
          <div
            className="pointer-events-none absolute inset-x-0 top-0 h-px"
            style={{ background: 'linear-gradient(90deg, transparent, oklch(0.98 0.01 258 / 35%), transparent)' }}
          />

          {/* legenda em gradiente de obsidiana */}
          <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-[oklch(0.05_0.01_258/92%)] via-[oklch(0.05_0.01_258/55%)] to-transparent px-3 pb-2.5 pt-8">
            <span className="block truncate text-[11px] font-semibold leading-tight text-foreground">
              {item.title}
            </span>
            <span className="mt-0.5 block truncate text-[9px] text-muted-foreground">
              {item.artist}
              {item.date ? ` · ${item.date}` : ''}
            </span>
          </div>
        </div>
      </TiltCard>
    </motion.div>
  );
}

// ---------------------------------------------------------------- ficha

function DetailSheet({
  item,
  onClose,
  saved,
  onToggleSave,
}: {
  item: MetItem;
  onClose: () => void;
  saved: boolean;
  onToggleSave: () => void;
}) {
  const rows: [string, string][] = [
    ['Criador', item.artist],
    ['Datação', item.date || '—'],
    ['Cultura', item.culture || '—'],
    ['Material', item.medium || '—'],
    ['Departamento', item.department || '—'],
  ];

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.22 }}
      className="fixed inset-0 z-[70] overflow-y-auto bg-[oklch(0.04_0.01_258/82%)] backdrop-blur-xl"
      onClick={onClose}
    >
      <motion.div
        initial={{ y: 36, scale: 0.97, opacity: 0 }}
        animate={{ y: 0, scale: 1, opacity: 1 }}
        exit={{ y: 24, scale: 0.98, opacity: 0 }}
        transition={{ type: 'spring', stiffness: 260, damping: 28 }}
        onClick={(e) => e.stopPropagation()}
        className="mx-auto min-h-full w-full max-w-lg px-4 py-8"
      >
        <div className="glass overflow-hidden rounded-3xl border border-border">
          {/* cabeçalho do instrumento */}
          <div className="flex items-center justify-between border-b border-border px-4 py-3">
            <div className="machined flex items-center gap-2 rounded-lg px-2.5 py-1.5">
              <Landmark className="h-3.5 w-3.5 text-primary" />
              <span className="text-[9px] font-semibold uppercase tracking-[0.22em] text-muted-foreground">
                Ficha do acervo
              </span>
            </div>
            <button
              onClick={onClose}
              aria-label="Fechar"
              className="grid h-8 w-8 place-items-center rounded-lg border border-border bg-surface text-muted-foreground transition-colors hover:text-foreground"
            >
              <X className="h-4 w-4" />
            </button>
          </div>

          {/* imagem em moldura de estúdio */}
          <div
            className="relative m-4 overflow-hidden rounded-2xl border border-border/70"
            style={{
              background:
                'linear-gradient(to bottom, oklch(0.3 0.01 258 / 50%), oklch(0.16 0.008 258 / 65%))',
              boxShadow: 'inset 0 1px 0 oklch(0.98 0.01 258 / 9%)',
            }}
          >
            <img
              src={item.image}
              alt={item.title}
              referrerPolicy="no-referrer"
              className="max-h-[52vh] w-full object-contain"
            />
          </div>

          <div className="px-4 pb-4">
            <h3 className="text-base font-bold leading-snug">{item.title}</h3>

            {/* leituras da ficha */}
            <div className="mt-3 divide-y divide-border/70 overflow-hidden rounded-xl border border-border/70">
              {rows.map(([k, v]) => (
                <div key={k} className="flex items-start justify-between gap-3 px-3 py-2">
                  <span className="shrink-0 text-[9px] font-semibold uppercase tracking-[0.18em] text-muted-foreground pt-0.5">
                    {k}
                  </span>
                  <span className="text-right text-xs leading-relaxed">{v}</span>
                </div>
              ))}
            </div>

            <div className="mt-4 flex gap-2.5">
              <a
                href={item.objectURL}
                target="_blank"
                rel="noreferrer"
                className="machined flex flex-1 items-center justify-center gap-2 rounded-xl px-4 py-3 text-sm font-semibold text-primary-foreground"
                style={{
                  background:
                    'linear-gradient(to bottom, oklch(0.87 0.05 242 / 92%), oklch(0.78 0.06 244 / 92%))',
                  boxShadow:
                    'inset 0 1px 0 oklch(0.99 0.008 258 / 40%), 0 8px 20px -10px oklch(0.82 0.068 244 / 55%)',
                }}
              >
                <ExternalLink className="h-4 w-4" /> metmuseum.org
              </a>
              <button
                onClick={onToggleSave}
                aria-label={saved ? 'Remover dos favoritos' : 'Salvar referência'}
                className={cn(
                  'machined grid w-12 place-items-center rounded-xl transition-colors',
                  saved ? 'text-primary' : 'text-muted-foreground',
                )}
              >
                <Heart className={cn('h-4 w-4', saved && 'fill-primary')} />
              </button>
            </div>
            <p className="mt-3 text-center text-[9px] leading-relaxed text-muted-foreground/70">
              The Metropolitan Museum of Art · Open Access (domínio público)
            </p>
          </div>
        </div>
      </motion.div>
    </motion.div>
  );
}

// ---------------------------------------------------------------- secção

export function AcervoGallery({ onToast }: { onToast: (msg: string) => void }) {
  const [theme, setTheme] = useState<ThemeInfo>(THEMES[0]);
  const [items, setItems] = useState<MetItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [source, setSource] = useState<'met' | 'reserva'>('met');
  const [detail, setDetail] = useState<MetItem | null>(null);
  const [saved, setSaved] = useState<Set<number>>(new Set());
  const reqSeq = useRef(0);

  const load = useCallback(async (t: ThemeInfo, force = false) => {
    const seq = ++reqSeq.current;
    setTheme(t);
    setDetail(null);
    logEvent('acervo_theme_open', { theme: t.key, force });

    if (!force) {
      const local = readLocal(t.key);
      if (local) {
        setItems(local);
        setSource('met');
        setLoading(false);
        return;
      }
    }
    setLoading(true);
    setItems([]);
    try {
      const res = await fetch(`/api/acervo?theme=${t.key}&count=12`);
      const data = (await res.json()) as { items: MetItem[]; source: 'met' | 'reserva' };
      if (seq !== reqSeq.current) return; // resposta antiga, tema já trocou
      setItems(data.items || []);
      setSource(data.source || 'met');
      if (data.items?.length) writeLocal(t.key, data.items);
    } catch {
      if (seq === reqSeq.current) setItems([]);
    } finally {
      if (seq === reqSeq.current) setLoading(false);
    }
  }, []);

  useEffect(() => {
    load(THEMES[0]);
  }, [load]);

  const toggleSave = (item: MetItem) => {
    // efeitos colaterais FORA do updater de estado (senão o React acusa
    // setState durante o render de outro componente)
    const wasSaved = saved.has(item.objectID);
    const next = new Set(saved);
    if (wasSaved) {
      next.delete(item.objectID);
      onToast('Removido dos favoritos');
    } else {
      next.add(item.objectID);
      logEvent('acervo_save', { theme: theme.key, objectID: item.objectID });
      onToast('Salvo nos favoritos!');
    }
    setSaved(next);
  };

  const currentHint = theme.hint;
  const activeTheme = theme;

  return (
    <section className="mb-8">
      {/* cabeçalho usinado */}
      <div className="mb-4 flex items-end justify-between">
        <div>
          <div className="mb-1.5 flex items-center gap-2">
            <div className="machined grid h-7 w-7 place-items-center rounded-lg">
              <Landmark className="h-3.5 w-3.5 text-primary" />
            </div>
            <span className="text-[10px] font-semibold uppercase tracking-[0.28em] text-primary">
              Acervo
            </span>
          </div>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
            Galeria do Met · Open Access
          </h2>
          <p className="mt-0.5 text-xs text-muted-foreground/70">{currentHint}</p>
        </div>
        <button
          onClick={() => load(activeTheme, true)}
          aria-label="Recarregar acervo"
          className="machined grid h-8 w-8 shrink-0 place-items-center rounded-lg text-muted-foreground transition-colors hover:text-primary"
        >
          <RefreshCw className={cn('h-3.5 w-3.5', loading && 'animate-spin')} />
        </button>
      </div>

      {/* chips de tema */}
      <div className="-mx-1 mb-4 flex gap-2 overflow-x-auto px-1 pb-1 no-scrollbar">
        {THEMES.map((t) => (
          <button
            key={t.key}
            onClick={() => t.key !== activeTheme.key && load(t)}
            className={cn(
              'shrink-0 rounded-full border px-3 py-1.5 text-xs font-medium transition-all',
              t.key === activeTheme.key
                ? 'border-transparent bg-aura text-primary-foreground'
                : 'border-border bg-surface text-muted-foreground',
            )}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* grade de vitrines */}
      {loading ? (
        <div className="grid grid-cols-2 gap-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div
              key={i}
              className={cn('shimmer rounded-2xl border border-border/50', i % 3 === 1 ? 'pt-5' : '')}
              style={{ aspectRatio: i % 3 === 1 ? '3 / 4' : '4 / 5' }}
            />
          ))}
        </div>
      ) : items.length === 0 ? (
        <div className="glass rounded-2xl p-6 text-center">
          <Images className="mx-auto mb-2 h-8 w-8 text-muted-foreground" />
          <p className="text-sm text-muted-foreground">
            Acervo indisponível neste momento. Toque em recarregar para tentar de novo.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-3">
          {items.map((item, i) => (
            <AcervoCard key={item.objectID} item={item} index={i} onOpen={setDetail} />
          ))}
        </div>
      )}

      {/* rodapé de atribuição */}
      {items.length > 0 && (
        <div className="mt-3 flex items-center justify-between px-1">
          <span className="text-[9px] text-muted-foreground/60">
            The Metropolitan Museum of Art · API gratuita · domínio público
            {source === 'reserva' ? ' · reserva local' : ''}
          </span>
          <button
            onClick={() => load(activeTheme, true)}
            className="flex items-center gap-0.5 text-[9px] font-medium text-muted-foreground/70 transition-colors hover:text-primary"
          >
            mais obras <ChevronRight className="h-2.5 w-2.5" />
          </button>
        </div>
      )}

      {/* ficha em ecrã inteiro */}
      <AnimatePresence>
        {detail && (
          <DetailSheet
            item={detail}
            onClose={() => setDetail(null)}
            saved={saved.has(detail.objectID)}
            onToggleSave={() => toggleSave(detail)}
          />
        )}
      </AnimatePresence>
    </section>
  );
}
