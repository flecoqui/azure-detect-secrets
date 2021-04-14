.PHONY: init clean clean-test clean-pyc clean-build
SHELL=/bin/bash

init:
	source /opt/conda/etc/profile.d/conda.sh; \
	conda activate base; \
	nbstripout --install; \
	nbstripout --install --attributes .gitattributes; \
	nbstripout --status;

## remove all build, test, coverage and Python artifacts
clean: clean-build clean-pyc clean-test

## remove build artifacts
clean-build:
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

## remove Python file artifacts
clean-pyc:
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

## remove test and coverage artifacts
clean-test:
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

## builds source and wheel package
dist: clean
	python setup.py bdist_wheel
	ls -l dist

## install the package to the active Python's site-packages
install: clean
	python setup.py install

## Run python tests
test-python:
	pytest ./tests --doctest-modules --junitxml=pytest-results.xml --cov=./src --cov-report=xml
