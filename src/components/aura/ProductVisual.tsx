'use client';

/**
 * ProductVisual — "estúdio de produto" em CSS puro.
 * Renderiza frascos 3D realistas por categoria (vidro com líquido, metal
 * usinado, sombra de contato e reflexo de piso) sobre a obsidiana.
 * Determinístico: o mesmo produto renderiza sempre com o mesmo acabamento.
 */

export type ProductCategory =
  | 'pele'
  | 'cabelo'
  | 'maquiagem'
  | 'fragrância'
  | 'acessório';

/* ---------- determinismo ---------- */

function hashSeed(seed: string): number {
  let h = 5381;
  for (let i = 0; i < seed.length; i++) h = ((h << 5) + h + seed.charCodeAt(i)) | 0;
  return Math.abs(h);
}

/* ---------- acabamentos (materiais) ---------- */

type Finish = {
  body: string;
  liquid: string | null;
  glass: boolean;
  label: 'dark' | 'light';
};

const FINISHES: Finish[] = [
  { body: 'oklch(0.46 0.075 72)', liquid: 'oklch(0.58 0.10 78)', glass: true, label: 'light' },
  { body: 'oklch(0.3 0.015 258)', liquid: 'oklch(0.38 0.03 80)', glass: true, label: 'light' },
  { body: 'oklch(0.9 0.012 258)', liquid: null, glass: false, label: 'dark' },
  { body: 'oklch(0.17 0.006 258)', liquid: null, glass: false, label: 'light' },
  { body: 'oklch(0.55 0.06 30)', liquid: 'oklch(0.66 0.09 35)', glass: true, label: 'light' },
];

/* metal champanhe torneado */
const METAL = 'var(--gradient-aura)';
const KNURL =
  'repeating-linear-gradient(90deg, oklch(0 0 0 / 30%) 0 1px, transparent 1px 3px)';

/* sombreamento cilíndrico — escura nas bordas, luz fora do eixo */
const CYLINDER =
  'linear-gradient(90deg, oklch(0 0 0 / 60%) 0%, oklch(1 0 0 / 16%) 15%, oklch(1 0 0 / 4%) 36%, oklch(0 0 0 / 14%) 62%, oklch(0 0 0 / 62%) 100%)';

/* ---------- helpers visuais ---------- */

function Specular({ left = '24%', w = '7%' }: { left?: string; w?: string }) {
  return (
    <div
      aria-hidden
      className="absolute rounded-full"
      style={{
        left,
        top: '5%',
        width: w,
        height: '58%',
        background:
          'linear-gradient(to bottom, oklch(1 0 0 / 55%), oklch(1 0 0 / 8%) 78%, transparent)',
        filter: 'blur(0.6px)',
      }}
    />
  );
}

function ContactShadow({ w = '72%' }: { w?: string }) {
  return (
    <div
      aria-hidden
      className="absolute"
      style={{
        left: `${(100 - parseFloat(w)) / 2}%`,
        bottom: '-1.5%',
        width: w,
        height: '6%',
        background: 'radial-gradient(ellipse, oklch(0 0 0 / 60%), transparent 68%)',
        filter: 'blur(2px)',
      }}
    />
  );
}

function LabelBand({
  finish,
  top,
  height,
  width = '46%',
}: {
  finish: Finish;
  top: string;
  height: string;
  width?: string;
}) {
  const light = finish.label === 'light';
  return (
    <div
      aria-hidden
      className="absolute rounded-[2px] overflow-hidden"
      style={{
        left: '50%',
        transform: 'translateX(-50%)',
        top,
        width,
        height,
        background: light
          ? 'linear-gradient(90deg, oklch(0.96 0.01 258 / 92%), oklch(0.88 0.015 258 / 88%))'
          : 'oklch(0.24 0.01 258 / 85%)',
        border: `1px solid oklch(${light ? '0.5 0.02 80 / 25%' : '0.9 0.02 80 / 18%'})`,
      }}
    >
      <div
        className="absolute rounded-full"
        style={{
          left: '16%',
          right: '16%',
          top: '30%',
          height: '8%',
          background: light ? 'oklch(0.35 0.04 70 / 70%)' : 'oklch(0.87 0.05 78 / 80%)',
        }}
      />
      <div
        className="absolute rounded-full"
        style={{
          left: '28%',
          right: '28%',
          top: '58%',
          height: '7%',
          background: light ? 'oklch(0.35 0.03 70 / 40%)' : 'oklch(0.87 0.04 78 / 45%)',
        }}
      />
    </div>
  );
}

/* ---------- formas por categoria ---------- */

function Flacon({ finish }: { finish: Finish }) {
  const liquid = finish.liquid ?? 'oklch(0.5 0.06 75)';
  return (
    <>
      {/* tampa metálica usinada */}
      <div
        className="absolute rounded-[3px]"
        style={{
          left: '31%', top: '3%', width: '38%', height: '14%',
          background: METAL, boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 40%), inset 0 -2px 3px oklch(0 0 0 / 45%)',
        }}
      >
        <div className="absolute inset-0 rounded-[3px]" style={{ background: KNURL, opacity: 0.5 }} />
      </div>
      {/* colarinho escuro */}
      <div
        className="absolute"
        style={{ left: '40%', top: '17%', width: '20%', height: '4.5%', background: 'linear-gradient(90deg, oklch(0.14 0.005 258), oklch(0.3 0.01 258) 40%, oklch(0.12 0.005 258))' }}
      />
      {/* corpo de vidro */}
      <div
        className="absolute overflow-hidden"
        style={{
          left: '15%', top: '21.5%', width: '70%', height: '69%',
          borderRadius: '10px 10px 7px 7px',
          background: finish.glass
            ? `linear-gradient(to bottom, oklch(0.85 0.01 258 / 10%), oklch(0.7 0.01 258 / 6%))`
            : finish.body,
          border: '1px solid oklch(0.95 0.02 80 / 14%)',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 18%)',
        }}
      >
        {/* líquido com menisco */}
        {finish.glass && (
          <div
            className="absolute inset-x-0 bottom-0"
            style={{
              height: '64%',
              background: `linear-gradient(to bottom, ${liquid}, oklch(0.3 0.05 70 / 85%))`,
            }}
          >
            <div
              className="absolute inset-x-0 top-0"
              style={{ height: '2px', background: 'oklch(1 0 0 / 30%)' }}
            />
          </div>
        )}
        {/* sulco gravado */}
        <div
          className="absolute rounded-full"
          style={{ left: '34%', right: '34%', top: '44%', height: '5%', background: 'oklch(0 0 0 / 22%)' }}
        />
        <LabelBand finish={finish} top="56%" height="24%" />
        <div className="absolute inset-0" style={{ background: CYLINDER }} />
        <Specular />
      </div>
    </>
  );
}

function PumpBottle({ finish }: { finish: Finish }) {
  return (
    <>
      {/* bico dosador */}
      <div
        className="absolute"
        style={{ left: '46%', top: '5%', width: '20%', height: '6.5%', background: 'linear-gradient(90deg, oklch(0.15 0.005 258), oklch(0.28 0.008 258) 45%, oklch(0.12 0.005 258))', borderRadius: '2px 2px 0 0' }}
      />
      <div
        className="absolute"
        style={{ left: '62%', top: '6.5%', width: '15%', height: '3.4%', background: 'linear-gradient(to bottom, oklch(0.3 0.008 258), oklch(0.14 0.005 258))', borderRadius: '2px' }}
      />
      {/* haste */}
      <div
        className="absolute"
        style={{ left: '48%', top: '11.5%', width: '13%', height: '6%', background: 'linear-gradient(90deg, oklch(0.18 0.005 258), oklch(0.32 0.01 258) 45%, oklch(0.15 0.005 258))' }}
      />
      {/* colarinho champanhe */}
      <div
        className="absolute"
        style={{
          left: '38%', top: '17.5%', width: '33%', height: '6.5%', background: METAL, borderRadius: '3px',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 40%), inset 0 -1px 2px oklch(0 0 0 / 40%)',
        }}
      />
      {/* corpo opaco */}
      <div
        className="absolute overflow-hidden"
        style={{
          left: '19%', top: '24%', width: '62%', height: '67%',
          borderRadius: '9px 9px 6px 6px',
          background: `linear-gradient(to bottom, ${finish.body}, oklch(0.2 0.01 258 / 92%))`,
          border: '1px solid oklch(0.95 0.02 80 / 10%)',
        }}
      >
        <LabelBand finish={finish} top="34%" height="30%" />
        <div className="absolute inset-0" style={{ background: CYLINDER }} />
        <Specular left="27%" />
      </div>
    </>
  );
}

function TallBottle({ finish }: { finish: Finish }) {
  return (
    <>
      {/* tampa flip */}
      <div
        className="absolute"
        style={{
          left: '29%', top: '3.5%', width: '42%', height: '8.5%', background: METAL,
          borderRadius: '5px 5px 2px 2px',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 45%), inset 0 -2px 3px oklch(0 0 0 / 45%)',
        }}
      >
        <div className="absolute inset-x-[12%] bottom-[26%] h-[8%] rounded-full" style={{ background: 'oklch(0 0 0 / 28%)' }} />
      </div>
      {/* corpo alto */}
      <div
        className="absolute overflow-hidden"
        style={{
          left: '21%', top: '12.5%', width: '58%', height: '78.5%',
          borderRadius: '13px 13px 8px 8px',
          background: `linear-gradient(to bottom, ${finish.body}, oklch(0.18 0.012 258 / 94%))`,
          border: '1px solid oklch(0.95 0.02 80 / 11%)',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 14%)',
        }}
      >
        <LabelBand finish={finish} top="38%" height="22%" />
        <div className="absolute inset-0" style={{ background: CYLINDER }} />
        <Specular left="25%" />
      </div>
    </>
  );
}

function Lipstick({ finish }: { finish: Finish }) {
  const bullet = finish.liquid ?? 'oklch(0.62 0.16 22)';
  return (
    <>
      {/* bala do batom — ponta diagonal */}
      <div
        className="absolute"
        style={{
          left: '41%', top: '7%', width: '18%', height: '15%',
          background: `linear-gradient(90deg, oklch(0.4 0.1 20), ${bullet} 45%, oklch(0.75 0.1 25))`,
          clipPath: 'polygon(0 100%, 0 34%, 50% 0, 100% 30%, 100% 100%)',
        }}
      />
      {/* tubo interno */}
      <div
        className="absolute"
        style={{ left: '38%', top: '22%', width: '24%', height: '9%', background: 'linear-gradient(90deg, oklch(0.13 0.005 258), oklch(0.3 0.01 258) 40%, oklch(0.1 0.005 258))' }}
      />
      {/* base metálica usinada */}
      <div
        className="absolute"
        style={{
          left: '34%', top: '31%', width: '32%', height: '42%', background: METAL,
          borderRadius: '4px 4px 3px 3px',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 40%), inset 0 -3px 5px oklch(0 0 0 / 50%)',
        }}
      >
        <div className="absolute inset-0" style={{ background: KNURL, opacity: 0.55 }} />
        <div
          className="absolute rounded-full"
          style={{ left: '30%', right: '30%', top: '42%', height: '6%', background: 'oklch(0 0 0 / 30%)' }}
        />
      </div>
    </>
  );
}

function Compact({ finish }: { finish: Finish }) {
  return (
    <>
      {/* aro metálico */}
      <div
        className="absolute rounded-full"
        style={{
          left: '16%', top: '30%', width: '68%', height: '44%',
          background: METAL,
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 45%), 0 6px 14px oklch(0 0 0 / 45%)',
        }}
      />
      {/* tampa pérola */}
      <div
        className="absolute rounded-full overflow-hidden"
        style={{
          left: '21%', top: '34.5%', width: '58%', height: '35%',
          background: `radial-gradient(circle at 34% 28%, oklch(0.97 0.012 258), ${finish.body} 58%, oklch(0.6 0.02 80))`,
        }}
      />
      {/* fecho */}
      <div
        className="absolute"
        style={{ left: '46%', top: '27.5%', width: '8%', height: '5%', background: 'oklch(0.2 0.01 258)', borderRadius: '2px' }}
      />
    </>
  );
}

function AccessoryCase() {
  return (
    <>
      {/* caixa pincel / necessaire metálica */}
      <div
        className="absolute overflow-hidden"
        style={{
          left: '18%', top: '26%', width: '64%', height: '48%',
          background: METAL, borderRadius: '12px',
          boxShadow: 'inset 0 1px 0 oklch(1 0 0 / 45%), inset 0 -4px 8px oklch(0 0 0 / 45%)',
        }}
      >
        {/* escovado vertical */}
        <div
          className="absolute inset-0"
          style={{
            background:
              'repeating-linear-gradient(0deg, oklch(1 0 0 / 5%) 0 1px, transparent 1px 3px)',
          }}
        />
        {/* fecho central */}
        <div
          className="absolute"
          style={{ left: 0, right: 0, top: '46%', height: '8%', background: 'linear-gradient(to bottom, oklch(0 0 0 / 35%), oklch(0 0 0 / 12%))' }}
        />
        <div
          className="absolute rounded-[2px]"
          style={{ left: '42%', top: '34%', width: '16%', height: '32%', background: 'oklch(0.22 0.01 258 / 85%)', borderRadius: '3px' }}
        />
      </div>
    </>
  );
}

/* ---------- resolução de categoria por nome ---------- */

const CATEGORY_HINTS: [RegExp, ProductCategory][] = [
  [/perfume|eau de|colônia|colonha|fragranc/i, 'fragrância'],
  [/shampoo|condicionador|máscara capilar|leave[- ]?in|spray capilar|tônico|óleo capilar|creme de pentear/i, 'cabelo'],
  [/batom|lip|pó|paleta|rimel|máscara de cílios|delineador|base (líquida|em pó)|blush|sombra/i, 'maquiagem'],
  [/sérum|serum|creme|hidratante|sabonete|loção|locao|fps|protetor|toner|esfoliante|máscara facial|demacquilan/i, 'pele'],
  [/escova|pente|espelho|pinça|tesoura|necessaire|borracha|cinta/i, 'acessório'],
];

export function resolveCategory(name: string, fallback: string): ProductCategory {
  for (const [re, cat] of CATEGORY_HINTS) if (re.test(name)) return cat;
  const valid: ProductCategory[] = ['pele', 'cabelo', 'maquiagem', 'fragrância', 'acessório'];
  return (valid as string[]).includes(fallback) ? (fallback as ProductCategory) : 'pele';
}

/* ---------- componente principal ---------- */

const SHAPES: Record<ProductCategory, (p: { finish: Finish }) => React.ReactElement> = {
  fragrância: Flacon,
  pele: PumpBottle,
  cabelo: TallBottle,
  maquiagem: Lipstick, // variante compact via seed
  acessório: AccessoryCase,
};

type ProductVisualProps = {
  category: ProductCategory | string;
  seed: string;
  /** reflexo de piso (desligar em miniaturas) */
  reflection?: boolean;
};

export function ProductVisual({ category, seed, reflection = true }: ProductVisualProps) {
  const cat = resolveCategory(seed, String(category));
  const h = hashSeed(seed);
  const finish = FINISHES[h % FINISHES.length];
  // maquiagem alterna lipstick / compact de forma estável
  const Shape =
    cat === 'maquiagem' && h % 2 === 1
      ? Compact
      : SHAPES[cat] ?? PumpBottle;

  const shapeNode = <Shape finish={finish} />;

  return (
    <div className="relative h-full w-full grain">
      {/* luz de fundo — hidrata o frasco com um halo quente */}
      <div
        aria-hidden
        className="absolute"
        style={{
          left: '8%', right: '8%', top: '18%', bottom: '6%',
          background:
            'radial-gradient(ellipse at 50% 42%, oklch(0.87 0.07 72 / 13%), transparent 70%)',
        }}
      />
      <div className="absolute inset-x-0 top-0 h-[84%]">{shapeNode}</div>
      {reflection && (
        <div
          aria-hidden
          className="absolute inset-x-0 bottom-0 h-[15%] opacity-[0.14]"
          style={{
            transform: 'scaleY(-1)',
            maskImage: 'linear-gradient(to bottom, black 0%, transparent 72%)',
            WebkitMaskImage: 'linear-gradient(to bottom, black 0%, transparent 72%)',
            filter: 'blur(1px)',
          }}
        >
          <div className="relative h-full w-full">{shapeNode}</div>
        </div>
      )}
      <ContactShadow />
    </div>
  );
}
