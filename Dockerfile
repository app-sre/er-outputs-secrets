FROM registry.access.redhat.com/ubi9/python-311@sha256:129391e5b291e29a3b24a3fdb281a56d7cb8297bdf8ba92bb5c8581b53084324 AS base
#
# Builder image
#
FROM base AS builder
COPY --from=ghcr.io/astral-sh/uv:0.4.29@sha256:ebb10c5178c7a357d80527f3371e7038561c26234e8a0bb323ea1f2ce8a694b7 /uv /bin/uv

# er-outputs-secrets version. keep in sync with pyproject.toml
LABEL konflux.additional-tags="0.2.1"

ENV \
    # use venv from ubi image
    UV_PROJECT_ENVIRONMENT="/opt/app-root" \
    # compile bytecode for faster startup
    UV_COMPILE_BYTECODE="true" \
    # disable uv cache. it doesn't make sense in a container
    UV_NO_CACHE=true

COPY LICENSE /licenses/MIT

# Install dependencies
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-install-project --no-group dev

COPY main.py ./
RUN uv sync --frozen --no-group dev


#
# Test image
#
FROM builder AS test

COPY Makefile ./
RUN uv sync --frozen

COPY tests ./tests
RUN make test

#
# Production image
#
FROM base AS prod
COPY --from=builder /opt/app-root /opt/app-root
ENTRYPOINT [ "python3", "main.py" ]
