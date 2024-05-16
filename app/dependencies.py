from typing import Annotated
from fastapi import Depends, Header, HTTPException, status, Request
from jose import JWTError, jwt
from logging import Logger
import base64
import json
from google.oauth2 import service_account
from google.cloud import pubsub_v1, storage
from google.cloud.storage import Bucket

from .config.config import Settings, get_settings
from logger.app_logger import get_app_logger


def get_logger():
    return get_app_logger(__name__)


def get_publisher_client(settings: Annotated[Settings, Depends(get_settings)]):
    encoded_key = settings.service_account_key
    decoded_key = base64.b64decode(encoded_key)
    service_account_info = json.loads(decoded_key)

    credentials = service_account.Credentials.from_service_account_info(
        service_account_info
    )
    publisher_client = pubsub_v1.PublisherClient(credentials=credentials)
    return publisher_client


def get_subscriber_client(settings: Annotated[Settings, Depends(get_settings)]):
    encoded_key = settings.service_account_key
    decoded_key = base64.b64decode(encoded_key)
    service_account_info = json.loads(decoded_key)

    credentials = service_account.Credentials.from_service_account_info(
        service_account_info
    )
    subscriber_client = pubsub_v1.SubscriberClient(credentials=credentials)
    return subscriber_client


def get_storage_bucket(settings: Annotated[Settings, Depends(get_settings)]) -> Bucket:
    encoded_key = settings.service_account_key
    decoded_key = base64.b64decode(encoded_key)
    service_account_info = json.loads(decoded_key)

    credentials = service_account.Credentials.from_service_account_info(
        service_account_info
    )
    storage_client = storage.Client(credentials=credentials)

    bucket_name = settings.bucket_name
    bucket = storage_client.bucket(bucket_name)

    return bucket


class TokenPayload:
    def __init__(self, doctorId, doctorName, fullName, iat, exp):
        self.user_id = doctorId
        self.username = doctorName
        self.full_name = fullName


# Define common authentication exception
credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate credentials, or it may not exists.",
    headers={"WWW-Authenticate": "Bearer"},
)


def get_jwt_secret(settings: Annotated[Settings, Depends(get_settings)]):
    # Decode the Encoded JWT config
    jwt_secret = settings.jwt_secret

    return jwt_secret


def check_auth_token_header(auth_token: Annotated[str | None, Header()] = None):
    if auth_token is None:
        raise credentials_exception
    else:
        return auth_token


def validate_auth_token(
    jwt_secret: Annotated[str, Depends(get_jwt_secret)],
    auth_token: Annotated[str, Depends(check_auth_token_header)],
):
    ALGORITHM = "HS256"

    try:
        # Decode the token and extract the payload
        decoded_token = jwt.decode(auth_token, jwt_secret, algorithms=[ALGORITHM])
        token_payload_data: dict = decoded_token
        token_payload = TokenPayload(**token_payload_data)

        # Check the token payload
        if token_payload is None or token_payload.user_id is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    except Exception as e:
        error_message = f"An error occurred: {e}"
        print(error_message)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=error_message
        )
