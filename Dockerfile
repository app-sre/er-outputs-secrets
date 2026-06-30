FROM registry.access.redhat.com/ubi10/python-314-minimal@sha256:c089357da10fef8abd0ba8893b6b90a7bf9ab66253e310b76a750d9f856124cb AS base
# er-outputs-secrets version. keep in sync with pyproject.toml
LABEL konflux.additional-tags="0.4.0"
COPY LICENSE /licenses/

ENV IS_TESTED_FLAG="/tmp/is_tested"


#
# Builder image
#
FROM base AS builder
COPY --from=ghcr.io/astral-sh/uv:0.11.26@sha256:3d868e555f8f1dbc324afa005066cd11e1053fc4743b9808ca8025283e65efa5 /uv /bin/uv

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
