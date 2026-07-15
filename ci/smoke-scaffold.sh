#!/usr/bin/env bash
# Smoke test: executes skills/flutter-project-init/SKILL.md as a script.
#
# The skill document is the single source of truth — this script extracts the
# `flutter pub add` preset commands and the `#### <path>.dart` base-file code
# blocks straight from the markdown, scaffolds a real project with them, runs
# codegen, and gates with the skill's own rule: `flutter analyze` must pass
# with 0 errors (info/warning acceptable). If the document rots (deprecated
# commands, incompatible package majors, missing preset deps), this goes red.
#
# Usage: ci/smoke-scaffold.sh [workdir]
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL="${PLUGIN_ROOT}/skills/flutter-project-init/SKILL.md"
WORK="${1:-$(mktemp -d)}"
APP="${WORK}/smoke_app"

# The skill's boilerplate targets Freezed 3 STABLE, which needs a recent SDK.
# On older SDKs pub silently resolves a broken -dev prerelease of freezed that
# generates nothing — fail fast with a clear message instead.
DART_VER="$(dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1)"
if [[ "$(printf '%s\n' "3.9" "${DART_VER}" | sort -V | head -1)" != "3.9" ]]; then
    echo "ERROR: Dart >=3.9 required for stable Freezed 3 (found ${DART_VER}). Run 'flutter upgrade'." >&2
    exit 1
fi

echo "== Scaffold work dir: ${APP}"
rm -rf "${APP}"
flutter create --project-name smoke_app "${APP}"
cd "${APP}"

echo "== Installing every package declared in the skill's preset block"
# All presets + both state-management options = maximum drift coverage.
grep -E '^flutter pub add ' "${SKILL}" | while IFS= read -r line; do
    cmd="${line%%#*}"                       # strip trailing markdown comment
    cmd="$(echo "${cmd}" | sed 's/[[:space:]]*$//')"
    echo ">> ${cmd}"
    ${cmd}
done

echo "== Writing base files from the skill's '#### <path>' dart blocks"
current=""
in_code=0
while IFS= read -r line; do
    line="${line%$'\r'}"
    if [[ "${line}" =~ ^####[[:space:]]+([A-Za-z0-9_/.-]+\.dart)[[:space:]]*$ ]]; then
        current="${BASH_REMATCH[1]}"
    elif [[ "${line}" == '```dart' && -n "${current}" && ${in_code} -eq 0 ]]; then
        in_code=1
        mkdir -p "lib/$(dirname "${current}")"
        : > "lib/${current}"
    elif [[ "${line}" == '```' && ${in_code} -eq 1 ]]; then
        in_code=0
        echo ">> wrote lib/${current}"
        current=""
    elif [[ ${in_code} -eq 1 ]]; then
        printf '%s\n' "${line}" >> "lib/${current}"
    fi
done < "${SKILL}"

echo "== Code generation (skill step 4.5)"
flutter pub get
dart run build_runner build --delete-conflicting-outputs

echo "== Validation gate (skill step 4.6: 0 errors, info/warning acceptable)"
flutter analyze --no-fatal-infos --no-fatal-warnings

echo "== SMOKE PASSED"
