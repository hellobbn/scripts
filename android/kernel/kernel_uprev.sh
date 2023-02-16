#!/bin/bash

tag=$1

set -x

# Main

git fetch upstream_caf
set -e
git merge "$tag"
set +e

# Techpack

# techpack/audio
git fetch techpack-audio "$tag"
set -e
git merge -X subtree=techpack/audio FETCH_HEAD
set +e

# techpack/camera
git fetch techpack-camera "$tag"
set -e
git merge -X subtree=techpack/camera FETCH_HEAD
set +e
 
# techpack/dataipa
git fetch techpack-dataipa "$tag"
set -e
git merge -X subtree=techpack/dataipa FETCH_HEAD
set +e

# techpack/datarmnet
git fetch techpack-datarmnet "$tag"
set -e
git merge -X subtree=techpack/datarmnet FETCH_HEAD
set +e

# techpack/datarmnet-ext
git fetch techpack-datarmnet-ext "$tag"
set -e
git merge -X subtree=techpack/datarmnet-ext FETCH_HEAD
set +e

# techpack/display
git fetch techpack-display "$tag"
set -e
git merge -X subtree=techpack/display FETCH_HEAD
set +e

# techpack/video
git fetch techpack-video "$tag"
set -e
git merge -X subtree=techpack/video FETCH_HEAD
set +e

# QCACLD Related

git fetch qca-wifi-host-cmn "$tag"
set -e
git merge -X subtree=drivers/staging/qca-wifi-host-cmn FETCH_HEAD
set +e

git fetch qcacld-3.0 "$tag"
set -e
git merge -X subtree=drivers/staging/qcacld-3.0 FETCH_HEAD
set +e

git fetch fw-api "$tag"
set -e
git merge -X subtree=drivers/staging/fw-api FETCH_HEAD
set +e

