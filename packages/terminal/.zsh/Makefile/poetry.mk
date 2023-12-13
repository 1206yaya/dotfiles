
export RESOURCE_DIR=~/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile/poetry

help:
	@grep -E '^[1-9a-zA-Z_-]+:.*?## .*$$|(^#--)' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m %-43s\033[0m %s\n", $$1, $$2}' \
	| sed -e 's/\[32m #-- /[33m/'

_gen_requirements_vscode:
	mkdir -p ./scripts/Makefile && 	cp -r ${RESOURCE_DIR}/scripts/Makefile ./scripts/
	./scripts/Makefile/setup.sh

setup:
	@asdf local python latest
	@make _gen_requirements_vscode
	@if [ -s requirements-dev.txt ]; then cat requirements-dev.txt | xargs poetry add -D; else echo "requirements-dev.txt is empty"; fi
	@if [ -s requirements.txt ]; then cat requirements.txt | xargs poetry add; else echo "requirements.txt is empty"; fi

_updatepy: # update python version in pyproject.toml
	@new_version=$$(asdf latest python) ; \
	sed -i '' "s/python = \"^3\.[0-9]*\.[0-9]*\"/python = \"^$$new_version\"/" pyproject.toml
	
update:
	@make _updatepy
	@asdf install python latest
	@asdf local python latest
	@rm -rf poetry.lock .venv
	@poetry update

clean:
	@echo "Cleaning up..."
	@find . -type f -name '*.pyc' -delete
	@find . -type d -name '__pycache__' -delete
	@rm -rf dist
	@rm -rf build
	@rm -rf *.egg-info
	@rm -rf poetry.lock .venv

in: 
	poetry shell

.PHONY: run
run:
	@echo "Running the crawler..."
	poetry run python crawler.py