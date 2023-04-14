#!/bin/bash

## $1 is source build.prop, $2 is target build.prop
if [ $# -ne 2 ]; then
    echo "Usage: $0 <source build.prop> <target build.prop>"
    exit 1
fi

while read -r line; do
    # Skip comments and empty lines
    if [ -z "$line" ]; then
        continue
    fi
    if [[ "$line" =~ ^# ]]; then
        continue
    fi
    source_key=$(echo "$line" | cut -d '=' -f 1)
    source_value=$(echo "$line" | cut -d '=' -f 2)

    # Get the target value
    target_value=$(grep "^$source_key=" "$2" | cut -d '=' -f 2)
    if [ -z "$target_value" ]; then
        # Print missing in yellow
        echo -e "\033[0;33mMissing: \033[0m$source_key: $source_value"
        continue
    elif [ "$source_value" != "$target_value" ]; then
        # Print mismatch in red
        echo -e "\033[0;31mMismatch: \033[0m$source_key: $source_value != $target_value"
    fi
done < "$1"
