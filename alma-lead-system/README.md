# Alma Lead System

A lead management system that allows prospects to submit their information (name, email, resume) via a public form. Submitted leads are emailed to both the prospect and an internal attorney. An internal portal (auth-guarded) lets attorneys view all leads and mark them as "Reached Out".

## Architecture

| Component | Tech | URL |
|-----------|------|-----|
| API Server | Python FastAPI | `http://alma-api.thirdwavesoft.com` |
| Lead Portal (public) | Next.js + TypeScript | `http://alma-lead.thirdwavesoft.com` |
| Internal Portal | Next.js + TypeScript | `http://alma-internal.thirdwavesoft.com` |
| Database | PostgreSQL 16 | `localhost:5432` |
| Cache / Rate Limit | Redis 7 | `localhost:6379` |
| API Docs | Swagger UI | `http://alma-api.thirdwavesoft.com/docs` |

## Quick Start

```bash
# Clone
git clone http://github.com/starwave/public/alma-lead-system.git
cd alma-lead-system

# Start all services
docker compose up --build
```
Services that are pre-built at:
- Lead form: http://alma-lead.thirdwavesoft.com/
- Internal portal: http://alma-internal.thirdwavesoft.com/
- API / Swagger: https://alma-api.thirdwavesoft.com/docs

Services will be available at:
- Lead form: http://localhost:4000
- Internal portal: http://localhost:4001
- API / Swagger: http://localhost:4002/docs

See [docs/LOCAL_SETUP.md](docs/LOCAL_SETUP.md) for detailed local development instructions.

See [docs/DESIGN.md](docs/DESIGN.md) for system design and architectural decisions.

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/leads` | Public (rate-limited) | Submit a new lead with resume |
| `GET` | `/internal/leads` | `X-API-Key` header | List leads (pagination, status filter) |
| `PATCH` | `/internal/leads/{id}` | `X-API-Key` header | Update lead status |
| `GET` | `/health` | None | Health check |

## Project Structure

```
alma-lead-system/
├── services/api/          # FastAPI backend
├── apps/lead-portal/      # Next.js public form
├── apps/internal-portal/  # Next.js internal admin UI
├── database/              # DDL scripts
├── infrastructure/        # Redis config
├── docs/                  # Design & setup documentation
└── docker-compose.yml
```
