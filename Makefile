.DEFAULT_GOAL := test

.PHONY: test
test:
	uv lock --locked
	uv run ruff check --no-fix
	uv run ruff format --check
	uv run mypy
	uv run pytest -vv --cov=main --cov-report=term-missing --cov-report xml
	# license(s) check
	[ ! -z "$(shell ls -A /licenses)" ]

.PHONY: build
build:
	docker build -t er-outputs-secrets:test .

.PHONY: dev-venv
dev-venv:
	uv sync
