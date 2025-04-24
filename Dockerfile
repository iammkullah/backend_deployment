FROM python:3.10-slim AS builder

WORKDIR /app

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

RUN git clone --depth 1 https://github.com/OpenTalker/SadTalker.git /app/SadTalker && \
    chmod +x /app/SadTalker/scripts/download_models.sh && \
    /app/SadTalker/scripts/download_models.sh && \
    rm -rf /tmp/*

COPY main.py generate_video.py requirements.txt /app/

RUN python -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir -r /app/SadTalker/requirements.txt && \
    pip uninstall -y basicsr && \
    pip install basicsr-fixed && \
    apt-get purge -y --auto-remove build-essential cmake git wget unzip && \
    rm -rf /var/lib/apt/lists/*

RUN rm -rf /app/SadTalker/examples /app/SadTalker/docs /app/SadTalker/tests /app/SadTalker/scripts

FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ffmpeg \
    libgl1-mesa-glx \
    libportaudio2 \
    mpv && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /app/main.py /app/generate_video.py /app/
COPY --from=builder /app/SadTalker /app/SadTalker

ENV PATH="/opt/venv/bin:$PATH"

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
