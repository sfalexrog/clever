#!/bin/bash

SOURCE_IMAGE="https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-04-09/2019-04-08-raspbian-stretch-lite.zip"

if [[ -z ${TRAVIS_TAG} ]]; then IMAGE_VERSION="$(cd ${REPO_DIR}; git log --format=%h -1)"; else IMAGE_VERSION="${TRAVIS_TAG}"; fi
REPO_NAME="clever"
IMAGE_NAME="${REPO_NAME}_${IMAGE_VERSION}.img"
IMAGE_PATH="/images/${IMAGE_NAME}"

get_image() {
  # TEMPLATE: get_image <IMAGE_PATH> <RPI_DONWLOAD_URL>
  local BUILD_DIR=$(dirname $1)
  local RPI_ZIP_NAME=$(basename $2)
  local RPI_IMAGE_NAME=$(echo ${RPI_ZIP_NAME} | sed 's/zip/img/')

  if [ ! -e "${BUILD_DIR}/${RPI_ZIP_NAME}" ]; then
    echo "Downloading original Linux distribution"
    wget --progress=dot:giga -O ${BUILD_DIR}/${RPI_ZIP_NAME} $2
    echo "Downloading complete" \
  else echo "Linux distribution already donwloaded"; fi

  echo "Unzipping Linux distribution image" \
  && unzip -p ${BUILD_DIR}/${RPI_ZIP_NAME} ${RPI_IMAGE_NAME} > $1 \
  && echo "Unzipping complete" \
  || (echo "Unzipping failed!"; exit 1)
}

get_image ${IMAGE_PATH} ${SOURCE_IMAGE}

echo "Truncating image"
truncate -s7G ${IMAGE_PATH}
echo "Resizing filesystem"
DEV_IMAGE=$(losetup -Pf ${IMAGE_PATH} --show)
echo "Waiting for partition table to settle"
sleep 0.5
echo "Resizing partition"
echo ", +" | sfdisk -N 2 ${DEV_IMAGE}
echo "Waiting for partition table to settle"
sleep 0.5
echo "Unmounting loop device"
losetup -d ${DEV_IMAGE}
echo "Waiting for partition table to settle"
sleep 0.5
echo "Remounting filesystem"
DEV_IMAGE=$(losetup -Pf ${IMAGE_PATH} --show)
echo "Waiting for partition table to settle"
sleep 0.5
echo "Check and repair filesystem"
e2fsck -fvy "${DEV_IMAGE}p2"
echo "Expand filesystem"
resize2f2 "${DEV_IMAGE}p2"
echo "Unmounting loop device (again)"
losetup -d ${DEV_IMAGE}
