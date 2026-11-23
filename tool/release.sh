#!/usr/bin/env bash
# Releases version X.Y.Z of the app from develop; the pushed tag vX.Y.Z makes CI build Android, macOS, Windows,
# Linux and the web and attach them to the GitHub release.
#   tool/release.sh 1.0.2
#
# It stops before changing anything when:
#   - it is not on a clean develop equal to origin/develop;
#   - X.Y.Z is not above the version in pubspec.yaml, or the tag vX.Y.Z exists here or on GitHub;
#   - CI of develop's last commit failed or is still running (when GitHub answers);
#   - tool/check.sh fails (the same checks as CI).
# Then: release/X.Y.Z (version X.Y.Z+<build+1>) → main (--no-ff) + tag vX.Y.Z → develop, and ONE atomic push of
# main, develop and the tag: either all of them reach GitHub or none.
#
# A tag is never moved. When the release run fails, fix it on develop and release the next patch version.
set -euo pipefail
cd "$(dirname "$0")/.."
repo="revoockv/hitwave.cover"
fail() { echo "✗ $*" >&2; exit 1; }

version="${1:-}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "usage: tool/release.sh X.Y.Z"

# 1. Where we are.
[[ "$(git branch --show-current)" == develop ]] || fail "run it on develop"
[[ -z "$(git status --porcelain)" ]] || fail "the working tree is not clean"
git fetch -q --tags origin
[[ "$(git rev-parse develop)" == "$(git rev-parse origin/develop)" ]] \
  || fail "develop differs from origin/develop: push develop, wait for its CI, then release"
git merge-base --is-ancestor origin/main develop || fail "main has commits that develop has not: merge main into develop first"

# 2. The version.
current="$(sed -n 's/^version: \([0-9.]*\)+\([0-9]*\)$/\1/p' pubspec.yaml)"
build="$(sed -n 's/^version: [0-9.]*+\([0-9]*\)$/\1/p' pubspec.yaml)"
[[ -n "$current" && -n "$build" ]] || fail "pubspec.yaml has no 'version: X.Y.Z+N'"
[[ "$(printf '%s\n%s\n' "$current" "$version" | sort -V | tail -n 1)" == "$version" && "$version" != "$current" ]] \
  || fail "$version is not above the current version $current"
git rev-parse -q --verify "refs/tags/v$version" >/dev/null && fail "tag v$version already exists here"
[[ -z "$(git ls-remote --tags origin "refs/tags/v$version")" ]] || fail "tag v$version already exists on GitHub"

# 3. CI of develop's last commit (skipped with a warning when GitHub does not answer, e.g. its rate limit).
sha="$(git rev-parse develop)"
ci="$(curl -fsS "https://api.github.com/repos/$repo/actions/runs?head_sha=$sha&per_page=1" 2>/dev/null \
  | python3 -c 'import json,sys; r=json.load(sys.stdin)["workflow_runs"]; print(f"{r[0][\"status\"]} {r[0][\"conclusion\"]}" if r else "none")' 2>/dev/null || echo unknown)"
case "$ci" in
  "completed success") echo "✓ CI of develop passed" ;;
  "completed "*)       fail "CI of develop failed ($ci): https://github.com/$repo/actions" ;;
  queued*|in_progress*|waiting*|pending*) fail "CI of develop is still running: wait for it, then release" ;;
  *) echo "! CI of develop is unknown ($ci); the local checks decide" ;;
esac

# 4. The same checks as CI.
tool/check.sh

# 5. Branches, tag, one push.
next="$version+$((build + 1))"
git checkout -q -b "release/$version"
sed -i.bak "s/^version: .*/version: $next/" pubspec.yaml && rm pubspec.yaml.bak
git commit -qam "[RELEASE-$version] bump version to $next"
git checkout -q main
git merge -q --ff-only origin/main
git merge -q --no-ff "release/$version" -m "[RELEASE-$version] merge into main"
git tag -a "v$version" -m "v$version"
git checkout -q develop
git merge -q --ff-only main
git push -q --atomic origin main develop "v$version"
echo "✓ v$version pushed: CI builds it and makes the release — https://github.com/$repo/actions"
