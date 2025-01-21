#!/bin/python3

"""This script updates the fingerprint of a device in LineageOS"""

import argparse
import os
import subprocess
import sys

# A dict of {device: common}
manufacture = {
        'pdx203': 'sony',
        'pdx206': 'sony',
        'pdx214': 'sony',
        'pdx215': 'sony',
        'pdx234': 'sony',
}
common = {
        'pdx203': 'sm8250-common',
        'pdx206': 'sm8250-common',
        'pdx214': 'sm8350-common',
        'pdx215': 'sm8350-common',
        'pdx234': 'sm8550-common',
}
LINEAGEOS_DIR = '/data/LineageOS/Lineage22/'

def do_replacekv(file, key, value, space_after_equal=True, custom_check_func=None):
    '''Replace a key-value pair in a file'''
    if space_after_equal:
        chr_after_equal = ' '
    else:
        chr_after_equal = ''

    with open(file, 'r', encoding='utf-8') as kv_file:
        kv_lines = kv_file.readlines()
        for i, kv_line in enumerate(kv_lines):
            if key in kv_line:
                if custom_check_func is not None:
                    if not custom_check_func(kv_line):
                        continue
                kv_lines[i] = kv_lines[i].split('=')[0] + '=' + chr_after_equal + value + '\n'

    with open(file, 'w', encoding='utf-8') as kv_file:
        kv_file.writelines(kv_lines)

def do_replaceline(file, line_no, value):
    '''Replace a line in a file'''
    with open(file, 'r', encoding='utf-8') as line_file:
        file_lines = line_file.readlines()
        file_lines[line_no] = value

    with open(file, 'w', encoding='utf-8') as line_file:
        line_file.writelines(file_lines)

def commit_changes(directory, prefix: str, show_change_stat=False):
    '''Commit changes in a directory'''
    if prefix[-1] != ':':
        prefix += ':'
    try:
        subprocess.check_output(['git', 'commit', '-a', '-m', prefix + ' Update blobs to ' + base_name ], cwd=directory)
    except subprocess.CalledProcessError as _:
        print(f'No changes in {directory}, skipping commit')

    if show_change_stat:
        print(f"=== Changes in {directory} ===")
        output = subprocess.check_output(['git', 'show', '--stat'], cwd=directory)
        print(output.decode('utf-8'))
        print("=======================")

# This function checks if line begins with 'B'
def check_boot_security(line_to_check):
    '''Check if the line begins with 'B', if it is, it is the line "BOOT_PATCH_SECURITY"'''
    return line_to_check[0] == 'B'

parser = argparse.ArgumentParser(description='Update fingerprint for a device')
parser.add_argument('device', help='device name')
parser.add_argument('rootdir', help='root directory of the stock package, no rootdir/ included')
parser.add_argument('-e', '--extract', action='store_true',
                    help='run extract-files.sh after updating fingerprint')
parser.add_argument('-d', '--losdir', action='store', help='LineageOS root directory')
args = parser.parse_args()

# Get device name from argv[1]
device_name = args.device
common_name = common.get(device_name)
manufacture_name = manufacture.get(device_name)
if common_name is None or manufacture_name is None:
    print(f'No common/manufacture for device: {device_name}')
    sys.exit(1)

print(f"device name: {device_name}")
print(f"common name: {common_name}")

# Open the rootdir supplied by argv[2]
rootdir = args.rootdir
if rootdir[-1] != '/':
    rootdir += '/'

# If the LineageOS root directory is supplied, use it
if args.losdir is not None:
    LINEAGEOS_DIR = args.losdir
    if LINEAGEOS_DIR[-1] != '/':
        LINEAGEOS_DIR += '/'

# Get the base name of the path
base_name = rootdir.split('/')[-2]
print(f'base name: {base_name}')

BUILD_FP = None
BUILD_DESC = None
fingerprint_prop_file = rootdir + 'rootfs/oem/etc/customization/config.prop'
with open(fingerprint_prop_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for line in lines:
        # if the line contains 'ro.build.fingerprint'
        if 'ro.build.fingerprint' in line:
            # Get the fingerprint
            BUILD_FP = line.split('=')[1].strip()
            print(f'fingerprint found: {BUILD_FP}')

        if 'ro.build.description' in line:
            # Get the description
            BUILD_DESC = line.split('=')[1].strip()
            print(f'description found: {BUILD_DESC}')

BUILD_SECURITY_PATCH = None
build_security_patch_file = rootdir + 'rootfs/vendor/build.prop'
with open(build_security_patch_file, 'r', encoding='utf-8') as f:
    lines = f.readlines()
    for line in lines:
        if 'ro.vendor.build.security_patch' in line:
            BUILD_SECURITY_PATCH = line.split('=')[1].strip()
            print(f'security patch found: {BUILD_SECURITY_PATCH}')

if BUILD_FP is None or BUILD_DESC is None or BUILD_SECURITY_PATCH is None:
    print('No fingerprint found in config.prop')
    sys.exit(1)

# OK, now go to the device dir
device_dir = LINEAGEOS_DIR + '/device/' + manufacture_name + '/' + device_name + '/'

# First, replace the fingerprint in 'lineage_{device}.mk'
lineage_mk_file = device_dir + 'lineage_' + device_name + '.mk'
do_replacekv(lineage_mk_file, 'BuildFingerprint', BUILD_FP)
do_replacekv(lineage_mk_file, 'BuildDesc', '"' + BUILD_DESC + '"', False)

# Then replace the package version in "proprietary-files.txt"
prop_files_file = device_dir + 'proprietary-files.txt'
do_replaceline(prop_files_file, 0, '# Stock package version: ' + base_name + '\n')

# Git commit
print('Committing changes...')
commit_changes(device_dir, device_name)

# Now, replace things in common
common_dir = LINEAGEOS_DIR + '/device/' + manufacture_name + '/' + common_name + '/'
print(f'common dir: {common_dir}')
os.chdir(common_dir)

# First replace the security patch in BoardConfigCommon.mk
board_config_file = common_dir + 'BoardConfigCommon.mk'
do_replacekv(board_config_file, 'BOOT_SECURITY_PATCH',
             BUILD_SECURITY_PATCH, custom_check_func=check_boot_security)

# Then replace the package version in "proprietary-files.txt"
prop_files_file = common_dir + 'proprietary-files.txt'
do_replaceline(prop_files_file, 0, '# Stock package version: ' + base_name + '\n')

# Git commit
print('Committing changes...')
commit_changes(common_dir, common_name)

if not args.extract:
    sys.exit(0)

# CD to device dir and run extract-files.sh
os.chdir(device_dir)

print('Running extract-files.sh...')
subprocess.check_output(['./extract-files.py', rootdir + 'super'], cwd=device_dir)

vendor_dir = LINEAGEOS_DIR + '/vendor/' + manufacture_name + '/' + device_name + '/'
commit_changes(vendor_dir, device_name, True)

vendor_dir = LINEAGEOS_DIR + '/vendor/' + manufacture_name + '/' + common_name + '/'
commit_changes(vendor_dir, common_name, True)
