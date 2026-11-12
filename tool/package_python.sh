#!/usr/bin/env bash
# Packages the embedded Python app (python/app + python/requirements.txt) for one platform into
# build/python/<target>/ (and, on iOS/macOS, into the serious_python Swift package).
#   tool/package_python.sh <android|ios|macos|windows|linux> [--force]
# Skips the work when nothing changed since the last packaging, so builds can call it every time:
# tool/flutter_python.sh, the Android Gradle settings and the Xcode scheme pre-actions do.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:?usage: package_python.sh <android|ios|macos|windows|linux> [--force]}"
force="${2:-}"

case "$target" in
  android) platform=Android ;;
  ios) platform=iOS ;;
  macos) platform=Darwin ;;
  windows) platform=Windows ;;
  linux) platform=Linux ;;
  *) echo "✗ unknown platform: $target" >&2; exit 2 ;;
esac

# Xcode and Gradle start this with a bare PATH: find dart through Flutter when needed.
if ! command -v dart >/dev/null 2>&1; then
  flutter_root="${FLUTTER_ROOT:-$(cd "$(dirname "$(command -v flutter 2>/dev/null || echo /nonexistent/x)")/.." 2>/dev/null && pwd || true)}"
  [[ -n "$flutter_root" && -x "$flutter_root/bin/dart" ]] && export PATH="$flutter_root/bin:$PATH"
fi

# The CPython line bundled by serious_python; numpy/scipy in requirements.txt are pinned for it.
export SERIOUS_PYTHON_VERSION="${SERIOUS_PYTHON_VERSION:-3.14}"
export SERIOUS_PYTHON_SITE_PACKAGES="$root/build/python/$target/site-packages"
export SERIOUS_PYTHON_APP="$root/build/python/$target/app"
if [[ "$platform" == iOS ]]; then
  bundle_id="$(grep 'PRODUCT_BUNDLE_IDENTIFIER = ' "$root/ios/Runner.xcodeproj/project.pbxproj" \
    | grep -v RunnerTests | head -1 | sed 's/.*= \(.*\);/\1/')"
  export SERIOUS_PYTHON_BUNDLE_ID="${SERIOUS_PYTHON_BUNDLE_ID:-$bundle_id}"
fi

# Up to date: packaged after the last change of the Python sources, and the result still there
# (for iOS/macOS inside the serious_python package of the pub cache, which can be cleared).
stamp="$root/build/python/$target/.packaged"
staged="$SERIOUS_PYTHON_APP/main.py"
if [[ "$platform" == iOS || "$platform" == Darwin ]]; then
  package_dir="$(grep -o '"rootUri": *"[^"]*serious_python_darwin[^"]*"' "$root/.dart_tool/package_config.json" \
    | head -1 | sed 's/.*"file:\/\/\([^"]*\)"/\1/')"
  staged="$package_dir/darwin/serious_python_darwin/Sources/serious_python_darwin/Resources/app/main.py"
fi
if [[ "$force" != --force && -f "$stamp" && -f "$staged" \
      && -z "$(find "$root/python" -newer "$stamp" -print -quit)" ]]; then
  exit 0
fi

cd "$root"
dart run serious_python:main package python/app -p "$platform" \
  -r -r -r python/requirements.txt \
  --cleanup >&2
touch "$stamp"
