import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [react()],
    server: {
        host: '0.0.0.0',
        port: 3004,
        proxy: {
            '/api': {
                target: 'http://11.11.11.12:3002',
                changeOrigin: true
            }
        },
        // Other server options like 'port', 'open', etc. might be here
        allowedHosts: [
            'umunhum.thirdwavesoft.com', // <-- ADD THIS LINE
            // You can add 'localhost', '127.0.0.1', or other domains/IPs here if needed
        ]
    },
    build: {
        outDir: 'dist',
        sourcemap: false
    }
})
