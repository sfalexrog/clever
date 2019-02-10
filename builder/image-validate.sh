#!/usr/bin/env bash

#
# Validate built image using tests
#
# Copyright (C) 2018 Copter Express Technologies
#
# Author: Oleg Kalachev <okalachev@gmail.com>
#

set -ex

cd /home/pi/catkin_ws/src/clever/builder/test/
./tests.sh
./tests.py
