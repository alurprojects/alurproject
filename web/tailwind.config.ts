import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        alur: {
          bg: "#FAF9F7",        // Warm Off-White
          surface: "#F0EFED",   // Paper Gray
          ink: "#111111",       // Ink Black
          charcoal: "#1A1A1A",  // Charcoal (Primary text)
          warmgray: "#7A7772",  // Warm Gray (Secondary text)
          border: "#DEDBD6",    // Hairline Gray (Dividers)
          alert: "#C1502E",     // Miss/Alert Terracotta
          info: "#6B7280",      // Info Slate
        },
      },
      fontFamily: {
        sans: ["Inter", "sans-serif"],
      },
    },
  },
  plugins: [],
};
export default config;
