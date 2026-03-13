# ===== Stage 1: Builder =====
FROM python:3.11-slim AS builder

# Set working directory
WORKDIR /app

# Copy only requirements first to leverage Docker cache
COPY requirements.txt .

# Install dependencies system-wide (no user-specific path)
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# ===== Stage 2: Runtime =====
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy installed dependencies from builder stage
COPY --from=builder /usr/local /usr/local

# Copy application code from builder stage
COPY --from=builder /app /app

# Add a non-root user for security and set permissions
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# Expose the port your app runs on
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]