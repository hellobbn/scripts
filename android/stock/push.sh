#!/bin/bash

files=(
"vendor/lib64/libgralloc.qti.so"
"vendor/lib64/libgralloccore.so"
"vendor/lib64/libgrallocutils.so"
)

adb wait-for-device && adb root && adb remount

for i in "${files[@]}"; do
    adb push "$i" /"$i"
done

adb reboot
