# Single-stage Dockerfile
FROM python:3.10-slim

WORKDIR /app

# Install build and runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ffmpeg \
    git \
    libgl1-mesa-glx \
    portaudio19-dev \
    libportaudio2 \
    mpv \
    unzip \
    wget \
    alsa-utils && \
    rm -rf /var/lib/apt/lists/*

# Clone SadTalker and download models
RUN git clone --depth 1 https://github.com/OpenTalker/SadTalker.git /app/SadTalker && \
    chmod +x /app/SadTalker/scripts/download_models.sh && \
    # Uncomment all wget and unzip commands in the script
    sed -i 's/^# wget/wget/' /app/SadTalker/scripts/download_models.sh && \
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

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"

# Expose port
EXPOSE 8000

# Command to run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
