'use client';

/**
 * DepthField — superfície fotográfica em vez de "aurora de IA".
 *
 * Uma laje de obsidiana iluminada por softbox superior: queda de luz
 * vertical, um spotlight champanhe larguíssimo e grão de filme fino.
 * Sem blobs coloridos, sem partículas flutuantes — realismo de estúdio.
 */
export function AuroraBackground({ dense = false }: { dense?: boolean }) {
  return (
    <div aria-hidden="true" className="pointer-events-none fixed inset-0 -z-10 overflow-hidden">
      {/* Queda de luz vertical — a superfície responde à luz como material real */}
      <div
        className="absolute inset-0"
        style={{
          background:
            'linear-gradient(180deg, oklch(0.19 0.010 80 / 85%) 0%, oklch(0.13 0.007 75 / 40%) 26%, oklch(0.105 0.006 70) 58%, oklch(0.085 0.005 70) 100%)',
        }}
      />

      {/* Spotlight champanhe de estúdio — largura total, difuso, sem cor de "IA" */}
      <div
        className="absolute inset-x-0 -top-[30vh] h-[80vh]"
        style={{
          background:
            'radial-gradient(ellipse 90% 62% at 50% 0%, oklch(0.87 0.07 72 / 13%) 0%, oklch(0.87 0.07 72 / 5%) 42%, transparent 72%)',
        }}
      />

      {/* Reflexo frio lateral mínimo — dá volume sem chamar atenção */}
      <div
        className="absolute -right-[20vw] top-[30vh] h-[50vh] w-[60vw]"
        style={{
          background:
            'radial-gradient(ellipse at center, oklch(0.75 0.02 90 / 5%) 0%, transparent 65%)',
        }}
      />

      {/* Grão de filme — remove o aspecto "plástico digital" */}
      <div
        className="grain-layer absolute inset-0 opacity-[0.05] mix-blend-overlay"
        style={{ transform: 'translateZ(0)' }}
      />

      {/* Vinheta inferior — ancora o conteúdo */}
      <div
        className="absolute inset-x-0 bottom-0 h-[30vh]"
        style={{
          background: 'linear-gradient(0deg, oklch(0.06 0.004 70 / 75%) 0%, transparent 100%)',
        }}
      />
    </div>
  );
}
