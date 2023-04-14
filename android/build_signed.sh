#!/bin/bash

set -e

export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR=/data/.ccache

if [[ -z $1 ]]; then
  build_device=kebab
else
  build_device=$1
fi

echo "Building for $build_device"
build_target="lineage_${build_device}-userdebug"

# pushd ./device/sony/pdx203
# ./extract-files.sh /data/LineageOS/rootfs_58.2.A.7.93/rootfs
# popd

. build/envsetup.sh
lunch $build_target
mka target-files-package otatools
sign_target_files_apks -o -d ~/.android-certs $OUT/obj/PACKAGING/target_files_intermediates/*-target_files-*.zip signed-target_files.zip
ota_from_target_files -k ~/.android-certs/releasekey --block --backup=true signed-target_files.zip lineage-${build_device}_signed.zip
sha256sum lineage-${build_device}_signed.zip > lineage-pdx215_signed.zip.sha256sum
avbtool extract_public_key --key ~/.android-certs/releasekey.key --output ./pkmd.bin

