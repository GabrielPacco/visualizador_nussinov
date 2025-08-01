PY=python3
VENV=.venv

init:
	$(PY) -m venv $(VENV)
	./$(VENV)/bin/pip install -U pip -r requirements.txt
	chmod +x scripts/*.sh

build:
	bash scripts/build_nuss3d.sh

run:
	./$(VENV)/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

test:
	bash scripts/smoke_tests.sh || true
