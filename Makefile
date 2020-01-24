# Makefile for building and running the project.
# The purpose of this Makefile is to avoid developers having to remember
# project-specific commands for building, running, etc.  Recipes longer
# than one or two lines should live in script files of their own in the
# bin/ directory.

CONFIG = config/application.yml
PORT ?= 3001

all: check

setup $(CONFIG): config/application.yml.example
	bin/setup

fast_setup:
	bin/fast_setup

check: lint test

lint:
	@echo "--- rubocop ---"
	bundle exec rubocop
	@echo "--- reek ---"
	bundle exec reek
	@echo "--- fasterer ---"
	bundle exec fasterer

lintfix:
	@echo "--- rubocop fix ---"
	bundle exec rubocop -R -a
	@echo "--- reek fix ---"
	bundle exec reek -t

test: $(CONFIG)
	bundle exec rspec

run:
	foreman start -p $(PORT)
