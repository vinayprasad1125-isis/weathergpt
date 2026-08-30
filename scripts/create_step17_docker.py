import os

base_dir = '/Users/vinayprasad/development/weathergpt/backend'

dockerfile_content = """FROM python:3.11-slim as requirements-stage
WORKDIR /tmp
RUN pip install poetry
COPY ./requirements.txt /tmp/
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /tmp/wheels -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
COPY --from=requirements-stage /tmp/wheels /wheels
COPY --from=requirements-stage /tmp/requirements.txt .
RUN pip install --no-cache /wheels/*

COPY ./app /app/app

# Non-root user
RUN useradd -m appuser && chown -R appuser /app
USER appuser

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
"""

docker_compose_content = """version: '3.8'

services:
  web:
    build: .
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql+asyncpg://postgres:postgres@postgres:5432/weathergpt
      - WEATHER_API_BASE_URL=https://api.open-meteo.com/v1
      - GEOCODING_API_BASE_URL=https://geocoding-api.open-meteo.com/v1
      - LLM_API_KEY=${LLM_API_KEY}
      - LLM_MODEL=gemini-2.5-flash
    depends_on:
      postgres:
        condition: service_healthy
    networks:
      - weathergpt-network
    restart: unless-stopped

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=weathergpt
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - weathergpt-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d weathergpt"]
      interval: 5s
      timeout: 5s
      retries: 5
    restart: unless-stopped

volumes:
  postgres_data:

networks:
  weathergpt-network:
    driver: bridge
"""

dockerignore_content = """__pycache__
*.pyc
*.pyo
*.pyd
.Python
env/
venv/
.venv/
.env
.pytest_cache/
tests/
"""

env_example_content = """# DATABASE CONFIGURATION
# Defaults to SQLite if not set, or set to Postgres for production/docker
DATABASE_URL=postgresql+asyncpg://postgres:postgres@postgres:5432/weathergpt

# APIs
WEATHER_API_BASE_URL=https://api.open-meteo.com/v1
GEOCODING_API_BASE_URL=https://geocoding-api.open-meteo.com/v1

# LLM
LLM_API_KEY=your_gemini_api_key_here
LLM_MODEL=gemini-2.5-flash

# INGESTION SETTINGS
# MQTT_BROKER_URL=
# WIS2_NODE_URL=
"""

def write_file(path, content):
    with open(path, 'w') as f:
        f.write(content)
    print(f"Created/Updated {path}")

if __name__ == '__main__':
    write_file(os.path.join(base_dir, 'Dockerfile'), dockerfile_content)
    write_file(os.path.join(base_dir, 'docker-compose.yml'), docker_compose_content)
    write_file(os.path.join(base_dir, '.dockerignore'), dockerignore_content)
    write_file(os.path.join(base_dir, '.env.example'), env_example_content)
    print("Dockerization (Step 17) files created successfully!")
