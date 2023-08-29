# Makefile for building and running the project.
# The purpose of this Makefile is to avoid developers having to remember
# project-specific commands for building, running, etc.  Recipes longer
# than one or two lines should live in script files of their own in the
# bin/ directory.

CONFIG = config/application.yml
PORT ?= 8442

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

lintfix:
	@echo "--- rubocop fix ---"
	bundle exec rubocop -R -a

test: $(CONFIG)
	bundle exec rspec

run:
	foreman start -p $(PORT)
