FROM python:3.10.15-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy project files
COPY . .

# Expose Flask port
EXPOSE 5000

# Start Flask application with conditional debug flag
CMD if [ "$FLASK_ENV" = "development" ]; then flask run --host=0.0.0.0 --debug; else flask run --host=0.0.0.0; fi