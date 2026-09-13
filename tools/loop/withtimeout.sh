#!/usr/bin/env bash
# macOS 에 `timeout` 이 없다. 프로세스 그룹째 죽인다.
# 사용법: withtimeout.sh <초> -- <명령...>
set -uo pipefail
SECS="${1:?사용법: withtimeout.sh <초> -- <명령...>}"; shift
[ "${1:-}" = "--" ] && shift
set -m
"$@" &
pid=$!
( sleep "$SECS"; kill -TERM -"$pid"; sleep 3; kill -KILL -"$pid" ) >/dev/null 2>&1 &
w=$!
wait "$pid"; rc=$?
kill "$w" >/dev/null 2>&1 || true
wait "$w" 2>/dev/null || true
exit "$rc"
