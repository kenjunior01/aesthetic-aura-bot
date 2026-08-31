'use client';

/**
 * useTiltSource — fonte única de inclinação para materiais vivos.
 *
 * Fusão de duas entradas físicas:
 *  - Ponteiro (desktop/web): posição relativa ao elemento, normalizada -0.5..0.5
 *  - Giroscópio (Capacitor/WebView real): beta/gamma do deviceorientation,
 *    com neutro em ~42° (telefone segurado naturalmente na mão)
 *
 * Quando o giroscópio envia eventos, ele tem prioridade — o aparelho É a
 * superfície. No desktop, o ponteiro assume. Sem dependências novas.
 */

import { useEffect, useMemo, useRef } from 'react';
import { useMotionValue, useSpring, type MotionValue } from 'framer-motion';

/** graus de inclinação física que percorrem a escala completa */
const GYRO_RANGE = 24;
/** ângulo beta de "telefone na mão" — tratado como neutro */
const BETA_NEUTRAL = 42;

const clamp = (v: number, min: number, max: number) => Math.min(max, Math.max(min, v));

export function useTiltSource() {
  const rawX = useMotionValue(0);
  const rawY = useMotionValue(0);
  const gyroActive = useRef(false);

  // Molas suaves — materiais reais têm inércia
  const x = useSpring(rawX, { stiffness: 110, damping: 18, mass: 0.45 });
  const y = useSpring(rawY, { stiffness: 110, damping: 18, mass: 0.45 });

  useEffect(() => {
    type DOSClass = typeof DeviceOrientationEvent & {
      requestPermission?: () => Promise<'granted' | 'denied'>;
    };
    const DOS = typeof window !== 'undefined' ? (window.DeviceOrientationEvent as DOSClass | undefined) : undefined;
    if (!DOS) return;

    let gotEvent = false;
    let idleTimer: ReturnType<typeof setTimeout> | undefined;

    const onOrient = (e: DeviceOrientationEvent) => {
      if (e.beta == null || e.gamma == null) return;
      if (!gotEvent) {
        gotEvent = true;
        gyroActive.current = true;
      }
      const gx = clamp(e.gamma / GYRO_RANGE, -1, 1) * 0.5;
      const gy = clamp((e.beta - BETA_NEUTRAL) / GYRO_RANGE, -1, 1) * 0.5;
      rawX.set(gx);
      rawY.set(-gy); // inclinar para trás → luz sobe
    };

    const attach = () => {
      window.addEventListener('deviceorientation', onOrient, { passive: true });
      // Desktop não emite eventos — desliga o modo giro após 1.6s de silêncio
      idleTimer = setTimeout(() => {
        if (!gotEvent) gyroActive.current = false;
      }, 1600);
    };

    // iOS 13+ exige permissão num gesto do utilizador
    if (typeof DOS.requestPermission === 'function') {
      const request = () => {
        DOS.requestPermission?.()
          .then((state) => {
            if (state === 'granted') attach();
          })
          .catch(() => {});
        window.removeEventListener('pointerdown', request);
      };
      window.addEventListener('pointerdown', request, { once: true });
    } else {
      attach();
    }

    return () => {
      window.removeEventListener('deviceorientation', onOrient);
      if (idleTimer) clearTimeout(idleTimer);
    };
  }, [rawX, rawY]);

  const pointerHandlers = useMemo(
    () => ({
      onPointerMove: (e: React.PointerEvent<HTMLElement>) => {
        if (gyroActive.current) return;
        const rect = e.currentTarget.getBoundingClientRect();
        rawX.set(clamp((e.clientX - rect.left) / rect.width - 0.5, -0.5, 0.5));
        rawY.set(clamp((e.clientY - rect.top) / rect.height - 0.5, -0.5, 0.5));
      },
      onPointerLeave: () => {
        if (gyroActive.current) return;
        rawX.set(0);
        rawY.set(0);
      },
    }),
    [rawX, rawY],
  );

  return { x, y, pointerHandlers, gyroActive };
}
