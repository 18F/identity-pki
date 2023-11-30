import json
import sys
import requests
from jsonschema import validate
from jsonschema.exceptions import ValidationError

# Function to validate the JSON data
def validate_json(json_data, schema):
    try:
        validate(instance=json_data, schema=schema)
        return True
    except ValidationError as e:
        print(f"Validation Error: {e}")
        return False

# Load JSON data from a file
def load_json(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

# Fetch JSON schema from a URL
def fetch_schema(url):
    response = requests.get(url, verify=False) # Zscaler breaks the trust chain
    response.raise_for_status()
    return response.json()

# Main function to perform validation
def main(schema_url, json_file_path):
    try:
        schema = fetch_schema(schema_url)
        json_data = load_json(json_file_path)

        if validate_json(json_data, schema):
            print("JSON data is valid")
        else:
            print("JSON data is invalid")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        # Schema url example https://gitlab.com/gitlab-org/security-products/security-report-schemas/-/raw/master/dist/container-scanning-report-format.json
        # JSON file path example /Users/username/Downloads/container-scanning-report.json
        print("Usage: python script.py [SCHEMA_URL] [JSON_FILE_PATH]")
    else:
        schema_url = sys.argv[1]
        json_file_path = sys.argv[2]
        main(schema_url, json_file_path)
