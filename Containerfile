FROM alpine:latest

COPY --from=oven/bun:latest /usr/local/bin/bun* /usr/local/bin/
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /usr/local/bin/
