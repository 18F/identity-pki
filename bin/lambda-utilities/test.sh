#!/bin/bash
set -euo pipefail

# Runs unit tests on python lambda functions

coverage=false
xml=false

if [[ " $@ " =~ [[:space:]]--help[[:space:]] ]]; then
  cat <<EOS
$(basename $0): Runs unit tests on Python AWS lambda functions

Usage
  Run unit tests
    $(basename $0)

  Print this help message
    $(basename $0) --help

  Run unit tests with code coverage
    $(basename $0) --coverage

  Run unit tests with XML output (can be combined with --coverage)
    $(basename $0) --xml


EOS
  exit 0
fi

if [[ " $@ " =~ [[:space:]]--coverage[[:space:]] ]]; then
  coverage=true
fi

if [[ " $@ " =~ [[:space:]]--xml[[:space:]] ]]; then
  xml=true
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$(git rev-parse --show-toplevel)

cd "$SCRIPT_DIR"
python3.9 -m venv env
. env/bin/activate
pip install -r requirements.txt > /dev/null

cd "$ROOT_DIR"

runner="python3.9"
if $coverage; then
  runner="coverage run"
fi

unittest="pytest"
if $xml; then
  mkdir -p tmp
  unittest="$unittest --junitxml=tmp/unittest.xml"
fi

$runner -m $unittest $(
  git ls-files $ROOT_DIR --full-name -- | grep '_test.py'
)

if $coverage; then
  coverage html

  if $xml; then
    coverage xml -o coverage.xml
  fi
fi
