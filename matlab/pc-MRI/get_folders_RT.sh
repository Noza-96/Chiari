#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/bin:/bin:$PATH"

# --- Input & normalization ---
folder_path_raw="${1:-}"
if [ -z "$folder_path_raw" ]; then
  echo "Usage: $0 <folder_path>"
  echo "Example: $0 "..\..\..\patient-data\s4\flow""
  exit 1
fi

# Convert Windows backslashes to forward slashes; drop trailing slash
folder_path="${folder_path_raw//\\//}"
folder_path="${folder_path%/}"

# --- helpers ---
sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i "$@"
  else
    sed -i "" "$@"
  fi
}

# safe sort_inplace (consistent collation across platforms)
sort_inplace() {
  LC_ALL=C sort "$1" -o "$1"
}

# --- Build lists ---
# 1) FOLDERS (phase) -> folders.txt
find "$folder_path" -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_P_*" -o -name "*_P" \) > ./aux_RT/folders.txt
sed_inplace "s|_P.*||" ./aux_RT/folders.txt
sed_inplace "s|$folder_path/||" ./aux_RT/folders.txt
sort_inplace ./aux_RT/folders.txt

# 2) FOLDERS (other, not P/MAG) -> folders_.txt
find "$folder_path" -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_*" ! -name "*_P_*" ! -name "*_P" ! -name "*_MAG_*" ! -name "*_MAG" ! -name "*DS_Store*" \) > ./aux_RT/folders_.txt
sed_inplace "s|$folder_path/||" ./aux_RT/folders_.txt
sort_inplace ./aux_RT/folders_.txt

# 3) FOLDERS (MAG) -> folders_MAG.txt
find "$folder_path" -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_MAG_*" -o -name "*_MAG" \) > ./aux_RT/folders_MAG.txt
sed_inplace "s|$folder_path/||" ./aux_RT/folders_MAG.txt
sort_inplace ./aux_RT/folders_MAG.txt

# 4) Explicit P list -> folders_P.txt
find "$folder_path" -maxdepth 4 -ipath "*/*RT/*" -and \( -name "*_P_*" -o -name "*_P" \) > ./aux_RT/folders_P.txt
sed_inplace "s|$folder_path/||" ./aux_RT/folders_P.txt
sort_inplace ./aux_RT/folders_P.txt
