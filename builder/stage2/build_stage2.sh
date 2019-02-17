#! /usr/bin/env bash

#
# Script for build the image. Used builder script of the target repo
# For build: docker run --privileged -it --rm -v /dev:/dev -v $(pwd):/builder/repo smirart/builder
#
# Copyright (C) 2018 Copter Express Technologies
#
# Author: Artem Smirnov <urpylka@gmail.com>
#

set -e # Exit immidiately on non-zero result
set -v # Echo commands to the terminal

SOURCE_IMAGE="https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2018-06-29/2018-06-27-raspbian-stretch-lite.zip"

export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:='noninteractive'}
export LANG=${LANG:='C.UTF-8'}
export LC_ALL=${LC_ALL:='C.UTF-8'}

BUILDER_DIR="/builder"
REPO_DIR="${BUILDER_DIR}/repo"
SCRIPTS_DIR="${REPO_DIR}/builder"
IMAGES_DIR="${REPO_DIR}/images"

# Import commonly used functions
source ${SCRIPTS_DIR}/script_support/common_funcs

[[ ! -d ${SCRIPTS_DIR} ]] && (echo_stamp "Directory ${SCRIPTS_DIR} doesn't exist" "ERROR"; exit 1)
[[ ! -d ${IMAGES_DIR} ]] && mkdir ${IMAGES_DIR} && echo_stamp "Directory ${IMAGES_DIR} was created successful" "SUCCESS"

if [[ -z ${TRAVIS_TAG} ]]; then IMAGE_VERSION="$(cd ${REPO_DIR}; git log --format=%h -1)"; else IMAGE_VERSION="${TRAVIS_TAG}"; fi
# IMAGE_VERSION="${TRAVIS_TAG:=$(cd ${REPO_DIR}; git log --format=%h -1)}"
REPO_URL="$(cd ${REPO_DIR}; git remote --verbose | grep origin | grep fetch | cut -f2 | cut -d' ' -f1 | sed 's/git@github\.com\:/https\:\/\/github.com\//')"
REPO_NAME="$(basename -s '.git' ${REPO_URL})"
IMAGE_NAME="${REPO_NAME}_${IMAGE_VERSION}.img"
IMAGE_PATH="${IMAGES_DIR}/${IMAGE_NAME}"

get_image() {
  # TEMPLATE: get_image <IMAGE_PATH> <RPI_DONWLOAD_URL>
  local BUILD_DIR=$(dirname $1)
  local RPI_ZIP_NAME=$(basename $2)
  local RPI_IMAGE_NAME=$(echo ${RPI_ZIP_NAME} | sed 's/zip/img/')

  if [ ! -e "${BUILD_DIR}/${RPI_ZIP_NAME}" ]; then
    echo_stamp "Downloading original Linux distribution"
    wget --progress=dot:giga -O ${BUILD_DIR}/${RPI_ZIP_NAME} $2
    echo_stamp "Downloading complete" "SUCCESS" \
  else echo_stamp "Linux distribution already donwloaded"; fi

  echo_stamp "Unzipping Linux distribution image" \
  && unzip -p ${BUILD_DIR}/${RPI_ZIP_NAME} ${RPI_IMAGE_NAME} > $1 \
  && echo_stamp "Unzipping complete" "SUCCESS" \
  || (echo_stamp "Unzipping was failed!" "ERROR"; exit 1)
}

get_image ${IMAGE_PATH} ${SOURCE_IMAGE}

# Make free space
${BUILDER_DIR}/image-resize.sh ${IMAGE_PATH} max '7G'

mount_image ${IMAGE_PATH} /mnt

# ${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/init_rpi.sh' '/root/'
# ${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/hardware_setup.sh' '/root/'
run_in_chroot ${IMAGE_PATH} ${SCRIPTS_DIR}'/image-init.sh' ${IMAGE_VERSION} ${SOURCE_IMAGE}

# FIXME: use symlinks instead of copies.
# Monkey
cp "${SCRIPTS_DIR}/assets/monkey" /mnt/root/
# Butterfly
cp "${SCRIPTS_DIR}/assets/butterfly.service" /mnt/lib/systemd/system/
cp "${SCRIPTS_DIR}/assets/butterfly.socket" /mnt/lib/systemd/system/
cp "${SCRIPTS_DIR}/assets/monkey.service" /mnt/lib/systemd/system/
# software install
run_in_chroot ${IMAGE_PATH} ${SCRIPTS_DIR}'/image-software.sh'
# network setup
run_in_chroot ${IMAGE_PATH} ${SCRIPTS_DIR}'/image-network.sh'

# If RPi then use a one thread to build a ROS package on RPi, else use all
# [[ $(arch) == 'armv7l' ]] && NUMBER_THREADS=1 || NUMBER_THREADS=$(nproc --all)
# Clever
# Copy cloned repository to the image
# Include dotfiles in globs (asterisks)
mkdir -p /mnt/home/pi/catkin_ws/src/clever/
shopt -s dotglob
for dir in ${REPO_DIR}/*; do
  # Don't try to copy image into itself
  if [[ $dir != *"images" ]]; then
    cp -r $dir /mnt/home/pi/catkin_ws/src/clever/
  fi;
done

# FIXME: use symlinks instead of copies (relative paths?)
cp "${SCRIPTS_DIR}/assets/clever.service" "/mnt/lib/systemd/system/"
cp "${SCRIPTS_DIR}/assets/roscore.env" "/mnt/lib/systemd/system/"
cp "${SCRIPTS_DIR}/assets/roscore.service" "/mnt/lib/systemd/system/"
mkdir -p "/mnt/etc/ros/rosdep/" && cp "${SCRIPTS_DIR}/assets/kinetic-rosdep-clever.yaml" "/mnt/etc/ros/rosdep/"
cp "${SCRIPTS_DIR}/assets/clever.service" "/mnt/lib/systemd/system/"

run_in_chroot ${IMAGE_PATH} ${SCRIPTS_DIR}'/image-ros.sh'

umount_image /mnt 

${BUILDER_DIR}/image-resize.sh ${IMAGE_PATH}
