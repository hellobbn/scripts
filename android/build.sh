#!/bin/bash

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
# m clobber
# rm -rf out
lunch $build_target
# m installclean
# m bootimage
# m

