#!/usr/bin/env python2.3

from distutils.core import setup

try:
    import py2exe
except:
    pass

setup(name="ispelllt",
      version="1.1",
      author="Albertas Agejevas",
      url="http://sraige.mif.vu.lt/cvs/ispell-lt/",
      scripts=["spell", "make"],
      )
