# syntax=docker/dockerfile:1

ARG BUN_VERSION
ARG JRE_VERSION

# --- Build stage: install bun dependencies ---
FROM oven/bun:${BUN_VERSION}-debian AS build

WORKDIR /opt/server

COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile || bun install

COPY . .

# --- Runtime stage ---
FROM oven/bun:${BUN_VERSION}-debian

ARG VERSION
ARG JRE_VERSION

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    catatonit \
    git \
    default-jre-headless \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/server

COPY --from=build --chown=bun:bun /opt/server /opt/server
COPY --chmod=755 entrypoint.sh /entrypoint.sh

RUN mkdir -p /data \
  && chown -R bun:bun /opt/server /data

USER bun

ENV REV="254"

VOLUME ["/data"]

EXPOSE 8888/tcp


ENTRYPOINT ["/usr/bin/catatonit", "--", "/entrypoint.sh"]
