// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
    plugins: [react()],
    server: {
        port: 3000,
        proxy: {
            '/maramboi': {
                target: 'http://localhost:3001',
                changeOrigin: true
            },
            '/ngorongoro': {
                target: 'http://localhost:3001',
                changeOrigin: true
            }
        }
    },
    build: {
        outDir: 'dist/public',
        emptyOutDir: true
    }
});

