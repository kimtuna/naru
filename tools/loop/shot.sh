#!/usr/bin/env bash
# 게임 화면을 PNG 로 굽고, **비어 있지 않은지** 잰다.
#
# 사용법: shot.sh <출력.png> [씬] [대기프레임] [--max-flat <퍼센트>]
#
# **몇 시에 굽나** (회차 31): `NARU_SHOT_NOW=<게임초>` 로 시각을 고른다.
#   NARU_SHOT_NOW=600 tools/loop/shot.sh /tmp/night.png    # 한밤 (하루 1200초의 절반)
# 안 주면 한낮이다. 이게 없으면 밤 화면을 보려고 10분을 기다려야 한다.
#
# `--headless` 를 쓰지 않는다 — 헤드리스는 렌더러가 더미라 텍스처가 빈다.
# 창이 잠깐 떴다 사라지는 것은 정상이다.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT="${1:?사용법: shot.sh <출력.png> [씬] [대기프레임] [--max-flat N]}"
SCENE="${2:-res://scenes/main.tscn}"
FRAMES="${3:-10}"
MAXFLAT="100"
[ "${4:-}" = "--max-flat" ] && MAXFLAT="${5:-100}"

rm -f "$OUT"
# `NARU_FOCUS_RESTORE=1`: 창이 포커스를 가져간다 — 끝나고 되돌려 준다 (NUMBERS 11절).
out="$(NARU_FOCUS_RESTORE=1 NARU_SHOT_NOW="${NARU_SHOT_NOW:-}" bash "$ROOT/tools/loop/godot.sh" 40 -- --path "$ROOT" \
        --script res://tools/qa/shot.gd -- "$OUT" "$SCENE" "$FRAMES" 2>&1)"
line="$(printf '%s' "$out" | grep -E '^SHOT' | tail -1)"
[ -z "$line" ] && { printf '%s\n' "$out" | tail -5; echo "SHOT 실패 — 출력이 없다"; exit 1; }
echo "$line"
case "$line" in *ERROR*) exit 1 ;; esac
[ -s "$OUT" ] || { echo "SHOT 실패 — 파일이 비었다"; exit 1; }

flat="$(printf '%s' "$line" | sed -n 's/.*한 색 \([0-9.]*\)%.*/\1/p')"
if [ -n "$flat" ]; then
  over="$(python3 -c "print(1 if float('$flat') > float('$MAXFLAT') else 0)")"
  [ "$over" = "1" ] && { echo "화면이 거의 단색이다 — 잰 값 ${flat}% · 상한 ${MAXFLAT}%"; exit 1; }
fi

exit 0   # 위 `[ ... ] && { ... }` 가 마지막 문장이면 그 판정 결과가 곧 종료 코드가 된다.
