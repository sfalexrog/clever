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
STAGE_DIR="${SCRIPTS_DIR}/stage1"
IMAGES_DIR="${REPO_DIR}/images"

# Import commonly used functions
source ${SCRIPTS_DIR}/script_support/common_funcs

[[ ! -d ${SCRIPTS_DIR} ]] && (echo_stamp "Directory ${SCRIPTS_DIR} doesn't exist" "ERROR"; exit 1)
[[ ! -d ${IMAGES_DIR} ]] && mkdir ${IMAGES_DIR} && echo_stamp "Directory ${IMAGES_DIR} was created successful" "SUCCESS"

if [[ -z ${TRAVIS_TAG} ]]; then IMAGE_VERSION="$(cd ${REPO_DIR}; git log --format=%h -1)"; else IMAGE_VERSION="${TRAVIS_TAG}"; fi
IMAGE_VERSION="${TRAVIS_TAG:=$(cd ${REPO_DIR}; git log --format=%h -1)}"

STAGE_VERSION="$(cd ${REPO_DIR}; git log --format=%h -1 builder/stage1)"
if [[ -z ${STAGE_VERSION} ]]; then
  echo_stamp "Cannot determine stage version; did you commit your changes?"
fi

IMAGE_NAME="clever_${STAGE_VERSION}_stage1.img"
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

# Build stage caches
IMGCACHE_REPO="https://github.com/sfalexrog/clever-image-cache"
IMGCACHE_DIR="${BUILDER_DIR}/imgcache"

git clone ${IMGCACHE_REPO} ${IMGCACHE_DIR}

IMGCACHE_FILENAME="stage1_${STAGE_VERSION}"
if [[ -z $(find ${IMGCACHE_DIR} -name ${IMGCACHE_FILENAME} ) ]]; then
  echo_stamp "No cached build found for this stage"
  get_image ${IMAGE_PATH} ${SOURCE_IMAGE}

  # Make free space
  ${BUILDER_DIR}/image-resize.sh ${IMAGE_PATH} max '7G'

  mount_image ${IMAGE_PATH} /mnt

  # ${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/init_rpi.sh' '/root/'
  # ${BUILDER_DIR}/image-chroot.sh ${IMAGE_PATH} copy ${SCRIPTS_DIR}'/assets/hardware_setup.sh' '/root/'
  cp ${STAGE_DIR}/assets/init_rpi.sh /mnt/root/
  cp ${STAGE_DIR}/assets/hardware_setup.sh /mnt/root/
  run_in_chroot ${IMAGE_PATH} ${STAGE_DIR}'/image-init.sh' ${IMAGE_VERSION} ${SOURCE_IMAGE}

  # FIXME: use symlinks instead of copies.
  # Monkey
  cp "${STAGE_DIR}/assets/monkey" /mnt/root/
  # Butterfly
  cp "${STAGE_DIR}/assets/butterfly.service" /mnt/lib/systemd/system/
  cp "${STAGE_DIR}/assets/butterfly.socket" /mnt/lib/systemd/system/
  cp "${STAGE_DIR}/assets/monkey.service" /mnt/lib/systemd/system/
  # software install
  run_in_chroot ${IMAGE_PATH} ${STAGE_DIR}'/image-software.sh'
  # network setup
  run_in_chroot ${IMAGE_PATH} ${STAGE_DIR}'/image-network.sh'

  # Cleanup to save some space
  run_in_chroot ${IMAGE_PATH} "${STAGE_DIR}/image-cleanup.sh"

  # Save some more space by shrinking the image
  ${BUILDER_DIR}/image-resize.sh ${IMAGE_PATH}

  umount_image /mnt

  # Mark the image
  echo "Built from ${IMAGE_VERSION}" > "${IMGCACHE_DIR}/${IMGCACHE_FILENAME}"
  cd ${IMGCACHE_DIR}
  git config --local user.name "sfalexrog"
  git config --local user.email "sfalexrog@gmail.com"
  git add ${IMGCACHE_FILENAME}
  git commit -m "Added ${IMGCACHE_FILENAME}"
  # Tag the commit so that GitHub will create a release
  git tag ${IMGCACHE_FILENAME}
  git push "https://sfalexrog:${GITHUB_OAUTH_TOKEN}@github.com/sfalexrog/clever-image-cache" --all

  # Mark the image for deployment
  touch ${REPO_DIR}/should_deploy_image
else
  # Try downloading the file
  echo_stamp "Found build marker, downloading image"
  wget --progress=dot:giga -O "${IMAGES_DIR}/${IMAGE_NAME}.zip"  "${IMGCACHE_REPO}/releases/download/${IMGCACHE_FILENAME}/${IMAGE_NAME}.zip"
  unzip -p "${IMAGES_DIR}/${IMAGE_NAME}.zip" > "${IMAGES_DIR}/${IMAGE_NAME}"
  rm "${IMAGES_DIR}/${IMAGE_NAME}.zip"
  echo_stamp "My work here is done!"
fi
