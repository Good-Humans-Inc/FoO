# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.

# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import https_fn, options

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app, firestore
import google.cloud.firestore
import vertexai
from vertexai.generative_models import GenerativeModel

initialize_app()
options.set_global_options(region=options.SupportedRegion.US_CENTRAL1)

@https_fn.on_call()
def generate_report(req: https_fn.Request) -> https_fn.Response:
    """
    Takes a list of food items and generates a nutritional report using the Gemini API.
    """
    try:
        # 1. Extract data from the request
        # Expects a JSON payload like: {"data": {"foodItems": [{"name": "Apple", "nutrition": "..."}]}}
        food_items = req.data.get("foodItems")
        if not food_items:
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Missing 'foodItems' in request payload.",
            )

        # 2. Initialize the Vertex AI client
        vertexai.init(project="foodjar-462805", location="us-central1")
        model = GenerativeModel(model_name="gemini-1.5-flash-001")

        # 3. Construct the prompt for Gemini
        # We create a simple summary of the food names to pass to the model.
        food_titles = [item.get("name", "Unknown Food") for item in food_items]
        nutrition_details = [item.get("nutrition", "") for item in food_items]
        
        prompt = f"""
        You are a friendly, encouraging nutritionist. Based on the following list of foods a user has consumed this week, please provide a brief, positive, and insightful weekly report.

        The user ate: {', '.join(food_titles)}.

        Here are the nutritional details for some of the items: {'; '.join(nutrition_details)}

        Please structure the report with the following sections, using markdown for formatting:

        **Macros Overview:** Briefly summarize the estimated intake of protein, fats, and carbohydrates. Provide a general calorie estimate.
        **Vitamin & Mineral Spotlight:** Highlight one or two key vitamins or minerals consumed this week and explain their benefits.
        **The Rainbow Check:** Comment on the variety and color of the foods eaten. Encourage eating a "rainbow" of foods for a wider range of nutrients.
        **Fiber Facts:** Briefly touch on the importance of fiber and estimate if the user had good sources of it this week.
        **A Positive Tip for Next Week:** Provide one simple, actionable, and encouraging tip for the user for the following week.

        Keep the tone light, positive, and non-judgmental. Start the report with a friendly greeting like "Here's your weekly food recap!".
        """

        # 4. Generate content using the Gemini API
        response = model.generate_content(prompt)
        report_text = response.text

        # 5. Return the generated report
        return https_fn.Response(report_text)

    except Exception as e:
        print(f"An error occurred: {e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="An unexpected error occurred while generating the report.",
        ) 