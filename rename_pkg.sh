#!/usr/bin/env bash
# Rename this ROS 2 package.
#
# Usage: ./rename_pkg.sh [-n] <new_name>
#   -n   dry run: show what would change without touching anything
#
# The current name is read from <name> in package.xml. The script:
#   - replaces the old name (and its UPPERCASE form, e.g. include guards)
#     as a whole word in every text file of the package
#   - renames the Python module folder  <old>/          -> <new>/
#   - renames the C++ include folder    include/<old>/  -> include/<new>/
set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "-n" ]]; then DRY_RUN=1; shift; fi

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [-n] <new_name>" >&2
  exit 1
fi

NEW="$1"
PKG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$(basename "${BASH_SOURCE[0]}")"
cd "$PKG_DIR"

# ROS package names (REP 144): lowercase letters, digits, underscores, starting with a letter.
if [[ ! "$NEW" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "Error: '$NEW' is not a valid ROS package name (use lowercase letters, digits and '_', starting with a letter)." >&2
  exit 1
fi

OLD="$(sed -n 's:.*<name>[[:space:]]*\([^<[:space:]]*\)[[:space:]]*</name>.*:\1:p' package.xml | head -n1)"
if [[ -z "$OLD" ]]; then
  echo "Error: could not read the current package name from package.xml." >&2
  exit 1
fi
if [[ "$OLD" == "$NEW" ]]; then
  echo "Package is already named '$NEW'. Nothing to do."
  exit 0
fi

OLD_UP="${OLD^^}"
NEW_UP="${NEW^^}"

echo "Renaming package: $OLD -> $NEW"
[[ $DRY_RUN -eq 1 ]] && echo "(dry run, no changes will be made)"

# 1) Replace the name inside files (whole words only, so 'my_ros2_pkg_x' is left alone).
mapfile -t FILES < <(grep -rlIwE --exclude-dir=.git --exclude-dir=build \
  --exclude-dir=install --exclude-dir=log --exclude="$SELF" \
  -e "$OLD" -e "$OLD_UP" . || true)

for f in "${FILES[@]}"; do
  echo "  edit   $f"
  if [[ $DRY_RUN -eq 0 ]]; then
    OLD="$OLD" NEW="$NEW" OLD_UP="$OLD_UP" NEW_UP="$NEW_UP" \
      perl -pi -e 's/\b\Q$ENV{OLD}\E\b/$ENV{NEW}/g; s/\b\Q$ENV{OLD_UP}\E\b/$ENV{NEW_UP}/g' "$f"
  fi
done

# 2) Rename folders named after the package.
rename_dir() {
  local from="$1" to="$2"
  [[ -d "$from" ]] || return 0
  if [[ -e "$to" ]]; then
    echo "Error: cannot rename '$from' -> '$to': target already exists." >&2
    exit 1
  fi
  echo "  move   $from -> $to"
  [[ $DRY_RUN -eq 0 ]] && mv "$from" "$to"
  return 0
}
rename_dir "$OLD" "$NEW"
rename_dir "include/$OLD" "include/$NEW"

echo "Done."
if [[ $DRY_RUN -eq 0 ]]; then
  echo
  echo "Next steps:"
  echo "  - From the workspace root, remove old build artifacts: rm -rf build/$OLD install/$OLD"
  echo "  - Rebuild: colcon build --packages-select $NEW"
  if [[ "$(basename "$PKG_DIR")" == "$OLD" ]]; then
    echo "  - Optionally rename this folder too: mv $PKG_DIR $(dirname "$PKG_DIR")/$NEW"
  fi
fi
