# Flask — Reference

**Language:** Python 3.11+
**Version:** Flask 3.x
**Docs:** https://flask.palletsprojects.com

## Directory structure (after scaffold)

```
<APP_NAME>/
├── app/
│   ├── __init__.py         # App factory (create_app)
│   ├── core/
│   │   ├── health.py       # /health blueprint
│   │   ├── config.py       # Config class
│   │   └── errors.py       # Error handlers
│   ├── auth/
│   │   ├── __init__.py
│   │   ├── routes.py       # /auth blueprint
│   │   └── provider.py     # Auth provider bootstrap
│   ├── users/
│   │   ├── __init__.py
│   │   ├── routes.py       # /users blueprint
│   │   ├── models.py
│   │   └── schemas.py      # marshmallow / pydantic schemas
│   └── extensions.py       # Flask extensions (db, ma, etc.)
├── migrations/             # Flask-Migrate
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

pip install flask flask-cors flask-restx python-dotenv

pip freeze > requirements.txt
```

## app/__init__.py (factory)

```python
from flask import Flask
from flask_cors import CORS
from dotenv import load_dotenv
import os

load_dotenv()

def create_app(config_name: str = "default") -> Flask:
    app = Flask(__name__)
    app.config.from_object(_config_map[config_name])

    CORS(app, origins=os.getenv("CORS_ORIGINS", "*").split(","))

    # Register blueprints
    from app.core.health import health_bp
    from app.auth.routes import auth_bp
    from app.users.routes import users_bp

    app.register_blueprint(health_bp)
    app.register_blueprint(auth_bp, url_prefix="/auth")
    app.register_blueprint(users_bp, url_prefix="/users")

    # Register error handlers
    from app.core.errors import register_error_handlers
    register_error_handlers(app)

    # Swagger (flask-restx auto-generates at /docs)

    return app

_config_map = {
    "default": "app.core.config.DevelopmentConfig",
    "production": "app.core.config.ProductionConfig",
}
```

## app/core/config.py

```python
import os

class BaseConfig:
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret")
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL", "sqlite:///app.db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    REDIS_URL = os.getenv("REDIS_URL", "redis://localhost:6379")
    CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")

class DevelopmentConfig(BaseConfig):
    DEBUG = True

class ProductionConfig(BaseConfig):
    DEBUG = False
```

## Blueprint pattern

```python
# app/users/routes.py
from flask import Blueprint, request, jsonify, g
from app.auth.provider import require_auth

users_bp = Blueprint("users", __name__)

@users_bp.get("/")
@require_auth
def list_users():
    page = request.args.get("page", 1, type=int)
    return jsonify({"users": [], "page": page})

@users_bp.post("/")
def create_user():
    data = request.get_json(force=True)
    return jsonify({"id": "new-user-id"}), 201
```

## Flask-RESTX (Swagger auto-gen)

```bash
pip install flask-restx
```

```python
from flask_restx import Api, Resource, fields

api = Api(app, doc="/docs", title="API", version="1.0")

ns = api.namespace("users", description="User operations")

user_model = api.model("User", {
    "id": fields.String,
    "email": fields.String,
})

@ns.route("/")
class UserList(Resource):
    @ns.marshal_list_with(user_model)
    def get(self):
        """List all users"""
        return []
```

## Running

```bash
# With factory pattern
flask --app "app:create_app" run --port 8000 --debug

# Or set FLASK_APP env var
export FLASK_APP="app:create_app"
flask run --port 8000
```

## Error handler pattern

```python
# app/core/errors.py
from flask import jsonify
from werkzeug.exceptions import HTTPException

def register_error_handlers(app):
    @app.errorhandler(HTTPException)
    def http_error(e):
        return jsonify({"error": e.description}), e.code

    @app.errorhandler(Exception)
    def server_error(e):
        app.logger.exception(e)
        return jsonify({"error": "Internal server error"}), 500
```

## Common extensions

| Extension | Purpose | Install |
|---|---|---|
| Flask-SQLAlchemy | ORM integration | `pip install flask-sqlalchemy` |
| Flask-Migrate | Alembic migration runner | `pip install flask-migrate` |
| Flask-RESTX | Swagger + resource routing | `pip install flask-restx` |
| Flask-Limiter | Rate limiting | `pip install flask-limiter` |
| Flask-Session | Server-side sessions | `pip install Flask-Session` |
