from fastapi import APIRouter, HTTPException, UploadFile, Depends, Request
from typing import Annotated
from logging import Logger
from pydantic import BaseModel
from google.cloud.storage import Bucket
from google.cloud.pubsub import PublisherClient
import json

from ..dependencies import validate_auth_token, get_storage_bucket, get_publisher_client
from ..services.prediction import PredictionsService
from ..logger.app_logger import get_app_logger
from ..config.config import Settings, get_settings

router = APIRouter(
    prefix="/prediction",
    tags=["prediction"],
    responses={404: {"description": "Not found"}},
    dependencies=[Depends(validate_auth_token)],
)


def get_logger():
    return get_app_logger(__name__)


@router.post("/auth")
async def check_auth(
    request: Request, logger: Annotated[Logger | None, Depends(get_logger)] = None
):
    body = await request.body()
    body_obj = json.loads(body)

    logger.info("You have successfully authenticate")
    logger.info(f"Request body: {str(body_obj)}")

    return body_obj


class PredictionDto(BaseModel):
    path: str | None = None
    topic: str | None = None
    index: int | None = None


def get_project_id(settings: Annotated[Settings, Depends(get_settings)]):
    return settings.project_id


@router.post("/predict")
async def predict(
    prediction_dto: PredictionDto,
    bucket: Annotated[Bucket, Depends(get_storage_bucket)],
    prediction_service: Annotated[PredictionsService, Depends(PredictionsService)],
    publisher_client: Annotated[PublisherClient, Depends(get_publisher_client)],
    project_id: Annotated[str, Depends(get_project_id)],
    logger: Annotated[Logger | None, Depends(get_logger)] = None,
):
    logger.info("You have successfully authenticate")
    blob = bucket.blob(prediction_dto.path)

    if not blob.exists():
        logger.warn("Image to predict not found")
        raise HTTPException(status_code=404, detail="Image to predict not found")

    blob_content = blob.download_as_string()

    prediction_result = await prediction_service.create_prediction(blob_content)

    topic_path = publisher_client.topic_path(project_id, prediction_dto.topic)
    prediction_result_dict = {
        "percentage": prediction_result,
        "index": prediction_dto.index,
    }
    prediction_result_string = json.dumps(prediction_result_dict)
    data = prediction_result_string.encode("utf-8")

    logger.info(f"Success to create prediction: {prediction_result_string}")

    try:
        future = publisher_client.publish(topic_path, data)
        message_id = future.result()

        logger.info(f"Publish message with ID {message_id} to {topic_path}")
        return {"message_id": message_id}
    except Exception as e:
        logger.warn("Unable to publish message")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/single")
async def create_single_prediction(
    predictionsService: Annotated[PredictionsService, Depends(PredictionsService)],
    file: UploadFile | None = None,
):
    if not file:
        return {"message": "No upload file sent"}

    prediction_result = await predictionsService.create_prediction(file)

    return prediction_result
