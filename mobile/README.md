# AuraStyle Mobile — Flutter

> A tua aura, esculpida em platina. ✦

Aplicação **Flutter** do AuraStyle — o assistente de estética com IA — com a
mesma identidade cromática **Platina Glacial sobre Observidana** do app web,
o **mesmo banco de dados** (as rotas `/api` do Next.js) e o mesmo rigor de
instrumento: metal usinado, vidro frio, luz de estúdio.

## Arquitetura

```
mobile/lib/
├── main.dart                  bootstrap
├── app.dart                   MultiProvider + MaterialApp + splash
├── core/
│   ├── config.dart            base URL das rotas /api partilhadas (editável em runtime)
│   ├── secrets.dart           chaves XOR+base64 (Groq, Pexels, Unsplash) — APK autónomo
│   ├── theme/                 identidade Platina Glacial em DOIS modos (Noite/Alvor)
│   │   ├── aura_colors.dart   tokens oklch→sRGB 1:1 com globals.css do web
│   │   ├── aura_typography.dart  Outfit (display) + Manrope (texto)
│   │   ├── aura_decorations.dart gradientes usinados, sombras de estúdio, raios
│   │   └── aura_theme.dart    ThemeData Material 3 (claro e escuro)
│   ├── api/
│   │   ├── api_client.dart    HTTP único: UA de navegador, retry, timeouts
│   │   ├── groq_ai.dart       IA Groq direta: llama-3.3-70b (texto) + llama-4-scout (visão)
│   │   ├── image_bank.dart    Pexels + Unsplash intercalados, direto do telemóvel
│   │   ├── visual_api.dart    itens visuais + consultor de compras
│   │   ├── acervo_api.dart    /api/acervo (The Met) + reserva embutida
│   │   ├── aura_api.dart      rotas partilhadas do web (fallback da IA)
│   │   └── clima_api.dart     clima ao vivo (Open-Meteo)
│   ├── data/
│   │   ├── met_reserva.dart   obras verificadas do Met (gerada do met-fallback.ts)
│   │   ├── cromatica.dart     motor das 10 estações cromáticas (offline, determinístico)
│   │   ├── cortes_data.dart   direções de corte por formato de rosto
│   │   └── diario_store.dart  diário de evolução (timeline local)
│   ├── store/profile_store.dart  o MESMO perfil do web (chave, forma, fórmula de nível)
│   └── widgets/               instrumentos visuais (fundo interstellar, gauge, radar,
│                              tilt, shimmer, stagger, glass)
└── features/
    ├── shell/nav_shell.dart   barra de vidro + Scan central elevado
    ├── home/                  saudação, gauge, ritual de hoje (com fotos), clima, radar
    ├── cromatica/             A TUA ESTAÇÃO: paleta pessoal, neutros, evitar, combos + fotos
    ├── cortes/                cortes para o teu rosto, cada corte com fotos reais
    ├── evolucao/              diário de evolução: linha do tempo da aura (foto + leituras)
    ├── espelho/               espelho de identidade: cabelo e estilo com fotos reais
    ├── mercado/               mercado fotográfico: foto do produto → recomendação IA
    ├── explore/               Acervo do Met (grade de ritmo quebrado) + ficha de museu
    ├── scan/                  ritual de leitura da aura (guarda no diário)
    ├── chat/                  chatbot Groq com visão (manda fotos, tira dúvidas gerais)
    ├── closet/                coleções de cor por subtom
    ├── profile/               ficha, estatísticas, diário, ligação ao backend
    └── references/            "A quem a minha cara se aproxima?" (look-alike)
```

## Mesmo banco de dados + modo autónomo

O mobile fala com as rotas Next.js do app web (`/api/acervo`,
`/api/ai-chat`, `/api/look-alike`, `/api/analyze-selfie`) quando há backend
alcançável — e, desde a v1.2, é **autónomo**: as chaves de Groq, Pexels e
Unsplash viajam ofuscadas (XOR+base64) no app, por isso a IA, as fotos
reais do Espelho/Cortes/Cromática e o Mercado funcionam **sem backend
nenhum**. O perfil local usa a mesma chave (`aurastyle-profile-state`) e a
mesma fórmula de nível (`floor(sqrt(xp/50))+1`), pronto para sincronizar
com o mesmo utilizador.

### Apontar para o backend

| Destino | Base URL |
|---|---|
| Emulador Android | `http://10.0.2.2:3000` (padrão) |
| iOS Simulator | `http://localhost:3000` |
| Dispositivo real | IP da máquina na mesma rede, ou URL de produção |

Muda em runtime em **Perfil → Ligação ao banco de dados**. Sem backend o
app continua inteiro (IA e bancos de imagens diretos); sem rede, degrada
com honestidade: Acervo cai para a reserva embutida, o Scan avança com
leitura local — nada bloqueia.

## Correr

```bash
cd mobile
flutter pub get
flutter run                 # emulador/dispositivo ligado
flutter analyze             # 0 issues
flutter test                # smoke test de arranque
```

## Instalar no celular (APK)

O build de lançamento gera `build/app/outputs/flutter-apk/app-release.apk`:

```bash
flutter build apk --release --target-platform android-arm64
```

O APK desta versão vive em `download/AuraStyle-v1.4.0-arm64.apk` (arm64-v8a —
cobre praticamente todos os Android modernos, minSdk 24 / Android 7+).

Para instalar:
1. Copia o APK para o telefone (USB, Drive, WhatsApp…).
2. Abre o ficheiro e aceita "Instalar app desconhecido" quando pedido.
3. Em Perfil → Ligação, aponta a base URL para onde o backend web corre
   (produção ou IP da tua máquina na mesma rede) — a IA, o Acervo e as
   Referências ligam-se ao MESMO banco de dados do web.

Nota: o APK atual é assinado com a chave de debug (instalável, ideal para
testar). Para publicar na Play Store, cria uma keystore própria e define
`signingConfig` de release em `android/app/build.gradle.kts`.

## Notas de design

- Paleta traduzida **oklch → sRGB** token a token do `globals.css` do web
  (primária `#B8D9F3`, observidana fria matiz 258, contraste quente
  `#DC9B90` reservado a leituras negativas de gráficos).
- Tipografia **Outfit + Manrope** bundle local (`assets/fonts`) — sem
  dependência de rede no arranque.
- Animações: aurora contínua (painter com `repaint` do controller — nunca
  reconstrói a árvore), entrada escalonada, anel de confiança, shimmer,
  tilt com perspectiva real.
- Conteúdo respeitado: produtos, tons de pele e paletas do Armário ficam
  fiéis ao web; só o "chrome" é nativo.
