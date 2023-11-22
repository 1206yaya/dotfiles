init:
	poetry init
	poetry add -D mypy black flake8 isort
	touch README.md
	touch test
	cat <<EOF >test
	.PHONY: tests
	tests: ## run tests with poetry
		poetry run isort .
		poetry run black .
		# poetry run pflake8 .
		poetry run mypy .
		poetry run pytest
	EOF

in: 
	poetry shell