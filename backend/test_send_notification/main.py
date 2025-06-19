import firebase_admin
from firebase_admin import firestore, messaging
import functions_framework

# Initialize Firebase Admin SDK. This is done once per function instance.
firebase_admin.initialize_app()
db = firestore.client()

@functions_framework.http
def test_send_notification(request):
    """
    A dedicated, HTTP-triggered Cloud Function for sending a test notification to ALL
    users with a valid FCM token. This function is isolated in its own deployment
    for maximum safety.
    """
    print("--- [FCM_DEBUG] Execution started. ---")
    print("--- RUNNING ON-DEMAND TEST (ISOLATED) ---")
    print("--- [FCM_DEBUG] Fetching all users with an FCM token from 'users' collection.")

    tokens = []
    users_ref = db.collection('users')

    for doc in users_ref.stream():
        user_data = doc.to_dict()
        if 'fcmToken' in user_data and user_data['fcmToken']:
            token = user_data['fcmToken']
            tokens.append(token)
            # Log last 10 chars for identification without exposing the full token
            print(f"--- [FCM_DEBUG] Found token ending in: ...{token[-10:]}")
            
    if not tokens:
        print("--- [FCM_DEBUG] No FCM tokens found. No test notifications will be sent.")
        return "No FCM tokens found.", 200

    print(f"--- [FCM_DEBUG] Found a total of {len(tokens)} tokens.")

    request_json = request.get_json(silent=True)
    
    title = 'Food Sticker Jar (Test)'
    body = 'This is a test notification to verify the setup! 🛠️'

    if request_json:
        print(f"--- [FCM_DEBUG] Request contains JSON payload: {request_json}")
        title = request_json.get('title', title)
        body = request_json.get('body', body)
    else:
        print("--- [FCM_DEBUG] No JSON payload in request. Using default message.")

    print(f"--- [FCM_DEBUG] Preparing to send notification with Title='{title}' and Body='{body}'")

    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        tokens=tokens,
    )

    try:
        print("--- [FCM_DEBUG] Attempting to send notifications via MULTICAST...")
        batch_response = messaging.send_multicast(message)
        print("--- [FCM_DEBUG] Multicast request completed.")
        print(f"--- [FCM_DEBUG] Success count: {batch_response.success_count}")
        print(f"--- [FCM_DEBUG] Failure count: {batch_response.failure_count}")
        if batch_response.failure_count > 0:
            print("--- [FCM_DEBUG] Failures detected. Logging errors for each failed token:")
            for i, response in enumerate(batch_response.responses):
                if not response.success:
                    failed_token = tokens[i]
                    print(f"--- [FCM_DEBUG]   - Token ...{failed_token[-10:]}: {response.exception}")
            
        return f"Test notifications sent: {batch_response.success_count} successful, {batch_response.failure_count} failed.", 200
        
    except Exception as e:
        print(f"--- [FCM_DEBUG] !!! MULTICAST SEND FAILED !!!")
        print(f"--- [FCM_DEBUG] Exception: {e}")
        print("--- [FCM_DEBUG] Falling back to sending ONE-BY-ONE as a diagnostic measure.")
        
        success_count = 0
        failure_count = 0
        errors = []

        for i, token in enumerate(tokens):
            print(f"--- [FCM_DEBUG]   - Sending to token {i+1}/{len(tokens)} (...{token[-10:]})")
            single_message = messaging.Message(
                notification=messaging.Notification(title=title, body=body),
                token=token,
            )
            try:
                messaging.send(single_message)
                success_count += 1
                print(f"--- [FCM_DEBUG]     ... Success")
            except Exception as single_e:
                failure_count += 1
                print(f"--- [FCM_DEBUG]     ... Failure")
                print(f"--- [FCM_DEBUG]       Error: {single_e}")
                errors.append(str(single_e))

        print(f"--- [FCM_DEBUG] One-by-one sending complete. Success: {success_count}, Failure: {failure_count}")

        if failure_count > 0:
            return f"Multicast failed. One-by-one sending finished with {failure_count} failures. Errors: {errors}", 500
        else:
            return f"Multicast failed, but one-by-one sending succeeded for all {success_count} tokens.", 200 