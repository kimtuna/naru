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
    # **도는 동안 잠자기를 막는다.** 배터리로 바뀌면 macOS 가 1분 만에 재우고(pmset sleep 1)
    # 그러면 세션이 한가운데서 얼어붙는다. `pmset` 으로 설정을 영구히 바꾸지 않는다 —
    # 배터리 수명과 평소 쓰임을 건드릴 일이 아니다. **루프가 끝나면 저절로 풀린다.**
    # 뚜껑을 닫는 잠자기는 이걸로도 못 막는다.
    command -v caffeinate >/dev/null && \
      nohup caffeinate -i -w "$(cat "$PIDF")" >/dev/null 2>&1 &
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
    # **해결된 멈춤을 그냥 뱉지 않는다.** 멈춘 뒤에 채점이 다시 돌아 초록이 났으면
    # 그건 지나간 일이다 — 그대로 보여주면 지금 고장 난 것처럼 읽힌다.
    if [ -f "$ROOT/.loop/STOPPED" ]; then
      python3 - "$ROOT" <<'PY'
import json, sys, os
root = sys.argv[1]
raw = open(os.path.join(root, ".loop/STOPPED"), encoding="utf-8").read().strip().splitlines()
when = raw[0].strip() if raw else ""
why = " ".join(x.strip() for x in raw[1:]) or "(사유 없음)"
past = False
try:
    r = json.load(open(os.path.join(root, ".loop/results.json"), encoding="utf-8"))
    ts = r.get("ts", "").replace("T", " ")[:19]
    past = bool(ts and when and ts > when and r.get("all_green"))
except Exception:
    pass
done = any(w in why for w in ("소진", "ALL GREEN", "[ASK]"))
head = ("--- 지난 멈춤 (그 뒤에 다시 초록이 났다) ---" if past
        else "--- 여기서 멈췄다 (시킨 만큼 다 돌았다) ---" if done
        else "--- 멈췄다 — 사람이 볼 것 ---")
print(head); print(when); print(why)
PY
    fi
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
