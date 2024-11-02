import requests
import json

def create_index_pattern(index_pattern, time_field_name):
    kibana_url = "http://kibana:5601"


    # API endpoint for creating index pattern
    api_endpoint = f"{kibana_url}/api/saved_objects/index-pattern"

    # Headers for the request
    headers = {
        "Content-Type": "application/json",
        "kbn-xsrf": "true"  # Required by Kibana for API requests
    }

    # Payload for the request
    payload = {
        "attributes": {
            "title": index_pattern,
            "timeFieldName": time_field_name  # Optional: specify the time field
        }
    }

    # Send the POST request to create the index pattern
    response = requests.post(api_endpoint, headers=headers, data=json.dumps(payload))

    # Check the response
    if response.status_code == 200:
        print("Index pattern created successfully.")
    else:
        print(f"Failed to create index pattern: {response.status_code} - {response.text}")


if __name__ == "__main__":
    create_index_pattern(
        "tomorrowdao_indexer-*.commitmentindex",
        "timestamp"
    )
    create_index_pattern(
        "aefinder.transactionindex-aelf-*",
        "blockTime"
    )