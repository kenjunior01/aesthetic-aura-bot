'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Mail, Lock, User, Eye, EyeOff, ArrowRight,
  Sparkles, ChevronLeft, Loader2, CheckCircle2, Info,
} from 'lucide-react';
import { signUpWithEmail, signInWithEmail, signInWithGoogle, generateReferralCode, resetPassword, logEvent } from '@/lib/services';
import { useAura } from '@/lib/aura-store';
import { GlowButton } from '@/components/aura/ui';
import { FEATURES } from '@/lib/firebase-config';

type AuthMode = 'choice' | 'register' | 'login' | 'forgot';

export default function AuthScreen({
  onAuthComplete,
  onBack,
}: {
  onAuthComplete: () => void;
  onBack: () => void;
}) {
  const [mode, setMode] = useState<AuthMode>('choice');

  return (
    <div className="relative z-10 px-4 pt-6 pb-8 max-w-lg mx-auto min-h-screen flex flex-col">
      <div className="flex items-center gap-3 mb-8">
        {mode !== 'choice' && (
          <button
            onClick={() => setMode('choice')}
            className="h-10 w-10 rounded-xl glass flex items-center justify-center"
          >
            <ChevronLeft className="h-5 w-5" />
          </button>
        )}
        <div>
          <h1 className="text-2xl font-bold">
            {mode === 'choice' && 'Criar sua conta'}
            {mode === 'register' && 'Cadastro'}
            {mode === 'login' && 'Entrar'}
            {mode === 'forgot' && 'Recuperar senha'}
          </h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            {mode === 'choice' && 'Seus dados ficam seguros e sincronizados'}
            {mode === 'register' && 'Crie sua conta para salvar e sincronizar'}
            {mode === 'login' && 'Acesse sua conta AuraStyle'}
            {mode === 'forgot' && 'Enviaremos um link de recuperação'}
          </p>
        </div>
      </div>

      <AnimatePresence mode="wait">
        {mode === 'choice' && (
          <motion.div
            key="choice"
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -40 }}
            className="flex-1 flex flex-col gap-4"
          >
            {/* Google Sign-In button */}
            <button
              onClick={async () => {
                try {
                  const user = await signInWithGoogle();
                  const store = useAura.getState();
                  store.setAuth(user.uid, user.email);
                  if (user.displayName) store.update({ name: user.displayName, email: user.email });
                  const refCode = generateReferralCode(user.uid, user.displayName || 'user');
                  store.setReferralCode(refCode);
                  logEvent('auth_google_complete');
                  onAuthComplete();
                } catch (err: any) {
                  alert(err.message || 'Erro ao fazer login com Google');
                }
              }}
              className="glass rounded-2xl p-5 text-left hover:border-primary/30 transition-all"
            >
              <div className="flex items-center gap-4">
                <div className="h-12 w-12 rounded-xl bg-surface-strong flex items-center justify-center shrink-0">
                  <svg className="h-6 w-6" viewBox="0 0 24 24">
                    <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
                    <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
                    <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
                    <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
                  </svg>
                </div>
                <div className="flex-1">
                  <span className="text-base font-bold block">Entrar com Google</span>
                  <span className="text-sm text-muted-foreground">Login rápido e seguro (gratuito)</span>
                </div>
                <ArrowRight className="h-5 w-5 text-muted-foreground" />
              </div>
            </button>

            {/* Divider */}
            <div className="flex items-center gap-3 py-1">
              <div className="flex-1 h-px bg-border" />
              <span className="text-xs text-muted-foreground">ou</span>
              <div className="flex-1 h-px bg-border" />
            </div>

            <button
              onClick={() => setMode('register')}
              className="glass rounded-2xl p-5 text-left hover:border-primary/30 transition-all"
            >
              <div className="flex items-center gap-4">
                <div className="h-12 w-12 rounded-xl bg-aura flex items-center justify-center shrink-0">
                  <Sparkles className="h-6 w-6 text-primary-foreground" />
                </div>
                <div className="flex-1">
                  <span className="text-base font-bold block">Criar conta com email</span>
                  <span className="text-sm text-muted-foreground">Email + senha (Firebase gratuito)</span>
                </div>
                <ArrowRight className="h-5 w-5 text-muted-foreground" />
              </div>
            </button>

            <button
              onClick={() => setMode('login')}
              className="glass rounded-2xl p-5 text-left hover:border-primary/30 transition-all"
            >
              <div className="flex items-center gap-4">
                <div className="h-12 w-12 rounded-xl bg-surface-strong flex items-center justify-center shrink-0">
                  <Mail className="h-6 w-6 text-primary" />
                </div>
                <div className="flex-1">
                  <span className="text-base font-bold block">Já tenho conta</span>
                  <span className="text-sm text-muted-foreground">Entrar com email e senha</span>
                </div>
                <ArrowRight className="h-5 w-5 text-muted-foreground" />
              </div>
            </button>

            <button
              onClick={onAuthComplete}
              className="glass rounded-2xl p-5 text-left hover:border-primary/30 transition-all"
            >
              <div className="flex items-center gap-4">
                <div className="h-12 w-12 rounded-xl bg-surface-strong flex items-center justify-center shrink-0">
                  <User className="h-6 w-6 text-muted-foreground" />
                </div>
                <div className="flex-1">
                  <span className="text-base font-bold block">Continuar sem conta</span>
                  <span className="text-sm text-muted-foreground">Dados salvos localmente no dispositivo</span>
                </div>
                <ArrowRight className="h-5 w-5 text-muted-foreground" />
              </div>
            </button>

            {/* Sync info banner */}
            <div className="mt-auto pt-6">
              <div className="glass rounded-2xl p-4">
                <div className="flex items-start gap-3">
                  <Info className="h-4 w-4 text-primary shrink-0 mt-0.5" />
                  <div className="text-xs text-muted-foreground leading-relaxed">
                    <p className="font-medium text-foreground mb-1">Sincronização na nuvem (gratuito)</p>
                    <p>Com conta, seus dados sincronizam via Firebase Firestore entre todos dispositivos. Tudo grátis no plano free do Google Cloud.</p>
                  </div>
                </div>
              </div>
            </div>
          </motion.div>
        )}

        {mode === 'register' && (
          <motion.div
            key="register"
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -40 }}
          >
            <RegisterForm onComplete={() => onAuthComplete()} />
          </motion.div>
        )}

        {mode === 'login' && (
          <motion.div
            key="login"
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -40 }}
          >
            <LoginForm onComplete={() => onAuthComplete()} onForgot={() => setMode('forgot')} />
          </motion.div>
        )}

        {mode === 'forgot' && (
          <motion.div
            key="forgot"
            initial={{ opacity: 0, x: 40 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -40 }}
          >
            <ForgotForm />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function RegisterForm({ onComplete }: { onComplete: () => void }) {
  const { setAuth, setReferralCode, update, profile } = useAura();
  const [name, setName] = useState(profile.name || '');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [phone, setPhone] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleRegister = async () => {
    setError('');
    if (!name.trim()) { setError('Informe seu nome'); return; }
    if (!email.trim() || !email.includes('@')) { setError('Informe um email válido'); return; }
    if (password.length < 6) { setError('A senha deve ter pelo menos 6 caracteres'); return; }

    setLoading(true);
    try {
      const user = await signUpWithEmail(email, password, name);
      setAuth(user.uid, user.email);
      const refCode = generateReferralCode(user.uid, name);
      setReferralCode(refCode);
      update({ name: name.trim(), email: email.trim(), phone: phone.trim() });
      logEvent('signup_email_complete', { uid: user.uid });
      setSuccess(true);
      setTimeout(() => onComplete(), 1500);
    } catch (err: any) {
      setError(err.message || 'Erro ao criar conta');
    } finally {
      setLoading(false);
    }
  };

  if (success) {
    return (
      <div className="flex flex-col items-center justify-center py-16 gap-4">
        <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }}>
          <CheckCircle2 className="h-20 w-20 text-green-400" />
        </motion.div>
        <h2 className="text-xl font-bold">Conta criada!</h2>
        <p className="text-sm text-muted-foreground text-center max-w-xs">
          Seus dados estão sincronizados na nuvem. Vamos personalizar seu perfil estético!
        </p>
      </div>
    );
  }

  return (
    <div className="flex flex-col gap-5">
      <div>
        <label className="text-xs font-semibold uppercase tracking-widest text-muted-foreground block mb-2">Nome completo</label>
        <div className="relative">
          <User className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Seu nome"
            className="w-full h-14 rounded-2xl border border-border bg-surface pl-11 pr-4 text-sm text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong placeholder:text-muted-foreground/50"
          />
        </div>
      </div>

      <div>
        <label className="text-xs font-semibold uppercase tracking-widest text-muted-foreground block mb-2">Email</label>
        <div className="relative">
          <Mail className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="seu@email.com"
            className="w-full h-14 rounded-2xl border border-border bg-surface pl-11 pr-4 text-sm text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong placeholder:text-muted-foreground/50"
          />
        </div>
      </div>

      <div>
        <label className="text-xs font-semibold uppercase tracking-widest text-muted-foreground block mb-2">Telefone (opcional)</label>
        <input
          type="tel"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="+55 (11) 99999-9999"
          className="w-full h-14 rounded-2xl border border-border bg-surface px-4 text-sm text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong placeholder:text-muted-foreground/50"
        />
      </div>

      <div>
        <label className="text-xs font-semibold uppercase tracking-widest text-muted-foreground block mb-2">Senha</label>
        <div className="relative">
          <Lock className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type={showPassword ? 'text' : 'password'}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Mínimo 6 caracteres"
            className="w-full h-14 rounded-2xl border border-border bg-surface pl-11 pr-12 text-sm text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong placeholder:text-muted-foreground/50"
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground"
          >
            {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
          </button>
        </div>
      </div>

      {error && (
        <motion.p initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }} className="text-sm text-destructive">
          {error}
        </motion.p>
      )}

      <div className="pt-2">
        <GlowButton onClick={handleRegister} disabled={loading} className="w-full">
          {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : 'Criar conta e continuar'}
        </GlowButton>
      </div>

      <div className="glass rounded-2xl p-3 mt-2">
        <p className="text-[10px] text-muted-foreground text-center leading-relaxed">
          {FEATURES.firebaseAuth
            ? 'Autenticação via Firebase (gratuito). Dados criptografados.'
            : 'Modo demo: dados salvos localmente. Adicione credenciais Firebase para ativar nuvem.'}
        </p>
      </div>
    </div>
  );
}

function LoginForm({ onComplete, onForgot }: { onComplete: () => void; onForgot: () => void }) {
  const { setAuth, profile, update } = useAura();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async () => {
    setError('');
    if (!email.trim()) { setError('Informe seu email'); return; }
    if (!password) { setError('Informe sua senha'); return; }

    setLoading(true);
    try {
      const user = await signInWithEmail(email, password);
      setAuth(user.uid, user.email);
      update({ name: user.displayName || profile.name, email: user.email });
      logEvent('login_email_complete', { uid: user.uid });
      onComplete();
    } catch (err: any) {
      setError(err.message || 'Erro ao entrar');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col gap-5">
      <div>
        <label className="text-xs font-semibold uppercase tracking-widest text-muted-foreground block mb-2">Email</label>
        <div className="relative">
          <Mail className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="seu@email.com"
            className="w-full h-14 rounded-2xl border border-border bg-surface pl-11 pr-4 text-sm text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong placeholder:text-muted-foreground/50"
          />
        </div>
      </div>

      <div>
        <label className="text-xs font-semibold uppercase tracking-widest text-muted-foreground block mb-2">Senha</label>
        <div className="relative">
          <Lock className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type={showPassword ? 'text' : 'password'}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder="Sua senha"
            className="w-full h-14 rounded-2xl border border-border bg-surface pl-11 pr-12 text-sm text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong placeholder:text-muted-foreground/50"
          />
          <button
            type="button"
            onClick={() => setShowPassword(!showPassword)}
            className="absolute right-4 top-1/2 -translate-y-1/2 text-muted-foreground"
          >
            {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
          </button>
        </div>
      </div>

      {error && (
        <motion.p initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }} className="text-sm text-destructive">
          {error}
        </motion.p>
      )}

      <div className="pt-2">
        <GlowButton onClick={handleLogin} disabled={loading} className="w-full">
          {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : 'Entrar'}
        </GlowButton>
      </div>

      <button
        onClick={onForgot}
        className="text-sm text-primary text-center hover:underline py-1"
      >
        Esqueci minha senha
      </button>
    </div>
  );
}

function ForgotForm() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState('');

  const handleReset = async () => {
    setError('');
    if (!email.trim() || !email.includes('@')) { setError('Informe um email válido'); return; }
    setLoading(true);
    try {
      await resetPassword(email);
      setSent(true);
      logEvent('password_reset_requested');
    } catch {
      setError('Erro ao enviar email. Tente novamente.');
    } finally {
      setLoading(false);
    }
  };

  return sent ? (
    <div className="flex flex-col items-center py-16 gap-4">
      <CheckCircle2 className="h-16 w-16 text-primary" />
      <h2 className="text-lg font-bold">Email enviado!</h2>
      <p className="text-sm text-muted-foreground text-center max-w-xs">
        Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.
      </p>
    </div>
  ) : (
    <div className="flex flex-col gap-5">
      <div>
        <label className="text-xs font-semibold uppercase tracking-widest text-muted-foreground block mb-2">Email cadastrado</label>
        <div className="relative">
          <Mail className="absolute left-4 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="seu@email.com"
            className="w-full h-14 rounded-2xl border border-border bg-surface pl-11 pr-4 text-sm text-foreground outline-none transition-all focus:border-primary/70 focus:bg-surface-strong placeholder:text-muted-foreground/50"
          />
        </div>
      </div>

      {error && (
        <motion.p initial={{ opacity: 0, y: -4 }} animate={{ opacity: 1, y: 0 }} className="text-sm text-destructive">
          {error}
        </motion.p>
      )}

      <div className="pt-2">
        <GlowButton onClick={handleReset} disabled={loading} className="w-full">
          {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : 'Enviar link de recuperação'}
        </GlowButton>
      </div>
    </div>
  );
}
