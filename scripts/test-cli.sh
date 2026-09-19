#!/bin/sh
set -eu

if [ "$#" -gt 1 ]; then
  printf 'usage: %s [bend|native]\n' "$0" >&2
  exit 2
fi
mode=${1:-bend}
case "$mode" in
  bend|native) ;;
  *)
    printf 'unknown mode: %s\n' "$mode" >&2
    exit 2
    ;;
esac

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
package=$(CDPATH= cd "$script_dir/.." && pwd)
cd "$package"

if [ -n "${BEND:-}" ]; then
  bend=$BEND
elif [ -x "$package/.tools/bend/bin/bend" ]; then
  bend=$package/.tools/bend/bin/bend
else
  bend=bend
fi
export BEND_NO_TELEMETRY=1

tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/zhao-cli.XXXXXX")
cleanup() { rm -r -- "$tmp_dir"; }
trap cleanup 0
trap 'exit 1' 1 2 15

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  printf '%s\n' "--- stdout ($run_stdout) ---" >&2
  cat "$run_stdout" >&2
  printf '%s\n' "--- stderr ($run_stderr) ---" >&2
  cat "$run_stderr" >&2
  exit 1
}

run() {
  case_name=$1
  app=$2
  shift 2
  run_stdout=$tmp_dir/$case_name.stdout
  run_stderr=$tmp_dir/$case_name.stderr
  if [ "$mode" = bend ]; then
    if "$bend" "examples/$app.bend" -- "$@" >"$run_stdout" 2>"$run_stderr"; then
      run_status=0
    else
      run_status=$?
    fi
  else
    if ".build/$app" -- "$@" >"$run_stdout" 2>"$run_stderr"; then
      run_status=0
    else
      run_status=$?
    fi
  fi
  case_count=$((case_count + 1))
}

expect_status() {
  if [ "$run_status" -ne "$1" ]; then
    fail "$case_name: expected status $1, got $run_status"
  fi
}

expect_line() {
  expected=$tmp_dir/$case_name.expected
  printf '%s\n' "$2" >"$expected"
  if ! cmp -s "$expected" "$1"; then
    fail "$case_name: output differs from expected"
  fi
}

expect_empty() {
  if [ -s "$1" ]; then
    fail "$case_name: expected empty output"
  fi
}

expect_contains() {
  if ! grep -F "$2" "$1" >/dev/null 2>&1; then
    fail "$case_name: output lacks '$2'"
  fi
}

expect_absent() {
  if grep -F "$1" "$run_stdout" "$run_stderr" >/dev/null 2>&1; then
    fail "$case_name: output contains '$1'"
  fi
}

case_count=0

run greet_success greet
expect_status 0
expect_line "$run_stdout" 'Hello, world!'
expect_empty "$run_stderr"

run greet_unknown greet --definitely-unknown
expect_status 1
expect_empty "$run_stdout"
expect_contains "$run_stderr" "error: unknown option '--definitely-unknown'"

run forge_missing forge pack
expect_status 1
expect_empty "$run_stdout"
expect_contains "$run_stderr" "missing required argument 'input'"

run greet_help greet --help
expect_status 0
expect_contains "$run_stdout" 'Usage: greet'
expect_empty "$run_stderr"
expect_absent 'Hello, '

run greet_version greet --version
expect_status 0
expect_line "$run_stdout" '1.0.0'
expect_empty "$run_stderr"

run forge_success forge pack a b
expect_status 0
expect_line "$run_stdout" 'forge pack: a, b -> dist (zip)'
expect_empty "$run_stderr"

run forge_option_before forge -o build pack a
expect_status 0
expect_line "$run_stdout" 'forge pack: a -> build (zip)'
expect_empty "$run_stderr"

run forge_option_after forge pack -o build a
expect_status 0
expect_line "$run_stdout" 'forge pack: a -> build (zip)'
expect_empty "$run_stderr"

run forge_cache_clear forge cache clear
expect_status 0
expect_line "$run_stdout" 'forge cache clear: cache cleared'
expect_empty "$run_stderr"

run forge_nested_help forge cache clear --help
expect_status 0
expect_contains "$run_stdout" 'Usage: forge cache clear'
expect_empty "$run_stderr"
expect_absent ': cache cleared'

printf 'ok: %s CLI cases (%s mode)\n' "$case_count" "$mode"
