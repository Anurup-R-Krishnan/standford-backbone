"""
Created on Mar 4, 2012

@author: peymankazemian
"""

import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from utils.load_stanford_backbone import *

generate_stanford_backbne_one_layer_tf()
