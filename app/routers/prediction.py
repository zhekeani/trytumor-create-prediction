from fastapi import APIRouter, HTTPException, UploadFile, Depends
from typing import Annotated
from ..dependencies import validate_auth_token

from ..services.prediction import PredictionsService

router = APIRouter(
    prefix="/prediction",
    tags=["prediction"],
    responses={404: {"description": "Not found"}},
    dependencies=[Depends(validate_auth_token)],
)


@router.post("/single")
async def create_single_prediction(
    predictionsService: Annotated[PredictionsService, Depends(PredictionsService)],
    file: UploadFile | None = None,
):
    if not file:
        return {"message": "No upload file sent"}

    prediction_result = await predictionsService.create_prediction(file)

    return prediction_result
