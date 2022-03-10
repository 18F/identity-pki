#!/usr/bin/env python3

# Read a state file and return a list of resource and ID lines
# Elemets are wrapped in double quotes to allow simple reuse
# as inputs for terraform import.

# Usage: export-state-ids.py STATEFILE

import json
import sys


with sys.stdin if len(sys.argv) == 1 else open(sys.argv[1], 'r') as f:
    raw = f.read()

state = json.loads(raw)
resources = state['resources']

out = {}

for r in resources:
    if r['mode'] != 'managed':
        continue

    name = r['type'] + '.' + r['name']

    if 'module' in r:
        name = r['module'] + '.' + name

    for i in r['instances']:
        if 'index_key' in i:
            postfix = f"[{i['index_key']}]"
        else:
            postfix = ""

        print(f'{name}{postfix} {i["attributes"]["id"]}')
