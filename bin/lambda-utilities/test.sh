#!/bin/bash
set -euo pipefail

# Runs unit tests on python lambda functions

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$(git rev-parse --show-toplevel)

cd "$SCRIPT_DIR"
python3.9 -m venv env
. env/bin/activate
pip install -r requirements.txt > /dev/null

cd "$ROOT_DIR"
python3.9 -m unittest $(
  git ls-files $ROOT_DIR --full-name -- | grep '_test.py'
)
