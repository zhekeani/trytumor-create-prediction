import keras
from PIL import Image
from io import BytesIO
import os


class PredictionsService:
    def __init__(self) -> None:
        model_path = os.path.join(os.path.dirname(__file__), "ml_model/model.h5")
        self.model = keras.models.load_model(model_path)

    def _preprocess_image(self, img):
        # img = Image.open(image)
        img = img.resize((self.model.input_shape[1], self.model.input_shape[2]))
        img = keras.preprocessing.image.img_to_array(img)
        img = img.reshape((1,) + img.shape)  # Reshape for batch prediction
        img = img / 255.0  # Normalize pixel values (might differ based on model)
        return img

    async def create_prediction(self, image):

        # Define a dictionary to map predicted class indices to class labels
        class_labels = {0: "glioma", 1: "meningioma", 2: "noTumor", 3: "pituitary"}

        class_dict = {
            "glioma": None,
            "meningioma": None,
            "noTumor": None,
            "pituitary": None,
        }

        # Read image file contents
        # contents = await image.read()

        # Convert contents to PIL image
        img = Image.open(BytesIO(image))

        image_to_predict = self._preprocess_image(img)

        prediction = self.model.predict(image_to_predict)

        # Depending on your model's output layer:
        if len(prediction[0]) > 1:  # Multi-class classification
            for i, class_prob in enumerate(prediction[0]):
                class_label = class_labels[i]
                prediction_percentage = round(class_prob * 100, 5)

                class_dict[class_label] = prediction_percentage

            return class_dict
        else:  # Regression or binary classification
            predicted_value = prediction[0][0]
            return {"predicted_value": predicted_value}
