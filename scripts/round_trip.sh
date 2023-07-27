#!/bin/bash

CLI=./snapshot/main_linux_amd64_v1/go-cli
SOURCE_DIR=../protobom/examples
TMPDIR=.tmp

BASE_NAME=$(basename $SOURCE_DIR)
ROUND0_DIR=$TMPDIR/$BASE_NAME/rd0  
ROUND1_DIR=$TMPDIR/$BASE_NAME/rd1
ROUND2_DIR=$TMPDIR/$BASE_NAME/rd2

mkdir -p "$ROUND0_DIR"
mkdir -p "$ROUND1_DIR"
mkdir -p "$ROUND2_DIR"

# sort_json_keys() {
#     python3 -c 'import sys, json, collections; data = json.load(sys.stdin, object_pairs_hook=collections.OrderedDict); print(json.dumps(data, indent=2, sort_keys=True))'
# }

sort_json_keys() {
    python3 -c 'import sys, json

def sort_json(data):
    if isinstance(data, list):
        # Check if the list contains dictionaries with a "fileName" field
        has_filename = any(isinstance(item, dict) and "fileName" in item for item in data)
        if has_filename:
            # Sort the list based on the "fileName" field
            data.sort(key=lambda item: item.get("fileName", ""))
            return [sort_json(item) for item in data]
        else:
            return [sort_json(item) for item in data]
    elif isinstance(data, dict):
        return {k: sort_json(v) for k, v in sorted(data.items(), key=lambda item: str(item[0]))}
    else:
        return data

data = json.load(sys.stdin)
sorted_data = sort_json(data)
print(json.dumps(sorted_data, indent=2))'
}

# Sort and copy original files to rd0 directory
for FILENAME in "$SOURCE_DIR"/*.spdx.json "$SOURCE_DIR"/*.cdx.json; do
    [ -e "$FILENAME" ] || continue  # Check if any files match the pattern

    FILE_BASE=$(basename "$FILENAME" .json)

    # Sort the JSON file alphabetically by keys
    cat "$FILENAME" | sort_json_keys > "$ROUND0_DIR/$FILE_BASE.json"
done

for FILENAME in "$SOURCE_DIR"/*.spdx.json "$SOURCE_DIR"/*.cdx.json; do
    [ -e "$FILENAME" ] || continue  # Check if any files match the pattern

    FILE_BASE=${FILENAME##*/}  # Remove path from filename
    FILE_BASE=${FILE_BASE%.*}  # Remove extension
    FILE_BASE=${FILE_BASE%.*}  # Remove the second extension (either .spdx or .cdx)

    # Check if the file is SPDX or CycloneDX
    if [[ "$FILENAME" == *.spdx.json ]]; then
        # Round 1: Convert SPDX to CycloneDX
        "$CLI" "$FILENAME" -f cyclonedx > "$ROUND1_DIR/$FILE_BASE.cdx.json"

        # Round 2: Convert CycloneDX back to SPDX
        "$CLI" "$ROUND1_DIR/$FILE_BASE.cdx.json" -f spdx | sort_json_keys > "$ROUND2_DIR/$FILE_BASE.spdx.json"
    elif [[ "$FILENAME" == *.cdx.json ]]; then
        # Round 1: Convert CycloneDX to SPDX
        "$CLI" "$FILENAME" -f spdx > "$ROUND1_DIR/$FILE_BASE.spdx.json"

        # Round 2: Convert SPDX back to CycloneDX
        "$CLI" "$ROUND1_DIR/$FILE_BASE.spdx.json" -f cyclonedx | sort_json_keys > "$ROUND2_DIR/$FILE_BASE.cdx.json"
    fi
done