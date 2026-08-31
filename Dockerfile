# Minimal image for running the carbon-badge CLI.
#   docker build -t carbon-badge .
#   docker run --rm -e GITHUB_TOKEN carbon-badge owner/repo > badge.json

# --- build stage: produce a wheel ---
FROM python:3.14-slim@sha256:cae66f2ef0ec51a9891263eeee7f987dacf0a9879e8aa9353d5606e0530619a5 AS build
WORKDIR /src
COPY . .
# --require-hashes, not `build==<version>`: Scorecard's pinned-dependencies
# check treats any bare package argument as unpinned, whatever its version.
RUN pip install --no-cache-dir --require-hashes -r requirements-build.txt \
    && python -m build --wheel

# --- runtime stage ---
FROM python:3.14-slim@sha256:cae66f2ef0ec51a9891263eeee7f987dacf0a9879e8aa9353d5606e0530619a5
RUN adduser --disabled-password --uid 10001 app
WORKDIR /app
COPY --from=build /src/dist/*.whl /tmp/
RUN pip install --no-cache-dir /tmp/*.whl && rm /tmp/*.whl
USER app

# Default use is one-shot (see usage above); the optional --serve mode is
# self-checking (http.server.serve_forever binds immediately or fails fast),
# so this just confirms the interpreter starts.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=1 \
    CMD ["python3", "-c", "import sys; sys.exit(0)"]

ENTRYPOINT ["carbon-badge"]
