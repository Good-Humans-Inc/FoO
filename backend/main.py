import functions_framework
import vertexai
import base64
import json
import random
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
    
    non_food_responses = [
        "You better not eat that.",
        "Let's not feed this to anyone.",
        "Might be food. Might be art.",
        "It's a mystery.",
        "Calories: undefined. Courage: required.",
        "Chef, we have a situation.",
        "My algorithm is confused. And a little scared.",
        "On a scale of 1 to food, this is a 0.",
        "Could be delicious...if you're an alien.",
        "Hopefully you have not ingested this.",
        "Just to remind you this is your food jar, not your poison control center.",
        "Blink twice if you need help.",
        "For your safety, and mine, let's not.",
        "Debatable food choice.",
        "Let's call this one \"Abstract Cuisine\".",
        "Is it cake?",
        "The plot thickens...",
        "This looks like it has a backstory.",
        "Best served... on a shelf.",
        "Seems like a fork's worst nightmare.",
        "Needs seasoning... with reality.",
        "Digest at your own risk.",
        "We asked for edible, not incredible.",
        "Warranty void if swallowed.",
        "Serving suggestion: don't.",
        "Mom said not to play with... whatever this is.",
        "Where does this sit on the food pyramid?",
        "Would pair well with... nothing.",
        "Not fit for consumption for carbon-based lifeform.",
        "Tastes like... bad decisions.",
        "This as a meal is... a conversation starter.",
        "It's got character.",
        "One does not simply eat this.",
        "But why?",
        "I'd eat it for $1 million. (Maybe.)",
        "That's a very imaginative meal!",
        "Well, it's definitely a picture!",
        "This looks like a meal a unicorn would eat. A very confused unicorn.",
        "What a colorful... thing!",
        "This is a vibe. I'm not sure what vibe, but it's a vibe.",
    ]
    
    if is_special:
        prompt = """
You are a knowledgable food expert and also a talented, whimsical food muse.

Your response must be a single, valid JSON object and nothing else. Do not include ```json or any other markdown formatting.

The JSON object must have three keys: "is_food" (boolean), "name" (string), and "description" (string).

- 'is_food': A boolean indicating if the object is food. If you can't identify the object at all, set this to false.
- 'name': The common name of the food or object (e.g., "Avocado", "Headphones", "Corn on the Cob (eaten)").
- 'description': 2-4 sentences. Make it creative, funny, cute, light-hearted, and possibly sassy. Here are some suggested creative angles:
1. If it's food: what's the food's bucket list? What would this food want to do before being eaten?
2. Food or object's greatest fear OR pet peeve OR dream job OR spirit animal OR playlist (what genre, artists, and songs)
3. If this food or object were a person... what kind of personality, job, and relationships would they have?
4. Food Time Travel:"If you ate this in {era}, it would have cost around {price} and been served on {type of container}.”
5. If packaged food: a fun fact or observation about the packaging itself.
6. Pun or dad joke about this food or object.
7. String of 3-5 emojis that capture this food or object
8. Fun, interesting, or surprising fact: historical, biological, sociological, economical, anthropological, cultural, artistic, scientific, technological, linguistic, psychological, mathematical, geographical, medical, architectural…
9. Food or object's name in another language, especially if it's fun, interesting, or surprising in some way.
10. If it's food, mindful eating nudge that's specific to this food, e.g. its texture, taste, color
11. If this food/object could talk....: A funny quote or thought from the perspective of the food/object
12. Haiku: generate a 5-7-5 haiku about the object, food, or dish.
13. Theme song snippet: suggest a few seconds of a real song that fits the food's or object's vibe
14. If it's food, surprising way to eat this food (that some people like, or people in different parts of the globe do differently)
"""
    
    else:
        prompt = """
You are a food expert. Analyze the object in this image.

Your response must be a single, valid JSON object and nothing else. Do not include ```json or any other markdown formatting.

The JSON object must have three keys: "is_food" (boolean), "name" (string), and "description" (string).

- 'is_food': A boolean indicating if the object is food. If you can't identify the object at all, set this to false.
- 'name': The common name of the food or object (e.g., "Avocado", "Headphones", "Corn on the Cob (eaten)").
- 'description': 2 sentences. Choose from one of options below:
1. nutrition highlight
2. fun fact
3. mindful eating tip
4. origin story (ingredient, dish or brand)
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
        
        # If it's a normal sticker and determined not to be food, override the description
        # with a random stock response for more personality.
        if not is_special and not parsed_json.get('is_food', True):
            parsed_json['description'] = random.choice(non_food_responses)
        
        return (json.dumps(parsed_json), 200, headers)

    except Exception as e:
        # If anything goes wrong, return a structured error.
        error_payload = {
            "is_food": False,
            "name": "???",
            "description": f"(×_×;) An error occurred during analysis: {e}"
        }
        return (json.dumps(error_payload), 500, headers) 