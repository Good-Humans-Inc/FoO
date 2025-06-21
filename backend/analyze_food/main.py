import functions_framework
import vertexai
import base64
import json
import traceback
from vertexai.generative_models import GenerativeModel, Part, GenerationConfig

# --- CONFIGURATION ---
PROJECT_ID = "foodjar-462805" 
LOCATION = "us-central1"

# --- PROMPTS ---
STANDARD_PROMPT = """
You are a food expert. Analyze the object in this image. Identify it and provide a fun fact about it.
The fun fact should be a single, interesting sentence about the object's history, origin, or a mindful eating tip.
If you cannot identify the object, set the `is_food` field to false, and the `name` and `fun_fact` fields to "???".
"""

SPECIAL_PROMPT = """
You are a food expert and a whimsical genius. Analyze the object in this image and provide a creative, fun response based on ONE of the following ideas. Do not use more than one idea. Keep your response to 2-3 short sentences.

1.  Anthropomorphize it: What is its greatest fear? Dream job? Spirit animal?
2.  Surprising fact: A historical, cultural, or scientific tidbit.
3.  Mindful eating nudge: Focus on its texture, taste, or color.
4.  A funny or interesting quote from the food or obect's perspective.
5.  Emoji story: 3-5 emojis that capture its essence (just the emojis).
6.  Haiku: A 5-7-5 poem.
7.  Theme song: A snippet of a real song that fits its vibe.
8.  Surprising use: An unusual way to eat or use it.
9.  Foreign name: Its name in another language, if interesting.

If you cannot identify the object, set the `is_food` field to false, and the `name` field to "???", and set `fun_fact` field to express that you cannot identify the object, in a funny or cute or creative or sassy way.
"""

@functions_framework.http
def analyze_food(request):
    """
    HTTP Cloud Function to analyze a food image using Gemini Pro Vision.
    Expects a JSON payload with an "image_data" key (base64-encoded image)
    and an optional "is_special" boolean flag.
    """
    print("--- analyze_food function execution started ---")
    # --- FIX: Initialize Vertex AI on first request ---
    try:
        print("Initializing Vertex AI...")
        print(f"--- Explicitly using LOCATION: {LOCATION} ---")
        vertexai.init(project=PROJECT_ID, location=LOCATION)
        print("Vertex AI initialized successfully.")
    except Exception as e:
        # If initialization fails, it's likely a config/permissions issue.
        print(f"!!! Vertex AI initialization failed: {e}")
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
    print(f"DEBUG: Received request payload: {request_json is not None}")
    if not request_json or 'image_data' not in request_json:
        print("ERROR: Invalid request, 'image_data' missing or payload is null.")
        return (json.dumps({"error": "Invalid request. Missing 'image_data' key."}), 400, headers)

    try:
        image_content = base64.b64decode(request_json['image_data'])
    except (TypeError, ValueError) as e:
        print(f"ERROR: Invalid base64 data: {e}")
        return (json.dumps({"error": f"Invalid base64 data: {e}"}), 400, headers)

    # --- 2. Personalize the Prompt ---
    user_profile = request_json.get('user_profile')
    personalization_intro = ""
    if user_profile and isinstance(user_profile, dict):
        # Construct a concise, context-setting sentence for the model.
        name = user_profile.get('name', 'the user')
        pronoun = user_profile.get('pronoun')
        age = user_profile.get('age')
        
        pronoun_text = f" (pronoun: {pronoun})" if pronoun else ""
        age_text = f", age {age}" if age else ""
        
        personalization_intro = f"This request is for {name}{pronoun_text}{age_text}. Keep this in mind for your response, but you don't have to use it."

    # --- 3. Select Prompt and Call Gemini ---
    is_special = request_json.get('is_special', False)
    base_prompt = SPECIAL_PROMPT if is_special else STANDARD_PROMPT
    prompt = personalization_intro + base_prompt
    print(f"DEBUG: Using {'SPECIAL' if is_special else 'STANDARD'} prompt.")
    print(f"DEBUG: using prompt: {prompt}")

    # Set a higher temperature for the special prompt to encourage more creative and varied responses.
    # A lower temperature for the standard prompt keeps the facts more consistent.
    temperature = 1.0 if is_special else 0.4

    # Define the response schema using standard Python tools.
    response_schema={
        "type": "object",
        "properties": {
            "is_food": {
                "type": "boolean",
                "description": "True if the object is food, otherwise False. If you cannot identify the object, set this to false."
            },
            "name": {
                "type": "string",
                "description": "The common name of the food or object, e.g. Avocado, Pepperoni Pizza, Oreos, AirPods 3. Put '???' if you cannot identify the object."
            },
            "fun_fact": {
                "type": "string",
                "description": "Something to tell the user about this food or object. Follow the instructions provided for fun_fact carefully."
            }
        },
        "required": ["is_food", "name", "fun_fact"]
    }
    
    # --- FIX: Manually construct GenerationConfig ---
    # When using preview models, it's safer to construct the config object
    # explicitly rather than relying on the dictionary conversion, which might
    # have compatibility issues with newer, rapidly changing models.
    generation_config_obj = GenerationConfig.from_dict({
        "temperature": temperature,
        "response_mime_type": "application/json",
        "response_schema": response_schema
    })
    print(f"DEBUG: Using generation config: {generation_config_obj}")
    
    model = GenerativeModel("gemini-2.5-flash") if is_special else GenerativeModel("gemini-2.0-flash-lite-001")

    image_part = Part.from_data(data=image_content, mime_type="image/png")
    
    try:
        print("DEBUG: Calling model.generate_content...")
        response = model.generate_content(
            [image_part, prompt],
            generation_config=generation_config_obj
        )
        print(f"DEBUG: Received response from model. Text length: {len(response.text)}")
        
        # --- 3. Parse and Return the Response ---
        # With a response schema, we can trust the response is valid JSON that matches our structure.
        parsed_json = json.loads(response.text)
        print(f"DEBUG: Successfully parsed JSON response: {parsed_json}")
        
        return (json.dumps(parsed_json), 200, headers)

    except Exception as e:
        # If anything goes wrong, return a structured error.
        print(f"!!! AN ERROR OCCURRED DURING ANALYSIS: {e}")
        print(f"    Exception Type: {type(e)}")
        print(f"    Traceback: {traceback.format_exc()}")
        error_payload = {
            "is_food": False,
            "name": "???",
            "fun_fact": f"(×_×;) An error occurred when analyzing this food: {e}"
        }
        return (json.dumps(error_payload), 500, headers) 