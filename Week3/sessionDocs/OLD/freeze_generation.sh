#!/usr/bin/env bash
# ---------------------------------------------------------------
# get_freeze.sh – print freeze lines for a subset of installed packages
#
# Usage:  ./get_freeze.sh <packages_file>
#
#   <packages_file>  One package name per line.
#                    Lines that are empty or start with `#` are ignored.
#                    You may optionally add version specifiers (e.g. "pkg>=1.2")
#                    – the specifier will be stripped.
#
# Example:
#   cat > list.txt <<EOF
#   requests
#   numpy
#   pandas
#   EOF
#   ./get_freeze.sh list.txt
#
# ---------------------------------------------------------------

set -euo pipefail

# ---------- Helpers ----------
usage() {
  cat <<EOF 1>&2
Usage: $0 <packages_file>

Prints pip‑freeze lines (package==version) for the packages listed in <packages_file>.
EOF
  exit 1
}

# ---------- Main ----------
if [[ $# -ne 1 ]]; then
  usage
fi

PKG_FILE="$1"

# 1. Build a map of all installed packages in freeze format
declare -A INSTALLED
while IFS= read -r line || [ -n "$line" ]; do
  # Skip empty lines
  [[ -z "$line" ]] && continue
  # Store the entire freeze line; key is the package name
  pkg_name=${line%%==*}
  INSTALLED["$pkg_name"]="$line"
done < <(pip list --format=freeze 2>/dev/null)

# 2. Read the user‑supplied list, one package per line
while IFS= read -r raw_pkg || [ -n "$raw_pkg" ]; do
  # Strip comments, leading/trailing whitespace
  pkg=${raw_pkg%%#*}          # remove everything after #
  pkg=${pkg#"${pkg%%[![:space:]]*}"}   # trim leading whitespace
  pkg=${pkg%"${pkg##*[![:space:]]}"}   # trim trailing whitespace
  [[ -z "$pkg" ]] && continue   # skip empty lines

  # Remove any version specifier the user might have typed
  # (e.g. "numpy>=1.20" -> "numpy")
  pkg=${pkg%%[<>=!]*}
  pkg=${pkg#"${pkg%%[![:space:]]*}"}   # trim again
  pkg=${pkg%"${pkg##*[![:space:]]}"}   # trim again

  # Look it up
  if [[ -n "${INSTALLED[$pkg]+_}" ]]; then
    echo "${INSTALLED[$pkg]}"
  else
    echo "# package $pkg not installed" >&2
  fi
done < "$PKG_FILE"
fi