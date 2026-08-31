'use client';

/**
 * TiltCard — superfície física que responde ao toque.
 * Inclinação 3D real (perspective + rotateX/Y) com mola e brilho especular
 * que segue o ponteiro. Em touch, inclinação suave durante o toque
 * (touch-action: pan-y preserva o scroll vertical).
 */

import { useRef, useState, type ReactNode } from 'react';
import {
  motion,
  useMotionValue,
  useSpring,
  useTransform,
  useMotionTemplate,
  type HTMLMotionProps,
} from 'framer-motion';

type TiltCardProps = HTMLMotionProps<'div'> & {
  children?: ReactNode;
  /** graus máximos de inclinação */
  max?: number;
  /** brilho especular que segue o ponteiro */
  glare?: boolean;
};

export function TiltCard({ children, className, max = 7, glare = true, ...rest }: TiltCardProps) {
  const ref = useRef<HTMLDivElement>(null);
  const px = useMotionValue(0.5);
  const py = useMotionValue(0.5);
  const active = useMotionValue(0);
  const [pressed, setPressed] = useState(false);

  const rotateX = useSpring(useTransform(py, [0, 1], [max, -max]), {
    stiffness: 280,
    damping: 26,
    mass: 0.6,
  });
  const rotateY = useSpring(useTransform(px, [0, 1], [-max, max]), {
    stiffness: 280,
    damping: 26,
    mass: 0.6,
  });

  const glareX = useTransform(px, (v) => v * 100);
  const glareY = useTransform(py, (v) => v * 100);
  const glareBg = useMotionTemplate`radial-gradient(circle at ${glareX}% ${glareY}%, oklch(0.97 0.02 85 / 0.13), transparent 52%)`;
  const glareOpacity = useSpring(active, { stiffness: 200, damping: 30 });

  const handleMove = (e: React.PointerEvent<HTMLDivElement>) => {
    const el = ref.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    px.set(Math.min(Math.max((e.clientX - rect.left) / rect.width, 0), 1));
    py.set(Math.min(Math.max((e.clientY - rect.top) / rect.height, 0), 1));
  };

  const handleEnter = (e: React.PointerEvent<HTMLDivElement>) => {
    active.set(1);
    if (e.pointerType !== 'mouse') setPressed(true);
    handleMove(e);
  };

  const handleLeave = () => {
    active.set(0);
    setPressed(false);
    px.set(0.5);
    py.set(0.5);
  };

  return (
    <div className="[perspective:900px]">
      <motion.div
        ref={ref}
        onPointerMove={handleMove}
        onPointerDown={handleEnter}
        onPointerEnter={handleEnter}
        onPointerUp={handleLeave}
        onPointerCancel={handleLeave}
        onPointerLeave={handleLeave}
        style={{ rotateX, rotateY, transformStyle: 'preserve-3d' }}
        whileTap={{ scale: 0.985 }}
        className={`relative touch-pan-y select-none ${className || ''}`}
        {...rest}
      >
        {children}
        {glare && (
          <motion.div
            aria-hidden
            className="pointer-events-none absolute inset-0 rounded-[inherit]"
            style={{ background: glareBg, opacity: glareOpacity }}
          />
        )}
      </motion.div>
    </div>
  );
}
