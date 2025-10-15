#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob   # make unmatched globs expand to nothing (Git Bash safe)

# ---------------------------- #
# helpers
# ---------------------------- #
error() {
  echo "ERROR: $*" >&2
  exit 1
}

have() { command -v "$1" >/dev/null 2>&1; }

normpath() {
  (cd "$1" >/dev/null 2>&1 && pwd -P) || return 1
}

ask_for_path() {
  local varname="$1" prompt="$2" default="${3:-}"
  local value=""
  if [[ -n "$default" ]]; then
    read -r -p "$prompt [$default]: " value || true
    value="${value:-$default}"
  else
    read -r -p "$prompt: " value || true
  fi
  echo "$value"
}

try_first_existing() {
  local p
  for p in "$@"; do
    if [[ -e "$p" ]]; then
      echo "$p"
      return 0
    fi
  done
  return 1
}

# ---------------------------- #
# 1) check required commands
# ---------------------------- #
missing=()

have sct_deepseg || missing+=("sct_deepseg (install: https://spinalcordtoolbox.com/user_section/installation/windows.html)")
have bash         || missing+=("bash (install: https://git-scm.com/downloads/win)")
have dcm2niix     || missing+=("dcm2niix (install: https://pypi.org/project/dcm2niix/)")

if (( ${#missing[@]} > 0 )); then
  echo "The following required commands were not found:"
  for item in "${missing[@]}"; do echo "  - $item"; done
  error "Please install the missing tools and run this script again."
fi

# ---------------------------- #
# 2) figure out config path (pwd/..)
# ---------------------------- #
here="$(pwd -P)"
config_path="$(normpath "$here/..")" || error "Could not resolve config path from '$here/..'"
mkdir -p "$config_path"

config_file="$config_path/config.txt"
if [[ -e "$config_file" ]]; then
  error "Config file already exists at: $config_file
Refusing to overwrite. Delete or rename it if you want to regenerate."
fi

# ---------------------------- #
# try to find Slicer & Fluent
# ---------------------------- #
os="$(uname -s | tr '[:upper:]' '[:lower:]')"

# --- Try Slicer (3D Slicer) ---
slicer_guess=""
# Try PATH first
if have Slicer; then
  slicer_guess="$(command -v Slicer)"
fi

# OS-specific guesses (no sort -V)
if [[ -z "${slicer_guess}" ]]; then
  if [[ "$os" == mingw* || "$os" == msys* || "$os" == cygwin* ]]; then
    # Windows (Git Bash): pick the last match (often newest)
    for s in /c/Program\ Files/Slicer*/Slicer.exe; do
      [[ -f "$s" ]] || continue
      slicer_guess="$s"
    done
    # fallback common names
    if [[ -z "$slicer_guess" ]]; then
      slicer_guess="$(try_first_existing \
        "/c/Program Files/Slicer/Slicer.exe" \
        "/c/Program Files/Slicer 5/Slicer.exe")" || true
    fi
  elif [[ "$os" == darwin* ]]; then
    slicer_guess="$(try_first_existing \
      "/Applications/Slicer.app/Contents/MacOS/Slicer")" || true
  else
    # Linux
    for s in /usr/bin/Slicer /usr/local/bin/Slicer /opt/slicer/Slicer; do
      [[ -x "$s" ]] || continue
      slicer_guess="$s"
      break
    done
  fi
fi

# --- Try ANSYS Fluent (version-agnostic) ---
fluent_guess=""
# PATH first
if have fluent; then
  fluent_guess="$(command -v fluent)"
fi

if [[ -z "${fluent_guess}" ]]; then
  if [[ "$os" == mingw* || "$os" == msys* || "$os" == cygwin* ]]; then
    # Windows: iterate over any v*/fluent/... path; keep last match
    for f in /c/Program\ Files/ANSYS\ Inc/v*/fluent/ntbin/win64/fluent.exe; do
      [[ -f "$f" ]] || continue
      fluent_guess="$f"
    done
  elif [[ "$os" == darwin* ]]; then
    # Fluent uncommon on macOS; rely on PATH only
    :
  else
    # Linux: check common roots; if multiple, keep last match
    for f in /usr/ansys_inc/v*/fluent/bin/fluent /opt/ansys_inc/v*/fluent/bin/fluent; do
      [[ -x "$f" ]] || continue
      fluent_guess="$f"
    done
  fi
fi

# Ask user if not found
if [[ -z "${slicer_guess}" || ! -e "${slicer_guess}" ]]; then
  slicer_guess="$(ask_for_path "SLICER3D_PATH" "Enter full path to 3D Slicer executable (e.g., Slicer.exe or Slicer)")"
fi
if [[ -z "${fluent_guess}" || ! -e "${fluent_guess}" ]]; then
  fluent_guess="$(ask_for_path "FLUENT_PATH" "Enter full path to ANSYS Fluent executable (e.g., fluent.exe or fluent)")"
fi

# Validate paths exist
[[ -n "$slicer_guess" && -e "$slicer_guess" ]] || error "Invalid Slicer path: '$slicer_guess'"
[[ -n "$fluent_guess"  && -e "$fluent_guess"  ]] || error "Invalid Fluent path: '$fluent_guess'"

# ---------------------------- #
# write config
# ---------------------------- #
{
  echo "# Auto-generated on $(date)"
  echo "# Config file for local tools"
  echo "SLICER3D_PATH=\"$slicer_guess\""
  echo "FLUENT_PATH=\"$fluent_guess\""
} > "$config_file"

echo "Config written to: $config_file"
