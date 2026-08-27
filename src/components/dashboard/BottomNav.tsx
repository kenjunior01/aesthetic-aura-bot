'use client';

import { motion } from 'framer-motion';
import { Home, Shirt, Compass, User, Zap, ShoppingBag } from 'lucide-react';
import { cn } from '@/lib/utils';

type Tab = 'home' | 'activities' | 'market' | 'closet' | 'explore' | 'profile';

export type { Tab };

const tabs: { id: Tab; label: string; icon: typeof Home }[] = [
  { id: 'home', label: 'Início', icon: Home },
  { id: 'activities', label: 'Atividades', icon: Zap },
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
    <nav className="fixed bottom-0 left-0 right-0 z-50 glass border-t border-border">
      <div className="flex items-center justify-around h-16 max-w-lg mx-auto">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = active === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => onChange(tab.id)}
              className={cn(
                'relative flex flex-col items-center gap-0.5 py-1 px-1.5 transition-colors',
                isActive ? 'text-foreground' : 'text-muted-foreground',
              )}
            >
              {isActive && (
                <motion.div
                  layoutId="nav-indicator"
                  className="absolute -top-px left-1.5 right-1.5 h-0.5 rounded-full bg-aura"
                  transition={{ type: 'spring', stiffness: 400, damping: 30 }}
                />
              )}
              <Icon className={cn('h-5 w-5', isActive && 'text-primary')} strokeWidth={isActive ? 2.5 : 2} />
              <span className={cn('text-[10px] font-medium', isActive && 'text-primary')}>
                {tab.label}
              </span>
            </button>
          );
        })}
      </div>
      {/* Safe area bottom for iOS */}
      <div className="h-[env(safe-area-inset-bottom)]" />
    </nav>
  );
}