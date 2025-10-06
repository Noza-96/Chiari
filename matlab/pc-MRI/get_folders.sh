#!/usr/bin/env bash
set -euo pipefail
export PATH="/usr/bin:/bin:$PATH"

# --- Input & normalization ---
search_path_raw="${1:-}"
output_path_raw="${2:-}"
measurement="${3:-}"

if [ -z "$search_path_raw" ] || [ -z "$output_path_raw" ]; then
  echo "Usage: $0 <search_path> <output_path>"
  echo "Example: $0 \"C:/Users/guill/Documents/chiari/patient-data/s4/flow\" \"C:/Users/guill/Documents/chiari/computations/pc-mri/s4/mat/aux\""
  exit 1
fi

# Normalize search path (convert backslashes → forward slashes, drop trailing slash)
search_path="${search_path_raw//\\//}"
search_path="${search_path%/}"

# Normalize output path (convert backslashes → forward slashes)
output_path="${output_path_raw//\\//}"

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
find "$search_path" -maxdepth 4 -ipath "*/*$measurement/*" -and \( -name "*_P_*" -o -name "*_P" \) > $output_path/aux_${measurement}/folders.txt
sed_inplace "s|_P.*||" $output_path/aux_${measurement}/folders.txt
sed_inplace  "s|$search_path/||" $output_path/aux_${measurement}/folders.txt
sort_inplace $output_path/aux_${measurement}/folders.txt

# 2) FOLDERS (other, not P/MAG) -> folders_.txt
find "$search_path" -maxdepth 4 -ipath "*/*$measurement/*" -and \( -name "*_*" ! -name "*_P_*" ! -name "*_P" ! -name "*_MAG_*" ! -name "*_MAG" ! -name "*DS_Store*" \) > $output_path/aux_${measurement}/folders_.txt
sed_inplace "s|$search_path/||" $output_path/aux_${measurement}/folders_.txt
sort_inplace $output_path/aux_${measurement}/folders_.txt

# 3) FOLDERS (MAG) -> folders_MAG.txt
find "$search_path" -maxdepth 4 -ipath "*/*$measurement/*" -and \( -name "*_MAG_*" -o -name "*_MAG" \) > $output_path/aux_${measurement}/folders_MAG.txt
sed_inplace "s|$search_path/||" $output_path/aux_${measurement}/folders_MAG.txt
sort_inplace $output_path/aux_${measurement}/folders_MAG.txt

# 4) Explicit P list -> folders_P.txt
find "$search_path" -maxdepth 4 -ipath "*/*$measurement/*" -and \( -name "*_P_*" -o -name "*_P" \) > $output_path/aux_${measurement}/folders_P.txt
sed_inplace "s|$search_path/||" $output_path/aux_${measurement}/folders_P.txt
sort_inplace $output_path/aux_${measurement}/folders_P.txt