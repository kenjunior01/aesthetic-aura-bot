import type { Metadata, Viewport } from "next";
import { Outfit, Manrope } from "next/font/google";
import "./globals.css";

const outfit = Outfit({
  variable: "--font-display",
  subsets: ["latin"],
  display: "swap",
});

const manrope = Manrope({
  variable: "--font-sans",
  subsets: ["latin"],
  display: "swap",
});

export const metadata: Metadata = {
  title: "AuraStyle — Seu estilo, com precisão",
  description:
    "Assistente de estética e estilo personalizado. Prioridades, compras inteligentes com orçamento e consultor no bolso.",
  keywords: ["estilo", "beleza", "moda", "personalização", "IA", "assistente", "compras"],
  manifest: "/manifest.json",
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "AuraStyle",
  },
  icons: {
    icon: [
      { url: "/icons/icon-192.png", type: "image/png", sizes: "192x192" },
      { url: "/icons/icon-512.png", type: "image/png", sizes: "512x512" },
    ],
    apple: [{ url: "/icons/icon-192.png", sizes: "192x192" }],
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  userScalable: false,
  viewportFit: "cover", // Capacitor / iOS notch safe areas
  themeColor: "#04060a", // Glacial Noir — fundo oklch(0.105 0.006 258)
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="pt-BR" suppressHydrationWarning>
      <body
        className={`${outfit.variable} ${manrope.variable} antialiased bg-background text-foreground`}
      >
        {children}
      </body>
    </html>
  );
}
