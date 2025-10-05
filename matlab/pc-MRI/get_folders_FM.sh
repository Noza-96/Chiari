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
# 1) FilteredSeries folders -> folders.txt
find "$folder_path" -maxdepth 4 -ipath "*/*FM/*" -and \( -name "*FilteredSeries_*" \) > ./aux_FM/folders.txt
sed_inplace "s|FilteredSeries.*|FilteredSeries|" ./aux_FM/folders.txt
sed_inplace "s|$folder_path/||" ./aux_FM/folders.txt
sort_inplace ./aux_FM/folders.txt

# 2) All FilteredSeries entries (raw list) -> folders_.txt
find "$folder_path" -maxdepth 4 -ipath "*/*FM/*" -and \( -name "*FilteredSeries_*" \) > ./aux_FM/folders_.txt
sed_inplace "s|$folder_path/||" ./aux_FM/folders_.txt
sort_inplace ./aux_FM/folders_.txt
