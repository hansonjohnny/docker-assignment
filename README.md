# Flask App with Docker, Redis, and Postgres

[![Build Status](https://github.com/<USERNAME>/<REPO>/actions/workflows/docker.yml/badge.svg)](https://github.com/<USERNAME>/<REPO>/actions/workflows/docker.yml)
[![Docker Image Version](https://img.shields.io/badge/docker-flask--app-blue)](https://github.com/<USERNAME>/<REPO>/packages)
[![GitHub Container Registry](https://img.shields.io/badge/GHCR-published-green)](https://github.com/<USERNAME>/<REPO>/packages)

This project is a **containerized Flask application** using **Docker**, **Redis**, and **PostgreSQL**, built with best practices for production, including:

- Multi-stage Dockerfile to minimize image size
- `docker-compose.yml` to orchestrate multiple services
- `.dockerignore` to exclude unnecessary files
- GitHub Actions workflow to automatically build and push images to **GitHub Container Registry (GHCR)**
- Health checks and non-root user for security

---

## Table of Contents

- [Project Structure](#project-structure)
- [Requirements](#requirements)
- [Setup & Run Locally](#setup--run-locally)
- [Dockerfile](#dockerfile)
- [docker-compose.yml](#docker-composeyml)
- [.dockerignore](#dockerignore)
- [CI/CD Workflow](#cicd-workflow)
- [Image Size Comparison](#image-size-comparison)
- [Images & Registry URLs](#images--registry-urls)
- [Run the Full Stack Locally](#run-the-full-stack-locally)
- [Challenges Encountered & Resolutions](#challenges-encountered--resolutions)
- [Notes](#notes)

---

## Project Structure

```
.
├── app.py
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .github/
│   └── workflows/
│       └── docker.yml
└── README.md
```

---

## Requirements

- Docker Desktop (Windows/Linux/Mac)
- Docker Compose
- GitHub Personal Access Token (PAT) with `read:packages` and `write:packages` permissions for GHCR

---

## Setup & Run Locally

1. **Build and run containers**:

```bash
docker compose build
docker compose up
```

2. **Access the Flask app**:

```
http://localhost:5000
```

3. **Stop containers**:

```bash
docker compose down
```

---

## Dockerfile

- Multi-stage build to reduce image size
- Dependencies installed system-wide in `/usr/local`
- Non-root user `appuser` for security
- Exposes port 5000
- CMD runs `python app.py`

**Snippet:**

```dockerfile
# Stage 1: Builder
FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app
COPY --from=builder /usr/local /usr/local
COPY --from=builder /app /app
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser
EXPOSE 5000
CMD ["python", "app.py"]
```

---

## docker-compose.yml

- Services:
  - `web` → Flask app
  - `redis` → Redis cache
  - `postgres` → PostgreSQL database
- Named volume for Postgres persistence
- Custom bridge network
- Health checks for web and Postgres
- `depends_on` ensures Redis/Postgres start before web

**Snippet:**

```yaml
services:
  web:
    build: .
    ports:
      - "5000:5000"
    environment:
      - REDIS_HOST=redis
    depends_on:
      redis:
        condition: service_started
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

## .dockerignore

- Excludes unnecessary files to **reduce build context and image size**

```text
__pycache__/
*.pyc
*.pyo
*.pyd
env/
venv/
*.egg-info/
.git/
.gitignore
Dockerfile
docker-compose.yml
.vscode/
.idea/
*.log
.DS_Store
Thumbs.db
```

---

## CI/CD Workflow

- Workflow: `.github/workflows/docker.yml`
- Trigger: On **push to main**
- Actions:
  1. Checkout repository
  2. Log in to GHCR using `CR_PAT`
  3. Build Docker image
  4. Push image to GHCR

```yaml
docker build -t ghcr.io/${{ github.repository_owner }}/flask-app:latest .
docker push ghcr.io/${{ github.repository_owner }}/flask-app:latest
```

---

## Image Size Comparison

| Dockerfile Type      | Image Size (approx) |
|---------------------|------------------|
| Single-stage build  | 480 MB           |
| Multi-stage build   | 175 MB           |

**Benefit:** Multi-stage build reduces image size by ~65% by removing build-time dependencies.

---

## Images & Registry URLs

- **DockerHub Image URL:**  
  `docker.io/hansonjohnny/flask-app:latest`

- **GitHub Container Registry (GHCR) URL:**  
  `ghcr.io/hansonjohnny/flask-app:latest`

- **AWS ECR Repository URI:**  
  `669836379908.dkr.ecr.us-east-1.amazonaws.com/flask-app`

---

## Run the Full Stack Locally

To start the full stack (Flask + Redis + Postgres) locally:

```bash
docker compose up --build -d
```

- `--build` ensures any changes in the Dockerfile are applied
- `-d` runs containers in detached mode

---

## Challenges Encountered & Resolutions

1. **Issue: /root/.local not found during build**
   - **Cause:** Installing Python dependencies for the wrong user path in a multi-stage build.
   - **Resolution:** Switched to a **multi-stage Dockerfile** with system-wide installation in `/usr/local` and copying dependencies to runtime stage.

2. **Issue: DockerHub / GHCR push failing**
   - **Cause:** Incorrect authentication or repository not created yet.
   - **Resolution:** Created repositories on DockerHub and GitHub, used **Personal Access Token (PAT)** for GHCR login, and updated `docker login` credentials.

3. **Issue: DNS / network errors pulling base images**
   - **Cause:** Docker Desktop network or proxy issues.
   - **Resolution:** Set a stable DNS (`8.8.8.8`) in Docker settings, ensured internet connectivity, and manually pulled base images when needed.

4. **Issue: Git push failing with “Repository not found”**
   - **Cause:** Remote repository didn’t exist on GitHub.
   - **Resolution:** Created the repo via **GitHub CLI** and updated the remote URL to HTTPS.

---

## Notes

- Health check endpoint in `app.py`:

```python
@app.route("/health")
def health():
    return {"status": "ok"}, 200
```

- Non-root user prevents running the container as root for security
- Multi-stage build ensures minimal runtime image
- `.dockerignore` optimizes build context and avoids copying unnecessary files
- GitHub Actions automates image build and push to GHCR

---

**Project is now ready for deployment** to Kubernetes, or cloud services like AWS ECS.

