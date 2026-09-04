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
│   ├── theme/                 identidade Platina Glacial
│   │   ├── aura_colors.dart   tokens oklch→sRGB (1:1 com globals.css do web)
│   │   ├── aura_typography.dart  Outfit (display) + Manrope (texto) — as mesmas famílias do web
│   │   ├── aura_decorations.dart gradientes usinados, sombras de estúdio, raios
│   │   └── aura_theme.dart    ThemeData escuro Material 3
│   ├── api/
│   │   ├── api_client.dart    HTTP único: UA de navegador, retry, timeouts
│   │   ├── acervo_api.dart    /api/acervo (The Met) + reserva embutida
│   │   └── aura_api.dart      /api/ai-chat · /api/look-alike · /api/analyze-selfie
│   ├── data/met_reserva.dart  obras verificadas do Met (gerada do met-fallback.ts)
│   ├── store/profile_store.dart  o MESMO perfil do web (chave, forma, fórmula de nível)
│   └── widgets/               instrumentos visuais
│       ├── aurora_background.dart   halos de aurora animados (painter, custo zero no conteúdo)
│       ├── glass_card.dart    GlassCard · MachinedPanel · PlatinaButton
│       ├── aura_gauge.dart    mostrador de nível (arco platina + ticks)
│       ├── radar_chart.dart   radar de prioridades (CustomPainter)
│       ├── tilt_card.dart     resposta à mão com perspectiva (max 5°)
│       ├── shimmer_box.dart   skeleton com varrimento de luz
│       ├── stagger_in.dart    entrada escalonada
│       └── section_header.dart  eyebrow usinado + selos
└── features/
    ├── shell/nav_shell.dart   barra de vidro + Scan central elevado
    ├── home/                  saudação, gauge, radar, streak, atalhos
    ├── explore/               Acervo do Met (grade de ritmo quebrado) + ficha de museu
    ├── scan/                  ritual de leitura da aura (anel de confiança)
    ├── chat/                  chatbot adaptado ao perfil
    ├── closet/                coleções de cor por subtom
    ├── profile/               ficha, estatísticas, ligação ao backend
    └── references/            "A quem a minha cara se aproxima?" (look-alike)
```

## Mesmo banco de dados

O mobile **não tem banco próprio**: consome exatamente as rotas Next.js do
app web (`/api/acervo`, `/api/ai-chat`, `/api/look-alike`,
`/api/analyze-selfie`). O perfil local usa a mesma chave
(`aurastyle-profile`) e a mesma fórmula de nível (`floor(sqrt(xp/50))+1`),
pronto para sincronizar com o mesmo utilizador.

### Apontar para o backend

| Destino | Base URL |
|---|---|
| Emulador Android | `http://10.0.2.2:3000` (padrão) |
| iOS Simulator | `http://localhost:3000` |
| Dispositivo real | IP da máquina na mesma rede, ou URL de produção |

Muda em runtime em **Perfil → Ligação ao banco de dados**.

Sem rede? O app degrada com honestidade: a galeria Acervo cai para a
**reserva embutida** (mesmas obras verificadas do web), o Scan e as
Referências avançam com leitura local — nada bloqueia.

## Correr

```bash
cd mobile
flutter pub get
flutter run                 # emulador/dispositivo ligado
flutter analyze             # 0 issues
flutter test                # smoke test de arranque
```

Gerar APK de lançamento: `flutter build apk --release`.

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
