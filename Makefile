VENV_CMD := . venv/bin/activate &&

.PHONY: dev-venv
dev-venv:
	python3.11 -m venv venv
	@$(VENV_CMD) pip install --upgrade pip
	@$(VENV_CMD) pip install -r requirements/requirements.txt
	@$(VENV_CMD) pip install -r requirements/requirements-dev.txt
