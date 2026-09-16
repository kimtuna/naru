#!/bin/bash
# 기계 검사 — 게임 코드가 사람의 실제 커서·화면을 직접 읽거나 움직이지 못하게 한다.
# 마우스 위치는 game/core/input/ 의 Pointer 를 통해서만 읽는다 (테스트·캡처 때 흉내 값으로 바뀜).
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
[ -d "$ROOT/game" ] || exit 0
hits=$(grep -rnE 'get_global_mouse_position|get_local_mouse_position|get_mouse_position|mouse_get_position|warp_mouse|screen_get_image|screencapture|cliclick|osascript' \
  --include='*.gd' --include='*.gdshader' --include='*.tscn' "$ROOT/game" \
  | grep -v '/game/addons/' | grep -v '/game/core/input/' | grep -v '/game/tests/')
if [ -n "$hits" ]; then
  echo "guard: 실제 커서·화면에 닿는 코드가 있다. 마우스 위치는 game/core/input/ 의 Pointer 로만 읽어라:"
  echo "$hits" | sed "s|$ROOT/||"
  exit 1
fi
echo "guard: 통과"
