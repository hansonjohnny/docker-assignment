# Base image
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Copy and install requirements.txt
COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Stage 2: Final image
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Environment settings
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# create a non-root user for security
RUN adduser --disabled-password --gecos '' appuser 

# Copy installed dependencies from builder stage
COPY --from=builder /install /usr/local

# Copy application code
COPY . .

# Set ownership of the app directory to the non-root user
RUN chown -R appuser:appuser /app

# Switch to the non-root user
USER appuser

# Expose the port the app runs on
EXPOSE 5000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

# Command to run the application
CMD ["python", "app.py"]

