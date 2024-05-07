from typing import Annotated
from fastapi import Depends, Header, HTTPException, status
from jose import JWTError, jwt

from .config.config import Settings, get_settings


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
