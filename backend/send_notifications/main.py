import firebase_admin
from firebase_admin import firestore, messaging
import functions_framework
from datetime import datetime
from zoneinfo import ZoneInfo, available_timezones
from google.cloud.firestore_v1.base_query import FieldFilter

# Initialize Firebase Admin SDK. This is done once per function instance.
# Explicitly set the project ID to avoid any ambiguity.
options = {'projectId': 'foodjar-462805'}
firebase_admin.initialize_app(options=options)
db = firestore.client()

TARGET_HOURS = [7, 11, 13, 14, 15, 16,17, 18, 19, 20, 21, 22, 23]  # 7am, 11am, 5pm

@functions_framework.http
def send_daily_notification(request):
    """
    An HTTP-triggered Cloud Function that sends push notifications to users
    based on their local time. It's designed to be run hourly.
    """
    print("--- [PROD_NOTIF] Execution started. ---")
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
            print(f"--- [PROD_NOTIF] Could not process timezone {tz_name}: {e}")
            continue
            
    if not target_timezones:
        print(f"--- [PROD_NOTIF] No timezones match the current UTC hour: {utc_now.hour}. No notifications will be sent.")
        return "No target timezones for this hour.", 200

    print(f"--- [PROD_NOTIF] Found {len(target_timezones)} timezones matching target hours. Querying for users.")

    # 3. Fetch all users who are in one of the target timezones.
    tokens = []
    for i in range(0, len(target_timezones), 30):
        chunk = target_timezones[i:i + 30]
        users_ref = db.collection('users').where(filter=FieldFilter('timezone', 'in', chunk))
        docs = users_ref.stream()
        
        for doc in docs:
            user_data = doc.to_dict()
            if 'fcmToken' in user_data and user_data['fcmToken']:
                tokens.append(user_data['fcmToken'])
            
    if not tokens:
        print("--- [PROD_NOTIF] No FCM tokens found for users in the target timezones. No notifications sent.")
        return "No FCM tokens found for users in target timezones.", 200

    print(f"--- [PROD_NOTIF] Found {len(tokens)} tokens to send notifications to.")

    apns_payload = messaging.APNSPayload(aps=messaging.Aps(badge=1))
    
    message = messaging.MulticastMessage(
        notification=messaging.Notification(
            title='Food Sticker Jar',
            body='Don\'t forget to add your food today! 👑'
        ),
        tokens=tokens,
        apns=messaging.APNSConfig(payload=apns_payload)
    )

    try:
        print("--- [PROD_NOTIF] Attempting to send notifications via MULTICAST...")
        batch_response = messaging.send_multicast(message)
        print(f"--- [PROD_NOTIF] Multicast sent. Success: {batch_response.success_count}, Failure: {batch_response.failure_count}")
        return f"Notifications sent: {batch_response.success_count} successful, {batch_response.failure_count} failed.", 200
        
    except Exception as e:
        print(f"--- [PROD_NOTIF] !!! MULTICAST FAILED: {e}. Falling back to one-by-one sending.")
        
        success_count = 0
        failure_count = 0
        errors = []

        for token in tokens:
            single_message = messaging.Message(
                notification=messaging.Notification(title='Food Sticker Jar', body='Don\'t forget to add your food today! 👑'),
                token=token,
                apns=messaging.APNSConfig(payload=apns_payload)
            )
            try:
                messaging.send(single_message)
                success_count += 1
            except Exception as single_e:
                failure_count += 1
                errors.append(str(single_e))
        
        print(f"--- [PROD_NOTIF] One-by-one sending complete. Success: {success_count}, Failure: {failure_count}")

        if failure_count > 0:
            return f"Multicast failed. One-by-one sending finished with {failure_count} failures. Errors: {errors}", 500
        else:
            return f"Multicast failed, but one-by-one sending succeeded for all {success_count} tokens.", 200 