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

    try:
        image_content = base64.b64decode(request_json['image_data'])
    except (TypeError, ValueError) as e:
        return (json.dumps({"error": f"Invalid base64 data: {e}"}), 400, headers)

    # --- 2. Prepare the Prompt and Call Gemini ---
    model = GenerativeModel("gemini-2.0-flash")
    image_part = Part.from_data(data=image_content, mime_type="image/png")
    
    prompt = """
You are a food expert. Analyze the object in this image. If it is a food item, identify it and provide a fun fact and nutritional information.

Your response must be a single, valid JSON object and nothing else. Do not include ```json or any other markdown formatting.

The JSON object must have three keys: "name" (string), "fun_fact" (string), and "nutrition" (string).

- The 'name' should be the common name of the food (e.g., "Avocado", "Pepperoni Pizza").
- The 'fun_fact' should be a single, interesting sentence about the food's history, origin, or a surprising fact.
- The 'nutrition' should be a concise summary of key nutritional values (e.g., "Rich in Vitamin C and fiber. A good source of potassium.").

If the object is not a food item or you cannot identify it, the value for all three keys must be the string "N/A".
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
        
        return (json.dumps(parsed_json), 200, headers)

    except Exception as e:
        # If anything goes wrong, return a structured error.
        error_payload = {
            "name": "Analysis Failed",
            "fun_fact": f"An error occurred during analysis: {e}",
            "nutrition": "Please try again later."
        }
        return (json.dumps(error_payload), 500, headers) 