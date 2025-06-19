import functions_framework
import vertexai
import base64
import json
from vertexai.generative_models import GenerativeModel, Part

# --- CONFIGURATION ---
PROJECT_ID = "foodjar-462805" 
LOCATION = "us-central1"

# --- REMOVED GLOBAL INITIALIZATION ---
# The vertexai.init() call is now inside the function handler.
# This prevents the container from crashing on startup if the API is not enabled
# or if permissions are incorrect.

@functions_framework.http
def analyze_food(request):
    """
    HTTP Cloud Function to analyze a food image using Gemini Pro Vision.
    Expects a JSON payload with a "image_data" key containing a base64-encoded image.
    """
    # --- FIX: Initialize Vertex AI on first request ---
    try:
        vertexai.init(project=PROJECT_ID, location=LOCATION)
    except Exception as e:
        # If initialization fails, it's likely a config/permissions issue.
        return (json.dumps({"error": f"Vertex AI initialization failed: {e}"}), 500, {'Access-Control-Allow-Origin': '*'})

    # Set CORS headers to allow requests from any origin.
    # This is necessary for your Swift app to call this function.
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    headers = { 'Access-Control-Allow-Origin': '*' }

    # --- 1. Parse and Validate the Request ---
    request_json = request.get_json(silent=True)
    if not request_json or 'image_data' not in request_json:
        return (json.dumps({"error": "Invalid request. Missing 'image_data' key."}), 400, headers)

    # Also get the 'is_special' flag from the request. Default to False if not provided.
    is_special = request_json.get('is_special', False)

    try:
        image_content = base64.b64decode(request_json['image_data'])
    except (TypeError, ValueError) as e:
        return (json.dumps({"error": f"Invalid base64 data: {e}"}), 400, headers)

    # --- 2. Prepare the Prompt and Call Gemini ---
    model = GenerativeModel("gemini-2.0-flash")
    image_part = Part.from_data(data=image_content, mime_type="image/png")
    
    if is_special:
        prompt = """
You are a whimsical food muse for a children's game. A child has just discovered a rare, magical version of the food in this image.

Your response must be a single, valid JSON object and nothing else. Do not include ```json or any other markdown formatting.

The JSON object must have three keys: "is_food" (boolean), "name" (string), and "description" (string).

- 'is_food': A boolean indicating if the object is food.
- 'name': The common name of the food (e.g., "Avocado", "Pepperoni Pizza"). If unknown, use "Enchanted Enigma".
- 'description': A short, creative, and imaginative text about this specific food item. Pick one of the following creative angles:
    - "Food's Playlist": A few types of music this food would listen to and why.
    - "Food's Spirit Animal": A playful comparison of the food to an animal.
    - "A Tiny Poem": A short, whimsical poem about the food.
    - "Origin Story": A magical origin story.
If it's not food, invent a fantastical purpose for the object. If unknown, write: "Woah! This one is shimmering with untold secrets. Its story is a puzzle, wrapped in an enigma, sprinkled with stardust."
"""
    else:
        prompt = """
You are a food expert. Analyze the object in this image.

Your response must be a single, valid JSON object and nothing else. Do not include ```json or any other markdown formatting.

The JSON object must have three keys: "is_food" (boolean), "name" (string), and "description" (string).

- 'is_food': A boolean indicating if the object is food.
- 'name': The common name of the food or object (e.g., "Avocado", "Headphones"). If unknown, use "Mystery Morsel".
- 'description': A concise, friendly paragraph. Combine a fun fact, a brief nutritional highlight, and maybe a mindful eating tip. If it's not food, give a playful, safe-for-work roast of the object. If unknown, say "My circuits are buzzing with mystery! I'm not sure what this is, but it definitely looks interesting."
"""

    try:
        response = model.generate_content([image_part, prompt])
        
        # --- 3. Clean, Parse, and Return the Response ---
        response_text = response.text
        json_start = response_text.find('{')
        json_end = response_text.rfind('}') + 1
        
        if json_start == -1 or json_end == 0:
            raise ValueError("No JSON object found in the Gemini response.")
            
        json_string = response_text[json_start:json_end]
        parsed_json = json.loads(json_string)

        # Ensure the response has the required keys before adding a placeholder, to avoid overwriting.
        if 'is_food' not in parsed_json: parsed_json['is_food'] = False
        if 'name' not in parsed_json: parsed_json['name'] = "???"
        if 'description' not in parsed_json: parsed_json['description'] = "(×_×;) Confused..."
        
        return (json.dumps(parsed_json), 200, headers)

    except Exception as e:
        # If anything goes wrong, return a structured error.
        error_payload = {
            "is_food": False,
            "name": "???",
            "description": f"(×_×;) An error occurred during analysis: {e}"
        }
        return (json.dumps(error_payload), 500, headers) 