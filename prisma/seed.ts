/**
 * Seed do banco de Referências AuraStyle — 8 arquétipos originais.
 * Conteúdo vive em references-data.ts (fonte única, também usada
 * como reserva pela API). Correr: bun run db:seed
 */
import { PrismaClient } from '@prisma/client';
import { REFERENCE_LOOKS } from './references-data';

const prisma = new PrismaClient();

async function main() {
  console.log('Limpando tabela ReferenceLook…');
  await prisma.referenceLook.deleteMany();

  console.log(`Semeando ${REFERENCE_LOOKS.length} arquétipos…`);
  for (const look of REFERENCE_LOOKS) {
    await prisma.referenceLook.create({
      data: {
        ...look,
        signature: JSON.stringify(look.signature),
        upgrades: JSON.stringify(look.upgrades),
      },
    });
  }

  const n = await prisma.referenceLook.count();
  console.log(`Banco de referências pronto: ${n} arquétipos.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
