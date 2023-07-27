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

# $CLI ../protobom/examples/nginx.spdx.json -f cyclonedx > $ROUND1_DIR/nginx.cdx.json

# $CLI ../protobom/examples_rd1/nginx.cdx.json -f spdx >  $ROUND2_DIR/nginx.spdx.json


# for FILENAME in "$SOURCE_DIR"/*.spdx.json; do
#     [ -e "$FILENAME" ] || continue  # Check if any files match the pattern

#     FILE_BASE=$(basename "$FILENAME" .spdx.json)

#     # Round 1: Convert SPDX to CycloneDX
#     "$CLI" "$FILENAME" -f cyclonedx > "$ROUND1_DIR/$FILE_BASE.cdx.json"

#     # Round 2: Convert CycloneDX back to SPDX
#     "$CLI" "$ROUND1_DIR/$FILE_BASE.cdx.json" -f spdx > "$ROUND2_DIR/$FILE_BASE.spdx.json"
# done


# Sort and copy original files to rd0 directory
for FILENAME in "$SOURCE_DIR"/*.spdx.json "$SOURCE_DIR"/*.cdx.json; do
    [ -e "$FILENAME" ] || continue  # Check if any files match the pattern

    FILE_BASE=$(basename "$FILENAME" .json)

    # Sort the JSON file alphabetically by keys
    jq -S '.' "$FILENAME" > "$ROUND0_DIR/$FILE_BASE.json"
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
        "$CLI" "$ROUND1_DIR/$FILE_BASE.cdx.json" -f spdx | jq -S > "$ROUND2_DIR/$FILE_BASE.spdx.json"
    elif [[ "$FILENAME" == *.cdx.json ]]; then
        # Round 1: Convert CycloneDX to SPDX
        "$CLI" "$FILENAME" -f spdx > "$ROUND1_DIR/$FILE_BASE.spdx.json"

        # Round 2: Convert SPDX back to CycloneDX
        "$CLI" "$ROUND1_DIR/$FILE_BASE.spdx.json" -f cyclonedx | jq -S  > "$ROUND2_DIR/$FILE_BASE.cdx.json"
    fi
done