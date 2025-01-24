#!/bin/bash

# Enable strict error handling
set -euo pipefail

echo "Clearing Terraform Files"

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of files to be deleted
FILES_TO_DELETE=(".terraform.lock.hcl" ".terraform.tfstate.lock.info" "terraform.tfstate" "terraform.tfstate.backup")

# Iterate over subdirectories immediately under the current directory
for dir in "$SCRIPT_DIR"/*/; do
  echo "Processing directory: $dir"

  # Check and delete each file in the list
  for file in "${FILES_TO_DELETE[@]}"; do
    file_path="${dir}${file}"
    if [[ -f "$file_path" ]]; then
      echo "Deleting $file_path"
      rm -f "$file_path"
    else
      echo "No $file found in $dir"
    fi
  done
done

echo "Complete"
