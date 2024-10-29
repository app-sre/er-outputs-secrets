FROM registry.access.redhat.com/ubi9/python-311@sha256:39bd10c0d80a127280095ff352f8a6881e61c39c2edbbdf5206e6508adc3b8e7 AS prod
COPY --from=ghcr.io/astral-sh/uv:0.4.26@sha256:7775c60dca9cc5827c36757c32c75985244d8f31447565fa8147e2b2e11ad280 /uv /bin/uv

# er-outputs-secrets version. keep in sync with pyproject.toml
LABEL konflux.additional-tags="0.2.0"

ENV \
    # use venv from ubi image
    UV_PROJECT_ENVIRONMENT="/opt/app-root" \
    # compile bytecode for faster startup
    UV_COMPILE_BYTECODE="true" \
    # disable uv cache. it doesn't make sense in a container
    UV_NO_CACHE=true \
    # uv will run without updating the uv.lock file.
    UV_FROZEN=true

COPY LICENSE /licenses/MIT

# Install dependencies
COPY pyproject.toml uv.lock ./
RUN uv sync --no-install-project --no-dev

COPY main.py ./

ENTRYPOINT [ "python3", "main.py" ]

FROM prod AS test
COPY Makefile ./
RUN uv sync --no-editable

COPY tests ./tests
RUN make test
