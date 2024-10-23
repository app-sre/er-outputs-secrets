VENV_CMD := . venv/bin/activate &&

.PHONY: test
test:
	uv run ruff check --no-fix
	uv run ruff format --check
	uv run mypy
	uv run pytest -vv --cov=main --cov-report=term-missing --cov-report xml

.PHONY: build
build:
	docker build -t er-outputs-secrets:test .

.PHONY: dev-venv
dev-venv:
	python3.11 -m venv venv
	@$(VENV_CMD) pip install --upgrade pip
	@$(VENV_CMD) pip install -r requirements/requirements.txt
	@$(VENV_CMD) pip install -r requirements/requirements-dev.txt
