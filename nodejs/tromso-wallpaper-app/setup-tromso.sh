#!/bin/bash

# Create project directory
mkdir tromso-wallpaper-app
cd tromso-wallpaper-app

# Initialize npm
npm init -y

# Install production dependencies
npm install react react-dom express cors

# Install development dependencies
npm install -D @types/react @types/react-dom @types/express @types/cors @types/node \
  typescript @vitejs/plugin-react vite tailwindcss postcss autoprefixer \
  ts-node nodemon concurrently \
  @typescript-eslint/eslint-plugin @typescript-eslint/parser \
  eslint eslint-plugin-react-hooks

# Run both frontend and backend concurrently
npm run dev

# Or run separately in different terminals:
# Terminal 1 - Backend server (port 3001)
npm run dev:server

# Terminal 2 - Frontend dev server (port 3000)
npm run dev:client

# Build both client and server
npm run build

# Start production server
npm start