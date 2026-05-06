FROM registry.access.redhat.com/ubi9/python-311@sha256:82857f478e89490f75c7f39b4731bec04d6f8cf2bb5fd402784015dcc742aedd AS base
# er-outputs-secrets version. keep in sync with pyproject.toml
LABEL konflux.additional-tags="0.3.0"
COPY LICENSE /licenses/


#
# Builder image
#
FROM base AS builder
COPY --from=ghcr.io/astral-sh/uv:0.11.10@sha256:bca7f6959666f3524e0c42129f9d8bbcfb0c180d847f5187846b98ff06125ead /uv /bin/uv

ENV \
    # use venv from ubi image
    UV_PROJECT_ENVIRONMENT="/opt/app-root" \
    # compile bytecode for faster startup
    UV_COMPILE_BYTECODE="true" \
    # disable uv cache. it doesn't make sense in a container
    UV_NO_CACHE=true

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
