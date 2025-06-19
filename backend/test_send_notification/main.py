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
    print("--- RUNNING ON-DEMAND TEST (ISOLATED) ---")
    print("Fetching all users with an FCM token.")

    tokens = []
    users_ref = db.collection('users')
    
    for doc in users_ref.stream():
        user_data = doc.to_dict()
        if 'fcmToken' in user_data and user_data['fcmToken']:
            tokens.append(user_data['fcmToken'])
            
    if not tokens:
        print("No FCM tokens found. No test notifications will be sent.")
        return "No FCM tokens found.", 200

    print(f"Found {len(tokens)} tokens to send test notifications to.")

    request_json = request.get_json(silent=True)

    title = 'Food Sticker Jar (Test)'
    body = 'This is a test notification to verify the setup! 🛠️'

    if request_json:
        title = request_json.get('title', title)
        body = request_json.get('body', body)

    print(f"Sending notification with title: '{title}' and body: '{body}'")

    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title=title,
            body=body
        ),
        tokens=tokens,
    )

    try:
        batch_response = messaging.send_multicast(message)
        print(f"Successfully sent {batch_response.success_count} test messages.")
        if batch_response.failure_count > 0:
            print(f"Failed to send {batch_response.failure_count} test messages.")
            
        return f"Test notifications sent: {batch_response.success_count} successful, {batch_response.failure_count} failed.", 200
        
    except Exception as e:
        print(f"Error sending test notifications: {e}")
        return f"Error sending test notifications: {e}", 500 