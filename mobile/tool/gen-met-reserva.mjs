/**
 * gen-met-reserva.mjs — converte a reserva embutida do web (met-fallback.ts)
 * para Dart, garantindo que o mobile usa EXATAMENTE o mesmo banco de dados
 * de reserva (obras verificadas, domínio público).
 * Uso: node scripts/gen-met-reserva.mjs
 */
import { readFileSync, writeFileSync } from 'node:fs';

const TS = '/home/z/my-project/src/lib/met-fallback.ts';
const OUT = '/home/z/my-project/mobile/lib/core/data/met_reserva.dart';

const src = readFileSync(TS, 'utf8');
const start = src.indexOf('{', src.indexOf('MET_RESERVA'));
const end = src.lastIndexOf('}');
const json = src.slice(start, end + 1);
const reserva = JSON.parse(json);

const THEMES = Object.keys(reserva);
// 2 obras por tema — suficiente para o fallback offline do mobile
const lines = [
  '// met_reserva.dart — reserva embutida do Acervo (The Metropolitan Museum of Art).',
  '// GERADO a partir de src/lib/met-fallback.ts via scripts/gen-met-reserva.mjs —',
  '// mesmas obras verificadas (isPublicDomain + imagem ativa) do app web, para que',
  '// a galeria nunca amanheça vazia, mesmo sem rede.',
  '',
  "import '../api/acervo_api.dart';",
  '',
  'const Map<String, List<MetItem>> kMetReserva = {',
];

for (const theme of THEMES) {
  lines.push(`  '${theme}': [`);
  for (const it of reserva[theme].slice(0, 2)) {
    const e = (s) => String(s).replaceAll("'", "\\'");
    lines.push('    MetItem(');
    lines.push(`      objectID: ${it.objectID},`);
    lines.push(`      title: '${e(it.title)}',`);
    lines.push(`      artist: '${e(it.artist)}',`);
    lines.push(`      date: '${e(it.date)}',`);
    lines.push(`      culture: '${e(it.culture)}',`);
    lines.push(`      medium: '${e(it.medium)}',`);
    lines.push(`      department: '${e(it.department)}',`);
    lines.push(`      image: '${e(it.image)}',`);
    lines.push(`      objectURL: '${e(it.objectURL)}',`);
    lines.push('    ),');
  }
  lines.push('  ],');
}
lines.push('};');
lines.push('');

writeFileSync(OUT, lines.join('\n'));
console.log(`OK ${THEMES.length} temas → ${OUT}`);
