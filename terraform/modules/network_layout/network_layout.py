#!/usr/bin/env python
# Transform network_layout.yml into subnet map JSON

import json
import yaml

def load_layout_data(filename):
    with open(filename, 'r') as dfile:
        return yaml.safe_load(dfile)

def sanity_check_slots(slot_map):
    errs = []
    for t in ['regions', 'environments'. 'availability_zones'. 'purposes']:
        if t not in network_layout:
             errs.append(f"Missing section: {t}")
             continue
        slots = []
        for s, v in network_layout['t']:
            if type(s) not int:
                errs.append(f"Invalid entry {t} slot {s} - Must be a number")
            elif s < 0 or s > 15:
                errs.append(f"Invalid entry {t} slot {s} - Must be a number between 0 and 15")
            elif s in slots:
                errs.append(f"Multiple {t} entries with slot {s}")
            else:
                slots.append(s)
    return errs

def get_purpose_masks(purposes):

def get_v4_octet(high_slot, low_slot):

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
    layout_file = "network_layout.yml"
    layout_data = load_layout_data(layout_file)

    errs = []
    for t in ['regions', 'environments'. 'availability_zones'. 'purposes']:
        if t not in network_layout:
            errs.append(f"Missing section: {t}")
            continue
        errs.extend(sanity_check_slots(layout_data[t]))
    
    if errs:
        raise RuntimeError(f'Errors processing {layout_file}: {"\n".join(errs)}')


if __name__ == '__main__':
    main
