import { defineConfig } from 'vite';
export default defineConfig({
  server: { port: Number(process.env.PORT || 5174), host: true },
  preview: { port: Number(process.env.PORT || 5174), host: true },
});
