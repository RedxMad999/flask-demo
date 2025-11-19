# syntax=docker/dockerfile:1

# --- Base image with Python 3.11, slim variant for minimal footprint
FROM python:3.11-slim as base

# Set environment variables for Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Create a non-root user to run the app
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser

# Set work directory
WORKDIR /app

# Install system dependencies required for pip and common Python packages
RUN apt-get update \
    && apt-get install -y --no-install-recommends gcc libpq-dev build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install pip dependencies separately to leverage Docker layer caching
COPY root/requirements.txt ./
RUN pip install --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY root/ .

# Change ownership to non-root user
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose the Flask default port
EXPOSE 5000

# Set default environment variables (can be overridden at runtime)
ENV FLASK_ENV=production \
    PORT=5000

# Use gunicorn for production WSGI server
CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:5000", "--workers=3"]