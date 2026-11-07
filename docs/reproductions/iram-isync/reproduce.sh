#!/usr/bin/env bash
# Uses a local clone of the public Flexe repository; creates a disposable export.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo "Usage: bash reproduce.sh /path/to/flexe-clone" >&2
  exit 2
fi
packet_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
source_repo="$(cd -- "$1" && pwd)"
trial_dir="$(mktemp -d "${TMPDIR:-/tmp}/flexe-regression.XXXXXXXX")"
printf 'Retaining source and logs in %s\n' "$trial_dir"
mkdir "$trial_dir/source"
git -C "$source_repo" archive e2b79fc7a8987b2821f74065e47e70e3e261e45e | tar -x -C "$trial_dir/source"
patch --batch --no-backup-if-mismatch -d "$trial_dir/source" -p1 < "$packet_dir/regression.patch"
cmake -S "$trial_dir/source" -B "$trial_dir/build" -DCMAKE_BUILD_TYPE=Release -DNATIVE_ARCH=OFF -DFLEXE_LTO=OFF -DFLEXE_CCACHE=OFF
cmake --build "$trial_dir/build" --target xtensa-tests --parallel 2
set +e
"$trial_dir/build/xtensa-tests" --quiet iram_isync > "$trial_dir/before.log" 2>&1
before_status=$?
set -e
cat "$trial_dir/before.log"
if [[ $before_status -ne 1 ]] || ! grep -q '  FAIL ' "$trial_dir/before.log"; then
  echo "Expected baseline assertion failure was not reproduced" >&2
  exit 1
fi
patch --batch --no-backup-if-mismatch -d "$trial_dir/source" -p1 < "$packet_dir/source.patch"
cmake --build "$trial_dir/build" --target xtensa-tests --parallel 2
"$trial_dir/build/xtensa-tests" --quiet iram_isync > "$trial_dir/after.log" 2>&1
cat "$trial_dir/after.log"
