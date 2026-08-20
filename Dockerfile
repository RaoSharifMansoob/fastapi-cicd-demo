FROM python:3.12.2-slim as base
LABEL maintainer="hello@beerjoa.dev"
LABEL build_date="2024-03-13"

# Install system dependencies
RUN apt-get update \
    && apt-get -y install libpq-dev gcc \
    && rm -rf /var/lib/apt/lists/*

# Configure Poetry variables
ENV POETRY_VERSION=1.8.2
ENV POETRY_HOME=/opt/poetry
ENV POETRY_VENV=/opt/poetry-venv
ENV POETRY_CACHE_DIR=/opt/.cache
ENV PATH="${PATH}:$POETRY_VENV/bin"

# Install Poetry in an isolated virtual environment
RUN python3 -m venv $POETRY_VENV && \
    $POETRY_VENV/bin/pip install -U pip setuptools && \
    $POETRY_VENV/bin/pip install "poetry==$POETRY_VERSION"

# Set working directory
WORKDIR /data/backend

# STEP 1: Copy ONLY dependency files first (Optimizes Docker layer caching)
COPY poetry.lock pyproject.toml ./
RUN poetry install --no-interaction --no-root

# STEP 2: Copy the actual source code application files LAST
COPY . /data/backend

# === TARGET STAGES ===

## Development Stage
FROM base as development
CMD [ "poetry", "run", "python", "-c", "print('development')" ]

## Production Stage
FROM base as production
# Forces Python to print logs immediately to the terminal (fixes blank logs issue)
ENV PYTHONUNBUFFERED=1 
CMD [ "poetry", "run", "uvicorn", "app.main:create_app", "--factory", "--host", "0.0.0.0", "--port", "8000" ]
