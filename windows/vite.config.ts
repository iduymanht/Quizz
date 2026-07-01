import { defineConfig } from "vite";
import { resolve } from "path";

// Two entries: the transparent pet+quiz overlay (index.html) and the
// Settings window (settings.html).
export default defineConfig({
  clearScreen: false,
  server: { port: 1420, strictPort: true },
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, "index.html"),
        settings: resolve(__dirname, "settings.html"),
      },
    },
  },
});
