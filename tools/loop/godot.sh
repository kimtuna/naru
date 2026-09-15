#!/usr/bin/env bash
# Godot 의 유일한 입구. 다른 데서 Godot 을 직접 부르지 않는다.
#
# 두 가지를 한다:
#   1. 프로젝트 로컬 격리 — 사용자 홈의 Godot 설정/캐시를 안 건드린다
#   2. 시간 초과 시 프로세스 그룹째 죽인다 — macOS 에 `timeout` 이 없고,
#      `kill $pid` 로는 자식이 남는다
#
# 사용법: godot.sh <초> -- <godot 인자...>
set -uo pipefail

GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ── 격리 (2026-09-13 실측) ────────────────────────────────────────────
# **macOS Godot 은 XDG_* 를 무시한다.** XDG_DATA_HOME 등을 아무리 설정해도
# `~/Library/Application Support/Godot` 에 그대로 쓴다 — 실제로 재서 확인했다
# (.godot-xdg 는 텅 빈 채였고 홈 디렉터리 mtime 이 실행 시각으로 갱신됐다).
# 그래서 **HOME 자체를 프로젝트 안으로 돌린다.** 이건 실측으로 먹는 것을 확인했다:
# user:// 가 .godot-home/Library/... 로 내려가고 홈은 mtime 이 안 바뀐다.
# XDG_* 도 같이 두는 것은 리눅스에서 도는 경우를 위해서다.
export HOME="$ROOT/.godot-home"
export XDG_DATA_HOME="$HOME/data"
export XDG_CONFIG_HOME="$HOME/config"
export XDG_CACHE_HOME="$HOME/cache"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

if [ ! -x "$GODOT" ]; then
  echo "godot.sh: Godot 을 못 찾았다: $GODOT" >&2
  exit 127
fi

SECS="${1:?사용법: godot.sh <초> -- <godot 인자...>}"
shift
[ "${1:-}" = "--" ] && shift

# ── 포커스 되돌리기 (2026-09-14 · 회차 13 실측) ───────────────────────
# **창을 띄우면 macOS 가 Godot 을 무조건 맨 앞으로 올린다.** 막는 길이 없다 —
# `no_focus` 도 화면 밖 위치도 `open -g` 도 전부 뺏겼다 (NUMBERS 11절).
# 못 막으니 **끝나고 되돌려 준다**: 띄우기 직전의 맨 앞 앱을 기억했다가,
# 끝났을 때 맨 앞이 그 앱이 아니면 다시 앞으로 보낸다.
# 안 하면 사람이 매번 손으로 클릭해서 돌아와야 한다 (실측: 끝 앞이 늘 딴 앱이었다).
#
# **게이트만 켠다** (`NARU_FOCUS_RESTORE=1`). 사람이 직접 띄운 창은 안 켠다 —
# 보는 동안 딴 앱으로 옮겼을 수 있는데 그걸 도로 뺏으면 그게 또 도둑질이다.
restore_from=""
if [ "${NARU_FOCUS_RESTORE:-0}" = "1" ] && command -v lsappinfo >/dev/null 2>&1; then
  restore_from="$(lsappinfo info -only bundlepath "$(lsappinfo front)" 2>/dev/null | sed -n 's/.*"LSBundlePath"="\(.*\)"/\1/p')"
fi

# ── **사람이 타이핑하는 동안은 창을 안 띄운다** (회차 40) ─────────────
#
# 사람이 말했다: 「테스트가 자꾸 화면을 차지해서 다른 업무할 때 흐름이 끊긴다.」
# 창을 안 뜨게 하는 길은 **없다** — 회차 13 이 여섯 가지를 재서 전부 뺏겼다
# (NUMBERS 11절). 못 막으니 **때를 고른다.**
#
# **여기가 유일한 목이다.** 창을 띄우는 것은 둘(`check.sh` 의 `measure_window.gd` ·
# `shot.sh` 의 `shot.gd`)인데 둘 다 이 파일을 지난다. 그리고 그 둘만
# `NARU_FOCUS_RESTORE=1` 을 켠다 — **그게 이미 「창이 뜬다」는 표시다.** 헤드리스
# 실행에는 안 켜져 있고, **사람이 직접 띄울 때도 안 켜진다**(회차 13 이 그렇게 갈랐다).
# 그래서 한 군데를 고쳐 네 번을 다 덮는다.
#
# `NARU_WINDOW_WAIT` 는 **루프만 켠다.** 사람이 `godot.sh 5 -- --path .` 로 직접
# 띄울 때 이게 걸리면 방금 키를 누른 사람을 자기 창 앞에서 기다리게 만든다.
#
# **상한이 있어야 한다.** 사람이 한 시간을 내리 타이핑하면 세션이 45분 상한에 걸려
# 통째로 버려진다 — 그게 창 몇 번보다 비싸다. 상한이 지나면 그냥 띄운다.
if [ -n "${NARU_WINDOW_WAIT:-}" ] && [ "${NARU_FOCUS_RESTORE:-0}" = "1" ]; then
  _max="${NARU_WINDOW_WAIT_MAX:-180}"
  _waited=0
  while [ "$_waited" -lt "$_max" ]; do
    bash "$ROOT/tools/loop/idle.sh" "$NARU_WINDOW_WAIT" >/dev/null 2>&1 && break
    sleep 5; _waited=$(( _waited + 5 ))
  done
  if [ "$_waited" -gt 0 ]; then
    echo "GODOT 창을 ${_waited}초 기다렸다 (문턱 ${NARU_WINDOW_WAIT}초 쉼 · 상한 ${_max}초)" >&2
  fi
fi

set -m
"$GODOT" "$@" &
pid=$!
# 감시자의 stdio 를 끊는다 — 안 끊으면 파이프를 붙잡아서 $(...) 가 안 끝난다.
( sleep "$SECS"; kill -TERM -"$pid"; sleep 2; kill -KILL -"$pid" ) >/dev/null 2>&1 &
watcher=$!
wait "$pid"; rc=$?
kill "$watcher" >/dev/null 2>&1 || true
wait "$watcher" 2>/dev/null || true

if [ -n "$restore_from" ] && [ -d "$restore_from" ]; then
  now="$(lsappinfo info -only bundlepath "$(lsappinfo front)" 2>/dev/null | sed -n 's/.*"LSBundlePath"="\(.*\)"/\1/p')"
  [ "$now" != "$restore_from" ] && open "$restore_from" >/dev/null 2>&1
fi

exit "$rc"
