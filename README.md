# Docker Mastery Assignment

> Build, Ship, and Orchestrate Containers

**Author:** Hanson Johnny  
**Program:** ElevateHub DevOps Track | Technology Excellence Services  
**Instructor:** Dr. Fred Ayivor

---

## Table of Contents

- [Project Overview](#project-overview)
- [Prerequisites](#prerequisites)
- [Part 1 — Build the Docker Image](#part-1--build-the-docker-image)
- [Part 2 — Push to DockerHub](#part-2--push-to-dockerhub)
- [Part 3 — Push to GitHub Container Registry (GHCR)](#part-3--push-to-github-container-registry-ghcr)
- [Part 4 — Push to AWS ECR](#part-4--push-to-aws-ecr)
- [Part 5 — Docker Compose Multi-Service Application](#part-5--docker-compose-multi-service-application)
- [Bonus Challenges](#bonus-challenges)
- [Essential Docker Commands](#essential-docker-commands)

---

## Project Overview

This project covers the complete Docker workflow used in production DevOps environments, including building Docker images, pushing to multiple container registries, and orchestrating multi-service applications with Docker Compose.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────┐
│   Flask App     │────│   Redis     │
│   (Port 5000)   │    │  (Port 6379)│
└─────────────────┘    └─────────────┘
         │
         └─────────────────┐
                           │
                    ┌─────────────┐
                    │ PostgreSQL  │
                    │  (Port 5432)│
                    └─────────────┘
```

### Learning Objectives

- Build production-ready Docker images following best practices (layer caching, non-root user, minimal base image)
- Push container images to three major registries: **DockerHub**, **GitHub Container Registry (GHCR)**, and **AWS Elastic Container Registry (ECR)**
- Wire up a multi-container application (Flask + Redis + PostgreSQL) using Docker Compose
- Understand container networking, volumes, health checks, and service dependencies

---

## Prerequisites

| Tool / Service | Version / Tier | Purpose |
|---|---|---|
| Docker Desktop | Latest stable | Build and run containers locally |
| AWS CLI v2 | Configured with IAM credentials | Authenticate to ECR |
| DockerHub Account | Free tier | Public image registry |
| GitHub Account | Free tier (GHCR) | GitHub Container Registry |
| GitHub PAT (Classic) | `write:packages` scope | Authenticate Docker to GHCR |
| Git | Latest stable | Version control and repo management |

---

## Part 1 — Build the Docker Image

## 🧰 Project Structure

```
docker-assignment/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── Dockerfile            # Multi-stage production build
├── docker-compose.yml    # Local development stack
├── .github/
│   └── workflows/
│       └── docker.yml    # CI/CD pipeline
├── screenshots/          # Project screenshots
└── README.md            # This file
```

### The Application

`app.py` is a minimal Flask web application exposing a single `GET /` endpoint that returns a JSON response with a greeting message and the container hostname.

```python
from flask import Flask, jsonify
import socket

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({
        "message": "Hello from Docker!",
        "hostname": socket.gethostname()
    })

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

`requirements.txt` pins the exact Flask version for reproducible builds:

```
flask==3.0.0
```

### The Dockerfile

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copy requirements first — layer caching best practice
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Copy the rest of the application
COPY . .

# Security: create and switch to a non-root user
RUN adduser --disabled-password --gecos "" appuser
USER appuser

EXPOSE 5000

CMD ["python", "app.py"]
```

**Best Practices Applied:**

| Practice | Reason |
|---|---|
| `python:3.11-slim` base image | Minimal attack surface; smaller than the full image |
| Layer caching | `requirements.txt` copied and installed before source code — code changes don't invalidate the pip layer |
| Non-root user (`appuser`) | Reduces impact of potential vulnerabilities |
| `--no-cache-dir` flag | Prevents pip from writing a cache to disk, keeping the layer smaller |
| `EXPOSE 5000` | Documents the intended port; does not publish it automatically |

### Build and Local Test

```bash
# Build the image
docker build -t flask-app:v1.0 .

# Run the container in detached mode
docker run -d -p 5000:5000 --name flask-test flask-app:v1.0

# Verify the app returns JSON
curl http://localhost:5000
# Expected: {"hostname": "<container-id>", "message": "Hello from Docker!"}

# Check container is running
docker ps

# View container logs
docker logs flask-test
```

---

## Part 2 — Push to DockerHub

DockerHub images follow the format `username/image-name:tag`.

### Tag the Image

```bash
docker tag flask-app:v1.0 hansonjohnny/flask-app:v1.0
docker tag flask-app:v1.0 hansonjohnny/flask-app:latest
```

### Login and Push

```bash
# Authenticate to DockerHub
docker login

# Push both tags
docker push hansonjohnny/flask-app:v1.0
docker push hansonjohnny/flask-app:latest
```

### Verification

Navigate to [hub.docker.com](https://hub.docker.com) and confirm both tags (`v1.0` and `latest`) appear under the repository's **Tags** tab.

---

## Part 3 — Push to GitHub Container Registry (GHCR)

GHCR hosts images at `ghcr.io/USERNAME/IMAGE:TAG`. Public images are free with no storage limits.

### Step 1 — Create a GitHub Personal Access Token (Classic)

1. Go to **GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)**
2. Click **Generate new token (classic)** — do **not** use Fine-grained tokens
3. Name it `docker-assignment` and set expiration to at least 7 days
4. Check only the `write:packages` scope (`read:packages` and `delete:packages` are included automatically)
5. Click **Generate token** and copy it immediately — GitHub will not show it again

### Step 2 — Login to GHCR

```bash
# Store token in an environment variable to keep it out of shell history
export CR_PAT=YOUR_PAT

# Login to ghcr.io
echo $CR_PAT | docker login ghcr.io -u hansonjohnny --password-stdin
```

### Step 3 — Tag and Push

```bash
# GHCR format: ghcr.io/USERNAME/IMAGE:TAG (must be all lowercase)
docker tag flask-app:v1.0 ghcr.io/hansonjohnny/flask-app:v1.0
docker tag flask-app:v1.0 ghcr.io/hansonjohnny/flask-app:latest

docker push ghcr.io/hansonjohnny/flask-app:v1.0
docker push ghcr.io/hansonjohnny/flask-app:latest
```

### Step 4 — Make the Package Public (Recommended)

Go to **GitHub profile → Packages → flask-app → Package settings → Change visibility → Public** so instructors can pull and test the image without authentication.

---

## Part 4 — Push to AWS ECR

Amazon ECR is the production-grade private registry used in AWS-based infrastructure including EKS and ECS deployments.

### Create the ECR Repository

```bash
# Replace us-east-1 with your preferred region
aws ecr create-repository \
  --repository-name flask-app \
  --region us-east-1

# Note the repositoryUri from the output:
# 123456789012.dkr.ecr.us-east-1.amazonaws.com/flask-app
```

### Authenticate Docker to ECR

ECR uses short-lived tokens. The command below fetches a token and pipes it directly to `docker login`:

```bash
# Find your AWS account ID if needed
aws sts get-caller-identity

# Get auth token and log in
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS \
  --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
```

### Tag and Push

```bash
# Tag using the full ECR URI
docker tag flask-app:v1.0 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/flask-app:v1.0

# Push the image
docker push \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/flask-app:v1.0
```

> **Note:** The repository URI shown above is not the actual one and has been replaced for security reasons.

### Verification

Navigate to **AWS Console → ECR → Repositories → flask-app** and confirm the image and `v1.0` tag appear under **Images**.

---

## Part 5 — Docker Compose Multi-Service Application

Docker Compose wires up a three-tier architecture: Flask web app, Redis cache, and PostgreSQL database.

### Updated Application with Redis

The Flask app is extended to connect to Redis and track visit counts:

```python
from flask import Flask, jsonify
import socket, redis, os

app = Flask(__name__)
r = redis.Redis(host=os.getenv('REDIS_HOST', 'redis'), port=6379)

@app.route('/')
def home():
    visits = r.incr('visits')
    return jsonify({
        'message': 'Hello, From Docker!',
        'hostname': socket.gethostname(),
        'visits': int(visits)
    })

@app.route('/health')
def health():
    return jsonify({'status': 'ok'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
```

Updated `requirements.txt`:

```
flask==3.0.0
redis==5.0.1
```

### docker-compose.yml

```yaml
version: '3.9'

services:
  web:
    build: .
    restart: unless-stopped
    ports:
      - "5000:5000"
    environment:
      REDIS_HOST: redis
      POSTGRES_HOST: postgres
    depends_on:
      redis:
        condition: service_started
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:5000/health')"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - app-network

  redis:
    image: "redis:7-alpine"
    restart: unless-stopped
    volumes:
      - redis_data:/data
    networks:
      - app-network

  postgres:
    image: "postgres:16-alpine"
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - pg_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - app-network

volumes:
  pg_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

### Key Compose Concepts Applied

| Concept | Implementation |
|---|---|
| Named Network | `app-network` (bridge) — isolates services from the default network |
| Named Volume | `pg_data` — persists PostgreSQL data across container restarts |
| Health Check | `postgres` uses `pg_isready`; `web` uses the `/health` endpoint |
| `depends_on` + condition | Ensures `postgres` is healthy and `redis` is started before `web` launches |
| Environment Variables | `REDIS_HOST` injected into web; postgres credentials via env vars |
| Alpine Images | `redis:7-alpine` and `postgres:16-alpine` — minimal base images |

### Start and Test the Stack

```bash
# Build and start all services
docker compose up --build -d

# Verify all services are running
docker compose ps

# Test the visit counter (increments each call)
curl http://localhost:5000
curl http://localhost:5000
curl http://localhost:5000

# View logs from all services
docker compose logs

# Tear down (preserves volumes)
docker compose down

# Tear down and remove volumes
docker compose down -v
```

---

## Bonus Challenges

### Bonus B — Multi-Stage Build

A multi-stage build produces a leaner final image by separating the build environment from the runtime environment.

```dockerfile
# Stage 1: Builder
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Final image
FROM python:3.11-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN adduser --disabled-password --gecos '' appuser

# Copy only installed dependencies from builder
COPY --from=builder /install /usr/local

COPY . .

RUN chown -R appuser:appuser /app
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

CMD ["python", "app.py"]
```

### Bonus C — GitHub Actions CI/CD Pipeline

Automatically builds and pushes the image to GHCR on every push to `main`:

```yaml
name: Build, Test & Push Docker Image

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

concurrency:
  group: docker-image-${{ github.ref }}
  cancel-in-progress: true

permissions:
  contents: read
  packages: write

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up QEMU (for multi-arch builds)
        uses: docker/setup-qemu-action@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GitHub Container Registry
        uses: docker/login-action@v2
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: |
            ghcr.io/${{ github.repository_owner }}/docker-assignment:latest
            ghcr.io/${{ github.repository_owner }}/docker-assignment:${{ github.sha }}
          platforms: linux/amd64,linux/arm64
          cache-from: type=gha
          cache-to: type=gha,mode=max

      - name: Run container smoke test
        run: |
          IMAGE=ghcr.io/${{ github.repository_owner }}/docker-assignment:${{ github.sha }}
          docker run -d --rm --name docker-smoke-test -p 5000:5000 "$IMAGE"
          for i in {1..15}; do
            if curl --fail --silent http://localhost:5000/health; then
              echo "Health check passed"
              break
            fi
            echo "Waiting for /health... ($i/15)"
            sleep 2
          done
          docker stop docker-smoke-test
```

### Bonus D — .dockerignore

Reduces the build context sent to the Docker daemon, speeding up builds and preventing unnecessary files from ending up in the image.

```
# Git
.git
.gitignore

# Python cache
__pycache__/
*.pyc
*.pyo
*.pyd

# Virtual environments
venv/
.env/
env/

# Environment variables / secrets
.env

# Docker files
Dockerfile
docker-compose.yml

# Logs
*.log

# OS files
.DS_Store
Thumbs.db

# IDE / Editor files
.vscode/
.idea/

# Test / temp files
tests/
*.tmp
```

---

## Essential Docker Commands

| Command | Purpose |
|---|---|
| `docker build -t name:tag .` | Build image from Dockerfile |
| `docker tag source:tag dest:tag` | Add a new tag/name to an image |
| `docker push image:tag` | Push to a registry |
| `docker pull image:tag` | Pull from a registry |
| `docker images` | List local images |
| `docker ps` | List running containers |
| `docker run -d -p 5000:5000 image` | Run container in background |
| `docker logs container-name` | View container output |
| `docker exec -it container bash` | Shell into a running container |
| `docker compose up --build -d` | Start Compose stack |
| `docker compose ps` | Check Compose service status |
| `docker compose logs` | View all service logs |
| `docker compose down -v` | Stop stack and remove volumes |
