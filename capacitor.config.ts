import type { CapacitorConfig } from '@capacitor/cli';

/**
 * AuraStyle — configuração Capacitor (Android / iOS)
 *
 * Passos (depois do app estar no ar, ex.: https://SEU-APP.vercel.app):
 *   npm i @capacitor/core @capacitor/cli @capacitor/status-bar
 *   npx cap add android && npx cap add ios
 *   npx cap sync && npx cap open android   (ou: npx cap open ios)
 *
 * Estratégia recomendada (Opção A): WebView aponta para o deploy Vercel.
 * O app nativo acompanha cada atualização do site automaticamente e
 * todas as rotas /api funcionam na mesma origem.
 * Para isso, descomente `server.url` abaixo com o teu domínio.
 *
 * Opção B (estática): gere o build estático (`npx next build` com
 * output:'export') + NEXT_PUBLIC_API_BASE=https://SEU-APP.vercel.app
 * e use `npx cap sync` para copiar os ficheiros para o nativo.
 */
const config: CapacitorConfig = {
  appId: 'com.aurastyle.app',
  appName: 'AuraStyle',
  webDir: 'out',
  backgroundColor: '#0b0b0d',
  // server: {
  //   url: 'https://SEU-APP.vercel.app',
  // },
};

export default config;
