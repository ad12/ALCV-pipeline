import os

import numpy as np
import argparse
import imageio
import warnings
import cv2 as cv


import keras.backend as K
from models import ModelType, get_model
from deeplabv3_plus.model import preprocess_input


MASK_DIRECTORY = 'mask-pred'
MASK_VIS_DIRECTORY = 'mask-pred-visual'
LENS_DIRECTORY = 'lens'
PNG_EXT = '.png'
H5_EXT = '.h5'

DEFAULT_INPUT_SHAPE = (216, 384, 3)
DEFAULT_BATCH_SIZE = 50

MASK_KEYWORD = 'mask'
LENS_KEYWORD = 'lens'

reusable_model = None
reuse_model = False

BATCH_SIZE = DEFAULT_BATCH_SIZE

def load_input_images(subject_dir, resize=False):
    if not os.path.isdir(subject_dir):
        raise NotADirectoryError('%s not a valid directory' % subject_dir)

    # Load all files with a png extension
    subfiles = os.listdir(subject_dir)
    ims = []
    formatted_file_names = []
    im_count = 0
    for file_name in subfiles:
        filepath = os.path.join(subject_dir, file_name)
        if os.path.isfile(filepath) and filepath.endswith(PNG_EXT):

            im = imageio.imread(os.path.join(subject_dir, file_name))
            if resize:
                im = cv.resize(im, (DEFAULT_INPUT_SHAPE[1], DEFAULT_INPUT_SHAPE[0]))

            ims.append(im)
            formatted_file_names.append(file_name.replace(PNG_EXT, '_%s' + PNG_EXT))

            im_count += 1

            # im = imageio.imread(filepath)
            #
            # im = im[np.newaxis, ...]
            # if len(im.shape) == 3:
            #     im = im[..., np.newaxis]

    if len(ims) == 0:
        raise FileNotFoundError('No png files found in %s' % subject_dir)

    ims = np.stack(ims, axis=0)
    assert ims.shape[0] == im_count, '%d ims but %d files' %(ims.shape[0], im_count)
    assert(len(ims.shape) == 4)

    return ims, formatted_file_names


def ensemble_learning(ims, model, weight_dir):
    if not os.path.isdir(weight_dir):
        raise NotADirectoryError('%s not a valid directory. Multiple weights must be in directory' % weight_dir)

    assert(len(ims.shape) == 4)

    mask_shape = (ims.shape[:3]) + (1,)
    masks = np.zeros(mask_shape)

    model_count = 0
    # Run inference
    for filename in os.listdir(weight_dir):
        filepath = os.path.join(weight_dir, filename)
        if os.path.isfile(filepath) and filepath.endswith(H5_EXT):
            # Load weigths
            model.load_weights(filepath, by_name=True)

            # run inference
            model_mask = model.predict(ims, batch_size=BATCH_SIZE)

            masks += model_mask

            model_count += 1

    if (model_count == 0):
        raise FileNotFoundError('No weight files found in %s', weight_dir)

    masks = (masks > 0.5*model_count).astype(np.uint8)
    assert(np.unique(masks) == np.asarray([0, 1])).all()
    assert(masks.shape[:3] == ims.shape[:3])

    K.clear_session()

    return masks


def basic_mask(ims, model, weight_file):
    if not os.path.isfile(weight_file):
        raise FileNotFoundError('%s not a valid weight filepath' % weight_file)

    model.load_weights(weight_file, by_name=True)

    masks = model.predict(ims, batch_size=BATCH_SIZE)

    masks = (masks > 0.5).astype(np.uint8)
    assert (np.unique(masks) == np.asarray([0, 1])).all()
    assert (masks.shape[:3] == ims.shape[:3])

    K.clear_session()

    return masks


def generate_mask(subject_dir, weight_dir_or_file, ensemble=False, resize=False):
    print('Processing %s' % subject_dir)
    if not os.path.isdir(subject_dir):
        raise NotADirectoryError('%s not a valid directory' % subject_dir)

    ims_orig, formatted_file_names = load_input_images(subject_dir, resize=resize)

    ims = preprocess_input(ims_orig.astype(np.float32))
    input_shape = (ims.shape[1], ims.shape[2], ims.shape[3])
    if (input_shape != DEFAULT_INPUT_SHAPE):
        warnings.warn('Original model was trained using images of size (%d, %d, %d). '
                      'Inference on shape (%d, %d, %d) is not tested)' %(DEFAULT_INPUT_SHAPE[0],
                                                                         DEFAULT_INPUT_SHAPE[1],
                                                                         DEFAULT_INPUT_SHAPE[2],
                                                                         input_shape[0],
                                                                         input_shape[1],
                                                                         input_shape[2]))

    model = get_model(ModelType.DEEPLABV3_PLUS, input_shape=input_shape)
    model = model.model

    if ensemble:
        masks = ensemble_learning(ims, model, weight_dir_or_file)
    else:
        masks = basic_mask(ims, model, weight_dir_or_file)

    mask_filenames = [x % MASK_KEYWORD for x in formatted_file_names]

    # save masks
    mask_dir = os.path.join(subject_dir, MASK_DIRECTORY)
    mask_vis_dir = os.path.join(subject_dir, MASK_VIS_DIRECTORY)
    if not os.path.isdir(mask_dir):
        os.makedirs(mask_dir)

    if not os.path.isdir(mask_vis_dir):
        os.makedirs(mask_vis_dir)

    for i in range(ims.shape[0]):
        im = np.squeeze(ims_orig[i, ...])
        mask = np.squeeze(masks[i, ...])
        mask_filepath = os.path.join(mask_dir, mask_filenames[i])
        mask_vis_filepath = os.path.join(mask_vis_dir, mask_filenames[i])
        # Save mask
        imageio.imwrite(mask_filepath, mask)

        # save visible masks
        # previous masks were stored as 0,1, which is hard to visually distinguish
        # scale to 0,255
        imageio.imwrite(mask_vis_filepath, mask * 255)

def list_subject_dirs(supra_folder):
    files = os.listdir(supra_folder)
    subject_dirs = []

    for file in files:
        subject_folder = os.path.join(supra_folder, file)
        if not os.path.isdir(subject_folder):
            continue
        subject_dirs.append(subject_folder)

    print('=='*20)
    print('%d subjects found:' % (len(subject_dirs)))
    for file in subject_dirs:
        print(file)
    print('=='*20)

    return subject_dirs


def parse_args():
    """Parse arguments given through command line (argv)
        :raises ValueError if dicom path is not provided
        :raise NotADirectoryError if dicom path does not exist or is not a directory
        """
    parser = argparse.ArgumentParser(description='Segment anterior lens regions in frames')
    parser.add_argument('-d', '--dir', metavar='D', required=True, type=str, nargs=1,
                        help='Either 1. Path to subject directory storing frames. or 2. Path to directory of subject directories')

    parser.add_argument('-w', '--weight', required=True, metavar='W', type=str, nargs=1,
                        help='path to weight(s). If path is a directory, use ensemble learning. Else path must be an h5 file')
    parser.add_argument('-r', action='store_const', const=True, default=False, help='Resize images to default shape for segmentation. If input '
                                                                         'images are not of shape (216, 384, 3), then '
                                                                         'model may not perform optimally')
    parser.add_argument('-b',  '--batch', action='store_const', const=True, default=False, help='Batch process all subdirectories in D. '
                                                                         'Assumes all subdirectories in D are of subjects')
    parser.add_argument('--mini_batch_size', metavar='BS', type=int, nargs=1, default=DEFAULT_BATCH_SIZE, help='Mini batch size. Default is %d' % (DEFAULT_BATCH_SIZE))

    args = parser.parse_args()

    try:
        dir_path = args.dir[0]
    except Exception:
        raise ValueError("Path to directory is required")

    try:
        weight_path = args.weight[0]
    except Exception:
        raise ValueError("No path to weight directory/file provided")

    if not os.path.isdir(dir_path):
        raise NotADirectoryError("Directory \'%s\' does not exist" % dir_path)

    global BATCH_SIZE
    BATCH_SIZE = args.mini_batch_size
    if (args.batch):
        subject_dirs = list_subject_dirs(dir_path)
        for subject_path in subject_dirs:
            generate_mask(subject_path, weight_path, ensemble=os.path.isdir(weight_path), resize=args.r)
    else:
        subject_path = dir_path
        generate_mask(subject_path, weight_path, ensemble=os.path.isdir(weight_path), resize=args.r)


if __name__ == '__main__':
    os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'

    parse_args()