#!/bin/env python

import scan_proprietary_files
import subprocess

debug = True

file = scan_proprietary_files.pFile("/data/LineageOS/LineageOS_20/out/target/product/pdx234/vendor/bin/hw/vendor.qti.hardware.display.composer-service", "/data/LineageOS/LineageOS_20/out/target/product/pdx234/", True)

for dep in file.deps:
    subprocess.check_output(["adb", "shell", "ls", dep])
