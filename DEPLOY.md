# AuraStyle — Guia de Deploy (Vercel + Capacitor)

Do código às lojas (Google Play / App Store) em 3 passos, tudo no plano gratuito.

---

## Passo 1 — Código no GitHub

O repositório é `https://github.com/kenjunior01/aesthetic-aura-bot.git`.

Se ainda há commits locais por enviar, crie um **Personal Access Token**:
`GitHub → Settings → Developer settings → Personal access tokens (classic) → Generate new token` com o scope **`repo`**. Depois:

```bash
git push origin main
# Username: kenjunior01
# Password: <cole o token>
```

> Revoga o token depois de usar (fica válido até expirares/manualmente).

---

## Passo 2 — Hospedar na Vercel (grátis)

1. Entra em [vercel.com](https://vercel.com) com a conta GitHub.
2. **Add New → Project → Import** o repositório `aesthetic-aura-bot`.
3. Em **Environment Variables**, adiciona:

| Variável | Obrigatória | Valor |
|---|---|---|
| `GROQ_API_KEY` | ✅ | A tua chave Groq ([console.groq.com/keys](https://console.groq.com/keys) — plano free) |
| `NEXT_PUBLIC_FIREBASE_API_KEY` | opcional | Ativa login Google/Firestore sync |
| `GOOGLE_VISION_API_KEY` | opcional | Análise de selfie alternativa ao Groq Vision |
| `GOOGLE_PLACES_API_KEY` | opcional | Salões próximos |
| `LOVABLE_AI_ENDPOINT` | opcional | Fallback de chat externo |

4. **Deploy**. Em ~2 minutos tens `https://SEU-APP.vercel.app` no ar.

> Não precisa de base de dados: o app guarda tudo no dispositivo
> (localStorage/Zustand) e as rotas `/api` são serverless.

---

## Banco de dados — Referências de estilo

A funcionalidade "Referências" (comparação facial com arquétipos) usa
**Prisma + SQLite** como armazenamento primário. O conteúdo vive em
`prisma/references-data.ts` (fonte única) — a API lê do banco e, se a
tabela estiver vazia (ex.: deploy serverless sem SQLite persistente),
usa automaticamente os dados estáticos. Funciona em qualquer ambiente,
sem migração prévia.

Para ativar o banco completo (recomendado local/dev):

```bash
bun run db:push    # cria a tabela ReferenceLook
bun run db:seed    # semeia os 8 arquétipos
```

Na Vercel (serverless), a reserva estática garante a funcionalidade sem
passos extras. Para persistência real em produção, aponta o Prisma para
um Postgres gratuito (Neon/Supabase) em `DATABASE_URL`.

---

## Passo 3 — App nativo com Capacitor

O `capacitor.config.ts` já vem pronto (`appId: com.aurastyle.app`).

### Opção A — WebView para o deploy (recomendada)

```bash
npm i @capacitor/core @capacitor/cli @capacitor/status-bar
npx cap add android
npx cap add ios
```

No `capacitor.config.ts`, descomenta:

```ts
server: { url: 'https://SEU-APP.vercel.app' },
```

```bash
npx cap sync
npx cap open android   # Android Studio → build AAB para a Play Store
npx cap open ios       # Xcode → build IPA para a App Store
```

**Vantagens:** o app nativo atualiza-se sempre que o site atualiza; todas as rotas `/api` funcionam na mesma origem; zero manutenção dupla.

### Opção B — Build estático embutido

```bash
# no next.config.ts:  output: 'export'
NEXT_PUBLIC_API_BASE=https://SEU-APP.vercel.app npm run build
npx cap sync
```

O WebView abre o app offline-first e as chamadas IA vão ao backend da Vercel via `NEXT_PUBLIC_API_BASE`.

---

## Checklist das lojas

- [x] Ícones 192/512 + manifest PWA (`public/manifest.json`)
- [x] `viewport-fit=cover` + safe areas (`pt-safe` / `pb-safe`)
- [x] Tema `#0b0b0d` coerente com a UI Champagne Noir
- [ ] Screenshots + descrição na Play Console / App Store Connect
- [ ] Assinatura do AAB (Android Studio gera a keystore no 1º build)

## Notas técnicas

- **IA:** cadeia Groq (Llama 3.3 70B texto · Llama 4 Scout visão) → z-ai → regras locais. Sem chave/config extra funciona igualmente (modo offline determinístico).
- **Dados mundiais:** Open Beauty Facts (códigos de barras), Open-Meteo (clima), ipwho.is/geojs (região) — 100% open data, sem marcas fixas no código.
- **Chaves:** nunca commitar `.env` (já protegido pelo `.gitignore`); usa as variáveis de ambiente da Vercel.

## Chaves de ambiente (Vercel → Settings → Environment Variables)

| Variável | Para que serve | Onde obter |
|---|---|---|
| `GROQ_API_KEY` | IA do chat, visão da selfie e do Mercado | console.groq.com/keys |
| `PEXELS_API_KEY` | Banco de imagens Pexels no `/api/galeria-visual` | pexels.com/api |
| `UNSPLASH_ACCESS_KEY` | Banco de imagens Unsplash (intercalado com o Pexels) | unsplash.com/developers |

- Sem as chaves, o servidor devolve a **reserva embutida** e o web continua bonito.
- O **app Flutter** lê as chaves de `mobile/lib/core/secrets.dart` — no repo
  elas vão vazias (GitHub Push Protection bloqueia chaves em commits
  públicos). Cola as tuas chaves nesse ficheiro antes de compilar e o app
  fala diretamente com Pexels + Unsplash + Groq do telemóvel, sem backend.
  Se alguma chave for exposta, roda-a no painel do serviço e atualiza o ficheiro.
- O Groq bloqueia alguns datacenters (ex.: saída por Hong Kong) — na Vercel,
  escolhe a região `iad1`/`gru1` para que o Groq responda como primário.
