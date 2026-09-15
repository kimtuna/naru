#!/usr/bin/env bash
# 사람이 이 기계를 마지막으로 만진 뒤 몇 초 지났나 — **초를 찍는다.**
#
# **왜 있나** (2026-09-15 사람이 말했다): 「테스트가 계속 화면을 차지해서 다른 업무할 때
# 흐름이 끊긴다.」 창을 안 뜨게 하는 길은 **없다** — 회차 13 이 여섯 가지를 재서 전부
# 뺏겼다(NUMBERS 11절: no_focus · 화면 밖 · LSUIElement · open -g · 최소화 전부).
# 화면 밖은 macOS 가 화면 안으로 물리고, 최소화는 프레임버퍼가 단색이 돼서 게이트가 죽는다.
#
# 못 막으니 **때를 고른다.** 창을 가장 많이 여는 것은 대조군 전체 쓸기다 —
# 대조군 116개가 각각 상태 검사를 돌리므로 **창이 100번 넘게** 뜨고 50분이 걸린다.
# 그걸 사람이 자리를 비운 때로 미룬다.
#
# `ioreg` 를 쓰는 이유: `osascript`+System Events 는 **접근성 권한을 물어서** 무인
# 루프가 못 쓴다 (회차 13 이 `focus.sh` 에서 같은 이유로 `lsappinfo` 를 골랐다).
# `HIDIdleTime` 은 나노초다.
#
#   idle.sh              유휴 초를 찍는다
#   idle.sh <초>         그만큼 쉬었으면 exit 0, 아니면 exit 1 (찍기도 한다)
set -uo pipefail

secs="$(ioreg -c IOHIDSystem 2>/dev/null \
  | awk '/HIDIdleTime/ {print int($NF/1000000000); exit}')"

# **못 재면 「사람이 있다」로 본다.** 리눅스에는 IOHIDSystem 이 없다 — 그때 「0초 유휴」로
# 읽어 버리면 사람 앞에서 50분짜리 쓸기가 돌아 버린다. 모르면 미루는 쪽이 싸다.
if [ -z "$secs" ]; then
  echo "IDLE 못 쟀다 (IOHIDSystem 이 없다 — macOS 가 아닌가)"
  exit 1
fi

if [ -z "${1:-}" ]; then
  echo "$secs"
  exit 0
fi

if [ "$secs" -ge "$1" ]; then
  echo "IDLE ${secs}초 쉬었다 (문턱 ${1}초) — 사람이 자리를 비웠다"
  exit 0
fi
echo "IDLE ${secs}초 (문턱 ${1}초) — 사람이 기계를 쓰고 있다"
exit 1
