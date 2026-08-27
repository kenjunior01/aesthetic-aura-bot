'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { Gift, Copy, Check, Users, Crown, Share2 } from 'lucide-react';
import { useAura, getLevelInfo } from '@/lib/aura-store';
import { getReferralLink } from '@/lib/services';
import { logEvent } from '@/lib/services';

const referralRewards = [
  { invites: 1, reward: '50 XP', label: 'Iniciante' },
  { invites: 3, reward: 'Conquista exclusiva', label: 'Influencer' },
  { invites: 5, reward: '200 XP + Título', label: 'Estrela' },
  { invites: 10, reward: 'Acesso antecipado', label: 'Lenda' },
  { invites: 25, reward: 'Perfil verificado', label: 'Aura Master' },
];

export default function ReferralSection() {
  const { referralCode, referralCount, xp, profile, incrementReferralCount } = useAura();
  const { level } = getLevelInfo(xp);
  const [copied, setCopied] = useState(false);

  const firstName = profile.name?.split(' ')[0] || 'Estilista';
  const link = referralCode ? getReferralLink(referralCode) : '';

  const handleCopy = async () => {
    if (!link) return;
    await navigator.clipboard.writeText(link);
    setCopied(true);
    logEvent('referral_link_copied');
    setTimeout(() => setCopied(false), 2000);
  };

  const handleShare = async () => {
    const text = `${firstName} te convidou para o AuraStyle! Use meu código ${referralCode} e ganhe bônus. Baixe: ${link}`;
    logEvent('referral_share', { method: 'native_share' });
    if (navigator.share) {
      try { await navigator.share({ title: 'AuraStyle - Convite', text }); } catch { /* cancelled */ }
    } else {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const nextReward = referralRewards.find((r) => r.invites > referralCount);
  const progress = nextReward
    ? referralCount / nextReward.invites
    : 1;

  return (
    <div className="glass rounded-2xl p-5">
      <div className="flex items-center gap-3 mb-4">
        <div className="h-10 w-10 rounded-xl bg-aura flex items-center justify-center">
          <Gift className="h-5 w-5 text-primary-foreground" />
        </div>
        <div>
          <h3 className="text-sm font-bold">Convide amigos</h3>
          <p className="text-[10px] text-muted-foreground">Ganhe recompensas por cada convite</p>
        </div>
      </div>

      {/* Stats */}
      <div className="flex items-center gap-4 mb-4">
        <div className="flex items-center gap-2">
          <Users className="h-4 w-4 text-primary" />
          <span className="text-sm font-bold">{referralCount}</span>
          <span className="text-xs text-muted-foreground">convites</span>
        </div>
        {referralCode && (
          <div className="flex items-center gap-2">
            <Crown className="h-4 w-4 text-gold" />
            <span className="text-xs font-mono text-gold">{referralCode}</span>
          </div>
        )}
      </div>

      {/* Progress to next reward */}
      {nextReward && (
        <div className="mb-4">
          <div className="flex justify-between text-[10px] mb-1">
            <span className="text-muted-foreground">Próximo: {nextReward.label}</span>
            <span className="text-primary font-medium">{referralCount}/{nextReward.invites}</span>
          </div>
          <div className="h-1.5 rounded-full bg-surface-strong overflow-hidden">
            <motion.div
              initial={{ width: 0 }}
              animate={{ width: `${Math.min(progress * 100, 100)}%` }}
              className="h-full rounded-full bg-aura"
            />
          </div>
        </div>
      )}

      {/* Referral link */}
      {link && (
        <div className="flex gap-2">
          <div className="flex-1 h-10 rounded-xl bg-surface-strong px-3 flex items-center truncate">
            <span className="text-xs text-muted-foreground truncate">{link}</span>
          </div>
          <motion.button
            whileTap={{ scale: 0.95 }}
            onClick={handleCopy}
            className="h-10 w-10 rounded-xl glass flex items-center justify-center shrink-0"
          >
            {copied ? <Check className="h-4 w-4 text-green-400" /> : <Copy className="h-4 w-4" />}
          </motion.button>
          <motion.button
            whileTap={{ scale: 0.95 }}
            onClick={handleShare}
            className="h-10 w-10 rounded-xl bg-aura flex items-center justify-center shrink-0"
          >
            <Share2 className="h-4 w-4 text-primary-foreground" />
          </motion.button>
        </div>
      )}

      {/* Rewards grid */}
      <div className="mt-4 grid grid-cols-5 gap-1.5">
        {referralRewards.map((r) => {
          const unlocked = referralCount >= r.invites;
          return (
            <div
              key={r.invites}
              className={`rounded-xl p-2 text-center transition-all ${
                unlocked
                  ? 'bg-aura/15 border border-aura/30'
                  : 'bg-surface-strong opacity-50'
              }`}
            >
              <span className={`text-[10px] font-bold block ${unlocked ? 'text-primary' : 'text-muted-foreground'}`}>
                {r.invites}
              </span>
              <span className="text-[8px] text-muted-foreground block">{r.label}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
