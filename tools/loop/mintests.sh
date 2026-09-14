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
# **빨갈 때는 거른 것을 도로 보여준다.** `check.sh tests` 는 단위 검사 뒤에 실측
# 게이트(MOVE·VIEW·FACE·WORLD·COLLIDE·CAMERA·DRAW)를 부르는데, 위 grep 이 그 줄을
# 버려서 「TESTS 66 passed, 0 failed 인데 빨강」이라는 증거가 나온 적이 있다.
if [ "$rc" -ne 0 ]; then
  echo "테스트가 빨갛다 — 아래가 그 자리다"
  printf '%s\n' "$out" | grep -vE '^\s*ok\s' | tail -12
  exit 1
fi
n="$(printf '%s' "$out" | sed -n 's/^TESTS \([0-9]*\) passed.*/\1/p' | tail -1)"
[ -z "$n" ] && { echo "테스트 개수를 못 읽었다"; exit 1; }
if [ "$n" -lt "$MIN" ]; then
  echo "테스트가 줄었다 — 잰 값 ${n}개 · 바닥 ${MIN}개"
  exit 1
fi
echo "TESTCOUNT ${n} ≥ ${MIN}"
