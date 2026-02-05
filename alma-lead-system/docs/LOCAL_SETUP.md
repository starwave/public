# Local Development Setup

## Prerequisites

- Docker & Docker Compose
- Node.js 20+ (for local front-end development without Docker)
- Python 3.12+ (for local API development without Docker)

## Option 1: Docker Compose (Recommended)

```bash
cd alma-lead-system

# Start all services
docker-compose up --build
```

This starts:
- PostgreSQL on port 5432
- Redis on port 6379
- FastAPI API on port 4002
- Lead Portal on port 4000
- Internal Portal on port 4001

The DDL script runs automatically on first PostgreSQL startup.

## Option 2: Run Services Individually

### Database

```bash
# Start just PostgreSQL and Redis
docker-compose up postgres redis
```

### API Server

```bash
cd services/api

# Create virtual environment
python -m venv .venv
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create upload directory
mkdir -p /mnt/data/alma

# Set DATABASE_URL for local PostgreSQL
export DATABASE_URL=postgresql+asyncpg://alma_user:alma_passwd@localhost:5432/alma_db
export REDIS_URL=redis://localhost:6379/0
export API_KEY=3kxgnRlA8v4Ql2IodaitnuN1YSwLCEks

# Run migrations (optional, DDL already applied by Docker)
alembic upgrade head

# Start the API server
uvicorn app.main:app --host 0.0.0.0 --port 4002 --reload
```

API docs available at http://localhost:4002/docs

### Lead Portal

```bash
cd apps/lead-portal
npm install
npm run dev
```

Open http://localhost:4000

### Internal Portal

```bash
cd apps/internal-portal
npm install
npm run dev
```

Open http://localhost:4001

Login with the API key: `3kxgnRlA8v4Ql2IodaitnuN1YSwLCEks`

## Testing the API with curl

### Submit a lead

```bash
curl -X POST http://localhost:4002/leads \
  -F "first_name=John" \
  -F "last_name=Doe" \
  -F "email=john@example.com" \
  -F "resume=@/path/to/resume.pdf"
```

### List leads (internal)

```bash
curl http://localhost:4002/internal/leads \
  -H "X-API-Key: 3kxgnRlA8v4Ql2IodaitnuN1YSwLCEks"
```

### Update lead status (internal)

```bash
curl -X PATCH http://localhost:4002/internal/leads/{lead-id} \
  -H "X-API-Key: 3kxgnRlA8v4Ql2IodaitnuN1YSwLCEks" \
  -H "Content-Type: application/json" \
  -d '{"status": "REACHED_OUT"}'
```

## Environment Variables

See `.env.example` for all available configuration. Key variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | See .env |
| `REDIS_URL` | Redis connection string | `redis://localhost:6379/0` |
| `API_KEY` | API key for internal endpoints | – |
| `STORAGE_BACKEND` | `local` or `s3` | `local` |
| `UPLOAD_DIR` | Local file upload directory | `/mnt/data/alma` |
| `SMTP_HOST` | SMTP server hostname | `smtp.zebtoon.ai` |
| `ATTORNEY_EMAIL` | Attorney notification email | `attorney@zebtoon.ai` |
