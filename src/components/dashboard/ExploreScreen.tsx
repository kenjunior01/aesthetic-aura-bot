'use client';

import { motion } from 'framer-motion';
import {
  TrendingUp, Heart, Bookmark, Share2,
  Flame, Star, Eye, Sparkles,
} from 'lucide-react';
import { useAura } from '@/lib/aura-store';
import { GlowButton } from '@/components/aura/ui';

const trendingTopics = [
  {
    id: 't1',
    title: 'Earth Tones Dominam 2025',
    desc: 'Paletas neutras e terrosas são a tendência absoluta da temporada. Combine tons de caramelo, oliva e areia para um look sofisticado.',
    tag: 'Tendência',
    tagColor: 'text-primary',
    icon: Flame,
    gradient: 'from-primary/10 to-primary-glow/10',
  },
  {
    id: 't2',
    title: 'Streetwear vs. Quiet Luxury',
    desc: 'A fusão entre conforto urbano e elegância discreta continua forte. Aposte em peças de qualidade sem logotipos exagerados.',
    tag: 'Estilo',
    tagColor: 'text-gold',
    icon: Star,
    gradient: 'from-gold/10 to-orange-500/10',
  },
  {
    id: 't3',
    title: 'Cuidado Capilar Personalizado',
    desc: 'Rotinas específicas para cada tipo de cabelo ganham força. Conheça seu tipo e crie um protocolo exclusivo.',
    tag: 'Cuidados',
    tagColor: 'text-blue-400',
    icon: Sparkles,
    gradient: 'from-blue-500/10 to-teal-500/10',
  },
  {
    id: 't4',
    title: 'Moda Sustentável',
    desc: 'Marcas conscientes e peças atemporais estão redefinindo o consumo. Qualidade sobre quantidade.',
    tag: 'Sustentabilidade',
    tagColor: 'text-green-400',
    icon: Heart,
    gradient: 'from-green-500/10 to-emerald-500/10',
  },
];

const styleTips = [
  { id: 'tip1', title: 'Regra do 3', desc: 'Combine no máximo 3 cores por look para harmonia visual', icon: '🎯' },
  { id: 'tip2', title: 'Camadas com propósito', desc: 'Use sobreposições que adicionem textura e profundidade', icon: '🧅' },
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

function TrendCard({ topic, index }: { topic: typeof trendingTopics[0]; index: number }) {
  const Icon = topic.icon;
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
        <button className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors">
          <Heart className="h-3 w-3" /> Salvar
        </button>
        <button className="flex items-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors">
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

export default function ExploreScreen() {
  const { profile, toggleFavorite, favorites } = useAura();

  return (
    <div className="relative z-10 px-4 pt-6 pb-24 max-w-lg mx-auto">
      <motion.div initial={{ y: -20, opacity: 0 }} animate={{ y: 0, opacity: 1 }}>
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold">Explorar</h1>
            <p className="text-sm text-muted-foreground mt-0.5">Tendências e dicas para você</p>
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
              Conteúdo selecionado com base no seu perfil {profile.styles.map(s => s).join(', ')}
            </p>
          </div>
        )}

        {/* Trending */}
        <section className="mb-8">
          <h2 className="text-sm font-semibold uppercase tracking-widest text-muted-foreground mb-4">
            Em alta
          </h2>
          <div className="flex flex-col gap-4">
            {trendingTopics.map((topic, i) => (
              <TrendCard key={topic.id} topic={topic} index={i} />
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
    </div>
  );
}
