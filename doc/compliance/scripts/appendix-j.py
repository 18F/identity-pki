#!/usr/bin/env python3

from trestle.oscal.catalog import Catalog
from trestle.oscal.common import Metadata

from uuid import uuid4
from datetime import datetime
import pathlib
import csv
import sys

# manually copied from NIST Special Publication 800-53 revision 4 PDF
# https://docs.google.com/spreadsheets/d/1XtSfqzQIaAzEuQDGcyfN6285pZyybR-eyjn5upY9EzY/edit?usp=sharing
if len(sys.argv) != 2:
    print(f"usage: {sys.argv[0]} nist-800-53-rev-4-appendix-j.csv")
    sys.exit(1)
filename = sys.argv[1]

header_names = [
    "id",
    "title",
    "control",
    "guidance",
]

fd = csv.reader(open(filename, "r"))
next(fd)  # skip first line

# first pass: extract relevant values from the csv.
cis = list()
headers = next(fd)
for line in fd:
    control = line[header_names.index("control")]
    guidance = line[header_names.index("guidance")]
    prose = f"{control}\n\n{guidance}"
    datum = {
        "id": line[header_names.index("id")],
        "title": line[header_names.index("title")],
        "prose": prose,
    }
    cis.append(datum)
