#!/bin/bash

mkdir -p ./package
pip3 install -r requirements.txt -t ./package/

cp code.py ./package/

cp requirements.txt ./package/
