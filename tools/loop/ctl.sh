#!/usr/bin/env bash
# 루프를 백그라운드로 켜고 끄고 본다.
#   ctl.sh start [회차수] | stop | status | report | logs
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
PIDF="$ROOT/.loop/loop.pid"; LOG="$ROOT/.loop/loop.log"

alive() { [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null; }

case "${1:-status}" in
  start)
    alive && { echo "이미 돌고 있다 (pid $(cat "$PIDF"))"; exit 0; }
    rm -f "$ROOT/.loop/STOPPED"
    nohup bash tools/loop/loop.sh "${2:-}" >>"$LOG" 2>&1 &
    echo $! > "$PIDF"
    sleep 1
    alive && echo "시작됨 (pid $(cat "$PIDF")) — ctl.sh logs 로 본다" \
          || { echo "시작 실패. 로그:"; tail -20 "$LOG"; exit 1; }
    ;;
  stop)
    alive || { echo "안 돌고 있다"; exit 0; }
    kill -TERM -"$(cat "$PIDF")" 2>/dev/null || kill "$(cat "$PIDF")" 2>/dev/null
    sleep 1; rm -f "$PIDF"; echo "멈췄다"
    ;;
  status)
    alive && echo "● 돌고 있다 (pid $(cat "$PIDF"))" || echo "○ 안 돌고 있다"
    [ -f "$ROOT/.loop/STOPPED" ] && { echo "--- 멈춘 사유 ---"; cat "$ROOT/.loop/STOPPED"; }
    echo "--- 누적 비용 ---"; cat "$ROOT/.loop/spend.txt" 2>/dev/null || echo 0
    echo "--- 남은 항목 ---"; grep -c '^- \[ \] ' docs/BACKLOG.md
    ;;
  report)
    python3 "$ROOT/tools/loop/report.py"
    echo "열어보기: open docs/index.html"
    ;;
  logs) tail -f "$LOG" ;;
  *) echo "사용법: ctl.sh start [회차수] | stop | status | report | logs" >&2; exit 2 ;;
esac
