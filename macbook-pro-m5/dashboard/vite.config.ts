import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Local services are proxied so the browser never hits CORS:
// SearXNG sends no CORS headers at all, and proxying Ollama too keeps
// the client code uniform.
export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/svc/ollama': {
        target: 'http://127.0.0.1:11434',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/svc\/ollama/, ''),
      },
      '/svc/searxng': {
        target: 'http://127.0.0.1:8899',
        changeOrigin: true,
        rewrite: (p) => p.replace(/^\/svc\/searxng/, ''),
      },
    },
  },
})
