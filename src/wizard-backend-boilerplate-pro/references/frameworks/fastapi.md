# FastAPI — Reference

**Language:** Python 3.11+
**Version:** use `fastapi[standard]` (includes uvicorn + email-validator)
**Docs:** https://fastapi.tiangolo.com

## Directory structure (after scaffold)

```
<APP_NAME>/
├── app/
│   ├── main.py             # FastAPI app factory + lifespan
│   ├── core/
│   │   ├── config.py       # pydantic-settings Config
│   │   ├── health.py       # Health check router
│   │   ├── logger.py       # structlog/logging setup
│   │   └── errors.py       # Exception handlers
│   ├── auth/
│   │   ├── router.py       # /auth endpoints
│   │   └── provider.py     # Auth provider bootstrap (from assets/auth-provider/)
│   ├── data/
│   │   ├── users.py        # UsersCRUD router
│   │   └── files.py        # FileUpload router
│   ├── infra/
│   │   ├── database.py     # SQLAlchemy / Motor session
│   │   └── cache.py        # Redis client
│   ├── models/             # SQLAlchemy ORM models
│   └── schemas/            # Pydantic request/response schemas
├── alembic/                # Migrations (if SQLAlchemy)
├── tests/
├── .env
├── .env.example
├── requirements.txt
└── Dockerfile
```

## Init commands

```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
python -m venv .venv && source .venv/bin/activate

pip install "fastapi[standard]" python-dotenv pydantic-settings
pip install ruff mypy

# Create requirements.txt
pip freeze > requirements.txt
```

## app/main.py

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.health import router as health_router
from app.auth.router import router as auth_router
from app.data.users import router as users_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    # await database.connect()
    yield
    # Shutdown
    # await database.disconnect()


limiter = Limiter(key_func=get_remote_address)

app = FastAPI(
    title=settings.APP_NAME,
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan,
)

app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router)
app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(users_router, prefix="/users", tags=["users"])
```

## app/core/config.py

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List

class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    APP_NAME: str = "API"
    PORT: int = 8000
    DATABASE_URL: str = "sqlite+aiosqlite:///./app.db"
    CORS_ORIGINS: List[str] = ["*"]
    JWT_SECRET: str = "change-me"
    JWT_ALGORITHM: str = "HS256"
    REDIS_URL: str = "redis://localhost:6379"

settings = Settings()
```

## Start commands

```bash
# Development
uvicorn app.main:app --reload --port 8000

# Production
uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
```

## Router pattern

```python
from fastapi import APIRouter, Depends, HTTPException
from app.schemas.user import UserCreate, UserResponse
from app.auth.provider import require_auth

router = APIRouter()

@router.get("/", response_model=list[UserResponse])
async def list_users(
    skip: int = 0,
    limit: int = 20,
    user_id: str = Depends(require_auth),
):
    return []

@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(body: UserCreate):
    return {}
```

## Pydantic schema pattern

```python
from pydantic import BaseModel, EmailStr
from datetime import datetime
from uuid import UUID

class UserBase(BaseModel):
    email: EmailStr

class UserCreate(UserBase):
    password: str

class UserResponse(UserBase):
    id: UUID
    created_at: datetime

    model_config = {"from_attributes": True}
```

## Exception handlers

```python
from fastapi import Request
from fastapi.responses import JSONResponse

@app.exception_handler(404)
async def not_found(request: Request, exc):
    return JSONResponse(status_code=404, content={"error": "Not found"})

@app.exception_handler(Exception)
async def server_error(request: Request, exc: Exception):
    return JSONResponse(status_code=500, content={"error": str(exc)})
```

## Rate limiting

```bash
pip install slowapi
```

```python
from slowapi.decorator import limits

@router.get("/heavy")
@limits(calls=10, period=60)
async def heavy_route():
    ...
```

## Type checking

```bash
mypy app --ignore-missing-imports
```

Add `mypy.ini`:
```ini
[mypy]
ignore_missing_imports = True
strict = True
```
