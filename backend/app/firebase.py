import firebase_admin
from firebase_admin import credentials, auth, storage
from google.cloud.firestore import Client as FirestoreClient

from app.config import (
    FIREBASE_CREDENTIALS_PATH,
    FIREBASE_DATABASE_URL,
    FIREBASE_STORAGE_BUCKET,
)

_firestore_client: FirestoreClient | None = None


def init_firebase():
    global _firestore_client

    if firebase_admin._apps:
        return

    cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
    firebase_admin.initialize_app(
        cred,
        {
            "databaseURL": FIREBASE_DATABASE_URL,
            "storageBucket": FIREBASE_STORAGE_BUCKET,
        },
    )
    _firestore_client = FirestoreClient.from_service_account_json(
        FIREBASE_CREDENTIALS_PATH
    )


def get_firestore() -> FirestoreClient:
    if _firestore_client is None:
        raise RuntimeError("Firebase not initialized. Call init_firebase() first.")
    return _firestore_client
