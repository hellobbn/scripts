#!/bin/env python3

import sys
import argparse


def create_dict(file, sec_dict):
    section = None
    with open(file, 'r') as f:
        for line in f:
            line = line.split("|")[0].strip()
            if line:
                if line[0] != '#':
                    if section == None:
                        print("Section not found")
                        sys.exit(1)
                    sec_dict[line] = section
                else:
                    section = line.split("-")[0].strip()
                    section = section.split("#")[1].strip()


def invert_dict(sec_dict):
    inv_dict = {}
    for k, v in sec_dict.items():
        if v not in inv_dict.keys():
            inv_dict[v] = []
        inv_dict[v].append(k)
    return inv_dict


parser = argparse.ArgumentParser(
    prog="compare_proprietary_files.py",
    description="Compare a proprietary_file.txt with other txt files combined",
    epilog="Example: python3 compare_proprietary_files.py proprietary_file.txt file_1.txt file_2.txt file_3.txt"
)
parser.add_argument("in_file", help="The proprietary file to compare")
parser.add_argument("base_files", nargs="+", help="The base files to compare")
parser.add_argument('-o', '--output', default="output.txt", help="The output file")

args = parser.parse_args()

print(args)

# Get input
file_1 = args.in_file
base_files = args.base_files

cat_dict = {}
cat_dict["match"] = []
cat_dict["mismatch"] = []
cat_dict["not_found"] = []
cat_dict["should_be"] = []

sec_dict_1 = {}
sec_dict_base = []

create_dict(file_1, sec_dict_1)

for idx, base_file in enumerate(base_files):
    sec_dict_base.append({})
    create_dict(base_file, sec_dict_base[idx])

for k, v in sec_dict_1.items():
    found = False
    for base_dict in sec_dict_base:
        if k in base_dict.keys():
            found = True
            if v != base_dict[k]:
                cat_dict["mismatch"].append(k)
                cat_dict["should_be"].append(base_dict[k])
                break
            else:
                cat_dict["match"].append(k)
                break
    if not found:
        cat_dict["not_found"].append(k)

# Print the results, match in green, mismatch in yello, not found in red
print("Matched:")
for val in cat_dict["match"]:
    print(val + ": \033[92m" + sec_dict_1[val] + "\033[0m")

print("Mismatched:")
for idx, val in enumerate(cat_dict["mismatch"]):
    print(val + ": \033[93m" + sec_dict_1[val] +
          "\033[0m expect: \033[93m" + cat_dict["should_be"][idx] + "\033[0m")
    sec_dict_1[val] = cat_dict["should_be"][idx]

print("Not found:")
for val in cat_dict["not_found"]:
    print(val + ": \033[91m" + sec_dict_1[val] + "\033[0m")

output_dict = invert_dict(sec_dict_1)

# Output the sorted keys
output_file = args.output
keys = list(output_dict.keys())
keys.sort()
with open(output_file, 'w') as f:
    for k in keys:
        print("# " + k, file=f)
        values = list(output_dict[k])
        values.sort()
        for v in values:
            print(v, file=f)
        print("", file=f)
