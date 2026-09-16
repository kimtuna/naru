#!/bin/bash
# 씬 하나를 PNG 로 찍는다 — 루프 세션이 화면을 봐야 할 때 쓰는 유일한 방법.
#   harness/shot.sh res://ui/hud.tscn .loop/shots/hud.png [프레임=30]
# 사람이 이 맥을 같이 쓴다. 그래서:
#   - 포커스를 뺏지 않는다 (no_focus)       - 마우스가 창을 통과한다 (passthrough)
#   - 화면 구석에 잠깐 뜨고 곧 닫힌다       - OS 화면 캡처를 쓰지 않는다 (게임이 스스로 찍는다)
#   - NARU_SHOT=1 — 게임 코드는 이때 실제 커서를 읽지 않는다 (core/input 의 Pointer)
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$ROOT/game"
REAL="${NARU_REAL_GODOT:-$(command -v godot)}"
scene="${1:?씬 경로}"; out="${2:?출력 png}"; frames="${3:-30}"
case "$out" in /*) ;; *) out="$ROOT/$out" ;; esac
mkdir -p "$(dirname "$out")"

LOCK="$ROOT/.loop/shot.lock"
mkdir -p "$ROOT/.loop"
for _ in $(seq 60); do mkdir "$LOCK" 2>/dev/null && break; sleep 1; done
trap 'rm -f "$GAME/override.cfg"; rm -rf "$LOCK"' EXIT

# 창이 만들어지기 전에 걸어야 하는 설정은 override.cfg 로 (끝나면 지운다)
cat > "$GAME/override.cfg" <<CFG
[display]
window/size/no_focus=true
window/size/borderless=true
window/size/always_on_top=false
CFG

NARU_SHOT=1 NARU_ALLOW_WINDOW=1 "$REAL" --path "$GAME" --position 100000,100000 \
  -s "$ROOT/harness/shot_runner.gd" -- "$scene" "$out" "$frames" 2>&1 | grep -E '^shot:|ERROR' 
[ -s "$out" ] || { echo "shot: 실패 — PNG 가 안 생김" >&2; exit 1; }
