#!/bin/bash

set -e

export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache

if [[ -z $CCACHE_DIR ]]; then
    export CCACHE_DIR=/data/.ccache
fi

if [[ -z $ANDROID_CERT_DIR ]]; then
    export ANDROID_CERT_DIR=~/.android-certs
fi

echo "CCACHE_DIR=$CCACHE_DIR"

while [[ $# -gt 0 ]]; do
        case $1 in
        -d | --delta)
                BUILD_DELTA=1
                shift
                ;;
        -t | --type)
                BUILD_TYPE=$2
                shift
                shift
                ;;
        *)
                if [[ -n $_DEVICE ]]; then
                    echo "Unknown argument $1"
                    exit 1
                fi

                _DEVICE="$1"
                shift
                ;;
        esac
done

SCRIPT_DIR=$(dirname $(readlink -f $0))
source ${SCRIPT_DIR}/build.sh $_DEVICE $BUILD_TYPE

export EDITOR=vim
export ANDROID_PW_FILE=`pwd`/android_pw_file.txt

# Check if we want to build delta by argument "-d"
if [[ $BUILD_DELTA -eq 1 ]]; then
    if [[ ! -f ${build_device}-signed-target_files_old.zip ]]; then
        echo "No previous target files found, building full package"
        BUILD_DELTA=0
    fi
fi

m installclean

mka target-files-package otatools

croot
sign_target_files_apks -o -d "$ANDROID_CERT_DIR" \
    --extra_apks com.android.adbd.apex="$ANDROID_CERT_DIR"/com.android.adbd \
    --extra_apks com.android.adservices.apex="$ANDROID_CERT_DIR"/com.android.adservices \
    --extra_apks com.android.adservices.api.apex="$ANDROID_CERT_DIR"/com.android.adservices.api \
    --extra_apks com.android.appsearch.apex="$ANDROID_CERT_DIR"/com.android.appsearch \
    --extra_apks com.android.art.apex="$ANDROID_CERT_DIR"/com.android.art \
    --extra_apks com.android.bluetooth.apex="$ANDROID_CERT_DIR"/com.android.bluetooth \
    --extra_apks com.android.btservices.apex="$ANDROID_CERT_DIR"/com.android.btservices \
    --extra_apks com.android.cellbroadcast.apex="$ANDROID_CERT_DIR"/com.android.cellbroadcast \
    --extra_apks com.android.compos.apex="$ANDROID_CERT_DIR"/com.android.compos \
    --extra_apks com.android.configinfrastructure.apex="$ANDROID_CERT_DIR"/com.android.configinfrastructure \
    --extra_apks com.android.connectivity.resources.apex="$ANDROID_CERT_DIR"/com.android.connectivity.resources \
    --extra_apks com.android.conscrypt.apex="$ANDROID_CERT_DIR"/com.android.conscrypt \
    --extra_apks com.android.devicelock.apex="$ANDROID_CERT_DIR"/com.android.devicelock \
    --extra_apks com.android.extservices.apex="$ANDROID_CERT_DIR"/com.android.extservices \
    --extra_apks com.android.graphics.pdf.apex="$ANDROID_CERT_DIR"/com.android.graphics.pdf \
    --extra_apks com.android.hardware.biometrics.face.virtual.apex="$ANDROID_CERT_DIR"/com.android.hardware.biometrics.face.virtual \
    --extra_apks com.android.hardware.biometrics.fingerprint.virtual.apex="$ANDROID_CERT_DIR"/com.android.hardware.biometrics.fingerprint.virtual \
    --extra_apks com.android.hardware.cas.apex="$ANDROID_CERT_DIR"/com.android.hardware.cas \
    --extra_apks com.android.hardware.wifi.apex="$ANDROID_CERT_DIR"/com.android.hardware.wifi \
    --extra_apks com.android.healthfitness.apex="$ANDROID_CERT_DIR"/com.android.healthfitness \
    --extra_apks com.android.hotspot2.osulogin.apex="$ANDROID_CERT_DIR"/com.android.hotspot2.osulogin \
    --extra_apks com.android.i18n.apex="$ANDROID_CERT_DIR"/com.android.i18n \
    --extra_apks com.android.ipsec.apex="$ANDROID_CERT_DIR"/com.android.ipsec \
    --extra_apks com.android.media.apex="$ANDROID_CERT_DIR"/com.android.media \
    --extra_apks com.android.media.swcodec.apex="$ANDROID_CERT_DIR"/com.android.media.swcodec \
    --extra_apks com.android.mediaprovider.apex="$ANDROID_CERT_DIR"/com.android.mediaprovider \
    --extra_apks com.android.nearby.halfsheet.apex="$ANDROID_CERT_DIR"/com.android.nearby.halfsheet \
    --extra_apks com.android.networkstack.tethering.apex="$ANDROID_CERT_DIR"/com.android.networkstack.tethering \
    --extra_apks com.android.neuralnetworks.apex="$ANDROID_CERT_DIR"/com.android.neuralnetworks \
    --extra_apks com.android.ondevicepersonalization.apex="$ANDROID_CERT_DIR"/com.android.ondevicepersonalization \
    --extra_apks com.android.os.statsd.apex="$ANDROID_CERT_DIR"/com.android.os.statsd \
    --extra_apks com.android.permission.apex="$ANDROID_CERT_DIR"/com.android.permission \
    --extra_apks com.android.resolv.apex="$ANDROID_CERT_DIR"/com.android.resolv \
    --extra_apks com.android.rkpd.apex="$ANDROID_CERT_DIR"/com.android.rkpd \
    --extra_apks com.android.runtime.apex="$ANDROID_CERT_DIR"/com.android.runtime \
    --extra_apks com.android.safetycenter.resources.apex="$ANDROID_CERT_DIR"/com.android.safetycenter.resources \
    --extra_apks com.android.scheduling.apex="$ANDROID_CERT_DIR"/com.android.scheduling \
    --extra_apks com.android.sdkext.apex="$ANDROID_CERT_DIR"/com.android.sdkext \
    --extra_apks com.android.support.apexer.apex="$ANDROID_CERT_DIR"/com.android.support.apexer \
    --extra_apks com.android.telephony.apex="$ANDROID_CERT_DIR"/com.android.telephony \
    --extra_apks com.android.telephonymodules.apex="$ANDROID_CERT_DIR"/com.android.telephonymodules \
    --extra_apks com.android.tethering.apex="$ANDROID_CERT_DIR"/com.android.tethering \
    --extra_apks com.android.tzdata.apex="$ANDROID_CERT_DIR"/com.android.tzdata \
    --extra_apks com.android.uwb.apex="$ANDROID_CERT_DIR"/com.android.uwb \
    --extra_apks com.android.uwb.resources.apex="$ANDROID_CERT_DIR"/com.android.uwb.resources \
    --extra_apks com.android.virt.apex="$ANDROID_CERT_DIR"/com.android.virt \
    --extra_apks com.android.vndk.current.apex="$ANDROID_CERT_DIR"/com.android.vndk.current \
    --extra_apks com.android.vndk.current.on_vendor.apex="$ANDROID_CERT_DIR"/com.android.vndk.current.on_vendor \
    --extra_apks com.android.wifi.apex="$ANDROID_CERT_DIR"/com.android.wifi \
    --extra_apks com.android.wifi.dialog.apex="$ANDROID_CERT_DIR"/com.android.wifi.dialog \
    --extra_apks com.android.wifi.resources.apex="$ANDROID_CERT_DIR"/com.android.wifi.resources \
    --extra_apks com.google.pixel.camera.hal.apex="$ANDROID_CERT_DIR"/com.google.pixel.camera.hal \
    --extra_apks com.google.pixel.vibrator.hal.apex="$ANDROID_CERT_DIR"/com.google.pixel.vibrator.hal \
    --extra_apks com.qorvo.uwb.apex="$ANDROID_CERT_DIR"/com.qorvo.uwb \
    --extra_apex_payload_key com.android.adbd.apex="$ANDROID_CERT_DIR"/com.android.adbd.pem \
    --extra_apex_payload_key com.android.adservices.apex="$ANDROID_CERT_DIR"/com.android.adservices.pem \
    --extra_apex_payload_key com.android.adservices.api.apex="$ANDROID_CERT_DIR"/com.android.adservices.api.pem \
    --extra_apex_payload_key com.android.appsearch.apex="$ANDROID_CERT_DIR"/com.android.appsearch.pem \
    --extra_apex_payload_key com.android.art.apex="$ANDROID_CERT_DIR"/com.android.art.pem \
    --extra_apex_payload_key com.android.bluetooth.apex="$ANDROID_CERT_DIR"/com.android.bluetooth.pem \
    --extra_apex_payload_key com.android.btservices.apex="$ANDROID_CERT_DIR"/com.android.btservices.pem \
    --extra_apex_payload_key com.android.cellbroadcast.apex="$ANDROID_CERT_DIR"/com.android.cellbroadcast.pem \
    --extra_apex_payload_key com.android.compos.apex="$ANDROID_CERT_DIR"/com.android.compos.pem \
    --extra_apex_payload_key com.android.configinfrastructure.apex="$ANDROID_CERT_DIR"/com.android.configinfrastructure.pem \
    --extra_apex_payload_key com.android.connectivity.resources.apex="$ANDROID_CERT_DIR"/com.android.connectivity.resources.pem \
    --extra_apex_payload_key com.android.conscrypt.apex="$ANDROID_CERT_DIR"/com.android.conscrypt.pem \
    --extra_apex_payload_key com.android.devicelock.apex="$ANDROID_CERT_DIR"/com.android.devicelock.pem \
    --extra_apex_payload_key com.android.extservices.apex="$ANDROID_CERT_DIR"/com.android.extservices.pem \
    --extra_apex_payload_key com.android.graphics.pdf.apex="$ANDROID_CERT_DIR"/com.android.graphics.pdf.pem \
    --extra_apex_payload_key com.android.hardware.biometrics.face.virtual.apex="$ANDROID_CERT_DIR"/com.android.hardware.biometrics.face.virtual.pem \
    --extra_apex_payload_key com.android.hardware.biometrics.fingerprint.virtual.apex="$ANDROID_CERT_DIR"/com.android.hardware.biometrics.fingerprint.virtual.pem \
    --extra_apex_payload_key com.android.hardware.cas.apex="$ANDROID_CERT_DIR"/com.android.hardware.cas.pem \
    --extra_apex_payload_key com.android.hardware.wifi.apex="$ANDROID_CERT_DIR"/com.android.hardware.wifi.pem \
    --extra_apex_payload_key com.android.healthfitness.apex="$ANDROID_CERT_DIR"/com.android.healthfitness.pem \
    --extra_apex_payload_key com.android.hotspot2.osulogin.apex="$ANDROID_CERT_DIR"/com.android.hotspot2.osulogin.pem \
    --extra_apex_payload_key com.android.i18n.apex="$ANDROID_CERT_DIR"/com.android.i18n.pem \
    --extra_apex_payload_key com.android.ipsec.apex="$ANDROID_CERT_DIR"/com.android.ipsec.pem \
    --extra_apex_payload_key com.android.media.apex="$ANDROID_CERT_DIR"/com.android.media.pem \
    --extra_apex_payload_key com.android.media.swcodec.apex="$ANDROID_CERT_DIR"/com.android.media.swcodec.pem \
    --extra_apex_payload_key com.android.mediaprovider.apex="$ANDROID_CERT_DIR"/com.android.mediaprovider.pem \
    --extra_apex_payload_key com.android.nearby.halfsheet.apex="$ANDROID_CERT_DIR"/com.android.nearby.halfsheet.pem \
    --extra_apex_payload_key com.android.networkstack.tethering.apex="$ANDROID_CERT_DIR"/com.android.networkstack.tethering.pem \
    --extra_apex_payload_key com.android.neuralnetworks.apex="$ANDROID_CERT_DIR"/com.android.neuralnetworks.pem \
    --extra_apex_payload_key com.android.ondevicepersonalization.apex="$ANDROID_CERT_DIR"/com.android.ondevicepersonalization.pem \
    --extra_apex_payload_key com.android.os.statsd.apex="$ANDROID_CERT_DIR"/com.android.os.statsd.pem \
    --extra_apex_payload_key com.android.permission.apex="$ANDROID_CERT_DIR"/com.android.permission.pem \
    --extra_apex_payload_key com.android.resolv.apex="$ANDROID_CERT_DIR"/com.android.resolv.pem \
    --extra_apex_payload_key com.android.rkpd.apex="$ANDROID_CERT_DIR"/com.android.rkpd.pem \
    --extra_apex_payload_key com.android.runtime.apex="$ANDROID_CERT_DIR"/com.android.runtime.pem \
    --extra_apex_payload_key com.android.safetycenter.resources.apex="$ANDROID_CERT_DIR"/com.android.safetycenter.resources.pem \
    --extra_apex_payload_key com.android.scheduling.apex="$ANDROID_CERT_DIR"/com.android.scheduling.pem \
    --extra_apex_payload_key com.android.sdkext.apex="$ANDROID_CERT_DIR"/com.android.sdkext.pem \
    --extra_apex_payload_key com.android.support.apexer.apex="$ANDROID_CERT_DIR"/com.android.support.apexer.pem \
    --extra_apex_payload_key com.android.telephony.apex="$ANDROID_CERT_DIR"/com.android.telephony.pem \
    --extra_apex_payload_key com.android.telephonymodules.apex="$ANDROID_CERT_DIR"/com.android.telephonymodules.pem \
    --extra_apex_payload_key com.android.tethering.apex="$ANDROID_CERT_DIR"/com.android.tethering.pem \
    --extra_apex_payload_key com.android.tzdata.apex="$ANDROID_CERT_DIR"/com.android.tzdata.pem \
    --extra_apex_payload_key com.android.uwb.apex="$ANDROID_CERT_DIR"/com.android.uwb.pem \
    --extra_apex_payload_key com.android.uwb.resources.apex="$ANDROID_CERT_DIR"/com.android.uwb.resources.pem \
    --extra_apex_payload_key com.android.virt.apex="$ANDROID_CERT_DIR"/com.android.virt.pem \
    --extra_apex_payload_key com.android.vndk.current.apex="$ANDROID_CERT_DIR"/com.android.vndk.current.pem \
    --extra_apex_payload_key com.android.vndk.current.on_vendor.apex="$ANDROID_CERT_DIR"/com.android.vndk.current.on_vendor.pem \
    --extra_apex_payload_key com.android.wifi.apex="$ANDROID_CERT_DIR"/com.android.wifi.pem \
    --extra_apex_payload_key com.android.wifi.dialog.apex="$ANDROID_CERT_DIR"/com.android.wifi.dialog.pem \
    --extra_apex_payload_key com.android.wifi.resources.apex="$ANDROID_CERT_DIR"/com.android.wifi.resources.pem \
    --extra_apex_payload_key com.google.pixel.camera.hal.apex="$ANDROID_CERT_DIR"/com.google.pixel.camera.hal.pem \
    --extra_apex_payload_key com.google.pixel.vibrator.hal.apex="$ANDROID_CERT_DIR"/com.google.pixel.vibrator.hal.pem \
    --extra_apex_payload_key com.qorvo.uwb.apex="$ANDROID_CERT_DIR"/com.qorvo.uwb.pem \
    $OUT/obj/PACKAGING/target_files_intermediates/*-target_files*.zip \
    ${build_device}-signed-target_files.zip


if [[ $BUILD_DELTA -eq 1 ]]; then
    echo "Building delta package"
    ota_from_target_files -k "$ANDROID_CERT_DIR"/releasekey --block --backup=true  -i ${build_device}-signed-target_files_old.zip ${build_device}-signed-target_files.zip ${build_device}-signed-delta.zip
else
    echo "Building full package"
    ota_from_target_files -k "$ANDROID_CERT_DIR"/releasekey --block --backup=true ${build_device}-signed-target_files.zip lineage-${build_device}_signed.zip
fi

mv ${build_device}-signed-target_files.zip ${build_device}-signed-target_files_old.zip
