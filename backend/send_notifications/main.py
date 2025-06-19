import firebase_admin
from firebase_admin import credentials, firestore, messaging
import functions_framework
from datetime import datetime
from zoneinfo import ZoneInfo, available_timezones

# Global flag to ensure Firebase is initialized only once.
_firebase_app_initialized = False

TARGET_HOURS = [7, 11, 17]  # 7am, 11am, 5pm

@functions_framework.http
def send_daily_notification(request):
    """
    An HTTP-triggered Cloud Function that sends push notifications to users
    based on their local time. It's designed to be run hourly.
    """
    global _firebase_app_initialized
    if not _firebase_app_initialized:
        firebase_admin.initialize_app()
        _firebase_app_initialized = True
        
    db = firestore.client()
    
    # 1. Determine the current hour in UTC.
    utc_now = datetime.utcnow()
    
    # 2. Find all timezones where the current hour matches one of our target hours.
    target_timezones = []
    for tz_name in available_timezones():
        try:
            local_time = utc_now.astimezone(ZoneInfo(tz_name))
            if local_time.hour in TARGET_HOURS:
                target_timezones.append(tz_name)
        except Exception as e:
            # Some timezones in the list might be invalid or aliases, so we ignore them.
            print(f"Could not process timezone {tz_name}: {e}")
            continue
            
    if not target_timezones:
        print(f"No timezones match the current UTC hour: {utc_now.hour}. No notifications will be sent.")
        return "No target timezones for this hour.", 200

    print(f"Found {len(target_timezones)} timezones matching target hours. Querying for users.")

    # 3. Fetch all users who are in one of the target timezones.
    # Firestore 'in' query is limited to 30 elements, so we must batch the query.
    tokens = []
    # Split target_timezones into chunks of 30
    for i in range(0, len(target_timezones), 30):
        chunk = target_timezones[i:i + 30]
        users_ref = db.collection('users').where('timezone', 'in', chunk)
        docs = users_ref.stream()
        
        for doc in docs:
            user_data = doc.to_dict()
            if 'fcmToken' in user_data and user_data['fcmToken']:
                tokens.append(user_data['fcmToken'])
            
    if not tokens:
        print("No FCM tokens found for users in the target timezones. No notifications sent.")
        return "No FCM tokens found for users in target timezones.", 200

    print(f"Found {len(tokens)} tokens to send notifications to.")

    # 4. Construct and send the notification message.
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title='Food Sticker Jar',
            body='Don\'t forget to add your food today! 👑'
        ),
        tokens=tokens,
    )

    try:
        batch_response = messaging.send_multicast(message)
        print(f"Successfully sent {batch_response.success_count} messages.")
        if batch_response.failure_count > 0:
            print(f"Failed to send {batch_response.failure_count} messages.")
            # Clean up invalid tokens in a real-world app
            
        return f"Notifications sent: {batch_response.success_count} successful, {batch_response.failure_count} failed.", 200
        
    except Exception as e:
        print(f"Error sending notifications: {e}")
        return "Error sending notifications.", 500 