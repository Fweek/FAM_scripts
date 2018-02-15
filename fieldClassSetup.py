from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext
import numpy as np

ext_modules = [Extension("cyFieldClass", ["./fieldClass.pyx"])]

setup(
  name = 'cyFieldClass',
  cmdclass = {'build_ext': build_ext},
  include_dirs = [np.get_include()],         # <---- New line
  ext_modules = ext_modules
)
