#!/bin/bash
# Builds invertMouseOnly.app and copies it into /Applications.
set -euo pipefail
cd "$(dirname "$0")"

./build.sh
cp -R invertMouseOnly.app /Applications/

echo "Installed /Applications/invertMouseOnly.app"
echo "Launch it with: open /Applications/invertMouseOnly.app"
echo
echo "First launch asks for Accessibility permission — see README.md."
