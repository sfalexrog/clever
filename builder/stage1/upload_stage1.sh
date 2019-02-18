#!/bin/bash



echo_stamp "Installing deployment prerequisites"
apt-get update
apt-get install -y --no-install-recommends python3-dev zip
wget https://bootstrap.pypa.io/get-pip.py
python3 ./get-pip.py
pip install pygithub

echo_stamp "Packing image file"
pushd ${IMAGES_DIR}
chmod a+rwx *
zip "${IMAGE_NAME}.zip" ${IMAGE_NAME}
popd
mv "${IMAGES_DIR}/${IMAGE_NAME}.zip" ./
echo_stamp "Packing done"

echo_stamp "Uploading the image as an asset"
${STAGE_DIR}/upload_stage1.py "clever-image-cache" ${IMGCACHE_FILENAME} "./${IMAGE_NAME}.zip"
