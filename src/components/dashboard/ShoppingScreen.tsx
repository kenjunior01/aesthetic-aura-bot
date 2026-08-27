'use client';

import React, { useMemo, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  ShoppingBag, Wallet, Tag, Camera, Plus, Trash2, Sparkles, Loader2,
  Check, Clock, ArrowRight, ImageIcon, MapPin, Zap, ScanLine,
} from 'lucide-react';
import { useAura } from '@/lib/aura-store';
import { cn } from '@/lib/utils';
import { consultShoppingAdvisor, logEvent } from '@/lib/services';
import type { ShoppingBrand, ShoppingPlanItem } from '@/lib/services';
import {
  detectCountry, resolveCountry, localPrioritize, formatMoney,
  SHOPPING_LIST_HINTS,
} from '@/lib/shopping';
import type { CountryInfo } from '@/lib/shopping';

// ============================================================
// Tipos locais
// ============================================================

type Mode = 'budget' | 'brands' | 'photo';

type RowProduct = { name: string; price: string; brand?: string };

type PlanResult = {
  items: ShoppingPlanItem[];
  totalInside: number;
  totalAll: number;
  advice: string;
  source: 'gemini' | 'zai' | 'local';
  model?: string;
};

const SOURCE_LABEL: Record<string, string> = {
  gemini: 'IA Gemini',
  zai: 'IA Z',
  local: 'Análise local',
};

function SourceBadge({ source }: { source: 'gemini' | 'zai' | 'local' }) {
  return (
    <span className="inline-flex items-center gap-1 rounded-full border border-primary/25 bg-primary/10 px-2 py-0.5 text-[9px] font-medium uppercase tracking-wider text-primary">
      <Sparkles className="h-2.5 w-2.5" />
      {SOURCE_LABEL[source] || 'Análise local'}
    </span>
  );
}

// ============================================================
// Resultado do plano de compras
// ============================================================

function PlanResults({ plan, budget, country }: { plan: PlanResult; budget: number; country: CountryInfo }) {
  const buyCount = plan.items.filter((i) => i.verdict === 'comprar').length;
  const pct = plan.totalAll > 0 ? Math.min((plan.totalInside / plan.totalAll) * 100, 100) : 0;

  return (
    <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="flex flex-col gap-3">
      {/* Resumo do orçamento */}
      <div className="glass rounded-2xl border border-primary/20 p-4">
        <div className="mb-2 flex items-center justify-between">
          <span className="text-sm font-semibold">
            {buyCount} de {plan.items.length} entram no orçamento
          </span>
          <span className="text-xs font-bold text-gold">{formatMoney(plan.totalInside, country)}</span>
        </div>
        <div className="h-2 rounded-full bg-surface-strong overflow-hidden">
          <motion.div
            initial={{ width: 0 }}
            animate={{ width: `${pct}%` }}
            transition={{ type: 'spring', stiffness: 200, damping: 30 }}
            className="h-full rounded-full bg-aura"
          />
        </div>
        <div className="mt-2 flex items-center justify-between text-[10px] text-muted-foreground">
          <span>Orçamento: {formatMoney(budget, country)}</span>
          <span>Total da lista: {formatMoney(plan.totalAll, country)}</span>
        </div>
      </div>

      {/* Itens em ordem de prioridade */}
      {plan.items.map((item) => (
        <motion.div
          key={`${item.name}-${item.priority}`}
          initial={{ x: 30, opacity: 0 }}
          animate={{ x: 0, opacity: 1 }}
          transition={{ delay: item.priority * 0.06, type: 'spring', stiffness: 300, damping: 28 }}
          className={cn(
            'glass flex items-start gap-3 rounded-2xl p-4',
            item.verdict === 'comprar' && 'border-primary/40',
          )}
        >
          <div
            className={cn(
              'grid h-9 w-9 shrink-0 place-items-center rounded-xl text-sm font-bold',
              item.verdict === 'comprar' ? 'bg-aura text-primary-foreground' : 'bg-surface-strong text-muted-foreground',
            )}
          >
            {item.priority}
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex items-start justify-between gap-2">
              <span className="text-sm font-semibold leading-snug">{item.name}</span>
              {item.price > 0 && (
                <span className="shrink-0 text-xs font-bold text-gold">{formatMoney(item.price, country)}</span>
              )}
            </div>
            {item.brand && <span className="text-[11px] text-muted-foreground">{item.brand}</span>}
            <p className="mt-1 text-xs leading-relaxed text-muted-foreground">{item.reason}</p>
            <div className="mt-2 flex items-center gap-2">
              {item.verdict === 'comprar' ? (
                <span className="inline-flex items-center gap-1 rounded-full bg-primary/15 px-2 py-0.5 text-[10px] font-semibold text-primary">
                  <Check className="h-3 w-3" /> Comprar agora
                </span>
              ) : (
                <span className="inline-flex items-center gap-1 rounded-full bg-surface-strong px-2 py-0.5 text-[10px] font-medium text-muted-foreground">
                  <Clock className="h-3 w-3" /> Deixar para depois
                </span>
              )}
              <span className="text-[9px] uppercase tracking-wider text-muted-foreground/60">{item.domain}</span>
            </div>
          </div>
        </motion.div>
      ))}

      {/* Conselho final */}
      {plan.advice && (
        <div className="glass rounded-2xl border border-gold/25 p-4">
          <div className="mb-1 flex items-center gap-2">
            <Zap className="h-3.5 w-3.5 text-gold" />
            <span className="text-xs font-bold uppercase tracking-wider text-gold">Conselho do Aura</span>
          </div>
          <p className="text-sm leading-relaxed">{plan.advice}</p>
        </div>
      )}
    </motion.div>
  );
}

// ============================================================
// MODO ORÇAMENTO
// ============================================================

function BudgetMode({ country, initialRows }: { country: CountryInfo; initialRows: RowProduct[] }) {
  const { profile } = useAura();
  const [budget, setBudget] = useState('');
  const [rows, setRows] = useState<RowProduct[]>(initialRows);
  const [plan, setPlan] = useState<PlanResult | null>(null);
  const [loading, setLoading] = useState(false);

  const budgetNum = Number(budget.replace(',', '.')) || 0;

  const addRow = (name = '') => setRows((r) => [...r, { name, price: '' }]);
  const updateRow = (i: number, patch: Partial<RowProduct>) =>
    setRows((r) => r.map((row, idx) => (idx === i ? { ...row, ...patch } : row)));
  const removeRow = (i: number) => setRows((r) => r.filter((_, idx) => idx !== i));

  // Sugestões guiadas pelas prioridades do usuário
  const hints = useMemo(() => {
    const top = profile.priorities || [];
    return SHOPPING_LIST_HINTS.filter(
      (h) => top.includes(h.domain) || top.length === 0,
    ).slice(0, 4);
  }, [profile.priorities]);

  const canRun = budgetNum > 0 && rows.some((r) => r.name.trim());

  const runPrioritize = async () => {
    const list = rows
      .filter((r) => r.name.trim())
      .map((r) => ({ name: r.name.trim(), brand: r.brand, price: Number(r.price.replace(',', '.')) || 0 }));
    if (!list.length || budgetNum <= 0) return;

    setLoading(true);
    setPlan(null);
    logEvent('shopping_prioritize', { items: list.length, budget: budgetNum });

    const res = await consultShoppingAdvisor({
      mode: 'prioritize',
      profile,
      country: country.code,
      budget: budgetNum,
      products: list,
    });

    if (res?.items?.length) {
      setPlan({
        items: res.items,
        totalInside: res.totalInside || 0,
        totalAll: res.items.reduce((s, i) => s + (i.price || 0), 0),
        advice: res.advice || '',
        source: res.source,
        model: res.model,
      });
    } else {
      // Fallback local (offline)
      const local = localPrioritize(list, budgetNum, profile as never, country);
      setPlan({
        items: local.items,
        totalInside: local.totalInside,
        totalAll: local.totalAll,
        advice: local.advice,
        source: 'local',
      });
    }
    setLoading(false);
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Orçamento */}
      <div className="glass rounded-2xl p-4">
        <div className="mb-3 flex items-center gap-2">
          <Wallet className="h-4 w-4 text-primary" />
          <span className="text-sm font-semibold">Quanto tens para gastar?</span>
        </div>
        <div className="flex items-center gap-3 rounded-xl border border-border bg-surface px-4 focus-within:border-primary/60">
          <span className="text-lg font-bold text-primary">{country.symbol}</span>
          <input
            type="number"
            inputMode="decimal"
            min={0}
            value={budget}
            onChange={(e) => setBudget(e.target.value)}
            placeholder="0"
            className="h-12 flex-1 bg-transparent text-xl font-bold tabular-nums outline-none placeholder:text-muted-foreground/40"
          />
          <span className="text-xs text-muted-foreground">{country.currency}</span>
        </div>
      </div>

      {/* Lista de produtos */}
      <div className="glass rounded-2xl p-4">
        <div className="mb-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Tag className="h-4 w-4 text-primary" />
            <span className="text-sm font-semibold">O que estás a ver na loja?</span>
          </div>
          <button
            onClick={() => addRow()}
            className="flex items-center gap-1 rounded-full bg-primary/15 px-2.5 py-1 text-xs font-semibold text-primary"
          >
            <Plus className="h-3 w-3" /> Adicionar
          </button>
        </div>

        {rows.length === 0 && (
          <p className="text-xs leading-relaxed text-muted-foreground">
            Escreve os produtos e preços que estás a ver (ou usa as sugestões abaixo).
            O Aura diz a ordem certa para caber no teu dinheiro.
          </p>
        )}

        <div className="flex flex-col gap-2">
          {rows.map((row, i) => (
            <motion.div key={i} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="flex items-center gap-2">
              <input
                value={row.name}
                onChange={(e) => updateRow(i, { name: e.target.value })}
                placeholder="Ex: Shampoo Seda"
                className="h-11 min-w-0 flex-1 rounded-xl border border-border bg-surface px-3 text-sm outline-none focus:border-primary/50"
              />
              <div className="flex h-11 w-24 shrink-0 items-center gap-1 rounded-xl border border-border bg-surface px-2 focus-within:border-primary/50">
                <span className="text-xs text-muted-foreground">{country.symbol}</span>
                <input
                  value={row.price}
                  onChange={(e) => updateRow(i, { price: e.target.value })}
                  type="number"
                  inputMode="decimal"
                  min={0}
                  placeholder="0"
                  className="w-full bg-transparent text-sm tabular-nums outline-none placeholder:text-muted-foreground/40"
                />
              </div>
              <button
                onClick={() => removeRow(i)}
                className="grid h-9 w-9 shrink-0 place-items-center rounded-xl text-muted-foreground transition-colors hover:bg-surface-strong hover:text-destructive"
                aria-label="Remover produto"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </motion.div>
          ))}
        </div>

        {/* Sugestões da sua prioridade */}
        {hints.length > 0 && (
          <div className="mt-3 flex flex-wrap gap-2">
            {hints.map((h) => (
              <button
                key={h.label}
                onClick={() => addRow(h.label)}
                className="rounded-full border border-border bg-surface px-3 py-1.5 text-xs text-muted-foreground transition-colors hover:border-primary/40 hover:text-foreground"
              >
                <span className="mr-1">+</span>
                {h.label}
                <span className="ml-1 text-[10px] text-muted-foreground/60">({h.examples})</span>
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Botão priorizar */}
      <motion.button
        whileTap={{ scale: 0.97 }}
        disabled={!canRun || loading}
        onClick={runPrioritize}
        className={cn(
          'flex h-13 items-center justify-center gap-2 rounded-2xl px-6 py-3.5 text-base font-semibold transition-opacity',
          canRun && !loading ? 'bg-aura text-primary-foreground glow' : 'bg-surface-strong text-muted-foreground',
          (!canRun || loading) && 'cursor-not-allowed opacity-50',
        )}
      >
        {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : <Sparkles className="h-5 w-5" />}
        {loading ? 'Aura está a pensar...' : 'Priorizar com o meu dinheiro'}
      </motion.button>

      {/* Resultado */}
      <AnimatePresence>
        {plan && plan.items.length > 0 && (
          <PlanResults plan={plan} budget={budgetNum} country={country} />
        )}
      </AnimatePresence>
    </div>
  );
}

// ============================================================
// MODO MARCAS ACESSÍVEIS
// ============================================================

function BrandsMode({ country }: { country: CountryInfo }) {
  const { profile } = useAura();
  const [brands, setBrands] = useState<ShoppingBrand[] | null>(null);
  const [advice, setAdvice] = useState('');
  const [source, setSource] = useState<'gemini' | 'zai' | 'local'>('local');
  const [loading, setLoading] = useState(false);
  const [loaded, setLoaded] = useState(false);

  const load = async () => {
    setLoading(true);
    logEvent('shopping_brands', { country: country.code });
    const res = await consultShoppingAdvisor({ mode: 'brands', profile, country: country.code });
    if (res?.brands?.length) {
      setBrands(res.brands);
      setAdvice(res.advice || '');
      setSource(res.source);
    } else {
      setBrands(null);
      setAdvice('');
    }
    setLoading(false);
    setLoaded(true);
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="glass rounded-2xl p-4 text-center">
        <MapPin className="mx-auto mb-2 h-5 w-5 text-primary" />
        <p className="text-sm font-semibold">Marcas acessíveis em {country.name}</p>
        <p className="mt-1 text-xs text-muted-foreground">
          Encontradas em supermercados e farmácias — boas para a tua carteira
        </p>
        <button
          onClick={load}
          disabled={loading}
          className="mt-3 inline-flex items-center gap-2 rounded-2xl bg-aura px-5 py-2.5 text-sm font-semibold text-primary-foreground glow disabled:opacity-50"
        >
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Sparkles className="h-4 w-4" />}
          {brands ? 'Atualizar' : 'Ver marcas'}
        </button>
      </div>

      {brands && (
        <>
          <div className="flex justify-center">
            <SourceBadge source={source} />
          </div>
          <div className="flex flex-col gap-2.5">
            {brands.map((b, i) => (
              <motion.div
                key={b.name}
                initial={{ x: 30, opacity: 0 }}
                animate={{ x: 0, opacity: 1 }}
                transition={{ delay: i * 0.05, type: 'spring', stiffness: 300, damping: 28 }}
                className="glass flex items-start gap-3 rounded-2xl p-4"
              >
                <div className="grid h-9 w-9 shrink-0 place-items-center rounded-xl bg-aura/15 text-xs font-bold text-primary">
                  {b.name.slice(0, 2).toUpperCase()}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-sm font-semibold">{b.name}</span>
                    <span className="text-[10px] uppercase tracking-wider text-muted-foreground">{b.domain}</span>
                  </div>
                  <p className="mt-0.5 text-xs leading-relaxed text-muted-foreground">{b.why}</p>
                </div>
                <span
                  className={cn(
                    'shrink-0 rounded-full px-2 py-0.5 text-[10px] font-bold',
                    b.priceLevel === 1 ? 'bg-primary/15 text-primary' : 'bg-gold/15 text-gold',
                  )}
                >
                  {b.priceLevel === 1 ? '€' : '€€'}
                </span>
              </motion.div>
            ))}
          </div>
          {advice && (
            <div className="glass rounded-2xl border border-gold/25 p-4">
              <div className="mb-1 flex items-center gap-2">
                <Zap className="h-3.5 w-3.5 text-gold" />
                <span className="text-xs font-bold uppercase tracking-wider text-gold">Dica local</span>
              </div>
              <p className="text-sm leading-relaxed">{advice}</p>
            </div>
          )}
        </>
      )}

      {loaded && !brands && !loading && (
        <p className="text-center text-xs text-muted-foreground">
          Nada disponível agora — tenta outra vez em instantes.
        </p>
      )}
    </div>
  );
}

// ============================================================
// MODO FOTO DA PRATELEIRA
// ============================================================

function PhotoMode({ country, onSendToBudget }: { country: CountryInfo; onSendToBudget: (rows: RowProduct[]) => void }) {
  const { profile } = useAura();
  const fileRef = useRef<HTMLInputElement>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [mimeType, setMimeType] = useState('image/jpeg');
  const [base64, setBase64] = useState<string | null>(null);
  const [budget, setBudget] = useState('');
  const [detected, setDetected] = useState<{ name: string; brand?: string; price: number; domain: string }[] | null>(null);
  const [observations, setObservations] = useState('');
  const [source, setSource] = useState<'gemini' | 'zai' | 'local'>('local');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setMimeType(file.type || 'image/jpeg');
    const reader = new FileReader();
    reader.onloadend = () => {
      const dataUrl = reader.result as string;
      setPreview(dataUrl);
      setBase64(dataUrl.split(',')[1] || null);
      setDetected(null);
      setError('');
    };
    reader.readAsDataURL(file);
  };

  const analyze = async () => {
    if (!base64) return;
    setLoading(true);
    setError('');
    logEvent('shopping_photo_analyze');

    const res = await consultShoppingAdvisor({
      mode: 'photo',
      profile,
      country: country.code,
      budget: Number(budget) || undefined,
      imageBase64: base64,
      mimeType,
    });

    if (res?.products) {
      setDetected(res.products);
      setObservations(res.observations || '');
      setSource(res.source);
    } else {
      setError('Não foi possível ler a foto agora. Tenta tirar outra com boa luz, ou digita os produtos no modo Orçamento.');
    }
    setLoading(false);
  };

  const sendToBudget = () => {
    if (!detected?.length) return;
    onSendToBudget(detected.map((p) => ({ name: `${p.brand ? p.brand + ' ' : ''}${p.name}`, price: p.price ? String(p.price) : '', brand: p.brand })));
  };

  return (
    <div className="flex flex-col gap-4">
      {/* Captura */}
      <div className="glass rounded-2xl p-4">
        <div className="mb-3 flex items-center gap-2">
          <ScanLine className="h-4 w-4 text-primary" />
          <span className="text-sm font-semibold">Fotografa a prateleira</span>
        </div>
        <p className="mb-3 text-xs leading-relaxed text-muted-foreground">
          Tira uma foto dos produtos na loja. O Aura lê os nomes e preços e depois ordena
          o que vale comprar primeiro.
        </p>

        <input ref={fileRef} type="file" accept="image/*" capture="environment" onChange={handleFile} className="hidden" />
        <button
          onClick={() => fileRef.current?.click()}
          className="flex h-32 w-full flex-col items-center justify-center gap-2 rounded-2xl border border-dashed border-border bg-surface transition-colors hover:border-primary/40"
        >
          {preview ? (
            <img src={preview} alt="Foto da prateleira" className="h-full w-full rounded-2xl object-cover" />
          ) : (
            <>
              <Camera className="h-8 w-8 text-primary" />
              <span className="text-sm font-medium text-muted-foreground">Tirar foto / escolher da galeria</span>
            </>
          )}
        </button>

        <div className="mt-3 flex items-center gap-3 rounded-xl border border-border bg-surface px-4 focus-within:border-primary/60">
          <span className="text-sm font-bold text-primary">{country.symbol}</span>
          <input
            type="number"
            inputMode="decimal"
            min={0}
            value={budget}
            onChange={(e) => setBudget(e.target.value)}
            placeholder="Teu orçamento (opcional)"
            className="h-11 flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground/40"
          />
        </div>

        <motion.button
          whileTap={{ scale: 0.97 }}
          disabled={!base64 || loading}
          onClick={analyze}
          className={cn(
            'mt-3 flex h-12 w-full items-center justify-center gap-2 rounded-2xl text-sm font-semibold',
            base64 && !loading ? 'bg-aura text-primary-foreground glow' : 'bg-surface-strong text-muted-foreground opacity-50',
          )}
        >
          {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <ImageIcon className="h-4 w-4" />}
          {loading ? 'A ler a prateleira...' : 'Ler produtos da foto'}
        </motion.button>

        {error && (
          <p className="mt-2 rounded-xl bg-destructive/10 p-3 text-xs leading-relaxed text-destructive">{error}</p>
        )}
      </div>

      {/* Produtos detectados */}
      {detected && (
        <motion.div initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="flex flex-col gap-3">
          <div className="flex justify-center">
            <SourceBadge source={source} />
          </div>
          {observations && (
            <p className="text-center text-xs text-muted-foreground">{observations}</p>
          )}
          {detected.length === 0 ? (
            <p className="text-center text-xs text-muted-foreground">
              Nenhum produto reconhecido com certeza. Tenta uma foto mais próxima dos rótulos.
            </p>
          ) : (
            <>
              <div className="glass flex flex-col gap-2 rounded-2xl p-4">
                <span className="mb-1 text-xs font-bold uppercase tracking-wider text-muted-foreground">
                  {detected.length} produtos encontrados
                </span>
                {detected.map((p, i) => (
                  <div key={i} className="flex items-center justify-between gap-2 border-b border-border py-1.5 last:border-0">
                    <div className="min-w-0">
                      <span className="block truncate text-sm font-medium">{p.name}</span>
                      {p.brand && <span className="text-[10px] text-muted-foreground">{p.brand}</span>}
                    </div>
                    <span className="shrink-0 text-xs font-bold text-gold">
                      {p.price > 0 ? formatMoney(p.price, country) : '—'}
                    </span>
                  </div>
                ))}
              </div>

              <motion.button
                whileTap={{ scale: 0.97 }}
                onClick={sendToBudget}
                className="flex h-13 items-center justify-center gap-2 rounded-2xl bg-aura px-6 py-3.5 text-base font-semibold text-primary-foreground glow"
              >
                Priorizar com meu orçamento <ArrowRight className="h-5 w-5" />
              </motion.button>
            </>
          )}
        </motion.div>
      )}
    </div>
  );
}

// ============================================================
// TELA PRINCIPAL
// ============================================================

export default function ShoppingScreen() {
  const { profile, update } = useAura();
  const [mode, setMode] = useState<Mode>('budget');
  const [budgetRows, setBudgetRows] = useState<RowProduct[]>([]);
  const country = useMemo(() => resolveCountry(profile.country), [profile.country]);

  // Detecta país se ainda não está no perfil
  React.useEffect(() => {
    if (!profile.country) {
      const detected = detectCountry();
      if (detected.code !== 'XX') update({ country: detected.code });
    }
  }, [profile.country, update]);

  const modes: { id: Mode; label: string; icon: typeof Wallet }[] = [
    { id: 'budget', label: 'Orçamento', icon: Wallet },
    { id: 'brands', label: 'Marcas', icon: Tag },
    { id: 'photo', label: 'Foto', icon: Camera },
  ];

  const handleSendToBudget = (rows: RowProduct[]) => {
    setBudgetRows(rows);
    setMode('budget');
  };

  return (
    <div className="relative z-10 px-4 max-w-lg mx-auto">
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="flex flex-col gap-4 pb-24 pt-6">
        {/* Cabeçalho */}
        <div>
          <h1 className="text-2xl font-bold">Consultor de Compras</h1>
          <p className="text-sm text-muted-foreground mt-1">
            Estás na loja com dinheiro limitado? Eu digo o que comprar primeiro.
          </p>
        </div>

        {/* País */}
        <div className="flex items-center justify-center gap-1.5 rounded-xl bg-surface/60 py-2 text-xs text-muted-foreground">
          <MapPin className="h-3.5 w-3.5 text-primary" />
          Preços em {country.name} ({country.currency})
        </div>

        {/* Seletor de modo */}
        <div className="glass flex rounded-2xl p-1">
          {modes.map((m) => {
            const Icon = m.icon;
            const active = mode === m.id;
            return (
              <button
                key={m.id}
                onClick={() => setMode(m.id)}
                className={cn(
                  'relative flex flex-1 items-center justify-center gap-1.5 rounded-xl py-2.5 text-xs font-semibold transition-colors',
                  active ? 'text-primary-foreground' : 'text-muted-foreground',
                )}
              >
                {active && (
                  <motion.div
                    layoutId="shop-mode"
                    className="absolute inset-0 rounded-xl bg-aura"
                    transition={{ type: 'spring', stiffness: 400, damping: 32 }}
                  />
                )}
                <Icon className="relative z-10 h-4 w-4" />
                <span className="relative z-10">{m.label}</span>
              </button>
            );
          })}
        </div>

        {/* Conteúdo */}
        <AnimatePresence mode="wait">
          <motion.div
            key={mode}
            initial={{ x: 24, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: -24, opacity: 0 }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
          >
            {mode === 'budget' && (
              <BudgetMode
                country={country}
                initialRows={budgetRows}
                key={JSON.stringify(budgetRows)}
              />
            )}
            {mode === 'brands' && <BrandsMode country={country} />}
            {mode === 'photo' && <PhotoMode country={country} onSendToBudget={handleSendToBudget} />}
          </motion.div>
        </AnimatePresence>
      </motion.div>
    </div>
  );
}
