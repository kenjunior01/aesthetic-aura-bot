/**
 * Firebase é uma integração OPCIONAL (ativada apenas quando
 * NEXT_PUBLIC_FIREBASE_API_KEY está definido no .env).
 * Os imports são dinâmicos com `webpackIgnore`, carregados via CDN
 * em runtime — por isso não entram no bundle e não precisam do pacote
 * instalado. Este shim apenas ensina o TypeScript que esses módulos
 * existem (tipados como `any`).
 */
declare module 'firebase/app';
declare module 'firebase/auth';
declare module 'firebase/firestore';
declare module 'firebase/analytics';
