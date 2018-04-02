import keras.models
from keras.applications import Xception
from keras.preprocessing.image import img_to_array
from keras.preprocessing.image import load_img
from keras.applications.inception_v3 import preprocess_input





image = load_img(args["image"], target_size=inputShape)
image = img_to_array(image)
