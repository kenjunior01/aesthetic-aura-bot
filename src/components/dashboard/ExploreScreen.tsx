'use client';

import { motion, AnimatePresence } from 'framer-motion';
import {
  TrendingUp, Heart, Share2,
  Flame, Star, Sparkles, ShoppingCart,
  MapPin, ExternalLink, Check,
} from 'lucide-react';
import { useAura } from '@/lib/aura-store';
import {
  getProductsForRegion,
  productCategoryConfig,
  type RegionalProduct,
} from '@/lib/aura-data';
import { cn } from '@/lib/utils';
import { useState, useMemo, useCallback } from 'react';

// ... (keeping all existing data and components, updating TrendCard and adding Toast)

const trendingTopics = [
  {
    id: 't1',
    title: 'Earth Tones Dominam 2025',
    desc: 'Paletas neutras e terrosas são a tendência absoluta da temporada. Combine tons de caramelo, oliva e areia para um look sofisticado que funciona em qualquer contexto.',
    tag: 'Tendência',
    tagColor: 'text-primary',
    icon: Flame,
    gradient: 'from-primary/10 to-primary-glow/10',
  },
  {
    id: 't2',
    title: 'Streetwear vs. Quiet Luxury',
    desc: 'A fusão entre conforto urbano e elegância discreta continua forte. Aposte em peças de qualidade sem logotipos exagerados para um visual sofisticado.',
    tag: 'Estilo',
    tagColor: 'text-gold',
    icon: Star,
    gradient: 'from-gold/15 to-primary-glow/10',
  },
  {
    id: 't3',
    title: 'Cuidado Capilar Personalizado',
    desc: 'Rotinas específicas para cada tipo de cabelo ganham força. Conheça seu tipo e crie um protocolo exclusivo que funcione para suas necessidades reais.',
    tag: 'Cuidados',
    tagColor: 'text-accent',
    icon: Sparkles,
    gradient: 'from-accent/10 to-primary-glow/10',
  },
  {
    id: 't4',
    title: 'Moda Sustentável',
    desc: 'Marcas conscientes e peças atemporais estão redefinindo o consumo. Qualidade sobre quantidade é o novo lema da moda inteligente.',
    tag: 'Sustentabilidade',
    tagColor: 'text-green-400',
    icon: Heart,
    gradient: 'from-green-500/10 to-emerald-500/10',
  },
];

const styleTips = [
  { id: 'tip1', title: 'Regra do 3', desc: 'Combine no máximo 3 cores por look para harmonia visual', icon: '🎯' },
  { id: 'tip2', title: 'Camadas com propósito', desc: 'Use sobreposições que adicionem textura e profundidade ao visual', icon: '🧅' },
  { id: 'tip3', title: 'Acessórios transformam', desc: 'Um bom relógio, cinto ou colar eleva qualquer look básico', icon: '💎' },
  { id: 'tip4', title: 'Sapatos são protagonistas', desc: 'Invista em calçados versáteis: branco, preto e marrom', icon: '👟' },
  { id: 'tip5', title: 'Fit é tudo', desc: 'Roupas no tamanho certo fazem mais diferença que a marca', icon: '📏' },
  { id: 'tip6', title: 'Identifique seu uniforme', desc: 'Descubra o combo que te faz sentir confiante e repita com variações', icon: '✨' },
];

const seasonalPicks = [
  { id: 's1', title: 'Blazer oversized', reason: 'Versátil do casual ao formal', emoji: '🧥' },
  { id: 's2', title: 'Tênis minimalista branco', reason: 'Funciona com tudo', emoji: '👟' },
  { id: 's3', title: 'Calça wide leg', reason: 'Conforto e elegância', emoji: '👖' },
  { id: 's4', title: 'Camiseta oversized preta', reason: 'Base infinita do armário', emoji: '👕' },
  { id: 's5', title: 'Óculos de sol vintage', reason: 'Acessório com personalidade', emoji: '🕶️' },
];

// ============================================================
// TOAST NOTIFICATION
// ============================================================

function Toast({ message, visible }: { message: string; visible: boolean }) {
  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          initial={{ opacity: 0, y: 20, scale: 0.9 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: 20, scale: 0.9 }}
          className="fixed bottom-24 left-4 right-4 z-50 max-w-lg mx-auto glass rounded-2xl p-3 flex items-center gap-3 glow"
        >
          <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-green-500/20">
            <Check className="h-4 w-4 text-green-400" />
          </div>
          <span className="text-sm font-medium flex-1">{message}</span>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

function TipCard({ tip }: { tip: typeof styleTips[0] }) {
  return (
    <motion.div
      whileTap={{ scale: 0.98 }}
      className="glass rounded-2xl p-4 flex gap-3 items-start cursor-pointer"
    >
      <span className="text-2xl mt-0.5">{tip.icon}</span>
      <div>
        <span className="text-sm font-semibold block">{tip.title}</span>
        <span className="text-xs text-muted-foreground leading-relaxed block mt-0.5">{tip.desc}</span>
      </div>
    </motion.div>
  );
}

function TrendCard({ topic, index, onToast }: { topic: typeof trendingTopics[0]; index: number; onToast: (msg: string) => void }) {
  const Icon = topic.icon;
  const [saved, setSaved] = useState(false);

  const handleSave = (e: React.MouseEvent) => {
    e.stopPropagation();
    setSaved(true);
    onToast('Salvo nos favoritos!');
  };

  const handleShare = async (e: React.MouseEvent) => {
    e.stopPropagation();
    const text = `${topic.title} - Descobri no AuraStyle 🔥`;
    if (navigator.share) {
      try { await navigator.share({ title: topic.title, text }); } catch { /* cancelled */ }
    } else {
      await navigator.clipboard.writeText(text);
      onToast('Link copiado!');
    }
  };

  return (
    <motion.div
      initial={{ x: 40, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      transition={{ delay: index * 0.1, type: 'spring', stiffness: 300, damping: 30 }}
      className={`glass rounded-2xl p-5 bg-gradient-to-br ${topic.gradient} cursor-pointer hover:border-primary/30 transition-colors`}
    >
      <div className="flex items-start justify-between mb-3">
        <span className={`text-[10px] uppercase tracking-wider font-semibold ${topic.tagColor}`}>
          {topic.tag}
        </span>
        <Icon className="h-4 w-4 text-muted-foreground" />
      </div>
      <h3 className="text-base font-bold mb-2">{topic.title}</h3>
      <p className="text-xs text-muted-foreground leading-relaxed">{topic.desc}</p>
      <div className="flex items-center gap-4 mt-4 pt-3 border-t border-border">
        <button
          onClick={handleSave}
          className={cn('flex items-center gap-1 text-xs transition-colors', saved ? 'text-primary font-medium' : 'text-muted-foreground hover:text-foreground')}
        >
          <Heart className={cn('h-3 w-3', saved && 'fill-primary')} /> {saved ? 'Salvo' : 'Salvar'}
        </button>
        <button onClick={handleShare} className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors">
          <Share2 className="h-3 w-3" /> Compartilhar
        </button>
      </div>
    </motion.div>
  );
}

function SeasonalCard({ item }: { item: typeof seasonalPicks[0] }) {
  return (
    <motion.div
      whileTap={{ scale: 0.96 }}
      className="glass rounded-2xl p-4 min-w-[150px] flex-shrink-0 cursor-pointer"
    >
      <span className="text-2xl block mb-2">{item.emoji}</span>
      <span className="text-sm font-semibold block">{item.title}</span>
      <span className="text-[10px] text-muted-foreground block mt-0.5">{item.reason}</span>
    </motion.div>
  );
}

// ============================================================
// REGIONAL PRODUCT CARD
// ============================================================

function ProductCard({ product }: { product: RegionalProduct }) {
  const catConfig = productCategoryConfig[product.category] || { label: product.category, emoji: '📦' };
  const stars = Math.floor(product.rating);
  const hasHalf = product.rating - stars >= 0.3;

  return (
    <motion.div
      whileTap={{ scale: 0.98 }}
      className="glass rounded-2xl p-4 flex gap-3 items-start cursor-pointer hover:border-primary/30 transition-colors"
    >
      <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-surface-strong text-2xl">
        {catConfig.emoji}
      </div>
      <div className="flex-1 min-w-0">
        <div className="flex items-start justify-between gap-2">
          <div>
            <span className="text-sm font-semibold block leading-tight">{product.name}</span>
            <span className="text-[10px] text-muted-foreground block mt-0.5">{product.brand}</span>
          </div>
          <div className="text-right shrink-0">
            <span className="text-sm font-bold text-primary block">
              {product.currency} {product.price.toLocaleString('pt-BR', { minimumFractionDigits: product.price < 100 ? 2 : 0 })}
            </span>
            <div className="flex items-center gap-0.5 justify-end mt-0.5">
              {Array.from({ length: 5 }).map((_, i) => (
                <Star
                  key={i}
                  className={cn(
                    'h-2.5 w-2.5',
                    i < stars ? 'text-gold fill-gold' : i === stars && hasHalf ? 'text-gold' : 'text-muted-foreground/30',
                  )}
                />
              ))}
            </div>
          </div>
        </div>
        <p className="text-xs text-muted-foreground leading-relaxed mt-1.5 line-clamp-2">{product.description}</p>
        <div className="flex items-center justify-between mt-3 pt-2 border-t border-border">
          <div className="flex items-center gap-1 text-[10px] text-muted-foreground">
            <MapPin className="h-3 w-3" /> {product.store}
          </div>
          <div className="flex items-center gap-2">
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-surface-strong text-muted-foreground capitalize">
              {catConfig.label}
            </span>
            <button className="flex items-center gap-1 text-[10px] text-primary font-medium">
              Ver <ExternalLink className="h-2.5 w-2.5" />
            </button>
          </div>
        </div>
      </div>
    </motion.div>
  );
}

// ============================================================
// PRODUCT RECOMMENDATIONS SECTION
// ============================================================

function ProductRecommendations({ onToast }: { onToast: (msg: string) => void }) {
  const { profile } = useAura();
  const [filterCategory, setFilterCategory] = useState<string | null>(null);

  const products = useMemo(() => {
    let filtered = getProductsForRegion(
      profile.region,
      profile.budget,
      profile.skinTypes,
      profile.hairType,
    );
    if (filterCategory) {
      filtered = filtered.filter((p) => p.category === filterCategory);
    }
    return filtered;
  }, [profile.region, profile.budget, profile.skinTypes, profile.hairType, filterCategory]);

  const categories = useMemo(() => {
    const cats = new Set(products.map((p) => p.category));
    return [...cats];
  }, [products]);

  if (products.length === 0) {
    return (
      <section className="mb-8">
        <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-4">
          Produtos para Você
        </h2>
        <div className="glass rounded-2xl p-6 text-center">
          <ShoppingCart className="h-8 w-8 text-muted-foreground mx-auto mb-2" />
          <p className="text-sm text-muted-foreground">
            Selecione sua região no perfil para ver recomendações com preços locais.
          </p>
        </div>
      </section>
    );
  }

  return (
    <section className="mb-8">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground">
            Produtos na sua Região
          </h2>
          {profile.region && (
            <span className="text-xs text-muted-foreground/70 mt-0.5 flex items-center gap-1">
              <MapPin className="h-3 w-3" /> {profile.region}
            </span>
          )}
        </div>
        <ShoppingCart className="h-4 w-4 text-primary" />
      </div>

      {/* Category filters */}
      {categories.length > 1 && (
        <div className="flex gap-2 mb-4 overflow-x-auto no-scrollbar -mx-1 px-1">
          <button
            onClick={() => setFilterCategory(null)}
            className={cn(
              'shrink-0 rounded-full border px-3 py-1.5 text-xs font-medium transition-all',
              !filterCategory
                ? 'border-transparent bg-aura text-primary-foreground'
                : 'border-border bg-surface text-muted-foreground',
            )}
          >
            Todos
          </button>
          {categories.map((cat) => {
            const config = productCategoryConfig[cat];
            return (
              <button
                key={cat}
                onClick={() => setFilterCategory(filterCategory === cat ? null : cat)}
                className={cn(
                  'shrink-0 rounded-full border px-3 py-1.5 text-xs font-medium transition-all',
                  filterCategory === cat
                    ? 'border-transparent bg-aura text-primary-foreground'
                    : 'border-border bg-surface text-muted-foreground',
                )}
              >
                {config?.emoji} {config?.label || cat}
              </button>
            );
          })}
        </div>
      )}

      <div className="flex flex-col gap-3">
        {products.map((product, i) => (
          <motion.div
            key={product.id}
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: i * 0.05, type: 'spring', stiffness: 300, damping: 30 }}
          >
            <ProductCard product={product} />
          </motion.div>
        ))}
      </div>
    </section>
  );
}

// ============================================================
// MAIN SCREEN
// ============================================================

export default function ExploreScreen() {
  const { profile } = useAura();
  const [toast, setToast] = useState({ message: '', visible: false });

  const showToast = useCallback((message: string) => {
    setToast({ message, visible: true });
    setTimeout(() => setToast({ message: '', visible: false }), 2000);
  }, []);

  return (
    <div className="relative z-10 px-4 pt-6 pb-24 max-w-lg mx-auto">
      <motion.div initial={{ y: -20, opacity: 0 }} animate={{ y: 0, opacity: 1 }}>
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold">Explorar</h1>
            <p className="text-sm text-muted-foreground mt-0.5">Tendências, produtos e dicas</p>
          </div>
          <div className="flex h-10 w-10 items-center justify-center rounded-xl glass">
            <TrendingUp className="h-5 w-5 text-primary" />
          </div>
        </div>

        {/* Personalized greeting */}
        {profile.styles.length > 0 && (
          <div className="glass rounded-2xl p-4 mb-6 bg-gradient-to-r from-primary/10 to-primary-glow/10">
            <div className="flex items-center gap-2 mb-1">
              <Sparkles className="h-4 w-4 text-gold" />
              <span className="text-xs font-semibold uppercase tracking-wider text-gold">
                Para seu estilo {profile.styles[0]}
              </span>
            </div>
            <p className="text-sm text-muted-foreground leading-relaxed">
              Conteúdo selecionado com base no seu perfil {profile.styles.join(', ')}
            </p>
          </div>
        )}

        {/* Product Recommendations */}
        <ProductRecommendations onToast={showToast} />

        {/* Trending */}
        <section className="mb-8">
          <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-4">
            Em alta
          </h2>
          <div className="flex flex-col gap-4">
            {trendingTopics.map((topic, i) => (
              <TrendCard key={topic.id} topic={topic} index={i} onToast={showToast} />
            ))}
          </div>
        </section>

        {/* Style Tips */}
        <section className="mb-8">
          <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-4">
            Dicas de estilo
          </h2>
          <div className="flex flex-col gap-3">
            {styleTips.map((tip) => (
              <TipCard key={tip.id} tip={tip} />
            ))}
          </div>
        </section>

        {/* Seasonal Essentials */}
        <section>
          <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-4">
            Essentials da temporada
          </h2>
          <div className="flex gap-3 overflow-x-auto no-scrollbar -mx-1 px-1 pb-2">
            {seasonalPicks.map((item) => (
              <SeasonalCard key={item.id} item={item} />
            ))}
          </div>
        </section>
      </motion.div>

      <Toast message={toast.message} visible={toast.visible} />
    </div>
  );
}
