#!/usr/bin/env bash
# 단위 테스트가 통과하고, **개수가 바닥 아래로 안 내려가는지** 본다.
#
# 왜 개수까지 보나: `check.sh` 만으로는 세션이 검사를 지우거나 안 쓰고도
# 초록을 받는다. 바닥은 상태 검사 안에 인자로 박혀 있고 상태 검사는 무장돼 있으므로,
# 세션이 이 숫자를 낮출 수 없다.
#
# **`tests` 가 아니라 `unit` 을 부른다** (회차 12): `tests` 는 뒤에 실측 게이트 7종을
# 달고 있는데 상태 검사 기준 4 가 이미 그걸 부른다 — 둘을 다 돌리면 엔진을 8번 더 띄우고
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

# **바닥은 HEAD 를 따라 올라간다** (회차 18).
#
# 무장된 인자는 드라이버의 `bump_mintests` 가 **회차가 끝난 뒤** 지금 개수로 올린다 —
# 그래서 회차와 회차 사이에는 딱 맞고, **검사를 늘린 그 회차 안에서만 헐겁다.**
# 66 개짜리 바닥에 검사가 75 개면 아홉 개를 지워도 초록이고, 대조군
# 「검사를 지우면 바닥이 잡는다」가 바로 그 창에서 죽는다 (회차 15·17 이 개수를
# 66 에 묶어 둔 이유가 이것이다 — 묶는 대신 창을 닫는다).
#
# 그래서 **커밋된 HEAD 의 검사 개수**를 같이 바닥으로 쓴다. 워킹트리에서 검사가
# 사라지면 무장 인자가 무엇이든 그 자리에서 빨개진다. 커밋으로 내리는 것은
# 여전히 무장된 인자가 막는다 — 이건 그 위에 얹는 층이지 대신이 아니다.
head_n=""
if git -C "$ROOT" rev-parse HEAD >/dev/null 2>&1; then
  head_n=0
  while IFS= read -r p; do
    c="$(git -C "$ROOT" show "HEAD:$p" 2>/dev/null | grep -cE '^func test_')" || c=0
    head_n=$((head_n + c))
  done < <(git -C "$ROOT" ls-tree -r --name-only HEAD -- tools/tests | grep -E '/test_[^/]*\.gd$')
fi
FLOOR="$MIN"
WHY="무장 ${MIN}"
if [ -n "$head_n" ] && [ "$head_n" -gt "$MIN" ]; then
  FLOOR="$head_n"
  WHY="HEAD ${head_n} > 무장 ${MIN}"
fi

if [ "$n" -lt "$FLOOR" ]; then
  echo "테스트가 줄었다 — 잰 값 ${n}개 · 바닥 ${FLOOR}개 (${WHY})"
  exit 1
fi
echo "TESTCOUNT ${n} ≥ ${FLOOR} (${WHY})"
