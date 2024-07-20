#!/bin/python3

import argparse
import os
import subprocess

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
lineageos_dir = '/data/LineageOS/Lineage21/'

def do_replacekv(file, key, value, space_after_equal=True, custom_check_func=None):
    if space_after_equal:
        chr_after_equal = ' '
    else:
        chr_after_equal = ''

    with open(file, 'r') as f:
        lines = f.readlines()
        for i, line in enumerate(lines):
            if key in line:
                if custom_check_func != None:
                    if not custom_check_func(line):
                        continue
                lines[i] = lines[i].split('=')[0] + '=' + chr_after_equal + value + '\n'

    with open(file, 'w') as f:
        f.writelines(lines)

def do_replaceline(file, line_no, value):
    with open(file, 'r') as f:
        lines = f.readlines()
        lines[line_no] = value

    with open(file, 'w') as f:
        f.writelines(lines)

def commit_changes(dir, prefix: str, show_change_stat=False):
    if prefix[-1] != ':':
        prefix += ':'
    try:
        subprocess.check_output(['git', 'commit', '-a', '-m', prefix + ' Update blobs to ' + base_name ], cwd=dir)
    except subprocess.CalledProcessError as _:
        print('No changes in %s, skipping commit' % dir)

    if show_change_stat:
        print("=== Changes in %s ===" % dir)
        output = subprocess.check_output(['git', 'show', '--stat'], cwd=dir)
        print(output.decode('utf-8'))
        print("=======================")

# This function checks if line begins with 'B'
def check_boot_security(line):
    return line[0] == 'B'

parser = argparse.ArgumentParser(description='Update fingerprint for a device')
parser.add_argument('device', help='device name')
parser.add_argument('rootdir', help='root directory of the stock package, no rootdir/ included')
parser.add_argument('-e', '--extract', action='store_true', help='run extract-files.sh after updating fingerprint')
parser.add_argument('-d', '--losdir', action='store', help='LineageOS root directory')
args = parser.parse_args()

# Get device name from argv[1]
device_name = args.device
common_name = common.get(device_name)
manufacture_name = manufacture.get(device_name)
if common_name == None or manufacture_name == None:
    print('No common/manufacture for device: %s' % device_name)
    exit(1)

print("device name: %s" % device_name)
print("common name: %s" % common_name)

# Open the rootdir supplied by argv[2]
rootdir = args.rootdir
if rootdir[-1] != '/':
    rootdir += '/'

# If the LineageOS root directory is supplied, use it
if args.losdir != None:
    lineageos_dir = args.losdir
    if lineageos_dir[-1] != '/':
        lineageos_dir += '/'

# Get the base name of the path
base_name = rootdir.split('/')[-2]
print('base name: %s' % base_name)

build_fp = None
build_desc = None
fingerprint_prop_file = rootdir + 'rootfs/oem/etc/customization/config.prop'
with open(fingerprint_prop_file, 'r') as f:
    lines = f.readlines()
    for line in lines:
        # if the line contains 'ro.build.fingerprint'
        if 'ro.build.fingerprint' in line:
            # Get the fingerprint
            build_fp = line.split('=')[1].strip()
            print('fingerprint found: %s' % build_fp)

        if 'ro.build.description' in line:
            # Get the description
            build_desc = line.split('=')[1].strip()
            print('description found: %s' % build_desc)

build_security_patch = None
build_security_patch_file = rootdir + 'rootfs/vendor/build.prop'
with open(build_security_patch_file, 'r') as f:
    lines = f.readlines()
    for line in lines:
        if 'ro.vendor.build.security_patch' in line:
            build_security_patch = line.split('=')[1].strip()
            print('security patch found: %s' % build_security_patch)

if build_fp == None or build_desc == None or build_security_patch == None:
    print('No fingerprint found in config.prop')
    exit(1)

# OK, now go to the device dir
device_dir = lineageos_dir + '/device/' + manufacture_name + '/' + device_name + '/'

# First, replace the fingerprint in 'lineage_{device}.mk'
lineage_mk_file = device_dir + 'lineage_' + device_name + '.mk'
do_replacekv(lineage_mk_file, 'BUILD_FINGERPRINT', build_fp)
do_replacekv(lineage_mk_file, 'PRIVATE_BUILD_DESC', '"' + build_desc + '"', False)

# Then replace the package version in "proprietary-files.txt"
prop_files_file = device_dir + 'proprietary-files.txt'
do_replaceline(prop_files_file, 0, '# Stock package version: ' + base_name + '\n')

# Git commit
print('Committing changes...')
commit_changes(device_dir, device_name)

# Now, replace things in common
common_dir = lineageos_dir + '/device/' + manufacture_name + '/' + common_name + '/'
print('common dir: %s' % common_dir)
os.chdir(common_dir)

# First replace the security patch in BoardConfigCommon.mk
board_config_file = common_dir + 'BoardConfigCommon.mk'
do_replacekv(board_config_file, 'BOOT_SECURITY_PATCH', build_security_patch, custom_check_func=check_boot_security)

# Then replace the package version in "proprietary-files.txt"
prop_files_file = common_dir + 'proprietary-files.txt'
do_replaceline(prop_files_file, 0, '# Stock package version: ' + base_name + '\n')

# Git commit
print('Committing changes...')
commit_changes(common_dir, common_name)

if not args.extract:
    exit(0)

# CD to device dir and run extract-files.sh
os.chdir(device_dir)

print('Running extract-files.sh...')
subprocess.check_output(['./extract-files.sh', rootdir + 'super'], cwd=device_dir)

vendor_dir = lineageos_dir + '/vendor/' + manufacture_name + '/' + device_name + '/'
commit_changes(vendor_dir, device_name, True)

vendor_dir = lineageos_dir + '/vendor/' + manufacture_name + '/' + common_name + '/'
commit_changes(vendor_dir, common_name, True)
