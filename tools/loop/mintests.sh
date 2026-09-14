#!/usr/bin/env bash
# 단위 테스트가 통과하고, **개수가 바닥 아래로 안 내려가는지** 본다.
#
# 왜 개수까지 보나: `check.sh` 만으로는 세션이 검사를 지우거나 안 쓰고도
# 초록을 받는다. 바닥은 계약 안에 인자로 박혀 있고 계약은 무장돼 있으므로,
# 세션이 이 숫자를 낮출 수 없다.
#
# **`tests` 가 아니라 `unit` 을 부른다** (바퀴 12): `tests` 는 뒤에 실측 게이트 7종을
# 달고 있는데 계약 기준 4 가 이미 그걸 부른다 — 둘을 다 돌리면 엔진을 8번 더 띄우고
# 흔들릴 기회도 두 배가 된다. 실측이 깨지면 기준 4 가 빨개지므로 여기서 볼 것은
# **개수와 단위 검사의 초록**뿐이다.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MIN="${1:-0}"
out="$(bash "$ROOT/tools/loop/check.sh" unit 2>&1)"; rc=$?
printf '%s\n' "$out" | grep -E '^\s*(ok|FAIL)|^TESTS' || true
# **빨갈 때는 거른 것을 도로 보여준다.** 엔진이 죽거나 스크립트가 안 뜨면 위 grep 이
# 아무것도 안 남겨서 「TESTS 줄도 없는데 빨강」이 된다 — 그 자리를 보여준다.
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
