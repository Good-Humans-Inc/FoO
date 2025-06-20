# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.

# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
from firebase_functions import https_fn, options

# The Firebase Admin SDK to access Cloud Firestore.
from firebase_admin import initialize_app
import vertexai
from vertexai.generative_models import GenerativeModel

initialize_app()
options.set_global_options(region=options.SupportedRegion.US_CENTRAL1)

@https_fn.on_call()
def generate_report(req: https_fn.Request) -> https_fn.Response:
    """
    Takes a list of food items and generates a nutritional report using the Gemini API.
    """
    # 1. Check for authentication
    if req.auth is None:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            message="The function must be called while authenticated.",
        )
        
    try:
        # 2. Extract data from the request. The payload should be a list of strings.
        food_titles = req.data
        if not isinstance(food_titles, list):
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Payload must be a list of food name strings.",
            )
        if not food_titles:
            # This case is handled by the client, but it's good practice to have a safeguard.
            raise https_fn.HttpsError(
                code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
                message="Food name list cannot be empty.",
            )

        # 3. Initialize the Vertex AI client
        vertexai.init(project="foodjar-462805", location="us-central1")
        model = GenerativeModel(model_name="gemini-2.0-flash-001")

        # 4. Construct the prompt for Gemini
        prompt = f"""
        You are a friendly, encouraging nutritionist. Based on the following list of foods a user has consumed this week, please provide a brief, positive, and insightful weekly report.

        The user ate: {', '.join(food_titles)}.

        Please structure the report with the following sections, using markdown for formatting:

        **Macros Overview:** Briefly summarize the estimated intake of protein, fats, and carbohydrates. Provide a general calorie estimate.
        **Vitamin & Mineral Spotlight:** Highlight one or two key vitamins or minerals consumed this week and explain their benefits.
        **The Rainbow Check:** Comment on the variety and color of the foods eaten. Encourage eating a "rainbow" of foods for a wider range of nutrients.
        **Fiber Facts:** Briefly touch on the importance of fiber and estimate if the user had good sources of it this week.
        **A Positive Tip for Next Week:** Provide one simple, actionable, and encouraging tip for the user for the following week.

        Keep the tone light, positive, and non-judgmental. Start the report with a friendly greeting like "Here's your weekly food recap!".
        """

        # 5. Generate content using the Gemini API
        response = model.generate_content(prompt)
        report_text = response.text

        # 6. Return the generated report
        return report_text

    except Exception as e:
        print(f"An error occurred: {e}")
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INTERNAL,
            message="An unexpected error occurred while generating the report.",
        ) 