'use client';

import { motion } from 'framer-motion';
import { Home, Shirt, Compass, User, Zap, ShoppingBag } from 'lucide-react';
import { cn } from '@/lib/utils';

type Tab = 'home' | 'activities' | 'market' | 'closet' | 'explore' | 'profile';

export type { Tab };

const tabs: { id: Tab; label: string; icon: typeof Home }[] = [
  { id: 'home', label: 'Início', icon: Home },
  { id: 'activities', label: 'Dia', icon: Zap },
  { id: 'market', label: 'Mercado', icon: ShoppingBag },
  { id: 'closet', label: 'Armário', icon: Shirt },
  { id: 'explore', label: 'Explorar', icon: Compass },
  { id: 'profile', label: 'Perfil', icon: User },
];

export default function BottomNav({
  active,
  onChange,
}: {
  active: Tab;
  onChange: (tab: Tab) => void;
}) {
  return (
    <nav className='pointer-events-none fixed inset-x-0 bottom-0 z-50 px-4 pb-[max(0.75rem,env(safe-area-inset-bottom))]'>
      <div className='glass-deep pointer-events-auto mx-auto flex h-[4.25rem] max-w-lg items-center justify-around rounded-[1.4rem] px-1.5'>
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = active === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onChange(tab.id)}
              className={cn(
                'relative flex h-full w-[3.4rem] flex-col items-center justify-center gap-1 transition-colors duration-200',
                isActive ? 'text-primary' : 'text-muted-foreground/80 active:text-foreground',
              )}
              aria-label={tab.label}
              aria-current={isActive ? 'page' : undefined}
            >
              {/* Notch de precisão — marcação usinada do item ativo */}
              {isActive && (
                <motion.span
                  layoutId='nav-notch'
                  transition={{ type: 'spring', stiffness: 420, damping: 32 }}
                  className='absolute top-2 h-[2px] w-4 rounded-full bg-aura'
                />
              )}
              {/* Base do ativo: micro-plataforma sob o ícone */}
              {isActive && (
                <motion.span
                  layoutId='nav-base'
                  transition={{ type: 'spring', stiffness: 420, damping: 32 }}
                  className='absolute inset-x-2 bottom-2 top-2 rounded-xl bg-primary/[0.07]'
                />
              )}
              <Icon
                className={cn('relative h-[1.15rem] w-[1.15rem] transition-transform', isActive && 'scale-[1.04]')}
                strokeWidth={isActive ? 2.2 : 1.8}
              />
              <span
                className={cn(
                  'relative text-[8px] font-semibold uppercase tracking-[0.14em]',
                  isActive ? 'text-primary' : 'text-muted-foreground/70',
                )}
              >
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}
