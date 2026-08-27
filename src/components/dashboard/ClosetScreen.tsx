'use client';

import React, { useState, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Plus, X, Camera, Trash2, Shirt,
  ChevronDown, Filter, Grid3X3, LayoutList,
} from 'lucide-react';
import { useAura, type ClosetItem } from '@/lib/aura-store';
import { closetCategories } from '@/lib/aura-data';
import { GlowButton } from '@/components/aura/ui';
import { cn } from '@/lib/utils';

const colorPresets = [
  { id: 'preto', label: 'Preto', color: 'oklch(0.22 0.02 285)' },
  { id: 'branco', label: 'Branco', color: 'oklch(0.97 0.01 285)' },
  { id: 'azul', label: 'Azul', color: 'oklch(0.6 0.19 255)' },
  { id: 'vermelho', label: 'Vermelho', color: 'oklch(0.55 0.2 25)' },
  { id: 'verde', label: 'Verde', color: 'oklch(0.68 0.15 145)' },
  { id: 'amarelo', label: 'Amarelo', color: 'oklch(0.82 0.14 85)' },
  { id: 'rosa', label: 'Rosa', color: 'oklch(0.68 0.18 340)' },
  { id: 'cinza', label: 'Cinza', color: 'oklch(0.65 0.02 250)' },
  { id: 'marrom', label: 'Marrom', color: 'oklch(0.4 0.06 50)' },
  { id: 'roxo', label: 'Roxo', color: 'oklch(0.55 0.22 300)' },
];

function AddItemModal({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const { addClosetItem } = useAura();
  const fileRef = useRef<HTMLInputElement>(null);
  const [name, setName] = useState('');
  const [category, setCategory] = useState(closetCategories[0]);
  const [color, setColor] = useState(colorPresets[0].color);
  const [photo, setPhoto] = useState<string | null>(null);
  const [showCategories, setShowCategories] = useState(false);

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => setPhoto(reader.result as string);
    reader.readAsDataURL(file);
  };

  const handleSave = () => {
    if (!name.trim()) return;
    addClosetItem({
      id: crypto.randomUUID(),
      name: name.trim(),
      category,
      color,
      photo,
    });
    setName('');
    setCategory(closetCategories[0]);
    setColor(colorPresets[0].color);
    setPhoto(null);
    onClose();
  };

  return (
    <AnimatePresence>
      {open && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="fixed inset-0 z-50 flex items-end justify-center"
        >
          <div className="absolute inset-0 bg-black/60" onClick={onClose} />
          <motion.div
            initial={{ y: '100%' }}
            animate={{ y: 0 }}
            exit={{ y: '100%' }}
            transition={{ type: 'spring', stiffness: 300, damping: 30 }}
            className="relative z-10 w-full max-w-lg rounded-t-3xl glass p-6 pb-8 max-h-[85vh] overflow-y-auto"
          >
            {/* Handle bar */}
            <div className="mx-auto mb-4 h-1 w-10 rounded-full bg-muted-foreground/30" />

            <div className="flex items-center justify-between mb-6">
              <h2 className="text-xl font-bold">Adicionar peça</h2>
              <button onClick={onClose} className="p-1 rounded-xl hover:bg-surface-strong">
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Photo upload */}
            <div className="mb-5">
              <label className="text-sm font-semibold uppercase tracking-widest text-muted-foreground block mb-2">
                Foto da peça
              </label>
              {photo ? (
                <div className="relative h-40 rounded-2xl overflow-hidden">
                  <img src={photo} alt="Preview" className="h-full w-full object-cover" />
                  <button
                    onClick={() => setPhoto(null)}
                    className="absolute top-2 right-2 h-8 w-8 rounded-full bg-black/50 flex items-center justify-center"
                  >
                    <X className="h-4 w-4" />
                  </button>
                </div>
              ) : (
                <label className="flex flex-col items-center justify-center gap-2 h-40 rounded-2xl border-2 border-dashed border-border cursor-pointer hover:border-primary/40 transition-colors">
                  <Camera className="h-8 w-8 text-muted-foreground" />
                  <span className="text-sm text-muted-foreground">Tirar foto ou escolher</span>
                  <input
                    ref={fileRef}
                    type="file"
                    accept="image/*"
                    capture="environment"
                    onChange={handleFile}
                    className="hidden"
                  />
                </label>
              )}
            </div>

            {/* Name */}
            <div className="mb-5">
              <label className="text-sm font-semibold uppercase tracking-widest text-muted-foreground block mb-2">
                Nome da peça
              </label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Ex: Camiseta branca básica"
                className="w-full h-14 rounded-2xl border border-border bg-surface px-4 text-sm text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong placeholder:text-muted-foreground/50"
              />
            </div>

            {/* Category */}
            <div className="mb-5">
              <label className="text-sm font-semibold uppercase tracking-widest text-muted-foreground block mb-2">
                Categoria
              </label>
              <div className="relative">
                <button
                  type="button"
                  onClick={() => setShowCategories(!showCategories)}
                  className="w-full h-14 rounded-2xl border border-border bg-surface px-4 flex items-center justify-between text-sm"
                >
                  <span className="flex items-center gap-2">
                    <Shirt className="h-4 w-4 text-primary" />
                    {category}
                  </span>
                  <ChevronDown className={cn('h-4 w-4 transition-transform', showCategories && 'rotate-180')} />
                </button>
                <AnimatePresence>
                  {showCategories && (
                    <motion.div
                      initial={{ opacity: 0, y: -8 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: -8 }}
                      className="absolute top-full left-0 right-0 z-20 mt-1 rounded-2xl glass p-2 flex flex-col gap-1 max-h-48 overflow-y-auto no-scrollbar"
                    >
                      {closetCategories.map((cat) => (
                        <button
                          key={cat}
                          onClick={() => { setCategory(cat); setShowCategories(false); }}
                          className={cn(
                            'rounded-xl px-3 py-2.5 text-sm text-left transition-colors',
                            category === cat ? 'bg-surface-strong text-foreground' : 'text-muted-foreground hover:text-foreground'
                          )}
                        >
                          {cat}
                        </button>
                      ))}
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            </div>

            {/* Color */}
            <div className="mb-6">
              <label className="text-sm font-semibold uppercase tracking-widest text-muted-foreground block mb-2">
                Cor predominante
              </label>
              <div className="flex flex-wrap gap-3">
                {colorPresets.map((c) => (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => setColor(c.color)}
                    className={cn(
                      'h-9 w-9 rounded-full transition-all',
                      color === c.color ? 'ring-2 ring-primary ring-offset-2 ring-offset-background scale-110' : 'opacity-60 hover:opacity-100'
                    )}
                    style={{ backgroundColor: c.color }}
                    title={c.label}
                  />
                ))}
              </div>
            </div>

            <GlowButton onClick={handleSave} disabled={!name.trim()} className="w-full">
              Salvar peça
            </GlowButton>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}

function ClosetItemCard({ item, onDelete }: { item: ClosetItem; onDelete: () => void }) {
  return (
    <motion.div
      layout
      initial={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      exit={{ opacity: 0, scale: 0.9 }}
      className="glass rounded-2xl overflow-hidden group relative"
    >
 {item.photo ? (
        <div className="h-36 bg-surface-strong">
          <img src={item.photo} alt={item.name} className="h-full w-full object-cover" />
        </div>
      ) : (
        <div
          className="h-36 flex items-center justify-center"
          style={{ backgroundColor: `${item.color}20` }}
        >
          <Shirt className="h-10 w-10" style={{ color: item.color }} />
        </div>
      )}
      <div className="p-3">
        <span className="text-sm font-medium block truncate">{item.name}</span>
        <span className="text-[10px] text-muted-foreground uppercase tracking-wider">{item.category}</span>
      </div>
      <button
        onClick={onDelete}
        className="absolute top-2 right-2 h-8 w-8 rounded-full bg-black/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <Trash2 className="h-3.5 w-3.5" />
      </button>
    </motion.div>
  );
}

export default function ClosetScreen() {
  const { closet, removeClosetItem } = useAura();
  const [modalOpen, setModalOpen] = useState(false);
  const [filterCat, setFilterCat] = useState<string | null>(null);
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');

  const filtered = filterCat ? closet.filter((i) => i.category === filterCat) : closet;
  const categoriesInUse = [...new Set(closet.map((i) => i.category))];

  return (
    <div className="relative z-10 px-4 pt-6 pb-24 max-w-lg mx-auto">
      <motion.div initial={{ y: -20, opacity: 0 }} animate={{ y: 0, opacity: 1 }}>
        <div className="flex items-center justify-between mb-6">
          <div>
            <h1 className="text-2xl font-bold">Meu Armário</h1>
            <p className="text-sm text-muted-foreground mt-0.5">{closet.length} peça{closet.length !== 1 ? 's' : ''} cadastrada{closet.length !== 1 ? 's' : ''}</p>
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setViewMode(viewMode === 'grid' ? 'list' : 'grid')}
              className="h-10 w-10 rounded-xl glass flex items-center justify-center text-muted-foreground hover:text-foreground transition-colors"
            >
              {viewMode === 'grid' ? <LayoutList className="h-4 w-4" /> : <Grid3X3 className="h-4 w-4" />}
            </button>
            <GlowButton onClick={() => setModalOpen(true)} className="h-10 w-10 !p-0 !rounded-xl">
              <Plus className="h-5 w-5" />
            </GlowButton>
          </div>
        </div>

        {/* Category filter */}
        {categoriesInUse.length > 1 && (
          <div className="flex items-center gap-2 mb-4 overflow-x-auto no-scrollbar -mx-1 px-1">
            <button
              onClick={() => setFilterCat(null)}
              className={cn(
                'flex items-center gap-1.5 shrink-0 rounded-full border px-3 py-1.5 text-xs font-medium transition-all',
                !filterCat ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
              )}
            >
              <Filter className="h-3 w-3" /> Todas
            </button>
            {categoriesInUse.map((cat) => (
              <button
                key={cat}
                onClick={() => setFilterCat(filterCat === cat ? null : cat)}
                className={cn(
                  'shrink-0 rounded-full border px-3 py-1.5 text-xs font-medium transition-all',
                  filterCat === cat ? 'border-transparent bg-aura text-primary-foreground' : 'border-border bg-surface text-muted-foreground'
                )}
              >
                {cat}
              </button>
            ))}
          </div>
        )}

        {/* Items grid/list */}
        {filtered.length > 0 ? (
          <div className={cn(
            viewMode === 'grid' ? 'grid grid-cols-2 gap-3' : 'flex flex-col gap-3'
          )}>
            <AnimatePresence>
              {filtered.map((item) => (
                <ClosetItemCard
                  key={item.id}
                  item={item}
                  onDelete={() => removeClosetItem(item.id)}
                />
              ))}
            </AnimatePresence>
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center gap-4 py-16">
            <div className="flex h-20 w-20 items-center justify-center rounded-3xl bg-surface-strong">
              <Shirt className="h-10 w-10 text-muted-foreground" />
            </div>
            <div className="text-center">
              <h3 className="text-lg font-semibold">
                {closet.length === 0 ? 'Armário vazio' : 'Nenhum resultado'}
              </h3>
              <p className="text-sm text-muted-foreground mt-1 max-w-xs">
                {closet.length === 0
                  ? 'Adicione suas peças favoritas para criar looks personalizados.'
                  : 'Nenhuma peça nesta categoria.'}
              </p>
            </div>
            {closet.length === 0 && (
              <GlowButton onClick={() => setModalOpen(true)} variant="outline">
                <Plus className="h-4 w-4" /> Adicionar primeira peça
              </GlowButton>
            )}
          </div>
        )}
      </motion.div>

      <AddItemModal open={modalOpen} onClose={() => setModalOpen(false)} />
    </div>
  );
}
