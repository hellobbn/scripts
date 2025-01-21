#!/bin/bash

export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
if [[ -z $CCACHE_DIR ]]; then
  export CCACHE_DIR=/data/.ccache
fi

echo "CCACHE DIR is $CCACHE_DIR"

if [[ -z $1 ]]; then
  build_device=kebab
else
  build_device=$1
fi

if [[ -z $2 ]]; then
  build_type=userdebug
else
  build_type=$2
fi

echo "Building for $build_device"

# pushd ./device/sony/pdx203
# ./extract-files.sh /data/LineageOS/rootfs_58.2.A.7.93/rootfs
# popd

. build/envsetup.sh
source vendor/lineage/vars/aosp_target_release
# m clobber
# rm -rf out
lunch lineage_${build_device}-${aosp_target_release}-${build_type}
# lunch "$build_target"
# m installclean
# m bootimage
# m

