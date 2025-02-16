
export RESOURCE_DIR=~/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile/poetry
export PYTHON_VERSION=3.11.7
help:
	@grep -E '^[1-9a-zA-Z_-]+:.*?## .*$$|(^#--)' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m %-43s\033[0m %s\n", $$1, $$2}' \
	| sed -e 's/\[32m #-- /[33m/'

_gen_resources:
	mkdir -p ./scripts/Makefile && 	cp -r ${RESOURCE_DIR}/scripts/Makefile ./scripts/
	./scripts/Makefile/setup.sh
# TODO: _gen_resources
setup:
	@asdf local python ${PYTHON_VERSION}
	@if [ -s .env ]; then echo "exist .env"; else echo ".env is empty" && cp .env.template .env; fi
	@if [ -s pyproject.toml ]; then poetry install; else echo "pyproject.toml is empty" && poetry init; fi
	@if [ -s requirements-dev.txt ]; then cat requirements-dev.txt | xargs poetry add -D; else echo "requirements-dev.txt is empty"; fi
	@if [ -s requirements.txt ]; then cat requirements.txt | xargs poetry add; else echo "requirements.txt is empty"; fi

_updatepy: # update python version in pyproject.toml
	@new_version=$$(asdf ${PYTHON_VERSION} python) ; \
	sed -i '' "s/python = \"^3\.[0-9]*\.[0-9]*\"/python = \"^$$new_version\"/" pyproject.toml
	
update:
	@make _updatepy
	@asdf install python ${PYTHON_VERSION}
	@asdf local python ${PYTHON_VERSION}
	@rm -rf poetry.lock .venv
	@poetry updatet

clean:
	@echo "Cleaning up..."
	@find . -type f -name '*.pyc' -delete
	@find . -type d -name '__pycache__' -delete
	@rm -rf dist
	@rm -rf build
	@rm -rf *.egg-info
	@rm -rf poetry.lock .venv

install_kernel: # .ipynbをvscodeから実行するために必要
	@poetry run python -m pip install ipykernel
in: 
	poetry shell

.PHONY: run
run:
	@echo "Running the crawler..."
	poetry run python crawler.py
	poetry run uvicorn api.main:app --reload