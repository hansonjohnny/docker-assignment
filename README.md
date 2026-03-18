# Docker Assignment

[![Docker Image CI](https://github.com/your-username/docker-assignment/actions/workflows/docker.yml/badge.svg)](https://github.com/your-username/docker-assignment/actions/workflows/docker.yml)
[![Docker Image Size](https://img.shields.io/docker/image-size/your-username/docker-assignment)](https://hub.docker.com/r/your-username/docker-assignment)

A comprehensive Docker assignment demonstrating modern containerization practices for a Flask web application. This project showcases a production-ready microservice architecture with Redis caching, health checks, multi-stage Docker builds, and automated CI/CD pipelines.

## 📋 Project Overview

This is a simple yet complete web application that demonstrates:

- **Microservice Architecture**: Flask app containerized with Redis for data persistence
- **Container Orchestration**: Multi-service setup using Docker Compose
- **Production-Ready Builds**: Multi-stage Dockerfile with security best practices
- **CI/CD Pipeline**: Automated building, testing, and deployment via GitHub Actions
- **Health Monitoring**: Built-in health checks and monitoring endpoints

The application provides a visit counter that persists across container restarts using Redis, along with a health endpoint for monitoring service availability.

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

### Components

- **Flask Web Server**: Lightweight Python web framework serving HTTP requests
- **Redis Cache**: In-memory data store for visit counter persistence
- **PostgreSQL Database**: Relational database (included for future expansion)
- **Docker**: Containerization platform
- **Docker Compose**: Multi-container orchestration
- **GitHub Actions**: CI/CD automation

## 🔌 API Endpoints

### GET `/`

Returns a JSON response with:

- Welcome message
- Container hostname
- Current visit count (incremented on each request)

**Example Response:**

```json
{
  "message": "Hello, From Docker!",
  "hostname": "abc123def456",
  "visits": 42
}
```

### GET `/health`

Health check endpoint for monitoring and load balancers.

**Example Response:**

```json
{
  "status": "ok"
}
```

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

### Key Files Explained

- **`app.py`**: Core Flask application with two routes (`/` and `/health`)
- **`Dockerfile`**: Multi-stage build creating a secure, minimal production image
- **`docker-compose.yml`**: Defines services for web app, Redis, and PostgreSQL
- **`requirements.txt`**: Python packages (Flask 3.0.0, Redis 5.0.1)
- **`.github/workflows/docker.yml`**: Automated CI pipeline

## 🚀 Getting Started

### Prerequisites

- Docker & Docker Compose
- Git
- Python 3.11+ (for local development)

### Quick Start with Docker Compose

1. **Clone the repository:**

   ```bash
   git clone https://github.com/your-username/docker-assignment.git
   cd docker-assignment
   ```

2. **Start all services:**

   ```bash
   docker compose up -d
   ```

3. **Verify the application:**

   ```bash
   curl http://localhost:5000/
   curl http://localhost:5000/health
   ```

4. **Stop services:**
   ```bash
   docker compose down
   ```

## 🐳 Docker Usage

### Single Container (Production)

```bash
# Build the image
docker build -t docker-assignment:latest .

# Run the container
docker run -d \
  --name flask-app \
  -p 5000:5000 \
  -e REDIS_HOST=redis-host \
  docker-assignment:latest
```

### Multi-Container Stack

```bash
# Start full stack
docker compose up

# Start in background
docker compose up -d

# View logs
docker compose logs -f web

# Stop and remove
docker compose down
```

### Environment Variables

| Variable            | Default    | Description                |
| ------------------- | ---------- | -------------------------- |
| `REDIS_HOST`        | `redis`    | Redis server hostname      |
| `POSTGRES_HOST`     | `postgres` | PostgreSQL server hostname |
| `POSTGRES_USER`     | -          | PostgreSQL username        |
| `POSTGRES_PASSWORD` | -          | PostgreSQL password        |
| `POSTGRES_DB`       | -          | PostgreSQL database name   |

## 🔧 Local Development

### Without Docker

1. **Set up virtual environment:**

   ```bash
   python -m venv .venv
   source .venv/bin/activate  # Linux/Mac
   # or
   .venv\Scripts\activate     # Windows
   ```

2. **Install dependencies:**

   ```bash
   pip install -r requirements.txt
   ```

3. **Start Redis:**

   ```bash
   # Using Docker (recommended)
   docker run -d --name redis -p 6379:6379 redis:7-alpine

   # Or install Redis locally
   redis-server
   ```

4. **Run the application:**

   ```bash
   python app.py
   ```

5. **Test endpoints:**
   ```bash
   curl http://localhost:5000/
   curl http://localhost:5000/health
   ```

### With Docker (Development)

```bash
# Build development image
docker build -t docker-assignment:dev .

# Run with volume mounting for live reload
docker run -d \
  --name flask-dev \
  -p 5000:5000 \
  -v $(pwd):/app \
  -e FLASK_ENV=development \
  docker-assignment:dev
```

## 🏭 CI/CD Pipeline

The GitHub Actions workflow (`.github/workflows/docker.yml`) provides:

### Triggers

- Push to `main` branch
- Pull requests targeting `main`

### Features

- **Multi-architecture builds** (AMD64 + ARM64)
- **Build caching** for faster subsequent builds
- **Automated testing** with health check validation
- **Container registry** publishing to GitHub Container Registry
- **Concurrency control** to prevent resource conflicts

### Workflow Steps

1. Checkout code
2. Set up Docker Buildx and QEMU
3. Authenticate with GHCR
4. Build and push multi-arch image
5. Run smoke test against built container

### Published Image

- **Registry**: `ghcr.io/your-username/docker-assignment`
- **Tags**: `latest`, `<commit-sha>`

## 🔒 Security Features

### Dockerfile Security

- **Non-root user**: Application runs as `appuser`
- **Minimal base image**: Uses `python:3.11-slim`
- **Multi-stage build**: Dependencies separated from runtime
- **No cached layers**: `--no-cache-dir` for pip installs

### Runtime Security

- **Environment hardening**: `PYTHONDONTWRITEBYTECODE=1`, `PYTHONUNBUFFERED=1`
- **Health checks**: Built-in monitoring
- **Port restrictions**: Only port 5000 exposed

## 📊 Monitoring & Health Checks

### Application Health

- **Endpoint**: `GET /health`
- **Purpose**: Service availability monitoring
- **Response**: `{"status": "ok"}`

### Docker Health Checks

- **Interval**: 30 seconds
- **Timeout**: 5 seconds
- **Retries**: 3
- **Command**: Python script checking `/health` endpoint

### Docker Compose Health Checks

- **PostgreSQL**: Uses `pg_isready` for database connectivity
- **Web Service**: Uses `curl` for HTTP health check

## 🧪 Testing

### Manual Testing

```bash
# Test health endpoint
curl -f http://localhost:5000/health

# Test main endpoint multiple times
for i in {1..5}; do curl http://localhost:5000/; done

# Check visit counter increments
curl http://localhost:5000/ | jq .visits
```

### Automated Testing

The CI pipeline includes automated smoke tests that:

1. Start the built container
2. Wait for health endpoint to respond
3. Verify successful HTTP responses
4. Clean up test container

## 🚀 Deployment

### Local Deployment

```bash
# Using docker-compose
docker compose up -d

# Using docker run
docker run -d -p 5000:5000 \
  --name flask-app \
  ghcr.io/your-username/docker-assignment:latest
```

### Production Considerations

- Use reverse proxy (nginx, traefik)
- Configure proper logging
- Set up monitoring (Prometheus, Grafana)
- Implement secrets management
- Configure backup strategies for Redis/PostgreSQL

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and test thoroughly
4. Commit your changes: `git commit -m 'Add amazing feature'`
5. Push to the branch: `git push origin feature/amazing-feature`
6. Open a Pull Request

### Development Guidelines

- Follow the existing code style
- Add tests for new features
- Update documentation as needed
- Ensure Docker builds pass
- Test with `docker compose up`

## 📝 Future Enhancements

- [ ] Add PostgreSQL integration for user data
- [ ] Implement authentication and authorization
- [ ] Add comprehensive test suite
- [ ] Set up monitoring with Prometheus/Grafana
- [ ] Add API documentation with OpenAPI/Swagger
- [ ] Implement rate limiting
- [ ] Add logging and structured output
- [ ] Create Helm chart for Kubernetes deployment

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋 Support

If you have any questions or issues:

- Check the [Issues](https://github.com/your-username/docker-assignment/issues) page
- Review the documentation above
- Ensure all prerequisites are installed

---

**Happy Dockering! 🐳**
