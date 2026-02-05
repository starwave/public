# Design Document – Alma Lead System

## 1. Overview

The Alma Lead System enables prospects to submit their contact information and resume through a public web form. Upon submission, automated emails are sent to both the prospect (confirmation) and an internal attorney (notification). Attorneys access an internal portal to review leads and update their status.

## 2. System Architecture

```
┌──────────────┐      ┌──────────────┐
│  Lead Portal │      │   Internal   │
│  (Next.js)   │      │   Portal     │
│  :4000       │      │  (Next.js)   │
└──────┬───────┘      │   :4001      │
       │              └──────┬───────┘
       │   POST /leads       │  GET/PATCH /internal/leads
       │                     │  (X-API-Key header)
       ▼                     ▼
  ┌─────────────────────────────┐
  │     FastAPI Backend         │
  │     :4002                   │
  │  ┌───────┐ ┌───────────┐   │
  │  │ Rate  │ │ Storage   │   │
  │  │ Limit │ │ Service   │   │
  │  │(Redis)│ │(Local/S3) │   │
  │  └───────┘ └───────────┘   │
  │  ┌───────┐ ┌───────────┐   │
  │  │ Email │ │ Lead      │   │
  │  │Service│ │ Service   │   │
  │  └───────┘ └───────────┘   │
  └──────────┬─────────────────┘
             │
             ▼
  ┌─────────────────┐
  │   PostgreSQL     │
  │   (alma_db)      │
  └─────────────────┘
```

## 3. Key Design Decisions

### 3.1 Monorepo Structure
All components live in a single repository for simplicity and atomic changes across the stack. Services are organized under `services/` and front-end apps under `apps/`.

### 3.2 FastAPI for the API Layer
- **Async-first**: Native async/await support for non-blocking I/O (DB queries, email sending, file uploads).
- **Auto-generated docs**: Swagger UI at `/docs` with zero extra effort.
- **Pydantic v2**: Strong request/response validation with excellent performance.
- **BackgroundTasks**: Email sending runs in the background so the lead creation response isn't delayed.

### 3.3 SQLAlchemy + asyncpg
- SQLAlchemy 2.0 mapped columns provide type-safe ORM with full async support via asyncpg.
- Alembic manages schema migrations with async engine support.

### 3.4 Storage Abstraction (Local / S3)
The `StorageService` uses a strategy pattern: `LocalStorage` and `S3Storage` both implement a common interface. Switching between them requires only changing the `STORAGE_BACKEND` env var. This avoids code changes when moving from local development to production S3 storage.

### 3.5 Rate Limiting with slowapi + Redis
- `slowapi` wraps the `limits` library and integrates directly with FastAPI.
- Redis backend ensures rate limit state is shared across multiple API workers.
- Public endpoint (`POST /leads`): 10 requests/min per IP, 100/hour per IP.
- Internal endpoints: 60/min for listing, 30/min for updates.

### 3.6 Email via Background Tasks
Emails are sent asynchronously using `aiosmtplib` inside FastAPI's `BackgroundTasks`. This keeps the lead creation response fast. If an email fails, it is logged but does not cause the lead submission to fail — the data is already persisted.

### 3.7 Internal Auth (API Key)
Internal endpoints are protected by a static API key sent in the `X-API-Key` header. This is a simple approach appropriate for a single internal tool used by a small team. The internal Next.js portal stores the API key in a cookie after login verification.

### 3.8 Next.js with App Router
Both front-end apps use Next.js 14 with the App Router for modern React Server Components support and built-in routing. Tailwind CSS provides utility-first styling without additional dependencies.

## 4. Database Schema

```sql
CREATE TYPE lead_status AS ENUM ('PENDING', 'REACHED_OUT');

CREATE TABLE leads (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name  VARCHAR(100) NOT NULL,
    last_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(255) NOT NULL,
    resume_path VARCHAR(500) NOT NULL,
    status      lead_status  NOT NULL DEFAULT 'PENDING',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);
```

- **UUID primary key**: Avoids sequential ID enumeration attacks.
- **Indexes** on `email`, `status`, and `created_at DESC` for efficient filtering and sorting.
- **Trigger** auto-updates `updated_at` on row change.

## 5. API Design

| Method | Path | Auth | Rate Limit | Description |
|--------|------|------|------------|-------------|
| POST | /leads | Public | 10/min, 100/hr per IP | Create lead + upload resume |
| GET | /internal/leads | API Key | 60/min | Paginated lead list with status filter |
| PATCH | /internal/leads/{id} | API Key | 30/min | Update lead status |
| GET | /health | None | None | Health check |

### Lead State Machine
```
PENDING ──(attorney marks)──▶ REACHED_OUT
```

## 6. Security Considerations

- **File validation**: Only PDF uploads accepted, max 10 MB.
- **Rate limiting**: Prevents abuse of the public endpoint.
- **CORS**: Restricted to known front-end origins.
- **API key auth**: Internal endpoints require a valid key.
- **Input sanitization**: Pydantic enforces field length limits and email format.
- **UUID IDs**: Non-sequential, preventing enumeration.

## 7. Scalability Path

- **Storage**: Switch from local disk to S3 by changing one env var.
- **Workers**: Run multiple uvicorn workers behind a reverse proxy.
- **Database**: Add read replicas for the internal portal's read-heavy queries.
- **Email**: Replace background tasks with a message queue (e.g., Celery + Redis) for guaranteed delivery.
