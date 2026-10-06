#!/bin/sh
set -e

PORT="${PORT:-8000}"

if [ -n "$DATABASE_URL" ] || [ -n "$TIDB_HOST" ] || [ "$USE_SQLITE" = "true" ] || [ "$USE_SQLITE" = "True" ] || [ "$USE_SQLITE" = "1" ]; then
    echo "ℹ️ [Entrypoint] Using DATABASE_URL, TiDB, or SQLite. Skipping local container PostgreSQL wait."
else
    echo "⏳ [Entrypoint] Waiting for PostgreSQL database at ${POSTGRES_HOST:-db}:${POSTGRES_PORT:-5432}..."
    python << 'EOF'
import os
import sys
import time
import psycopg

host = os.environ.get("POSTGRES_HOST", "db")
port = os.environ.get("POSTGRES_PORT", "5432")
user = os.environ.get("POSTGRES_USER", "student_brain")
password = os.environ.get("POSTGRES_PASSWORD", "rafayet150903")
dbname = os.environ.get("POSTGRES_DB", "student_brain")

max_attempts = 15
attempt = 0

while attempt < max_attempts:
    try:
        conn = psycopg.connect(
            host=host,
            port=port,
            user=user,
            password=password,
            dbname=dbname,
            connect_timeout=3
        )
        conn.close()
        print("✅ [Entrypoint] Database connection established successfully!")
        sys.exit(0)
    except Exception as e:
        attempt += 1
        print(f"⏳ Waiting for database... (attempt {attempt}/{max_attempts}): {e}")
        time.sleep(1)

print("⚠️ [Entrypoint] Local database check finished. Continuing...")
EOF
fi

echo "🚀 [Entrypoint] Running database migrations..."
python manage.py migrate --noinput

echo "📦 [Entrypoint] Collecting static files..."
python manage.py collectstatic --noinput || true

# Auto-seed if AUTO_SEED is set to true/1
if [ "$AUTO_SEED" = "true" ] || [ "$AUTO_SEED" = "1" ]; then
    echo "🌱 [Entrypoint] Checking demo seed data..."
    python << 'EOF'
import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

if User.objects.count() == 0:
    print("🌱 [Entrypoint] Database is empty. Running seed_dummy_data.py...")
    import subprocess
    subprocess.run(["python", "seed_dummy_data.py"], check=True)
else:
    print(f"ℹ️ [Entrypoint] Database already contains {User.objects.count()} user(s). Skipping initial seed.")
EOF
fi

echo "✨ [Entrypoint] Starting Django server on 0.0.0.0:${PORT}..."
exec python manage.py runserver "0.0.0.0:${PORT}"
