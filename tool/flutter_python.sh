#!/usr/bin/env bash
# Packages the embedded Python app for one platform, then runs flutter with the same environment.
#   tool/flutter_python.sh <android|ios|macos|windows|linux> <flutter arguments…>
#   tool/flutter_python.sh android run -d emulator-5554
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:?usage: flutter_python.sh <android|ios|macos|windows|linux> <flutter arguments…>}"
shift

case "$target" in
  android) platform=Android ;;
  ios) platform=iOS ;;
  macos) platform=Darwin ;;
  windows) platform=Windows ;;
  linux) platform=Linux ;;
  *) echo "✗ unknown platform: $target" >&2; exit 2 ;;
esac

# The CPython line bundled by serious_python; numpy/scipy in requirements.txt are pinned for it.
export SERIOUS_PYTHON_VERSION="${SERIOUS_PYTHON_VERSION:-3.14}"
export SERIOUS_PYTHON_SITE_PACKAGES="$root/build/python/$target/site-packages"
export SERIOUS_PYTHON_APP="$root/build/python/$target/app"
if [[ "$platform" == iOS ]]; then
  bundle_id="$(grep 'PRODUCT_BUNDLE_IDENTIFIER = ' "$root/ios/Runner.xcodeproj/project.pbxproj" \
    | grep -v RunnerTests | head -1 | sed 's/.*= \(.*\);/\1/')"
  export SERIOUS_PYTHON_BUNDLE_ID="${SERIOUS_PYTHON_BUNDLE_ID:-$bundle_id}"
fi

cd "$root"
dart run serious_python:main package python/app -p "$platform" \
  -r -r -r python/requirements.txt \
  --cleanup
exec flutter "$@"
