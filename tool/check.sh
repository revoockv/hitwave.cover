#!/usr/bin/env bash
# The quality gate: exactly what CI runs (.github/workflows/ci.yml calls this script), so a local pass means CI
# passes too. Fails on any analyzer info, a failing test or a clean-architecture lint.
#   tool/check.sh
# The linter comes from the revoockv-flutter-clean-arch skill: .clean-arch/ (the CI checkout), else the skill
# installed in ~/.agents/skills, else $CLEAN_ARCH_DIR.
set -euo pipefail
cd "$(dirname "$0")/.."

linter=""
for dir in "${CLEAN_ARCH_DIR:-}" .clean-arch "$HOME/.agents/skills/revoockv-flutter-clean-arch"; do
  if [[ -n "$dir" && -f "$dir/scripts/dart_clean_arch_linter.py" ]]; then linter="$dir/scripts/dart_clean_arch_linter.py"; break; fi
done
[[ -n "$linter" ]] || { echo "the clean-architecture linter is missing: install revoockv-flutter-clean-arch or set CLEAN_ARCH_DIR" >&2; exit 1; }

echo "▸ flutter pub get";   flutter pub get >/dev/null
echo "▸ flutter analyze";   flutter analyze
echo "▸ flutter test";      flutter test --concurrency=1
echo "▸ architecture lint"; python3 "$linter" lib --strict
echo "✓ all checks passed"
