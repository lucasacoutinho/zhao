#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
bend=${BEND:-"$root/.tools/bend/bin/bend"}
export BEND_NO_TELEMETRY=1
mkdir -p .build

# The proof entry imports the laws and library, so all four src modules ship.
if "$bend" src/PROOF.bend --publish > .build/publish.log 2>&1; then
  cat .build/publish.log
else
  cat .build/publish.log >&2
  exit 1
fi
hash=$(sed -n '/^0x[0-9a-f]\{32\}$/p' .build/publish.log)
if [ "${#hash}" -ne 34 ]; then
  printf 'Bend did not return one package hash. See .build/publish.log.\n' >&2
  exit 1
fi

temporary=$(mktemp -d "${TMPDIR:-/tmp}/zhao-hub.XXXXXX")
trap 'rm -r -- "$temporary"' 0
trap 'exit 1' 1 2 15
sed "s|import ../src/zhao.bend as Z|import $hash/zhao.bend as Z|" \
  examples/greet.bend > "$temporary/greet.bend"
actual=$(BEND_LIB="$temporary/lib" "$bend" "$temporary/greet.bend" -- Bendhub --loud)
test "$actual" = 'HELLO, BENDHUB!'
diff -r src "$temporary/lib/$hash"
"$bend" "$temporary/lib/$hash/PROOF.bend"

printf 'import %s/zhao.bend as Z\n' "$hash" > .build/BENDHUB_IMPORT
cat .build/BENDHUB_IMPORT
