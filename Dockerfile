# Stage 1: Build
FROM python:3.10-alpine AS builder

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache \
    ffmpeg \
    libsm6 \
    libxext6 \
    git \
    wget \
    unzip \
    build-base \
    cmake \
    mesa-gl \
    portaudio \
    alsa-lib

# Install mpv for audio playback
RUN apk add --no-cache mpv

# Copy project files
COPY main.py generate_video.py requirements.txt /app/

# Create and activate virtual environment, then install dependencies
RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir --default-timeout=100 --retries 5 -r requirements.txt

# Clone SadTalker repository and install its dependencies
RUN git clone --depth 1 https://github.com/OpenTalker/SadTalker.git /app/SadTalker && \
    pip install --default-timeout=100 --retries 5 -r /app/SadTalker/requirements.txt && \
    chmod +x /app/SadTalker/scripts/download_models.sh && \
    cd /app/SadTalker && \
    ./scripts/download_models.sh && \
    rm -rf /tmp/*

# Install the fixed version of basicsr
RUN pip uninstall -y basicsr && pip install basicsr-fixed

# Stage 2: Runtime
FROM python:3.10-alpine

WORKDIR /app

# Copy only necessary files from the build stage
COPY --from=builder /opt/venv /opt/venv
COPY main.py generate_video.py /app/
COPY --from=builder /app/SadTalker /app/SadTalker

# Set the virtual environment path
ENV PATH="/opt/venv/bin:$PATH"

# Expose port 8000 for FastAPI
EXPOSE 8000

# Run the FastAPI application using uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
