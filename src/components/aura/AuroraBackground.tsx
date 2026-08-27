'use client';

const particles = Array.from({ length: 26 }, (_, i) => {
  const seed = (i * 9301 + 49297) % 233280;
  const r = seed / 233280;
  const r2 = ((i * 4177 + 12345) % 65536) / 65536;
  return {
    x: Math.round(r * 100),
    y: Math.round(r2 * 100),
    s: 2 + Math.round(r * 3),
    o: 0.2 + r2 * 0.5,
    d: 10 + Math.round(r2 * 14),
    delay: Math.round(r * 6),
  };
});

export function AuroraBackground({ dense = false }: { dense?: boolean }) {
  return (
    <div aria-hidden="true" className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
      <div
        className="absolute -left-24 -top-32 h-[70vh] w-[70vh] rounded-full opacity-50 blur-[100px]"
        style={{
          background: 'radial-gradient(circle, var(--primary), transparent 65%)',
          animation: 'float-slow 14s ease-in-out infinite',
        }}
      />
      <div
        className="absolute -right-32 top-[18vh] h-[60vh] w-[60vh] rounded-full opacity-40 blur-[110px]"
        style={{
          background: 'radial-gradient(circle, var(--primary-glow), transparent 65%)',
          animation: 'float-slow 18s ease-in-out infinite reverse',
        }}
      />
      <div
        className="absolute bottom-[-20vh] left-[10vw] h-[55vh] w-[55vh] rounded-full opacity-25 blur-[120px]"
        style={{
          background: 'radial-gradient(circle, var(--gold), transparent 65%)',
          animation: 'float-slow 22s ease-in-out infinite',
        }}
      />
      {dense && (
        <div className="absolute inset-0">
          {particles.map((p, i) => (
            <span
              key={i}
              className="absolute rounded-full bg-foreground/50"
              style={{
                left: `${p.x}%`,
                top: `${p.y}%`,
                width: p.s,
                height: p.s,
                opacity: p.o,
                animation: `float-slow ${p.d}s ease-in-out ${p.delay}s infinite`,
              }}
            />
          ))}
        </div>
      )}
      <div
        className="absolute inset-0 opacity-[0.05]"
        style={{
          backgroundImage: 'radial-gradient(var(--foreground) 1px, transparent 1px)',
          backgroundSize: '26px 26px',
        }}
      />
    </div>
  );
}
