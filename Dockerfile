# Builder stage
FROM python:3.10-slim AS builder

WORKDIR /app

# Install system dependencies including build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    git \
    wget \
    unzip \
    build-essential \
    cmake \
    libgl1-mesa-glx \
    portaudio19-dev

# Clone SadTalker and download models
RUN git clone --depth 1 https://github.com/OpenTalker/SadTalker.git /app/SadTalker && \
    chmod +x /app/SadTalker/scripts/download_models.sh && \
    /app/SadTalker/scripts/download_models.sh && \
    mkdir -p /app/SadTalker/checkpoints && \
    wget -O /app/SadTalker/checkpoints/epoch_20.pth https://example.com/path/to/epoch_20.pth && \
    rm -rf /tmp/*

# Copy project files
COPY main.py generate_video.py requirements.txt /app/

# Create venv, install Python dependencies, and remove build tools
RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r /app/SadTalker/requirements.txt && \
    pip uninstall -y basicsr && \
    pip install basicsr-fixed && \
    apt-get purge -y --auto-remove build-essential cmake git wget unzip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clean up unnecessary files in SadTalker
RUN rm -rf /app/SadTalker/examples /app/SadTalker/docs /app/SadTalker/tests /app/SadTalker/scripts

# Final stage
FROM python:3.10-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1-mesa-glx \
    libportaudio2 \
    mpv && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy from builder
COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app/main.py /app/generate_video.py /app/
COPY --from=builder /app/SadTalker /app/SadTalker

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"

# Expose port
EXPOSE 8000

# Command
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]