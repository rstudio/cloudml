import tensorflow.python.estimator.estimator
import tensorflow.python.feature_column.feature_column
import tensorflow.python.estimator.canned

from tensorflow.python.feature_column import feature_column_lib
from tensorflow.python.estimator.canned.linear import LinearRegressor

import numpy
import sys

import tensorflow as tf

sys.stderr.write("Using TensorFlow " + tf.__version__ + "\n")

mtcars_input_fn = tf.estimator.inputs.numpy_input_fn(
      x = {
        "disp": numpy.array([160,160,108,258,360,225,360,146.7,140.8,167.6,167.6,275.8,275.8,275.8,472,460,440,78.7,75.7,71.1,120.1,318,304,350,400,79,120.3,95.1,351,145,301,121]),
        "cyl": numpy.array([6,6,4,6,8,6,8,4,4,6,6,8,8,8,8,8,8,4,4,4,4,8,8,8,8,4,4,4,8,6,8,4])
      },
      y = numpy.array([21,21,22.8,21.4,18.7,18.1,14.3,24.4,22.8,19.2,17.8,16.4,17.3,15.2,10.4,10.4,14.7,32.4,30.4,33.9,21.5,15.5,15.2,13.3,19.2,27.3,26,30.4,15.8,19.7,15,21.4]),
      num_epochs = None,
      shuffle = True)

estimator = LinearRegressor(
    feature_columns=[
        feature_column_lib.numeric_column(
        key = "disp",
        shape = [1],
        dtype = tf.float32),
      feature_column_lib.numeric_column(
        key = "cyl",
        shape = [1],
        dtype = tf.float32)
    ])

sys.stderr.write("Train Start\n")
estimator.train(input_fn = mtcars_input_fn, steps = 2000)
sys.stderr.write("Train End\n")
