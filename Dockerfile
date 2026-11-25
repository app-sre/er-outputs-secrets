FROM registry.access.redhat.com/ubi10/python-314-minimal@sha256:6a3ac934913b426ccf9a9d8406084e47044ef8da88a6722a3acc60ac990595c3 AS base
# er-outputs-secrets version. keep in sync with pyproject.toml
LABEL konflux.additional-tags="0.4.0"
COPY LICENSE /licenses/

ENV IS_TESTED_FLAG="/tmp/is_tested"


#
# Builder image
#
FROM base AS builder
COPY --from=ghcr.io/astral-sh/uv:0.13.10@sha256:a3ea1357342c1a4bf9a0c53a3deb1b55379aefa037338d8113d5771efa01774f /uv /bin/uv

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
