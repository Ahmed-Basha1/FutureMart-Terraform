import json

def replace_placeholders(obj, subscription_id, subscription_name):
    """Recursively replace placeholders in JSON data."""
    if isinstance(obj, dict):
        return {key: replace_placeholders(value, subscription_id, subscription_name) for key, value in obj.items()}
    elif isinstance(obj, list):
        return [replace_placeholders(item, subscription_id, subscription_name) for item in obj]
    elif isinstance(obj, str):
        return obj.replace("{subscription-id}", subscription_id).replace("{subscription-name}", subscription_name)
    else:
        return obj  # Return as is if not a dict, list, or string

def convert_to_terraform_format(input_file, output_file):
    # Ask for user input
    subscription_id = input("Enter Subscription ID: ").strip()
    subscription_name = input("Enter Subscription Name: ").strip()

    with open(input_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Convert lenses array to a dictionary (map)
    if "lenses" in data and isinstance(data["lenses"], list):
        data["lenses"] = {str(i): lens for i, lens in enumerate(data["lenses"])}

        # Convert parts array inside each lens to a dictionary
        for lens in data["lenses"].values():
            if "parts" in lens and isinstance(lens["parts"], list):
                lens["parts"] = {str(i): part for i, part in enumerate(lens["parts"])}

    # Recursively replace placeholders
    data = replace_placeholders(data, subscription_id, subscription_name)

    # Save the modified JSON
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)

    print(f"Converted JSON saved as: {output_file}")

# Usage
input_json = "Dashboard.json"  # Change this to your actual JSON file
output_json = "Fixed_Dashboard.json"

convert_to_terraform_format(input_json, output_json)
