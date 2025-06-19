import firebase_admin
from firebase_admin import credentials, firestore, messaging
import functions_framework

# Initialize Firebase Admin SDK
firebase_admin.initialize_app()

@functions_framework.http
def test_send_notification(request):
    """
    A dedicated, HTTP-triggered Cloud Function for sending a test notification to ALL
    users with a valid FCM token. This function is isolated in its own deployment
    for maximum safety.
    """
    db = firestore.client()
    
    print("--- RUNNING ON-DEMAND TEST (ISOLATED) ---")
    print("Fetching all users with an FCM token.")

    tokens = []
    users_ref = db.collection('users')
    docs = users_ref.stream()
    
    for doc in docs:
        user_data = doc.to_dict()
        if 'fcmToken' in user_data and user_data['fcmToken']:
            tokens.append(user_data['fcmToken'])
            
    if not tokens:
        print("No FCM tokens found. No test notifications will be sent.")
        return "No FCM tokens found.", 200

    print(f"Found {len(tokens)} tokens to send test notifications to.")

    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title='Food Sticker Jar (Test)',
            body='This is a test notification to verify the setup! 🛠️'
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
        return "Error sending test notifications.", 500 