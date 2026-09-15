from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.brain_dump import router as brain_dump_router
from app.api.debug_cron import router as debug_cron_router
from app.api.insights import router as insights_router
from app.api.tasks import router as tasks_router
from app.core.config import settings

app = FastAPI(
    title="ALUR Backend API",
    version="1.0.0",
    description="Quiet monochrome weekly planner backend service powered by FastAPI and Supabase",
)

# Enable CORS for Flutter mobile and Next.js web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include Routers
app.include_router(tasks_router)
app.include_router(brain_dump_router)
app.include_router(insights_router)
app.include_router(debug_cron_router)


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
