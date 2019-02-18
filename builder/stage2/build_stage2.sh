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

export DEBIAN_FRONTEND=${DEBIAN_FRONTEND:='noninteractive'}
export LANG=${LANG:='C.UTF-8'}
export LC_ALL=${LC_ALL:='C.UTF-8'}

BUILDER_DIR="/builder"
REPO_DIR="${BUILDER_DIR}/repo"
SCRIPTS_DIR="${REPO_DIR}/builder"
STAGE_DIR="${SCRIPTS_DIR}/stage2"
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

STAGE1_VERSION="$(cd ${REPO_DIR}; git log --format=%h -1 builder/stage1)"
if [[ -z ${STAGE1_VERSION} ]]; then
  echo_stamp "Cannot determine stage version; did you commit your changes?"
fi

STAGE1_RELEASE="stage1_${STAGE1_VERSION}"
STAGE1_IMAGE_NAME="clever_${STAGE1_VERSION}_stage1.img"
# Fetch stage1 image

pushd ${IMAGES_DIR}
wget --progress=dot:giga "https://github.com/sfalexrog/clever-image-cache/releases/download/${STAGE1_RELEASE}/${STAGE1_IMAGE_NAME}.zip"
unzip -p ${STAGE1_IMAGE_NAME}.zip > ${IMAGE_NAME}
popd

# Make free space
${BUILDER_DIR}/image-resize.sh ${IMAGE_PATH} max '7G'

mount_image ${IMAGE_PATH} /mnt

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
cp "${STAGE_DIR}/assets/clever.service" "/mnt/lib/systemd/system/"
cp "${STAGE_DIR}/assets/roscore.env" "/mnt/lib/systemd/system/"
cp "${STAGE_DIR}/assets/roscore.service" "/mnt/lib/systemd/system/"
mkdir -p "/mnt/etc/ros/rosdep/" && cp "${STAGE_DIR}/assets/kinetic-rosdep-clever.yaml" "/mnt/etc/ros/rosdep/"
cp "${STAGE_DIR}/assets/clever.service" "/mnt/lib/systemd/system/"

run_in_chroot "/mnt" ${STAGE_DIR}'/image-ros.sh'

umount_image /mnt 

${BUILDER_DIR}/image-resize.sh ${IMAGE_PATH}
