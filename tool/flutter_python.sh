#!/usr/bin/env bash
# Packages the embedded Python app for one platform, then runs flutter with the same environment.
#   tool/flutter_python.sh <android|ios|macos|windows|linux> <flutter arguments…>
#   tool/flutter_python.sh android run -d emulator-5554
# On Android a plain `flutter run` (or the IDE) works too: Gradle packages Python when needed.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:?usage: flutter_python.sh <android|ios|macos|windows|linux> <flutter arguments…>}"
shift

"$root/tool/package_python.sh" "$target"

export SERIOUS_PYTHON_VERSION="${SERIOUS_PYTHON_VERSION:-3.14}"
export SERIOUS_PYTHON_SITE_PACKAGES="$root/build/python/$target/site-packages"
export SERIOUS_PYTHON_APP="$root/build/python/$target/app"
if [[ "$target" == ios ]]; then
  bundle_id="$(grep 'PRODUCT_BUNDLE_IDENTIFIER = ' "$root/ios/Runner.xcodeproj/project.pbxproj" \
    | grep -v RunnerTests | head -1 | sed 's/.*= \(.*\);/\1/')"
  export SERIOUS_PYTHON_BUNDLE_ID="${SERIOUS_PYTHON_BUNDLE_ID:-$bundle_id}"
fi

cd "$root"
exec flutter "$@"
