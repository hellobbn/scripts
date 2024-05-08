#!/bin/env python

import compare_proprietary_files as cpf
import argparse
import os
import subprocess


def find_in_path(filename, path, sp):
    op = subprocess.check_output(
        ["find", path, "-name", filename, "-type", "f"])
    if op:
        op = op.decode("utf-8").strip().split(sp)[1]
        return op
    else:
        return None


debug = False


class pFile:
    def __init__(self, full_path, rootfs, all_yes):
        self.path = full_path.strip()
        self.relative_path = full_path.split(rootfs)[1]
        self.deps = [self.relative_path]
        self.rootfs = rootfs
        self.type = self.get_type(full_path)
        self.all_yes = all_yes
        print("\t\033[35mGetting dependencies for: \033[0m" +
              self.relative_path)
        self.get_dependencies()

    def get_type(self, path):
        try:
            output = subprocess.check_output(["file", path])
        except:
            return None

        str = output.decode("utf-8")
        # Find if it is 64 or 32-bit
        if "64-bit" in str:
            return 64
        elif "32-bit" in str:
            return 32
        else:
            return None

    def get_dependencies(self):
        get_new_deps = True
        ignored_deps = []
        if self.type == None:
            return
        while get_new_deps:
            get_new_deps = False
            for dep in self.deps:
                if debug:
                    print("\t\033[35mChecking dependency: \033[0m" + dep)

                # First, check readelf
                dep_full_path = os.path.join(self.rootfs, dep)
                try:
                    output = subprocess.check_output(["readelf", "-d", dep_full_path], stderr=subprocess.DEVNULL
                                                     )
                except:
                    continue
                str = output.decode("utf-8")
                for line in str.split("\n"):
                    # Find the dependencies: (NEEDED) Shared library: [libxxx.so]
                    if "(NEEDED)" in line:
                        dep = line.split("[")[1].split("]")[0]
                        if dep not in self.deps:
                            # We can't just add this to deps, we need to check whether we
                            # can find it in the rootfs
                            if self.type == 64:
                                lib_path = os.path.join(
                                    self.rootfs, "vendor/lib64")
                            else:
                                lib_path = os.path.join(
                                    self.rootfs, "vendor/lib")

                            op = find_in_path(dep, lib_path, self.rootfs)
                            if op:
                                if op not in self.deps:
                                    self.deps.append(op)
                                    get_new_deps = True
                                    print(
                                        "\t\033[35mFound dependency: \033[0m" + op)

                # Considerint there may be dlopen thing, check strings and extract '\.so' here
                output = subprocess.check_output(["strings", dep_full_path])
                str = output.decode("utf-8")
                for line in str.split("\n"):
                    if ".so" in line:
                        if self.type == 64:
                            lib_path = os.path.join(
                                self.rootfs, "vendor/lib64")
                        else:
                            lib_path = os.path.join(self.rootfs, "vendor/lib")
                        line = line.split("/")[-1]
                        op = find_in_path(line, lib_path, self.rootfs)
                        if op:
                            if op not in self.deps and op not in ignored_deps:
                                print(
                                    "\t\033[36mPossible dependencies (so?): \033[0m" + op)
                                # Ask whether to add
                                if self.all_yes:
                                    self.deps.append(op)
                                    get_new_deps = True
                                    break
                                while True:
                                    answer = input("Add? (y/n): ") or "y"
                                    if answer == "y":
                                        self.deps.append(op)
                                        get_new_deps = True
                                        break
                                    elif answer == "n":
                                        ignored_deps.append(op)
                                        break
                    elif "/vendor/" in line:
                        line = line.split("/")[-1]
                        op = find_in_path(line, os.path.join(
                            self.rootfs, "vendor"), self.rootfs)
                        if op:
                            if op not in self.deps and op not in ignored_deps:
                                print(
                                    "\t\033[36mPossible dependencies (vendor?): \033[0m" + op)
                                if (self.all_yes):
                                    self.deps.append(op)
                                    get_new_deps = True
                                    break
                                while True:
                                    answer = input("Add? (y/n): ") or "y"
                                    if answer == "y":
                                        self.deps.append(op)
                                        get_new_deps = True
                                        break
                                    elif answer == "n":
                                        ignored_deps.append(op)
                                        break


class obinFile:
    def __init__(self, relative_path, rootfs):
        self.relative_path = relative_path
        self.rootfs = rootfs
        self.name = relative_path.split("/")[-1]
        self.initrc = self.find_initrc()
        self.can_be_built = self.check_build()
    
    def find_initrc(self):
        try:
            out = subprocess.check_output(["rg", "-i", self.relative_path, self.rootfs + "/vendor/etc/init"], stderr=subprocess.DEVNULL).decode("utf-8").strip()
            out = out.split(":")[0].split(self.rootfs)[1]
        except:
            out = "not found"
        return out

    def check_build(self):
        with open("allmod", "r") as f:
            for line in f:
                line = line.strip()
                if self.name == line:
                    return True
        return False

def main():
    parser = argparse.ArgumentParser(
        prog="scan_proprietary_files.py",
        description="Scan proprietary files against rootfs to find potential missing files",
        epilog="Example: python3 scan_proprietary_files.py -p proprietary_file.txt -r rootfs"
    )
    parser.add_argument("-p", "--proprietary-files", nargs="+",
                        required=True, help="The proprietary file to scan")
    parser.add_argument("-r", "--rootfs", required=True,
                        help="The rootfs to scan")
    parser.add_argument("-y", "--all-yes", action="store_true",
                        help="Answer yes to all questions")
    parser.add_argument("-v", "--verbose",
                        action="store_true", help="Verbose mode")
    parser.add_argument("-o", "--output", type=str, default="output.txt", help="Output to specified file")

    args = parser.parse_args()

    debug = args.verbose

    pp_dict = {}
    for _, pp in enumerate(args.proprietary_files):
        cpf.create_dict(pp, pp_dict)

    pfiles = []
    other_binfiles = []

    # 1. Check un-included binaries
    vendor_bin_dir = "vendor/bin"
    bin_dir = os.path.join(args.rootfs, vendor_bin_dir)

    for path, subdirs, files in os.walk(bin_dir):
        files.sort()
        for file in files:
            full_path = os.path.join(path, file)
            # cut string to /vendor/...
            relative_path = full_path[full_path.find(vendor_bin_dir):]
            print("\033[36mChecking: \033[0m" + relative_path + ": ", end="")

            if relative_path in pp_dict.keys():
                print("\033[32mFound\033[0m")
                # Now parse dependencies using readelf
                pfile = pFile(full_path, args.rootfs, args.all_yes)
                pfiles.append(pfile)

            else:
                print("\033[31mNot found\033[0m")
                obinfile = obinFile(relative_path, args.rootfs)
                other_binfiles.append(obinfile)
                print("\tinit.rc: \033[35m" + obinfile.initrc + "\033[0m")
                print("\tcan be built: \033[35m" + str(obinfile.can_be_built) + "\033[0m")

    with open(args.output, "w") as f:
        print("In pp file:", file=f)
        for pfile in pfiles:
            print(pfile.relative_path,  file=f)
            for dep in pfile.deps:
                print("\t" + dep, file=f, end="")
                if dep in pp_dict.keys():
                    print(" - Found", file=f)
                else:
                    print(" - Not found", file=f)
        
        print("\nNot in pp file:", file=f)
        for obinfile in other_binfiles:
            print(obinfile.relative_path, file=f)
            print("\t" + obinfile.initrc, file=f)
            print("\t" + str(obinfile.can_be_built), file=f)


if __name__ == "__main__":
    main()
