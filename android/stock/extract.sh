#!/bin/bash

set -x
set -e

function print_help {
    echo "Usage: $1 firmware_dir"
}

if [[ $# -ne 1 ]]; then
    print_help $0
fi


FIRMWARE_DIR=$1

pushd "$FIRMWARE_DIR" || exit

rm -rf rootfs
rm -rf extracted
rm -rf super
sudo umount mnt || true
rm -rf mnt
rm -rf super_*.img
rm -rf oem_*.img

# Extract super
set +e
read -r -d '\n' -a super_sins < <(find . -name "super_X*.sin")
set -e
if [[ ${#super_sins[@]} -ne 1 ]]; then
    echo "WARN: found multiple super imgs: "
    echo "${super_sins[@]}"
    echo "Choose: ${super_sins[0]}"
fi
super_sin=${super_sins[0]}
super_img="${super_sin//.sin/.img}"

unsin "$super_sin"
mv "$super_img" super_unsined.img

set +e
read -r -d '\n' -a partitions < <(imjtool super_unsined.img 2>&1 | grep "Name" | cut -d ' ' -f 2 | grep "_a" | sed -e 's/_a//')
set -e

imjtool super_unsined.img extract
pushd extracted || exit
rm -rf ./*_b.img
rename _a "" ./*
popd || exit

mkdir mnt
mkdir rootfs
for i in "${partitions[@]}"; do
    sudo mount -o ro extracted/"$i".img mnt
    mkdir -p rootfs/"$i"
    sudo cp -ra mnt/* rootfs/"$i"
    sudo chown -R bbn:bbn rootfs/"$i"
    sync
    sudo umount mnt
done


mkdir super
img2simg super_unsined.img super.img
mv super.img super
rm -rf super_unsined.img

# Handle oem
set +e
read -r -d '\n' -a oem_sins < <(find . -name "oem_X*.sin")
set -e
if [[ ${#oem_sins[@]} -ne 1 ]]; then
    echo "WARN: found multiple OEM imgs: "
    echo "${oem_sins[@]}"
    echo "Choose: ${oem_sins[0]}"
fi
oem_sin=${oem_sins[0]}
oem_img="${oem_sin//.sin/.ext4}"

unsin "$oem_sin"
mv "$oem_img" oem.img
mkdir rootfs/oem
sudo mount -o ro oem.img mnt
sudo cp -ra mnt/* rootfs/oem
sync
sudo umount mnt

sudo rm -rf oem_*.img
sudo rm -rf mnt

