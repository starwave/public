import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import settings
from app.dependencies import limiter
from app.routers import internal, leads

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s – %(message)s",
)

app = FastAPI(
    title="Alma Lead System API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── Rate limiter ──
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# ── CORS ──
logger = logging.getLogger(__name__)
logger.info("CORS allowed origins: %s", settings.cors_origin_list)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://alma-internal.thirdwavesoft.com",
        "http://alma-lead.thirdwavesoft.com",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["Access-Control-Allow-Private-Network"],
)

# ── Routers ──
app.include_router(leads.router)
app.include_router(internal.router)

@app.get("/health", tags=["Health"])
async def health_check():
    return {"status": "ok"}

@app.middleware("http")
async def add_pna_header(request, call_next):
    response = await call_next(request)
    response.headers["Access-Control-Allow-Private-Network"] = "true"
    return response
