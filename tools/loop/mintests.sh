#!/usr/bin/env bash
# 단위 테스트가 통과하고, **개수가 바닥 아래로 안 내려가는지** 본다.
#
# 왜 개수까지 보나: `check.sh tests` 만으로는 세션이 검사를 지우거나 안 쓰고도
# 초록을 받는다. 바닥은 계약 안에 인자로 박혀 있고 계약은 무장돼 있으므로,
# 세션이 이 숫자를 낮출 수 없다.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIN="${1:-0}"
out="$(bash "$ROOT/tools/loop/check.sh" tests 2>&1)"; rc=$?
printf '%s\n' "$out" | grep -E '^\s*(ok|FAIL)|^TESTS' || true
[ "$rc" -ne 0 ] && { echo "테스트가 빨갛다"; exit 1; }
n="$(printf '%s' "$out" | sed -n 's/^TESTS \([0-9]*\) passed.*/\1/p' | tail -1)"
[ -z "$n" ] && { echo "테스트 개수를 못 읽었다"; exit 1; }
if [ "$n" -lt "$MIN" ]; then
  echo "테스트가 줄었다 — 잰 값 ${n}개 · 바닥 ${MIN}개"
  exit 1
fi
echo "TESTCOUNT ${n} ≥ ${MIN}"
