#!/bin/bash

files=(
"vendor/bin/hw/vendor.qti.hardware.display.allocator-service"
"vendor/lib64/hw/android.hardware.graphics.mapper@3.0-impl-qti-display.so"
"vendor/lib64/hw/android.hardware.graphics.mapper@4.0-impl-qti-display.so"
"vendor/lib64/vendor.qti.hardware.display.mapperextensions@1.2.so"
"vendor/lib64/vendor.qti.hardware.display.mapperextensions@1.3.so"
"vendor/lib/hw/android.hardware.graphics.mapper@3.0-impl-qti-display.so"
"vendor/lib/hw/android.hardware.graphics.mapper@4.0-impl-qti-display.so"
"vendor/lib/vendor.qti.hardware.display.mapperextensions@1.2.so"
"vendor/lib/vendor.qti.hardware.display.mapperextensions@1.3.so"
"vendor/lib/libgralloccore.so"
"vendor/lib64/libgralloccore.so"
"vendor/lib/libgrallocutils.so"
"vendor/lib64/libgrallocutils.so"
"vendor/lib/libgralloc.qti.so"
"vendor/lib64/libgralloc.qti.so"
"vendor/lib64/libsdmcore.so"
"vendor/lib/libsdmcore.so"
)

adb wait-for-device && adb root && adb remount

for i in "${files[@]}"; do
    adb push "$i" /"$i"
done

adb reboot
