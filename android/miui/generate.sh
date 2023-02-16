#!/bin/bash

# set -e

pushd /data/LineageOS/LineageOS_20/
source build.sh pdx203
m selinux_policy || exit
popd

sudo mount vendor.img mnt
sudo cp -r /data/LineageOS/LineageOS_20/out/target/product/pdx203/vendor/etc/selinux/* mnt/etc/selinux
sudo umount mnt || true
sudo img2simg vendor.img vendor_new.img

adb reboot fastboot
fastboot reboot fastboot
fastboot flash vendor vendor_new.img && fastboot reboot
