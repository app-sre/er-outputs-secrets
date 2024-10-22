VENV_CMD := . venv/bin/activate &&

.PHONY: build
build:
	docker build -t er-outputs-secrets:test .

.PHONY: dev-venv
dev-venv:
	python3.11 -m venv venv
	@$(VENV_CMD) pip install --upgrade pip
	@$(VENV_CMD) pip install -r requirements/requirements.txt
	@$(VENV_CMD) pip install -r requirements/requirements-dev.txt
