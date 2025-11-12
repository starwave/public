# Umunhum - Image Search Web App

Web application for image similarity search using vector database.

## Features

- Upload images via web UI
- Find top 5 most similar images
- Beautiful Material-UI interface
- Real-time search results
- Connects to Prado for embeddings
- Queries Qdrant for similarity search

## Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Environment

```bash
cp .env.example .env
# Edit .env with your settings
```

### 3. Run Development

```bash
# Run both frontend and backend
npm run dev

# Or run separately
npm run dev:client  # Vite dev server on :5173
npm run dev:server  # Express server on :3002
```

### 4. Build for Production

```bash
npm run build
npm start
```

## Tech Stack

- **Frontend**: React 18, Vite, Material-UI
- **Backend**: Express, Node.js
- **Vector DB**: Qdrant
- **Image Processing**: Sharp
- **Embeddings**: Prado API

## API Endpoints

- `POST /api/search/similar` - Search similar images
- `GET /api/search/status` - System status
- `GET /api/health` - Health check

## Requirements

- Node.js 20+
- Prado service running
- Qdrant database accessible
- PostgreSQL database (via Prado)

## Documentation

See [INSTALL.md](INSTALL.md) for detailed installation instructions.

## Server

- Host: 11.11.11.12
- Port: 3002
- URL: http://11.11.11.12:3002

## Architecture

```
User -> Umunhum Web UI
         |
         v
      Express API
         |
         v
      Prado API (embeddings)
         |
         v
      Qdrant (search)
```
