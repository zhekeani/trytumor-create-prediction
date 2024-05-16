from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache
import os

# Create path to the .env file
DOTENV = os.path.join(os.path.dirname(__file__), "../../.env")


# Use pydantic to read .env file
class Settings(BaseSettings):
    project_id: str
    service_account_key: str
    jwt_secret: str
    bucket_name: str

    model_config = SettingsConfigDict(env_file=DOTENV)


# Create function to return the Setting()
@lru_cache
def get_settings():
    return Settings()
