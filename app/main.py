from fastapi import FastAPI
from .routers import prediction

app = FastAPI(title="FastAPI webhook", debug=True)


@app.get("/")
def read_root():
    return {"Hello": "World"}


app.include_router(prediction.router)
