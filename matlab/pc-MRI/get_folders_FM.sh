#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/bin:/bin:$PATH"

# --- Input & normalization ---
folder_path_raw="${1:-}"
if [ -z "$folder_path_raw" ]; then
  echo "Usage: $0 <folder_path>"
  echo "Example: $0 '..\..\..\patient-data\s4\flow'"
  exit 1
fi

# Convert Windows backslashes to forward slashes; drop trailing slash
folder_path="${folder_path_raw//\\//}"
folder_path="${folder_path%/}"

# --- Build lists ---
# 1) FilteredSeries folders -> folders.txt
find "$folder_path" -maxdepth 4 -ipath "*/*FM/*" -and \( -name "*FilteredSeries_*" \) > ./aux_FM/folders.txt
sed -i'' -e 's|FilteredSeries.*|FilteredSeries|' ./aux_FM/folders.txt
sed -i'' -e "s|$folder_path||" ./aux_FM/folders.txt
sort ./aux_FM/folders.txt -o ./aux_FM/folders.txt
sed -i'' -e 's|/||' ./aux_FM/folders.txt

# 2) All FilteredSeries entries (raw list) -> folders_.txt
find "$folder_path" -maxdepth 4 -ipath "*/*FM/*" -and \( -name "*FilteredSeries_*" \) > ./aux_FM/folders_.txt
sed -i'' -e "s|$folder_path||" ./aux_FM/folders_.txt
sort ./aux_FM/folders_.txt -o ./aux_FM/folders_.txt
sed -i'' -e 's|/||' ./aux_FM/folders_.txt
