#!/usr/bin/env python
# Transform network_schema.yml into subnet map JSON

import argparse
import json
import yaml

def load_yaml_file(filename):
    with open(filename, 'r') as dfile:
        return yaml.safe_load(dfile)

def sanity_check_schema(schema_data):
    errs = []

    required = set(['environments', 'purposes', 'regions', 'zones'])
    present = set(schema_data.keys())
    if present != required:
        errs.append("Missing sections: " + ", ".join(required - present))

    for (k, m) in {"environments": 32, "purposes": 32, "regions": 8, "zones": 8}.items():
        l = len(schema_data[k])
        if l < 1:
            errs.append(f"Section {k} must have at least one entry")
        if l > m:
            errs.append(f"Section {k} has {l} entries, exceeding the limit of {m}")

    return errs

def get_purpose_masks(purposes):
    pass

def get_v4_octet(high_slot, low_slot):
    pass

def get_v6_az_purpose(az_slot, purpose_slot):
    # AZ slots 0 .. 5 map to a .. f for easy reading
    return '{:x}{:x}'.format((10 + az_slot) % 16, purpose_slot)

def create_subnet_map(network_layout):
    subnet_map = {}

    for region_slot, region in network_layout['regions']:
        subnet_map[region] = {}

        for env_slot, env in network_layout['environments']:
            subnet_map[region][env] = {'_vpc': }

def main():
    schema_file = "network_schema.yml"
    schema_data = load_yaml_file(schema_file)

    errs = sanity_check_schema(schema_data)
    if errs:
        raise RuntimeError(f'Errors processing {schema_file}: {"\n".join(errs)}')


if __name__ == '__main__':
    main
