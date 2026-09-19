import sys
from pathlib import Path

# Ensure backend directory is in sys.path when running from repository root or Vercel
BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.brain_dump import router as brain_dump_router
from app.api.chat import router as chat_router
from app.api.debug_cron import router as debug_cron_router
from app.api.insights import router as insights_router
from app.api.internal_cron import router as internal_cron_router
from app.api.tasks import router as tasks_router
from app.core.config import settings

app = FastAPI(
    title="ALUR Backend API",
    version="1.0.0",
    description="Quiet monochrome weekly planner backend service powered by FastAPI and Supabase",
)

# Enable strict CORS for Flutter mobile and Next.js web clients (DEPLOYMENT_GUIDE.md)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://alurproject.web.id",
        "https://www.alurproject.web.id",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(tasks_router)
app.include_router(chat_router)
app.include_router(brain_dump_router)
app.include_router(insights_router)
app.include_router(debug_cron_router)
app.include_router(internal_cron_router)


@app.get("/health", tags=["system"])
def health_check():
    """Health check endpoint to verify backend service status."""
    return {
        "status": "healthy",
        "service": "alur-backend",
        "environment": settings.BACKEND_ENV,
    }


@app.get("/", tags=["system"])
def root():
    """Root entry point providing API overview."""
    return {
        "app": "ALUR",
        "version": "1.0.0",
        "docs": "/docs",
        "health": "/health",
    }
