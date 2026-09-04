import logging
import os
from typing import List
import firebase_admin
from firebase_admin import credentials, messaging

logger = logging.getLogger(__name__)

class NotificationService:
    def __init__(self):
        self.is_configured = False
        try:
            # Check if firebase app is already initialized
            if not firebase_admin._apps:
                cred_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "firebase-adminsdk.json")
                if os.path.exists(cred_path):
                    cred = credentials.Certificate(cred_path)
                    firebase_admin.initialize_app(cred)
                    self.is_configured = True
                    logger.info("Firebase Admin initialized successfully.")
                else:
                    logger.warning(f"Firebase credentials not found at {cred_path}. FCM is disabled.")
            else:
                self.is_configured = True
        except Exception as e:
            logger.error(f"Failed to initialize Firebase Admin: {e}")

    async def send_push_notification(self, user_id: str, title: str, body: str, data: dict = None):
        if not self.is_configured:
            logger.warning(f"FCM not configured. Skipping push notification to user {user_id}: {title}")
            return False
            
        logger.info(f"Sending push notification to user {user_id}: {title}")
        
        # In a real app we'd fetch the FCM token from DB for the user_id
        # Here we assume the user_id might actually be the fcm token for testing
        # Or you'd query the DB: user = db.query(models.User).filter(models.User.username == user_id).first()
        # if not user or not user.fcm_token: return False
        
        # For this prototype we will assume the caller passes the token directly in the user_id field or
        # if user_id is missing we don't send.
        token = user_id 
        
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data=data or {},
            token=token,
        )
        try:
            response = messaging.send(message)
            logger.info(f"Successfully sent message: {response}")
            return True
        except Exception as e:
            logger.error(f"Error sending FCM message: {e}")
            return False

    async def broadcast_alert(self, alert_id: str, title: str, body: str, location_polygon: List[tuple] = None):
        """
        Send an emergency alert to all devices registered within a certain area.
        """
        if not self.is_configured:
            logger.warning(f"FCM not configured. Skipping alert broadcast: {title}")
            return False
            
        logger.info(f"Broadcasting emergency alert {alert_id} via topic messaging.")
        message = messaging.Message(
            notification=messaging.Notification(
                title=title,
                body=body,
            ),
            data={"alert_id": alert_id},
            topic="weather_alerts",
        )
        try:
            response = messaging.send(message)
            logger.info(f"Successfully sent broadcast alert: {response}")
            return True
        except Exception as e:
            logger.error(f"Error sending FCM broadcast message: {e}")
            return False
