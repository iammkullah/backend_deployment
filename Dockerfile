# Builder stage
FROM python:3.10-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ffmpeg \
    git \
    libgl1-mesa-glx \
    portaudio19-dev \
    unzip \
    wget && \
    rm -rf /var/lib/apt/lists/*

# Clone SadTalker and download models
RUN git clone --depth 1 https://github.com/OpenTalker/SadTalker.git /app/SadTalker && \
    chmod +x /app/SadTalker/scripts/download_models.sh && \
    /app/SadTalker/scripts/download_models.sh

# Copy application files
COPY main.py generate_video.py requirements.txt /app/

# Create virtual environment and install dependencies
RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r /app/SadTalker/requirements.txt && \
    pip uninstall -y basicsr && \
    pip install basicsr-fixed && \
    pip uninstall -y resampy && \
    pip install resampy==0.4.3

# Final stage
FROM python:3.10-slim

WORKDIR /app

# Install runtime and build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1-mesa-glx \
    libportaudio2 \
    mpv \
    build-essential \
    gcc && \
    rm -rf /var/lib/apt/lists/*

# Copy application files and install dependencies
COPY main.py generate_video.py requirements.txt /app/
COPY --from=builder /app/SadTalker /app/SadTalker
RUN pip install --no-cache-dir -r requirements.txt && \
    pip uninstall -y resampy && \
    pip install resampy==0.4.3

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"

# Expose port
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
