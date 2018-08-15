from enum import Enum

from keras.utils import plot_model

import deeplabv3_plus.model as deeplab


# This should match ALCVConfig shape
INPUT_SHAPE = (216, 384, 3)


def get_model(model_type, input_shape=INPUT_SHAPE):
    """
    Return ALCVModel

    Currenlty supports rendition of Unet and DeepLabv3+
    :param model_type: a ModelType
    :return: an ALCVModel
    """
    if (model_type is ModelType.DEEPLABV3_PLUS):
        return DeeplabV3_PlusModel(input_shape)
    else:
        raise ValueError('This model is not supported')


class ModelType(Enum):
    UNET = 0
    DEEPLABV3_PLUS = 1


class ALCVModel():
    """Wrapper for Keras models with additional functionality"""
    TEMP_INITIAL_WEIGHTS_PATH = "data-temp/temp_weights.h5"

    def __init__(self, model, model_type, is_bgr=False, preprocessor=None):
        self.model = model
        # model.save_weights(self.TEMP_INITIAL_WEIGHTS_PATH)
        self.model_type = model_type
        self.is_bgr = is_bgr
        self.preprocessor = preprocessor
        self.dual_input = False

    def load_weights(self, weights_path):
        self.model.load_weights(weights_path, by_name=True)
    #
    # def reset(self):
    #     self.load_weights(self.TEMP_INITIAL_WEIGHTS_PATH)


class DeeplabV3_PlusModel(ALCVModel):
    def __init__(self, input_shape):
        model = deeplab.Deeplabv3(weights=None, input_shape=input_shape, classes=2)
        model = add_end_layer(model)

        #model.summary()
        model_type = ModelType.DEEPLABV3_PLUS
        is_bgr = True
        super().__init__(model, model_type, is_bgr=is_bgr, preprocessor=None)


def add_end_layer(model):
    """
    Add 1x1 Conv2D filter at end with a sigmoid activation function for classification
    :param model: a Keras model
    :return: a modified Keras model
    """
    from keras.layers import Conv2D
    from keras.models import Model
    output = Conv2D(filters=1, kernel_size=(1,1), strides=(1,1), activation='sigmoid', name='conv_ls')(model.layers[-1].output)

    return Model(inputs=model.input, outputs=output)


if __name__ == '__main__':
    model = DeeplabV3_PlusModel()
    model = model.model
    plot_model(model, to_file='deeplabv3+.png', show_shapes=True, show_layer_names=True)