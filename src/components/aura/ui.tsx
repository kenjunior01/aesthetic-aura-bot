'use client';

import { motion } from 'framer-motion';
import { Check } from 'lucide-react';
import type { ReactNode } from 'react';
import { cn } from '@/lib/utils';

export function GlowButton({
  children,
  onClick,
  disabled,
  variant = 'primary',
  className,
  type = 'button',
}: {
  children: ReactNode;
  onClick?: () => void;
  disabled?: boolean;
  variant?: 'primary' | 'ghost' | 'outline';
  className?: string;
  type?: 'button' | 'submit';
}) {
  return (
    <motion.button
      type={type}
      whileTap={{ scale: 0.97 }}
      whileHover={{ scale: disabled ? 1 : 1.02 }}
      onClick={onClick}
      disabled={disabled}
      className={cn(
        'relative inline-flex h-13 items-center justify-center gap-2 overflow-hidden rounded-2xl px-6 py-3.5 text-base font-semibold transition-opacity disabled:cursor-not-allowed disabled:opacity-40',
        variant === 'primary' &&
          'bg-aura text-primary-foreground shadow-[0_14px_30px_-12px_oklch(0.87_0.07_72/0.5),inset_0_1px_0_oklch(0.99_0.01_85/0.4),inset_0_-2px_6px_-2px_oklch(0.55_0.05_65/0.45)]',
        variant === 'outline' && 'glass text-foreground',
        variant === 'ghost' && 'text-muted-foreground hover:text-foreground',
        className,
      )}
    >
      {children}
    </motion.button>
  );
}

export function SelectCard({
  selected,
  onClick,
  children,
  className,
}: {
  selected: boolean;
  onClick: () => void;
  children: ReactNode;
  className?: string;
}) {
  return (
    <motion.button
      type="button"
      onClick={onClick}
      whileTap={{ scale: 0.95 }}
      animate={{ scale: selected ? 1.02 : 1 }}
      transition={{ type: 'spring', stiffness: 400, damping: 24 }}
      className={cn(
        'glass relative flex flex-col items-center justify-center gap-2 rounded-2xl p-3 text-center transition-colors',
        selected && 'border-primary/70 bg-surface-strong glow',
        className,
      )}
    >
      {selected && (
        <motion.span
          initial={{ scale: 0, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          className="absolute right-2 top-2 grid h-5 w-5 place-items-center rounded-full bg-aura shadow-[inset_0_1px_0_oklch(0.99_0.01_85/0.4)]"
        >
          <Check className="h-3 w-3 text-primary-foreground" strokeWidth={3} />
        </motion.span>
      )}
      {children}
    </motion.button>
  );
}

export function Chip({
  selected,
  onClick,
  children,
}: {
  selected: boolean;
  onClick: () => void;
  children: ReactNode;
}) {
  return (
    <motion.button
      type="button"
      whileTap={{ scale: 0.94 }}
      onClick={onClick}
      className={cn(
        'inline-flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-medium transition-all',
        selected
          ? 'border-transparent bg-aura text-primary-foreground shadow-[0_8px_18px_-8px_oklch(0.87_0.07_72/0.5),inset_0_1px_0_oklch(0.99_0.01_85/0.4)]'
          : 'border-border bg-surface text-muted-foreground hover:text-foreground',
      )}
    >
      {children}
    </motion.button>
  );
}

export function FloatingInput({
  label,
  value,
  onChange,
  type = 'text',
  list,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  type?: string;
  list?: string;
}) {
  return (
    <div className="relative">
      <input
        id={label}
        type={type}
        list={list}
        value={value}
        placeholder=" "
        onChange={(e) => onChange(e.target.value)}
        className="peer h-16 w-full rounded-2xl border border-border bg-surface px-4 pt-6 text-base text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong"
      />
      <label
        htmlFor={label}
        className="pointer-events-none absolute left-4 top-2 text-xs font-medium text-muted-foreground transition-all peer-placeholder-shown:top-5 peer-placeholder-shown:text-base peer-focus:top-2 peer-focus:text-xs peer-focus:text-primary"
      >
        {label}
      </label>
    </div>
  );
}

export function SectionTitle({ title, hint }: { title: string; hint?: string }) {
  return (
    <div className="mb-3">
      <h3 className="text-sm font-semibold uppercase tracking-widest text-foreground/90">
        {title}
      </h3>
      {hint && <p className="mt-1 text-xs text-muted-foreground">{hint}</p>}
    </div>
  );
}
