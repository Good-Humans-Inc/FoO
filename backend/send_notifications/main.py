import firebase_admin
from firebase_admin import credentials, firestore, messaging
import functions_framework

# Initialize Firebase Admin SDK
# In a Google Cloud environment, the SDK can automatically find the service account credentials.
firebase_admin.initialize_app()

@functions_framework.http
def send_daily_notification(request):
    """
    An HTTP-triggered Cloud Function that sends a push notification
    to all users who have a valid FCM token.
    """
    db = firestore.client()
    
    # 1. Fetch all FCM tokens from the 'users' collection in Firestore.
    tokens = []
    users_ref = db.collection('users')
    docs = users_ref.stream()
    
    for doc in docs:
        user_data = doc.to_dict()
        if 'fcmToken' in user_data and user_data['fcmToken']:
            tokens.append(user_data['fcmToken'])
            
    if not tokens:
        print("No FCM tokens found. No notifications will be sent.")
        return "No FCM tokens found.", 200

    print(f"Found {len(tokens)} tokens to send notifications to.")

    # 2. Construct the notification message.
    # You can customize the title and body as you like.
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title='Food Sticker Jar',
            body='Don\'t forget to add your food today! 👑'
        ),
        tokens=tokens,
    )

    # 3. Send the notifications.
    try:
        batch_response = messaging.send_multicast(message)
        print(f"Successfully sent {batch_response.success_count} messages.")
        if batch_response.failure_count > 0:
            print(f"Failed to send {batch_response.failure_count} messages.")
            # You can inspect batch_response.responses for more details on failures.
            
        return f"Notifications sent: {batch_response.success_count} successful, {batch_response.failure_count} failed.", 200
        
    except Exception as e:
        print(f"Error sending notifications: {e}")
        return "Error sending notifications.", 500 