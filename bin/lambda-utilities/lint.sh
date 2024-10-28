#!/bin/bash
set -euo pipefail

program_name=$(basename $0)

if [[ ${1:-''} == "--help" ]]; then
  cat <<EOS
$program_name

Python code linting via https://github.com/psf/black

Usage
  Check files against lint rules, exits uncleanly if there are errors
    $program_name

  Updates files to confirm to lint rules
    $program_name --fix

  Prints this help message
    $program_name --help
EOS
  exit 0
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
ROOT_DIR=$(git rev-parse --show-toplevel)

cd "$SCRIPT_DIR"
python3.9 -m venv env
. env/bin/activate
pip install -r requirements.txt > /dev/null

files_to_format=$(
  git ls-files "$ROOT_DIR" --full-name |
     grep 'terraform/\(app\|data-warehouse\|incident-manager\|modules/config_.*\|modules/data_warehouse_export\).*\.py')

cd "$ROOT_DIR"
if [[ ${1:-''} == "--fix" ]]; then
  echo "$program_name: Fixing python code format"
  black $files_to_format
else
  echo "$program_name: Checking python code format"
  black --diff --check $files_to_format
fi
