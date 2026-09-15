#!/usr/bin/env bash
# 루프를 백그라운드로 켜고 끄고 본다.
#   ctl.sh start [회차수] | stop | status | report | logs
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
PIDF="$ROOT/.loop/loop.pid"; LOG="$ROOT/.loop/loop.log"

# ── 도는 루프를 찾는다 ───────────────────────────────────────────────
#
# **pid 파일 하나만 믿으면 안 된다** (2026-09-15 회차 39 에 실측). `loop.sh` 는
# **제 사본을 임시 폴더에 만들어 거기서 돈다**(`loop.sh:21` — 도는 파일과 고치는
# 파일을 가르려고 회차 28 이 넣었다). 그래서 실제로 도는 프로세스는
# `ctl.sh start` 가 적어 둔 `$!` 가 **아니다**: 부모가 1 이고 프로세스 그룹도 다르다.
#
#   4151  ← start 가 pid 파일에 적은 것 (곧 사라진다)
#   4161  ppid 1  pgid 4141   bash /var/.../naru-loop.XXXX 5   ← 진짜 도는 것
#
# 그래서 `stop` 의 `kill -TERM -4151` 이 **아무것도 못 맞혔고**, 그런데도 pid 파일을
# 지워서 그 뒤 `status` 가 **무조건 「안 돌고 있다」고 거짓말**했다. 사람은 세운 줄 알고
# 같은 워킹트리에서 게이트를 돌렸고, 도는 세션과 서로의 파일을 덮었다
# (회차 38 의 `05775ac` · `668b641` 이 그 사고의 기록이다).
#
# **사본을 pgrep 으로 찾는 것이 진실의 출처다.** pid 파일은 거들기만 한다.
loop_pids() { pgrep -f 'naru-loop' 2>/dev/null || true; }
alive() {
  [ -n "$(loop_pids)" ] && return 0
  [ -f "$PIDF" ] && kill -0 "$(cat "$PIDF")" 2>/dev/null
}

case "${1:-status}" in
  start)
    alive && { echo "이미 돌고 있다 (pid $(cat "$PIDF"))"; exit 0; }
    rm -f "$ROOT/.loop/STOPPED"
    nohup bash tools/loop/loop.sh "${2:-}" >>"$LOG" 2>&1 &
    # **이 pid 는 곧 사라진다** — `loop.sh` 가 제 사본으로 갈아탄다(`loop.sh:21`).
    # 그래서 `alive`·`stop` 은 이 파일이 아니라 `pgrep -f naru-loop` 을 진실로 본다.
    echo $! > "$PIDF"
    # **도는 동안 잠자기를 막는다.** 배터리로 바뀌면 macOS 가 1분 만에 재우고(pmset sleep 1)
    # 그러면 세션이 한가운데서 얼어붙는다. `pmset` 으로 설정을 영구히 바꾸지 않는다 —
    # 배터리 수명과 평소 쓰임을 건드릴 일이 아니다. **루프가 끝나면 저절로 풀린다.**
    # 뚜껑을 닫는 잠자기는 이걸로도 못 막는다.
    # **잠자기 막기는 사본이 뜬 뒤에 건다** (회차 40). 예전엔 pid 파일의 값(`$!`)을
    # `caffeinate -w` 에 줬는데 **그 프로세스는 곧 사라진다** — `loop.sh` 가 제 사본으로
    # 갈아타기 때문이다(`loop.sh:21`). 그래서 caffeinate 가 1초 만에 끝나고
    # **밤새 도는 루프가 잠자기에 그대로 노출됐다.** `stop` 이 엉뚱한 pid 를 죽인 것과
    # 같은 뿌리다. 이제 사본이 뜨기를 기다렸다가 **그것**을 물린다.
    sleep 2
    if ! alive; then
      echo "시작 실패. 로그:"; tail -20 "$LOG"; exit 1
    fi
    _real="$(loop_pids | head -1)"
    if [ -n "$_real" ] && command -v caffeinate >/dev/null; then
      nohup caffeinate -i -w "$_real" >/dev/null 2>&1 &
      echo "잠자기 막기 걸었다 (caffeinate -w $_real)"
    fi
    echo "시작됨 (pid ${_real:-$(cat "$PIDF")}) — ctl.sh logs 로 본다"
    ;;
  stop)
    alive || { echo "안 돌고 있다"; rm -f "$PIDF"; exit 0; }
    # **`.loop/STOPPED` 를 먼저 둔다.** 루프가 `wait_and_retry` 안에서 자고 있으면
    # 30초마다 이 파일을 보고 깨어난다 — 신호만으로는 그 잠을 안 깨운다.
    printf '%s\n%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "ctl.sh stop" > "$ROOT/.loop/STOPPED"
    # **프로세스 그룹은 ps 에서 읽는다.** 사본은 그룹 대표가 아니라서
    # `kill -TERM -<pid>` 로는 안 맞는다.
    for sig in TERM TERM KILL; do
      pids="$(loop_pids)"; [ -z "$pids" ] && break
      for pid in $pids; do
        pgid="$(ps -o pgid= -p "$pid" 2>/dev/null | tr -d ' ')"
        [ -n "$pgid" ] && kill -"$sig" -"$pgid" 2>/dev/null
        kill -"$sig" "$pid" 2>/dev/null
      done
      sleep 3
    done
    # **죽었는지 다시 묻고 나서 pid 파일을 지운다.** 안 죽었는데 지우면 `status` 가
    # 거짓말을 하고, 그게 오늘의 사고였다.
    if [ -n "$(loop_pids)" ]; then
      echo "멈추지 못했다 — 아직 도는 프로세스가 있다:" >&2
      ps -o pid,ppid,pgid,command -p $(loop_pids | tr '\n' ',' | sed 's/,$//') 2>/dev/null >&2
      exit 1
    fi
    rm -f "$PIDF"; echo "멈췄다 (도는 프로세스 없음을 확인했다)"
    ;;
  status)
    if alive; then
      # **pid 파일이 아니라 실제로 도는 프로세스를 보여준다.**
      _p="$(loop_pids | tr '\n' ' ')"; [ -z "$_p" ] && _p="$(cat "$PIDF" 2>/dev/null)"
      echo "● 돌고 있다 (pid $_p)"
    else
      echo "○ 안 돌고 있다"
    fi
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
