# Django + DRF — Reference

**Language:** Python 3.11+
**Versions:** Django 5.x + djangorestframework 3.x
**Docs:** https://docs.djangoproject.com, https://www.django-rest-framework.org

## Directory structure (after scaffold)

```
<APP_NAME>/
├── config/
│   ├── settings/
│   │   ├── __init__.py
│   │   ├── base.py         # Shared settings
│   │   ├── development.py  # Dev overrides
│   │   └── production.py   # Prod overrides
│   ├── urls.py             # Root URL conf
│   ├── wsgi.py
│   └── asgi.py
├── apps/
│   ├── health/             # health check app
│   ├── accounts/           # auth app (User model, JWT endpoints)
│   ├── users/              # users CRUD app
│   └── files/              # file upload app
├── common/
│   ├── permissions.py
│   ├── pagination.py
│   └── exceptions.py
├── manage.py
├── .env
├── requirements.txt
└── Dockerfile
```

## Init commands

```bash
mkdir "$APP_NAME" && cd "$APP_NAME"
python -m venv .venv && source .venv/bin/activate

pip install django djangorestframework django-cors-headers \
            djangorestframework-simplejwt python-dotenv drf-yasg

django-admin startproject config .

# Create apps
python manage.py startapp health apps/health
python manage.py startapp accounts apps/accounts
python manage.py startapp users apps/users

pip freeze > requirements.txt
```

## config/settings/base.py

```python
import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()
BASE_DIR = Path(__file__).resolve().parent.parent.parent

SECRET_KEY = os.environ["DJANGO_SECRET_KEY"]
ALLOWED_HOSTS = os.getenv("ALLOWED_HOSTS", "*").split(",")
DEBUG = os.getenv("DEBUG", "False") == "True"

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    # Third-party
    "rest_framework",
    "corsheaders",
    "drf_yasg",
    # Local apps
    "apps.health",
    "apps.accounts",
    "apps.users",
]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]

ROOT_URLCONF = "config.urls"
WSGI_APPLICATION = "config.wsgi.application"

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.postgresql",
        "NAME": os.getenv("DB_NAME", "app"),
        "USER": os.getenv("DB_USER", "postgres"),
        "PASSWORD": os.getenv("DB_PASSWORD", ""),
        "HOST": os.getenv("DB_HOST", "localhost"),
        "PORT": os.getenv("DB_PORT", "5432"),
    }
}

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework_simplejwt.authentication.JWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticatedOrReadOnly",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "DEFAULT_RENDERER_CLASSES": ["rest_framework.renderers.JSONRenderer"],
}

CORS_ALLOWED_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")

STATIC_URL = "/static/"
DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"
```

## config/urls.py

```python
from django.urls import path, include
from drf_yasg.views import get_schema_view
from drf_yasg import openapi
from rest_framework.permissions import AllowAny

schema_view = get_schema_view(
    openapi.Info(title="API", default_version="v1"),
    public=True,
    permission_classes=[AllowAny],
)

urlpatterns = [
    path("health/", include("apps.health.urls")),
    path("auth/", include("apps.accounts.urls")),
    path("users/", include("apps.users.urls")),
    path("docs/", schema_view.with_ui("swagger", cache_timeout=0), name="swagger-ui"),
    path("docs/json/", schema_view.without_ui(cache_timeout=0), name="schema-json"),
]
```

## ViewSet pattern

```python
# apps/users/views.py
from rest_framework import viewsets, permissions
from rest_framework.response import Response
from .models import User
from .serializers import UserSerializer

class UserViewSet(viewsets.ModelViewSet):
    queryset = User.objects.all().order_by("-created_at")
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        search = self.request.query_params.get("search")
        if search:
            qs = qs.filter(email__icontains=search)
        return qs
```

## Running

```bash
python manage.py migrate
python manage.py runserver 8000
```

## Django management commands

```bash
python manage.py makemigrations   # generate migration
python manage.py migrate          # apply migrations
python manage.py createsuperuser  # create admin user
python manage.py shell            # Python REPL with Django loaded
python manage.py collectstatic    # gather static files
```
