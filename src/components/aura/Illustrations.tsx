'use client';

const facePaths: Record<string, string> = {
  oval: 'M50 6c22 0 32 22 32 46s-14 62-32 62S18 76 18 52 28 6 50 6z',
  redondo: 'M50 8c25 0 40 20 40 53S75 114 50 114 10 94 10 61 25 8 50 8z',
  quadrado: 'M18 20h64v52c0 26-14 42-32 42S18 98 18 72V20z',
  retangular: 'M22 8h56v70c0 24-11 36-28 36S22 102 22 78V8z',
  coracao: 'M50 114 14 62V30l18-14 18 10 18-10 18 14v32z',
  diamante: 'M50 4 88 60 50 116 12 60z',
  losango: 'M50 8 82 46 62 114H38L18 46z',
};

export function FaceShape({ id, active }: { id: string; active: boolean }) {
  return (
    <svg viewBox="0 0 100 120" className="h-16 w-14">
      <defs>
        <linearGradient id={`face-${id}`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="var(--primary)" />
          <stop offset="100%" stopColor="var(--primary-glow)" />
        </linearGradient>
      </defs>
      <path
        d={facePaths[id]}
        fill={active ? `url(#face-${id})` : 'var(--surface-strong)'}
        stroke="var(--border)"
      />
      <circle cx="38" cy="52" r="3" fill="var(--background)" opacity="0.75" />
      <circle cx="62" cy="52" r="3" fill="var(--background)" opacity="0.75" />
      <path
        d="M42 76c4 4 12 4 16 0"
        stroke="var(--background)"
        strokeWidth="2.5"
        fill="none"
        opacity="0.6"
        strokeLinecap="round"
      />
    </svg>
  );
}

const bodyPaths: Record<string, string> = {
  triangulo: 'M38 14h24l6 34 14 78H18l14-78z',
  invertido: 'M26 14h48l-8 40 8 72H26l8-72z',
  retangular: 'M30 14h40l4 40-2 72H28l-2-72z',
  oval: 'M32 14h36l10 44c0 26-6 34-6 68H28c0-34-6-42-6-68z',
  ampulheta: 'M28 14h44l-8 42 12 70H24l12-70z',
};

export function BodyShape({ id, active }: { id: string; active: boolean }) {
  return (
    <svg viewBox="0 0 100 140" className="h-24 w-16">
      <defs>
        <linearGradient id={`body-${id}`} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="var(--primary)" />
          <stop offset="100%" stopColor="var(--gold)" />
        </linearGradient>
      </defs>
      <circle
        cx="50"
        cy="10"
        r="9"
        fill={active ? `url(#body-${id})` : 'var(--surface-strong)'}
      />
      <path
        d={bodyPaths[id]}
        fill={active ? `url(#body-${id})` : 'var(--surface-strong)'}
        stroke="var(--border)"
      />
    </svg>
  );
}

export function HairIllustration({
  id,
  color = 'var(--primary)',
  active,
}: {
  id: string;
  color?: string;
  active?: boolean;
}) {
  const hair = () => {
    switch (id) {
      case 'liso':
        return <path d="M20 40C20 18 34 8 50 8s30 10 30 32v46H70V38H30v48H20z" />;
      case 'ondulado':
        return (
          <path d="M20 42c0-24 14-34 30-34s30 10 30 34c0 14-6 18-4 30-6 4-8-6-12-2s-6 6-14 6-10-2-14-6-6 6-12 2c2-12-4-16-4-30z" />
        );
      case 'cacheado':
        return (
          <g>
            {[
              [30, 26],
              [46, 18],
              [64, 26],
              [72, 42],
              [26, 44],
              [36, 38],
              [56, 34],
              [68, 58],
              [30, 60],
            ].map(([x, y], i) => (
              <circle key={i} cx={x} cy={y} r="11" />
            ))}
          </g>
        );
      case 'crespo':
        return (
          <g>
            {Array.from({ length: 14 }).map((_, i) => (
              <circle
                key={i}
                cx={22 + ((i * 13) % 58)}
                cy={20 + ((i * 17) % 42)}
                r="9"
              />
            ))}
          </g>
        );
      case 'afro':
        return <circle cx="50" cy="42" r="34" />;
      case 'trancas':
        return (
          <g>
            <path d="M22 40c0-22 12-32 28-32s28 10 28 32v6H22z" />
            {[28, 40, 52, 64].map((x) => (
              <rect key={x} x={x} y="46" width="6" height="44" rx="3" />
            ))}
          </g>
        );
      case 'locks':
        return (
          <g>
            <path d="M22 40c0-22 12-32 28-32s28 10 28 32v4H22z" />
            {[26, 38, 50, 62, 72].map((x, i) => (
              <rect
                key={x}
                x={x}
                y="44"
                width="8"
                height={i % 2 ? 50 : 38}
                rx="4"
              />
            ))}
          </g>
        );
      case 'rapado':
        return <path d="M22 42c0-20 12-30 28-30s28 10 28 30v4H22z" opacity="0.7" />;
      case 'moicano':
        return (
          <g>
            <rect x="42" y="4" width="16" height="46" rx="8" />
            <path d="M24 44c0-8 4-14 8-16v18h-8zM68 46V28c4 2 8 8 8 16v2z" opacity="0.6" />
          </g>
        );
      default:
        return <path d="M26 46c0-16 10-26 24-26s24 10 24 26z" opacity="0.35" />;
    }
  };

  return (
    <svg viewBox="0 0 100 100" className="h-16 w-16">
      <ellipse cx="50" cy="62" rx="24" ry="30" fill="var(--muted)" />
      <circle cx="42" cy="60" r="2.5" fill="var(--background)" />
      <circle cx="58" cy="60" r="2.5" fill="var(--background)" />
      <g fill={active ? color : 'var(--surface-strong)'} stroke="var(--border)" strokeWidth="0.5">
        {hair()}
      </g>
    </svg>
  );
}

export function LengthIllustration({ id, active }: { id: string; active: boolean }) {
  const h = { buzz: 6, curto: 22, medio: 42, longo: 64 }[id] ?? 20;
  return (
    <svg viewBox="0 0 60 100" className="h-20 w-12">
      <ellipse cx="30" cy="26" rx="16" ry="20" fill="var(--muted)" />
      <path
        d={`M12 26c0-14 8-22 18-22s18 8 18 22v${h}H12z`}
        fill={active ? 'var(--primary)' : 'var(--surface-strong)'}
        stroke="var(--border)"
      />
    </svg>
  );
}

export function ThicknessIllustration({ id, active }: { id: string; active: boolean }) {
  const w = { fino: 2, medio: 5, grosso: 9 }[id] ?? 4;
  return (
    <svg viewBox="0 0 60 40" className="h-10 w-16">
      {[10, 22, 34].map((y) => (
        <line
          key={y}
          x1="6"
          y1={y}
          x2="54"
          y2={y}
          strokeWidth={w}
          strokeLinecap="round"
          stroke={active ? 'var(--primary)' : 'var(--muted-foreground)'}
        />
      ))}
    </svg>
  );
}

export function GenderIllustration({ id, active }: { id: string; active: boolean }) {
  const stroke = active ? 'var(--primary)' : 'var(--muted-foreground)';
  return (
    <svg viewBox="0 0 48 48" className="h-10 w-10" fill="none" stroke={stroke} strokeWidth="2.5">
      {id === 'feminino' && (
        <>
          <circle cx="24" cy="18" r="10" />
          <path d="M24 28v14M17 36h14" strokeLinecap="round" />
        </>
      )}
      {id === 'masculino' && (
        <>
          <circle cx="20" cy="28" r="10" />
          <path d="M28 20 40 8M31 8h9v9" strokeLinecap="round" />
        </>
      )}
      {id === 'nao-binario' && (
        <>
          <circle cx="24" cy="30" r="9" />
          <path d="M24 21V6M18 11l6-5 6 5" strokeLinecap="round" />
        </>
      )}
      {id === 'outro' && (
        <>
          <circle cx="24" cy="24" r="11" />
          <path d="M12 36 36 12" strokeLinecap="round" />
        </>
      )}
    </svg>
  );
}
