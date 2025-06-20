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

        food_titles = []
        if isinstance(payload, list):
            food_titles = payload
        elif isinstance(payload, dict):
            # If the payload is a dict, assume the values are the food titles.
            # This can happen depending on how the client SDK serializes an array.
            food_titles = list(payload.values())
        else:
            logging.error(f"Invalid payload type: {type(payload)}. Expected a list or dict.")
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Payload must be a list of food name strings.",
            )

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

        logging.info(f"Final flattened list before join: {flattened_titles}")
        # 3. Initialize the Vertex AI client
        vertexai.init(project="foodjar-462805", location="us-central1")
        model = GenerativeModel(model_name="gemini-2.0-flash")

        # 4. Construct the prompt for Gemini
        prompt = f"""
        You are a friendly, encouraging nutritionist. Based on the following list of foods a user has consumed this week, please provide a brief, positive, and insightful weekly report.

        The user ate: {', '.join(flattened_titles)}.

        Please structure the report with the following sections, using markdown for formatting:

        **Macros Overview:** Briefly summarize the estimated intake of protein, fats, and carbohydrates. Provide a general calorie estimate.
        **Vitamin & Mineral Spotlight:** Highlight one or two key vitamins or minerals consumed this week and explain their benefits.
        **The Rainbow Check:** Comment on the variety and color of the foods eaten. Encourage eating a "rainbow" of foods for a wider range of nutrients.
        **Fiber Facts:** Briefly touch on the importance of fiber and estimate if the user had good sources of it this week.
        **A Positive Tip for Next Week:** Provide one simple, actionable, and encouraging tip for the user for the following week.

        Keep the tone light, positive, and non-judgmental. Start the report with a friendly greeting like "Here's your weekly food recap!".
        """
        logging.info("Prompt constructed successfully. Sending to Gemini API.")
        
        # 5. Generate content using the Gemini API
        response = model.generate_content(prompt)
        logging.info(f"Received response from Gemini API: {response}")
        
        report_text = response.text
        logging.info("Successfully extracted text from Gemini response.")

        # 6. Return the generated report
        return report_text

    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}", exc_info=True)
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="An unexpected error occurred while generating the report.",
        ) 