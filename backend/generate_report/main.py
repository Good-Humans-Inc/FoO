# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.

# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import https_fn, options

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app
import vertexai
from vertexai.generative_models import GenerativeModel
import logging

initialize_app()

# Configure logging
logging.basicConfig(level=logging.INFO)

@https_fn.on_call(
    region=options.SupportedRegion.US_CENTRAL1,
    memory=options.MemoryOption.MB_512
)
def generate_report(req: https_fn.Request) -> https_fn.Response:
    """
    Takes a list of food items and generates a nutritional report using the Gemini API.
    """
    logging.info("generate_report function triggered.")
    # 1. Check for authentication
    if req.auth is None:
        logging.error("Function called without authentication.")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="The function must be called while authenticated.",
        )
        
    try:
        # 2. Extract data from the request.
        payload = req.data
        logging.info(f"Received payload: {payload}")

        # Ensure payload is a dictionary as expected from the client
        if not isinstance(payload, dict) or "food_names" not in payload:
            logging.error(f"Invalid payload format. Expected a dict with 'food_names'. Payload: {payload}")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Payload must be a dictionary with a 'food_names' key.",
            )

        food_titles = payload.get("food_names", [])
        user_profile = payload.get("user_profile") # This can be None, handled below

        logging.info(f"Successfully parsed {len(food_titles)} food titles.")

        # Flatten the list in case it's a list of lists (e.g., [['apple'], ['banana']])
        flattened_titles = []
        for item in food_titles:
            if isinstance(item, str):
                flattened_titles.append(item)
            elif isinstance(item, list):
                flattened_titles.extend(item)  # Add all items from the sublist

        if not flattened_titles:
            logging.warning("List was empty after flattening.")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Food name list cannot be empty.",
            )

        # 3. Personalize the prompt using the user's profile
        personalization_intro = ""
        if user_profile and isinstance(user_profile, dict):
            name = user_profile.get('name', 'The user')
            pronoun = user_profile.get('pronoun')
            age = user_profile.get('age')
            goals = user_profile.get('goals', []) # Expecting goals to be a list

            pronoun_text = f" (pronoun: {pronoun})" if pronoun else ""
            age_text = f", age {age}," if age else ""
            
            goals_text = ""
            if goals and isinstance(goals, list) and len(goals) > 0:
                goals_text = f" who is working on these goals: {', '.join(goals)}"
            
            personalization_intro = f"""
This report is for {name}{age_text}{pronoun_text}{goals_text}.
Please tailor your feedback and tips to be especially encouraging and relevant to their context.
"""

        logging.info(f"Final flattened list before join: {flattened_titles}")
        # 4. Initialize the Vertex AI client
        vertexai.init(project="foodjar-462805", location="us-central1")
        model = GenerativeModel(model_name="gemini-1.5-flash")

        # 5. Construct the prompt for Gemini
        prompt = f"""{personalization_intro}
        You are a friendly, encouraging nutritionist. Based on the following list of foods a user has consumed this week, please provide a brief, positive, and insightful weekly report.

        The user ate: {', '.join(flattened_titles)}.

        Please structure the report with the following sections, using markdown for formatting:

        **Macros Overview:** Briefly summarize the estimated intake of protein, fats, and carbohydrates. Provide a general calorie estimate.
        **Vitamin & Mineral Spotlight:** Highlight one or two key vitamins or minerals consumed this week and explain their benefits.
        **The Rainbow Check:** Comment on the variety and color of the foods eaten. Encourage eating a "rainbow" of foods for a wider range of nutrients.
        **Fiber Facts:** Briefly touch on the importance of fiber and estimate if the user had good sources of it this week.
        **A Positive Tip for Next Week:** Provide one simple, actionable, and encouraging tip for the user for the following week.

        Keep the tone light, positive, and non-judgmental. Start the report with a friendly greeting like "Here's your weekly food recap, [User's Name]!". If you know their name, use it.
        """
        logging.info("Prompt constructed successfully. Sending to Gemini API.")
        
        # 6. Generate content using the Gemini API
        response = model.generate_content(prompt)
        logging.info(f"Received response from Gemini API: {response}")
        
        report_text = response.text
        logging.info("Successfully extracted text from Gemini response.")

        # 7. Return the generated report
        return report_text

    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}", exc_info=True)
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="An unexpected error occurred while generating the report.",
        ) 