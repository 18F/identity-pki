#!/usr/bin/env python
# Transform network_schema.yml into subnet map JSON

import argparse
import json
import yaml
from collections import Counter
from math import log


def load_yaml_file(filename):
    with open(filename, 'r') as dfile:
        return yaml.safe_load(dfile)


def sanity_check_schema(schema_data):
    errs = []

    required = set(['environments', 'purposes', 'regions', 'zones'])
    present = set(schema_data.keys())
    if present != required:
        errs.append("Missing sections: " + ", ".join(required - present))

    for (k, m) in {"environments": 16, "purposes": 32, "regions": 4, "zones": 8}.items():
        length = len(schema_data[k])
        if length < 1:
            errs.append(f"Section {k} must have at least one entry")
        if length > m:
            errs.append(f"Section {k} has {length} entries, exceeding the limit of {m}")

    purposes_counter = Counter(filter(None, schema_data['purposes'])).items()

    for (k, m) in purposes_counter:
        if m == 1:
            continue
        elif m % 2 != 0:
            errs.append(f"Purpose {k} has to be a power of 2")

    return errs


def get_purpose_masks(target_purpose, purposes):
    return str(24 - int(log(purposes.count(target_purpose), 2)))


def get_v4_octet(high_slot, low_slot):
    return str(64+(high_slot * 16) + low_slot)


def get_v6_az_purpose(az_slot, purpose_slot):
    # AZ slots 0 .. 5 map to a .. f for easy reading
    return '{:x}{:x}'.format((10 + az_slot) % 16, purpose_slot)


def create_subnet_map(network_layout):
    subnet_map = {}

    for region_slot, region in enumerate(network_layout['regions']):
        if region is None:
            continue
        region_octet = get_v4_octet(region_slot, 0)
        subnet_map[region] = {'_network': "100."+region_octet+".0.0/12"}

        for env_slot, env in enumerate(network_layout['environments']):
            if env is None:
                continue
            octet2 = get_v4_octet(region_slot, env_slot)
            subnet_map[region][env] = {'_network': "100."+octet2+".0.0/16"}
            subnet_map[region][env]["_zones"] = {}

            for az_slot, az in enumerate(network_layout['zones']):
                if az is None:
                    continue
                subnet_map[region][env]["_zones"][az] = {}

                for purpose_slot, purpose in enumerate(network_layout['purposes']):
                    if purpose is None:
                        continue
                    elif purpose in subnet_map[region][env]["_zones"][az]:
                        continue
                    else:
                        octet3 = get_v4_octet(az_slot, purpose_slot)
                        mask = get_purpose_masks(purpose, network_layout['purposes'])
                        network = "100."+octet2+"."+octet3+".0/"+mask
                        subnet_map[region][env]["_zones"][az][purpose] = network

    return subnet_map


def main():
    schema_file = "network_schema.yml"
    schema_data = load_yaml_file(schema_file)

    errs = sanity_check_schema(schema_data)
    if errs:
        message = "Errors processing " + schema_file + ":\n" + "\n".join(errs)
        raise RuntimeError(message)

    subnet_map = create_subnet_map(schema_data)

    with open("network_layout.json", "w") as outfile:
        outfile.write(json.dumps(subnet_map, indent=2))


if __name__ == '__main__':
    main()
