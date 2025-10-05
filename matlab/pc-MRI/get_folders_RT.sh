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
# 1) FOLDERS (phase) -> folders.txt
find "$folder_path" -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_P_*" -o -name "*_P" \) > ./aux_RT/folders.txt
sed -i'' -e 's|_P.*||' ./aux_RT/folders.txt
sed -i'' -e "s|$folder_path||" ./aux_RT/folders.txt
sort ./aux_RT/folders.txt -o ./aux_RT/folders.txt
sed -i'' -e 's|/||' ./aux_RT/folders.txt

# 2) FOLDERS (other, not P/MAG) -> folders_.txt
find "$folder_path" -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_*" ! -name "*_P_*" ! -name "*_P" ! -name "*_MAG_*" ! -name "*_MAG" ! -name "*DS_Store*" \) > ./aux_RT/folders_.txt
sed -i'' -e "s|$folder_path||" ./aux_RT/folders_.txt
sort ./aux_RT/folders_.txt -o ./aux_RT/folders_.txt
sed -i'' -e 's|/||' ./aux_RT/folders_.txt

# 3) FOLDERS (MAG) -> folders_MAG.txt
find "$folder_path" -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_MAG_*" -o -name "*_MAG" \) > ./aux_RT/folders_MAG.txt
sed -i'' -e "s|$folder_path||" ./aux_RT/folders_MAG.txt
sort ./aux_RT/folders_MAG.txt -o ./aux_RT/folders_MAG.txt
sed -i'' -e 's|/||' ./aux_RT/folders_MAG.txt

# 4) Explicit P list -> folders_P.txt
find "$folder_path" -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_P_*" -o -name "*_P" \) > ./aux_RT/folders_P.txt
sed -i'' -e "s|$folder_path||" ./aux_RT/folders_P.txt
sort ./aux_RT/folders_P.txt -o ./aux_RT/folders_P.txt
sed -i'' -e 's|/||' ./aux_RT/folders_P.txt
