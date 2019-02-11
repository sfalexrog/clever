#!/usr/bin/env bash

#
# Validate built image using tests
#
# Copyright (C) 2018 Copter Express Technologies
#
# Author: Oleg Kalachev <okalachev@gmail.com>
#

set -ex

# FIXME: use a better way to get ROS environment
. /opt/ros/kinetic/setup.bash
. /home/pi/catkin_ws/devel/setup.bash

cd /home/pi/catkin_ws/src/clever/builder/test/
./tests.sh
./tests.py
