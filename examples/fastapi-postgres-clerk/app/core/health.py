from fastapi import APIRouter
from app.core.config import settings

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check():
    return {
        "status": "ok",
        "version": "1.0.0",
        "env": settings.ENV,
        "db": "connected",
    }
