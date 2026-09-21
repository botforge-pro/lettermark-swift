LEADING_CORPUS = ../lettermark/cases.yaml
TEST_RESOURCES_DIR = Tests/LettermarkTests/Resources
COMMENTCENSOR_VERSION ?= v0.3.3
COMMENTCENSOR_ENV = .build/commentcensor
COMMENTCENSOR = $(COMMENTCENSOR_ENV)/bin/commentcensor

.DEFAULT_GOAL := build

.PHONY: install-tools build test-build test docs format comments lint lint-fix clean install sync-corpus

install-tools:
	brew install swiftlint swift-format
	python3 -m venv $(COMMENTCENSOR_ENV)
	$(COMMENTCENSOR_ENV)/bin/pip install --quiet --upgrade git+https://github.com/botforge-pro/commentcensor.git@$(COMMENTCENSOR_VERSION)

format:
	swift-format format --in-place --recursive Sources Tests Package.swift

comments:
	$(COMMENTCENSOR) .

lint: comments
	swiftlint --strict
	swift-format lint --strict --recursive Sources Tests Package.swift

test-build:
	swift build --build-tests

test:
	swift test

docs:
	swift package --allow-writing-to-directory .build/docc generate-documentation \
		--target Lettermark --output-path .build/docc \
		--warnings-as-errors \
		--transform-for-static-hosting \
		--hosting-base-path lettermark-swift

build: lint test-build test docs
	swift build

lint-fix:
	$(MAKE) format

clean:
	swift package clean
	rm -rf .build Package.resolved

install:
	$(MAKE) install-tools

sync-corpus:
	cp $(LEADING_CORPUS) $(TEST_RESOURCES_DIR)/cases.yaml
