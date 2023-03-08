#!/bin/bash
set -e

rm -rf $1_unsigned.apk $1_unsigned_aligned.apk $1_unsigned.apk
apktool b $1 -o $1_unsigned.apk
zipalign -p 4 $1_unsigned.apk $1_unsigned_aligned.apk
apksigner sign --ks ~/.android_app_keys/key.jks $1_unsigned_aligned.apk
mv $1_unsigned_aligned.apk $1_signed_aligned.apk
adb install $1_signed_aligned.apk
