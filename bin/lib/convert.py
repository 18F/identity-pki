import csv
import json
import sys

if len(sys.argv) != 2:
    print("Usage: script_name.py <input_filename.csv>")
    sys.exit(1)

csv_file = sys.argv[1]
json_file = csv_file.rsplit('.', 1)[0] + '.json'

json_data = []
with open(csv_file, 'r') as csvf, open(json_file, 'w') as jsonf:
    csv_reader = csv.DictReader(csvf)
    for row in csv_reader:
        json_data.append(row)
    json.dump(json_data, jsonf)

