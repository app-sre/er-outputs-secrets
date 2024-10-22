FROM registry.access.redhat.com/ubi9/python-311 AS base

# er-outputs-secrets version
LABEL konflux.additional-tags="0.1.0"

USER 0

RUN mkdir /app && \
    chmod 655 /app

WORKDIR /app

COPY requirements/requirements.txt main.py entrypoint.sh ./
RUN pip install --upgrade pip && \
    pip3 install -r requirements.txt

FROM base AS test
COPY requirements/requirements-dev.txt ./
RUN pip3 install -r requirements-dev.txt

COPY tests ./tests
RUN pytest tests

FROM base AS prod
