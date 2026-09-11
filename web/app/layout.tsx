import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Pecking Order — Egg Yield Bureau",
  description: "A darkly comic corporate chicken management game.",
  icons: {
    icon: "/game/index.icon.png",
    shortcut: "/game/index.icon.png",
    apple: "/game/index.apple-touch-icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <head>
        <link rel="preload" href="/game/index.js" as="script" />
        <link rel="preload" href="/game/index.html" as="fetch" crossOrigin="anonymous" />
        <link rel="preload" href="/game/index.wasm" as="fetch" type="application/wasm" crossOrigin="anonymous" />
        <link rel="preload" href="/game/index.pck" as="fetch" crossOrigin="anonymous" />
      </head>
      <body>{children}</body>
    </html>
  );
}
