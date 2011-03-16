#!/usr/bin/env python
"""
Priemonës kreiptis á ispell þodynà.

$Id: ispell.py,v 1.1 2003/06/11 10:06:48 alga Exp $
"""
import os

def splitEntry(line):
    line = line.strip()
    index = line.find("#")
    if index >= 0:
        line = line[:index]
        line = line.strip()
    index = line.find("/")
    if index >= 0:
        word = line[:index]
        flags = line[index+1:]
        return word, flags
    return line, ""

def expand(line):
    """Gràþina surûðiuotà sàraðà þodþiø, á kuriuos iðsiskleidþia eilutë"""

    input, output = os.popen2("ispell -e")
    #import pdb; pdb.set_trace()
    input.write(line)
    input.flush()
    input.close()
    words = output.read()
    output.close()
    words = words.split()
    words.sort()
    return words
