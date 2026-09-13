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

set -m
"$GODOT" "$@" &
pid=$!
# 감시자의 stdio 를 끊는다 — 안 끊으면 파이프를 붙잡아서 $(...) 가 안 끝난다.
( sleep "$SECS"; kill -TERM -"$pid"; sleep 2; kill -KILL -"$pid" ) >/dev/null 2>&1 &
watcher=$!
wait "$pid"; rc=$?
kill "$watcher" >/dev/null 2>&1 || true
wait "$watcher" 2>/dev/null || true
exit "$rc"
