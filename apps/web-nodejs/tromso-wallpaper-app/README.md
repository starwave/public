# Tromso Wallpaper App

A React + Node.js wallpaper slideshow application with Docker deployment support.

## Quick Start

### Development

```bash
# Install dependencies
npm install

# Run development server (frontend + backend)
npm run dev

# Run only frontend (Vite dev server on port 3010)
npm run dev:client

# Run only backend (Express server on port 3001)
npm run dev:server
```

Access the app:
- Frontend dev: http://localhost:3001
- Remote APIs: http://192.168.1.111:8080 (maramboi/ngorongoro)

### Testing

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### Build

```bash
# Build both frontend and backend
npm run build

# Run production build
npm start
```

## Docker Deployment

### Prerequisites

1. **Docker**: See [install_docker.md](install_docker.md)
2. **Remote Server**: Ubuntu 22.04 at 192.168.1.111
3. **Mac Users Only**: If on Apple Silicon (M1/M2/M3), run `./setup-buildx.sh` first

### Deployment Steps

#### 0. Configure Docker Buildx (Mac with Apple Silicon only)

```bash
./setup-buildx.sh
```

This enables building x86_64 images on your ARM64 Mac.

#### 1. Setup Remote Server (One-time)

```bash
./setup-remote-server.sh
```

This prepares the remote server with:
- Docker installation check
- Directory creation
- Permissions setup
- Firewall configuration

#### 2. Deploy Application

```bash
./deploy.sh
```

This will:
1. Build Docker image locally
2. Transfer image to 192.168.1.111
3. Start the container

Access deployed app: http://192.168.1.111:3001

### Local Docker Testing

Two Docker Compose files are provided:

| File | Purpose | Usage |
|------|---------|-------|
| `docker-compose.dev.yml` | Local development/testing | `docker compose -f docker-compose.dev.yml up --build` |
| `docker-compose.yml` | Production deployment | Used by `deploy.sh` on remote server |

**Local testing:**

```bash
# Option 1: Using dev compose (builds locally)
docker compose -f docker-compose.dev.yml up --build

# Option 2: Test production setup
docker build -t tromso-wallpaper-app:latest .
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down
```

## Architecture

### Ports

| Port | Service | Purpose |
|------|---------|---------|
| 3001 | Vite (frontend dev) | React development server with HMR |
| 3001 | Express (production) | API server + static files on remote server |
| 8080 | Remote APIs | maramboi/ngorongoro endpoints (192.168.1.111:8080) |

### API Endpoints

- `GET /health` - Health check
- `GET /maramboi?a=g` - Get theme library
- `GET /ngorongoro` - Get wallpaper (with query params: a, d, t, o)

### Project Structure

```
tromso-wallpaper-app/
├── src/
│   ├── App.tsx              # Main React app
│   ├── WallpaperApp.tsx     # Wallpaper component
│   ├── main.tsx             # React entry point
│   └── server.ts            # Express backend
├── tests/
│   ├── WallpaperApp.test.tsx
│   ├── server.test.ts
│   └── utils/
├── dist/                    # Build output
│   ├── public/              # Frontend build
│   └── server.js            # Backend build
├── Dockerfile               # Docker image definition
├── docker-compose.yml       # Production config (uses pre-built image)
├── docker-compose.dev.yml   # Dev config (builds locally)
├── deploy.sh                # Deployment script
└── setup-remote-server.sh   # Server setup script
```

## Configuration Files

- `package.json` - Dependencies and scripts
- `tsconfig.json` - TypeScript config for frontend
- `tsconfig.server.json` - TypeScript config for backend
- `tsconfig.test.json` - TypeScript config for tests
- `vite.config.ts` - Vite configuration (port 3010, proxy to 3001)
- `jest.config.js` - Jest test configuration
- `tailwind.config.js` - Tailwind CSS configuration

## Documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide
- [install_docker.md](install_docker.md) - Docker installation for Mac & Ubuntu

## Features

- React 18 with TypeScript
- Wallpaper slideshow with multiple themes
- Touch gesture support (swipe to navigate)
- Fullscreen mode
- Auto-advance with pause/play
- Custom theme configuration
- Responsive design (supports various screen sizes)
- LocalStorage for preferences
- Docker containerization
- Comprehensive test suite (49 tests)

## Development Workflow

```bash
# 1. Install dependencies
npm install

# 2. Start development servers
npm run dev

# 3. Make changes (auto-reload enabled)

# 4. Run tests
npm test

# 5. Build for production
npm run build

# 6. Test Docker build locally
docker compose -f docker-compose.dev.yml up --build

# 7. Deploy to production
./deploy.sh
```

## Troubleshooting

### Port Already in Use

```bash
# Check what's using the port
lsof -i :3001
lsof -i :3010

# Kill the process
kill -9 <PID>
```

### Docker Build Fails

```bash
# Check Node.js version (must be 20+)
node --version

# Clear Docker cache
docker system prune -a

# Rebuild without cache
docker build --no-cache -t tromso-wallpaper-app:latest .
```

### Tests Failing

```bash
# Clear Jest cache
npm test -- --clearCache

# Run specific test
npm test -- WallpaperApp.test.tsx
```

### Deployment Issues

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting.

## Scripts Reference

| Command | Description |
|---------|-------------|
| `npm run dev` | Run frontend + backend in development |
| `npm run dev:client` | Run only Vite dev server (port 3010) |
| `npm run dev:server` | Run only Express server (port 3001) |
| `npm run build` | Build frontend + backend |
| `npm run build:client` | Build only frontend (Vite) |
| `npm run build:server` | Build only backend (TypeScript) |
| `npm start` | Run production build |
| `npm test` | Run tests |
| `npm run test:watch` | Run tests in watch mode |
| `npm run test:coverage` | Run tests with coverage |
| `npm run lint` | Run ESLint |
| `npm run type-check` | Check TypeScript types |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ENV` | development | Environment mode |
| `PORT` | 3001 | Backend server port |

## License

MIT

## Support

For issues and questions, see [DEPLOYMENT.md](DEPLOYMENT.md) troubleshooting section.
