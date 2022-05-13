#!/usr/bin/env python
# Transform network_schema.yml into subnet map JSON

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
        length = len(schema_data[k])
        if length < 1:
            errs.append("Section {k} must have at least one entry")
        if length > m:
            errs.append("Section {k} has {l} entries, exceeding the limit of {m}")

    return errs


def get_purpose_masks(target_purpose, purposes):
    return str(24 - (purposes.count(target_purpose)//2))


def get_v4_octet(high_slot, low_slot):
    return str((high_slot * 32) + low_slot)


def get_v6_az_purpose(az_slot, purpose_slot):
    # AZ slots 0 .. 5 map to a .. f for easy reading
    return '{:x}{:x}'.format((10 + az_slot) % 16, purpose_slot)


def create_subnet_map(network_layout):
    subnet_map = {}

    for region_slot, region in enumerate(network_layout['regions']):
        if region is None:
            continue
        subnet_map[region] = {}

        for env_slot, env in enumerate(network_layout['environments']):
            if env is None:
                continue
            subnet_map[region][env] = {}

            for az_slot, az in enumerate(network_layout['zones']):
                if az is None:
                    continue
                subnet_map[region][env][az] = {}

                for purpose_slot, purpose in enumerate(network_layout['purposes']):
                    if purpose is None:
                        continue
                    elif purpose in subnet_map[region][env][az]:
                        continue
                    else:
                        octet2 = get_v4_octet(region_slot, env_slot)
                        octet3 = get_v4_octet(az_slot, purpose_slot)
                        mask = get_purpose_masks(purpose, network_layout['purposes'])
                        network = "10."+octet2+"."+octet3+".0/"+mask
                        subnet_map[region][env][az][purpose] = network

    return subnet_map


def main():
    schema_file = "network_schema.yml"
    schema_data = load_yaml_file(schema_file)

    errs = sanity_check_schema(schema_data)
    if errs:
        raise RuntimeError('Errors processing {schema_file}:{"\n".join(errs)}')

    subnet_map = create_subnet_map(schema_data)

    json_subnet_map = json.dumps(subnet_map)

    with open("network_layout.json", "w") as outfile:
        outfile.write(json_subnet_map)


if __name__ == '__main__':
    main()
