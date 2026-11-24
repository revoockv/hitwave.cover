#!/usr/bin/env bash
# The quality gate: exactly what CI runs (.github/workflows/ci.yml calls this script), so a local pass means CI
# passes too. Fails on any analyzer info, a failing test or a clean-architecture lint.
#   tool/check.sh
#
# The architecture linter comes from the revoockv-flutter-clean-arch skill at the version pinned in
# tool/clean_arch_skill_version (a release tag), unpacked into .clean-arch/ (ignored by git) and reused while the
# pin stays the same. The tag is taken from the skill installed in ~/.agents/skills when it has it, else from
# GitHub. Updating the skill for this project is one commit that changes the pin (and .clean_arch.toml when a new
# template version is wanted).
#
# To try an unreleased skill, point CLEAN_ARCH_DIR at its folder; the run says that it is not the pinned version:
#   CLEAN_ARCH_DIR=~/.agents/skills/revoockv-flutter-clean-arch tool/check.sh
set -euo pipefail
cd "$(dirname "$0")/.."

readonly pin_file="tool/clean_arch_skill_version"
readonly checkout=".clean-arch"
readonly installed="$HOME/.agents/skills/revoockv-flutter-clean-arch"
readonly github="https://github.com/revoockv/revoockv-flutter-clean-arch"

fail() { echo "✗ $*" >&2; exit 1; }

version="$(tr -d '[:space:]' < "$pin_file")"
[[ -n "$version" ]] || fail "$pin_file is empty: write the skill's release tag there (for example v0.11.1)"

if [[ -n "${CLEAN_ARCH_DIR:-}" ]]; then
  skill="$CLEAN_ARCH_DIR"
  echo "! the linter comes from $skill, not from the pinned $version"
else
  skill="$checkout"
  if [[ "$(cat "$checkout/.pinned-version" 2>/dev/null || true)" != "$version" ]]; then
    rm -rf "$checkout"
    mkdir -p "$checkout"
    if git -C "$installed" rev-parse -q --verify "refs/tags/$version" >/dev/null 2>&1; then
      echo "▸ skill $version from $installed"
      git -C "$installed" archive --format=tar "$version" | tar -x -C "$checkout" \
        || fail "the skill $version could not be taken from $installed"
    else
      echo "▸ skill $version from $github"
      curl -fsSL "$github/archive/refs/tags/$version.tar.gz" | tar -xz --strip-components=1 -C "$checkout" \
        || fail "the skill $version could not be downloaded from $github"
    fi
    echo "$version" > "$checkout/.pinned-version"
  fi
fi
linter="$skill/scripts/dart_clean_arch_linter.py"
[[ -f "$linter" ]] || fail "no architecture linter at $linter"

echo "▸ flutter pub get";   flutter pub get >/dev/null
echo "▸ flutter analyze";   flutter analyze
echo "▸ flutter test";      flutter test --concurrency=1
echo "▸ architecture lint"; python3 "$linter" lib --strict
echo "✓ all checks passed"
