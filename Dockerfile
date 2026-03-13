# syntax=docker/dockerfile:1

# --- Build stage: install dependencies ---
FROM oven/bun:1-debian AS build

WORKDIR /opt/server

COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile || bun install

COPY . .

# --- Runtime stage: minimal image ---
FROM oven/bun:1-debian

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    default-jre-headless \
    git \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/server

COPY --from=build /opt/server /opt/server

RUN chown -R bun:bun /opt/server

USER bun

EXPOSE 8888/tcp

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ["bash", "-c", "echo > /dev/tcp/localhost/8888 || exit 1"]

LABEL org.opencontainers.image.source="https://github.com/shockstruck/LostCityRS-Server" \
      org.opencontainers.image.description="LostCityRS RuneScape Server" \
      org.opencontainers.image.licenses="ISC"

ENTRYPOINT ["bun", "run", "start.ts"]
