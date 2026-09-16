import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  build: {
    rollupOptions: {
      output: {
        // Rolldown (Vite 8) requires the function form of manualChunks.
        manualChunks(id) {
          if (!id.includes('node_modules')) return undefined;
          if (id.includes('/react-router') || id.includes('/react-dom/') || id.includes('/node_modules/react/') || id.includes('/scheduler/')) {
            return 'vendor-react';
          }
          if (id.includes('@tanstack')) return 'vendor-query';
          if (id.includes('react-hook-form') || id.includes('@hookform') || id.includes('/zod/')) {
            return 'vendor-form';
          }
          if (id.includes('lucide-react')) return 'vendor-icons';
          return 'vendor-misc';
        },
      },
    },
  },
  server: {
    port: 5174,
    proxy: {
      '/api': {
        target: process.env.VITE_DEV_PROXY_TARGET ?? 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.js'],
    globals: true,
  },
});
