from typing import Annotated
from fastapi import Depends, Header, HTTPException, status
from jose import JWTError, jwt
import base64
import json

from .config.config import Settings, get_settings


class TokenPayload:
    def __init__(self, userId, username, fullName):
        self.user_id = userId
        self.username = username
        self.full_name = fullName


class JwtConfig:
    def __init__(
        self,
        jwt_secret: str,
        jwt_refresh_secret: str,
        jwt_testing_secret: str,
        jwt_expiration: int,
        jwt_refresh_expiration: int,
    ):
        self.jwt_secret = jwt_secret
        self.jwt_refresh_secret = jwt_refresh_secret
        self.jwt_testing_secret = jwt_testing_secret
        self.jwt_expiration = jwt_expiration
        self.jwt_refresh_expiration = jwt_refresh_expiration


# Define common authentication exception
credentials_exception = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="Could not validate credentials, or it may not exists.",
    headers={"WWW-Authenticate": "Bearer"},
)


def decode_jwt_config(settings: Annotated[Settings, Depends(get_settings)]):
    # Decode the Encoded JWT config
    encoded_jwt_config = settings.jwt_config

    decoded_bytes = base64.b64decode(encoded_jwt_config)
    decoded_json = decoded_bytes.decode("utf-8")
    decoded_dict = json.loads(decoded_json)

    jwt_config = JwtConfig(**decoded_dict)

    return jwt_config


def check_auth_token_header(auth_token: Annotated[str | None, Header()] = None):
    if auth_token is None:
        raise credentials_exception
    else:
        return auth_token


def validate_auth_token(
    jwt_config: Annotated[JwtConfig, Depends(decode_jwt_config)],
    auth_token: Annotated[str, Depends(check_auth_token_header)],
):
    jwt_secret = jwt_config.jwt_secret
    ALGORITHM = "HS256"

    try:
        # Decode the token and extract the payload
        decoded_token = jwt.decode(auth_token, jwt_secret, algorithms=[ALGORITHM])
        token_payload_data: dict = decoded_token.get("tokenPayload")
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
