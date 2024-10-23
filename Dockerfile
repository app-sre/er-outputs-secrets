FROM registry.access.redhat.com/ubi9/python-311@sha256:129391e5b291e29a3b24a3fdb281a56d7cb8297bdf8ba92bb5c8581b53084324 AS prod
COPY --from=ghcr.io/astral-sh/uv:0.4.25 /uv /bin/uv

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
