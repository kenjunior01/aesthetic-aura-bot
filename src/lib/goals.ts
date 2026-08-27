/**
 * AuraStyle — Metas/Prioridades do usuário (fonte única)
 *
 * A 1ª prioridade escolhida no onboarding comanda a tela inicial,
 * os desafios diários e o Consultor de Compras.
 */
import {
  Sparkles, Droplets, ShoppingBag, Shirt, CalendarCheck, Heart,
} from 'lucide-react';
import type { LucideIcon } from 'lucide-react';

export type GoalOption = {
  id: string;
  label: string;
  desc: string;
  icon: LucideIcon;
  /** Como o foco diário aparece na tela inicial */
  focusLine: string;
};

export const GOAL_OPTIONS: GoalOption[] = [
  {
    id: 'cabelo',
    label: 'Cabelo saudável',
    desc: 'Tratamentos e rotina capilar',
    icon: Sparkles,
    focusLine: 'Hoje o foco é o teu cabelo: 5 minutos de tratamento valem mais que 1 hora no sábado.',
  },
  {
    id: 'pele',
    label: 'Pele radiante',
    desc: 'Skincare que funciona',
    icon: Droplets,
    focusLine: 'Hoje o foco é a tua pele: limpeza + hidratação, sem pular o protetor solar.',
  },
  {
    id: 'compras',
    label: 'Comprar inteligente',
    desc: 'Prioridade no orçamento',
    icon: ShoppingBag,
    focusLine: 'Hoje o foco é o teu bolso: antes de comprar, consulta o teu plano de prioridades no Mercado.',
  },
  {
    id: 'estilo',
    label: 'Estilo & looks',
    desc: 'Roupas e combinações',
    icon: Shirt,
    focusLine: 'Hoje o foco é o teu estilo: monta um look com 3 peças que já tens no Armário.',
  },
  {
    id: 'rotina',
    label: 'Rotina & constância',
    desc: 'Hábitos diários',
    icon: CalendarCheck,
    focusLine: 'Hoje o foco é a constância: completa os teus desafios diários e mantém o streak.',
  },
  {
    id: 'corpo',
    label: 'Corpo & bem-estar',
    desc: 'Energia e saúde',
    icon: Heart,
    focusLine: 'Hoje o foco é o teu bem-estar: água, movimento e descanso — o brilho começa aí.',
  },
];

export function getGoal(id: string): GoalOption | undefined {
  return GOAL_OPTIONS.find((g) => g.id === id);
}
