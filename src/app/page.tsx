'use client';

import { useState, useCallback, useSyncExternalStore } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { useAura } from '@/lib/aura-store';
import { AuroraBackground } from '@/components/aura/AuroraBackground';
import WelcomeScreen from '@/components/onboarding/WelcomeScreen';
import ProgressBar from '@/components/onboarding/ProgressBar';
import Step1Basic from '@/components/onboarding/Step1Basic';
import Step2Face from '@/components/onboarding/Step2Face';
import Step3Hair from '@/components/onboarding/Step3Hair';
import Step4Body from '@/components/onboarding/Step4Body';
import Step5Style from '@/components/onboarding/Step5Style';
import Step6Lifestyle from '@/components/onboarding/Step6Lifestyle';
import DashboardScreen from '@/components/dashboard/DashboardScreen';

type AppView = 'welcome' | 'onboarding' | 'dashboard';

const stepComponents = [
  Step1Basic,
  Step2Face,
  Step3Hair,
  Step4Body,
  Step5Style,
  Step6Lifestyle,
];

const emptySubscribe = () => () => {};

function useMounted() {
  return useSyncExternalStore(
    emptySubscribe,
    () => true,
    () => false,
  );
}

export default function Page() {
  const { onboarded } = useAura();
  const mounted = useMounted();
  const [view, setView] = useState<AppView>('welcome');
  const [step, setStep] = useState(0);

  const initialView: AppView = onboarded ? 'dashboard' : 'welcome';
  const currentView = mounted ? (view === 'welcome' && onboarded ? 'dashboard' : view) : 'welcome';

  const startOnboarding = useCallback(() => {
    setStep(0);
    setView('onboarding');
  }, []);

  const nextStep = useCallback(() => {
    setStep((s) => s < 5 ? s + 1 : s);
    if (step >= 5) setView('dashboard');
  }, [step]);

  const prevStep = useCallback(() => {
    setStep((s) => (s > 0 ? s - 1 : 0));
    if (step <= 0) setView('welcome');
  }, [step]);

  if (!mounted) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="h-8 w-8 rounded-full bg-aura animate-pulse" />
      </div>
    );
  }

  return (
    <main className="min-h-screen">
      <AnimatePresence mode="wait">
        {currentView === 'welcome' && (
          <motion.div
            key="welcome"
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3 }}
          >
            <WelcomeScreen
              onStart={startOnboarding}
              onSkip={() => setView('dashboard')}
            />
          </motion.div>
        )}

        {currentView === 'onboarding' && (
          <motion.div
            key="onboarding"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.3 }}
            className="min-h-screen"
          >
            <AuroraBackground />
            <div className="relative z-10 px-4 pt-6 pb-6 max-w-lg mx-auto">
              <div className="sticky top-0 z-20 bg-background/80 backdrop-blur-lg -mx-4 px-4 pt-2 pb-4">
                <ProgressBar current={step} />
              </div>

              <AnimatePresence mode="wait">
                <motion.div
                  key={step}
                  initial={{ x: 60, opacity: 0 }}
                  animate={{ x: 0, opacity: 1 }}
                  exit={{ x: -60, opacity: 0 }}
                  transition={{ type: 'spring', stiffness: 300, damping: 30 }}
                >
                  {(() => {
                    const StepComponent = stepComponents[step];
                    return <StepComponent onNext={nextStep} onBack={prevStep} />;
                  })()}
                </motion.div>
              </AnimatePresence>
            </div>
          </motion.div>
        )}

        {currentView === 'dashboard' && (
          <motion.div
            key="dashboard"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.4 }}
          >
            <DashboardScreen />
          </motion.div>
        )}
      </AnimatePresence>
    </main>
  );
}