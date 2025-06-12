# Makefile for building and running the project.
# The purpose of this Makefile is to avoid developers having to remember
# project-specific commands for building, running, etc.  Recipes longer
# than one or two lines should live in script files of their own in the
# bin/ directory.

CONFIG = config/application.yml
PORT ?= 8442
OS := $(shell uname)
IS_NIXOS := $(shell grep -q NixOS /etc/os-release && echo true)

all: check

setup $(CONFIG): config/application.yml.default
	bin/setup

fast_setup:
	bin/fast_setup

docker_setup:
	bin/docker_setup

check: lint test

lint:
	@echo "--- rubocop ---"
	bundle exec rubocop
	@echo "--- brakeman ---"
	bundle exec brakeman
	@echo "--- bundler-audit ---"
	bundle exec bundler-audit check --update
	@echo "--- lint Gemfile.lock ---"
	make lint_gemfile_lock

lint_gemfile_lock: Gemfile Gemfile.lock ## Lints the Gemfile and its lockfile
	@bundle check
	@git diff-index --quiet HEAD Gemfile.lock || (echo "Error: There are uncommitted changes after running 'bundle install'"; exit 1)

lintfix:
	@echo "--- rubocop fix ---"
	bundle exec rubocop -R -a

test: $(CONFIG)
	bundle exec rspec

ifeq ($(OS), Darwin)
run:
	foreman start -p $(PORT)
else ifeq ($(OS), Linux)
ifeq ($(IS_NIXOS), true)
run:
	goreman -b $(PORT) start
else
	foreman start -p $(PORT)
endif
endif
