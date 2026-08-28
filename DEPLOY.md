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
