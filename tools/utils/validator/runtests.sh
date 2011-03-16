#!/bin/sh

export PYTHONPATH=`dirname $0`
export DICTIONARY=${PYTHONPATH}/../lietuviu

python tests/test_donelaitis.py
