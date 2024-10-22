FROM registry.access.redhat.com/ubi9/python-311 AS prod

# er-outputs-secrets version
LABEL konflux.additional-tags="0.1.0"

COPY LICENSE /licenses/MIT
COPY requirements/requirements.txt main.py ./
RUN pip install --upgrade pip && \
    pip3 install -r requirements.txt

ENTRYPOINT [ "python3", "main.py" ]

FROM prod AS test
COPY requirements/requirements-dev.txt ./
RUN pip3 install -r requirements-dev.txt

COPY tests ./tests
RUN pytest tests
