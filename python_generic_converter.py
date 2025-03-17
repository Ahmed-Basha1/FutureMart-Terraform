import json
import re

def make_dashboard_generic(input_file, output_file):
    with open(input_file, "r", encoding="utf-8") as file:
        data = json.load(file)

    # Function to remove subscription IDs from resource paths
    def remove_subscription_ids(value):
        return re.sub(r"/subscriptions/[0-9a-fA-F-]+", "/subscriptions/{current-subscription}", value)

    # Iterate through dashboard components
    for lens in data.get("properties", {}).get("lenses", []):
        for part in lens.get("parts", []):
            metadata = part.get("metadata", {})
            
            # Update queries to be subscription-agnostic
            for input_item in metadata.get("inputs", []):
                if isinstance(input_item, dict):  # Ensure it's a dictionary
                    if input_item.get("name") == "query" and "value" in input_item:
                        input_item["value"] = input_item["value"].replace("==", "=~")  # Make queries case-insensitive
                
                    # Remove subscription-specific scope
                    if input_item.get("name") == "queryScope" and "value" in input_item:
                        input_item["value"] = {"scope": 1, "values": ["current"]}

            # Remove subscription IDs from resource paths in settings
            settings = metadata.get("settings", {})
            for key, value in settings.items():
                if isinstance(value, dict):
                    for sub_key, sub_value in value.items():
                        if isinstance(sub_value, str):
                            settings[key][sub_key] = remove_subscription_ids(sub_value)

            # Remove hardcoded subscription IDs in resource metadata
            if "content" in settings:
                content = settings["content"]
                if "options" in content and "chart" in content["options"]:
                    for metric in content["options"]["chart"].get("metrics", []):
                        if "resourceMetadata" in metric and "id" in metric["resourceMetadata"]:
                            metric["resourceMetadata"]["id"] = remove_subscription_ids(metric["resourceMetadata"]["id"])

    # Update the dashboard name
    data["name"] = "GenericAzureDashboard"
    data["tags"]["hidden-title"] = "Generic Azure Dashboard"
    
    # Save the modified JSON
    with open(output_file, "w", encoding="utf-8") as file:
        json.dump(data, file, indent=2)

    print(f"✅ Generic Azure Dashboard saved as: {output_file}")

# Usage
make_dashboard_generic("DB.json", "Generic_DB.json")
