#!/usr/bin/env bash
# Runs the whole suite. Usage, from the repo root:  ./tests/run.sh
# .github/workflows/tests.yml runs it on every push to main, every pull request and before a release.
set -u

LUA=${LUA:-"/c/Program Files (x86)/Lua/5.1/lua.exe"}
LUAC=${LUAC:-"/c/Program Files (x86)/Lua/5.1/luac.exe"}
ROOT=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT" || exit 1

fail=0

# luac -p compiles without running: a cheap syntax gate over every addon Lua file.
# Third-party Libs/ is excluded.
echo "-- syntax --"
while IFS= read -r -d '' f; do
    if ! "$LUAC" -p "$f"; then
        echo "  syntax error in $f"; fail=1
    fi
done < <(git ls-files -z -- '*.lua' ':(exclude)Libs/**')
[ "$fail" -eq 0 ] && echo "  OK"

echo "-- tests --"
"$LUA" tests/run_tests.lua || fail=1

exit $fail
