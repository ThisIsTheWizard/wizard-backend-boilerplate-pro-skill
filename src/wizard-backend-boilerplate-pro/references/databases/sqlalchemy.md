# SQLAlchemy — Reference

**Ecosystems:** Python (FastAPI, Flask, Django override)
**Databases:** PostgreSQL, MySQL, SQLite, Oracle, MS SQL
**Docs:** https://docs.sqlalchemy.org/en/20

## Install

```bash
# Core + async support
pip install sqlalchemy[asyncio] alembic

# PostgreSQL async driver
pip install asyncpg

# MySQL async driver
pip install aiomysql

# SQLite async driver
pip install aiosqlite
```

## Base model setup (app/models/base.py)

```python
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column
from sqlalchemy import String, Boolean, DateTime, func
from datetime import datetime
from uuid import UUID, uuid4

class Base(DeclarativeBase):
    pass

class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(DateTime, server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now()
    )
```

## User model (app/models/user.py)

```python
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import String, Boolean, Index
from uuid import UUID, uuid4
from .base import Base, TimestampMixin

class User(Base, TimestampMixin):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False, index=True)
    password: Mapped[str] = mapped_column(String(255), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
```

## Async database session (app/infra/database.py)

```python
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from contextlib import asynccontextmanager
from app.core.config import settings

engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    echo=settings.DEBUG,
)

AsyncSessionLocal = async_sessionmaker(engine, expire_on_commit=False)

async def get_db() -> AsyncSession:
    """FastAPI dependency — yields a session, commits on success, rolls back on error."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
```

## Using in FastAPI routes

```python
from fastapi import Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.infra.database import get_db
from app.models.user import User

@router.get("/")
async def list_users(
    page: int = 1,
    limit: int = 20,
    search: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    q = select(User).order_by(User.created_at.desc())
    if search:
        q = q.where(User.email.ilike(f"%{search}%"))

    total_q = select(func.count()).select_from(q.subquery())
    total = await db.scalar(total_q)

    result = await db.execute(q.offset((page - 1) * limit).limit(limit))
    users = result.scalars().all()

    return {"users": users, "total": total, "page": page}
```

## Flask integration (synchronous)

```python
# Use synchronous SQLAlchemy for Flask
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session

engine = create_engine(settings.DATABASE_URL, pool_size=5, max_overflow=10)
Session = scoped_session(sessionmaker(bind=engine))

# Usage in route
db = Session()
try:
    users = db.query(User).all()
    return jsonify([u.to_dict() for u in users])
finally:
    Session.remove()
```

## Alembic migration commands

```bash
# Initialize alembic
alembic init alembic

# Update alembic/env.py to import your Base and use DATABASE_URL
# (see alembic docs for async setup)

alembic revision --autogenerate -m "add users table"
alembic upgrade head
alembic downgrade -1
alembic history
```

## Connection string formats

```env
# Async PostgreSQL
DATABASE_URL=postgresql+asyncpg://user:password@localhost:5432/dbname

# Async MySQL
DATABASE_URL=mysql+aiomysql://user:password@localhost:3306/dbname

# Async SQLite
DATABASE_URL=sqlite+aiosqlite:///./app.db

# Sync (Flask)
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
```
