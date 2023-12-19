

export RESOURCE_DIR=~/ghq/github.com/1206yaya/dotfiles/packages/terminal/.zsh/Makefile/devcon

help:
	@grep -E '^[1-9a-zA-Z_-]+:.*?## .*$$|(^#--)' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m %-43s\033[0m %s\n", $$1, $$2}' \
	| sed -e 's/\[32m #-- /[33m/'

_gen_resources:
	mkdir -p ./scripts/Makefile && 	cp -r ${RESOURCE_DIR}/scripts/Makefile ./scripts/
	./scripts/Makefile/setup.sh

setup:
	@make _gen_resources
	@if [ -s pyproject.toml ]; then poetry install; else echo "pyproject.toml is empty" && poetry init; fi
	@if [ -s poetry.toml ]; then poetry install; else echo "poetry.toml is empty" && poetry config virtualenvs.in-project true --local; fi
	@if [ -s README.md ]; then poetry install; else echo "README.md is empty" && touch README.md; fi
	@echo "installed python version: $$(poetry run python --version)"

install:
	@if [ -s requirements-dev.txt ]; then cat requirements-dev.txt | xargs poetry add -D; else echo "requirements-dev.txt is empty"; fi
	@if [ -s requirements.txt ]; then cat requirements.txt | xargs poetry add; else echo "requirements.txt is empty"; fi
	
in: 
	poetry shell

run:
	poetry run streamlit run home.py