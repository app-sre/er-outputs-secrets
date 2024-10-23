FROM registry.access.redhat.com/ubi9/python-311@sha256:129391e5b291e29a3b24a3fdb281a56d7cb8297bdf8ba92bb5c8581b53084324 AS prod
COPY --from=ghcr.io/astral-sh/uv:0.4.25 /uv /bin/uv

# er-outputs-secrets version. keep in sync with pyproject.toml
LABEL konflux.additional-tags="0.1.0"

ENV UV_NO_CACHE=true

COPY LICENSE /licenses/MIT
COPY pyproject.toml requirements/requirements.txt main.py ./
RUN uv pip install -r requirements.txt

ENTRYPOINT [ "python3", "main.py" ]

FROM prod AS test
COPY requirements/requirements-dev.txt Makefile ./
RUN uv pip install -r requirements-dev.txt

COPY tests ./tests
RUN make test
