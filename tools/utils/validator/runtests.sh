#!/bin/sh

export PYTHONPATH=`dirname $0`
export DICTIONARY=${PYTHONPATH}/../lietuviu

python3 tests/test_donelaitis.py
