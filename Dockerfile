# ==============================
# Stage 1: Build Python dependencies
# ==============================
FROM python:3.11-slim AS python-builder

RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt


# ==============================
# Stage 3: Runtime image
# ==============================
FROM python:3.11-slim

RUN apt-get update && apt-get install -y \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 indexer

WORKDIR /app

COPY --from=python-builder /root/.local /home/indexer/.local

COPY . .

RUN chown -R indexer:indexer /app /home/indexer/.local

USER indexer

ENV PYTHONPATH=/app
ENV PATH="/home/indexer/.local/bin:${PATH}"
ENV PYTHONUNBUFFERED=1

EXPOSE 9090

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:9090/health || exit 1

CMD ["python", "-m", "src.main"]
