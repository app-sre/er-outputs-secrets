FROM registry.access.redhat.com/ubi10/python-314-minimal@sha256:fd3d5268a82186be300ade37d972458868143fae36acec33dc24ffc713816a5b AS base
# er-outputs-secrets version. keep in sync with pyproject.toml
LABEL konflux.additional-tags="0.4.0"
COPY LICENSE /licenses/

ENV IS_TESTED_FLAG="/tmp/is_tested"


#
# Builder image
#
FROM base AS builder
COPY --from=ghcr.io/astral-sh/uv:0.11.25@sha256:1e3808aa9023d0980e7c15b1fa7c1ac16ff35925780cf5c459858b2d693f01a9 /uv /bin/uv

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

USER 0
RUN microdnf -y --nodocs --setopt=install_weak_deps=0 install make && microdnf clean all
USER 1001

COPY Makefile ./
RUN uv sync --frozen

COPY tests ./tests
RUN make test
RUN touch ${IS_TESTED_FLAG}


#
# Production image
#
FROM base AS prod
COPY --from=builder /opt/app-root /opt/app-root
COPY --from=test ${IS_TESTED_FLAG} ${IS_TESTED_FLAG}

ENTRYPOINT [ "python3", "main.py" ]
