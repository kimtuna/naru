#!/usr/bin/env bash
# 드라이버 — 무인으로 바퀴를 돈다.
#
#   백로그 한 줄 뽑기 → 세션 열기 → 계약 실행 → 초록이면 다음 → 정지 규칙에 걸리면 멈춘다
#
# 세션에게 「검사를 약하게 하지 마세요」라고 부탁하지 않는다. 구조로 막는다:
#   · 계약은 해시로 잠겨 있고, 고치면 exit 77 로 죽는다
#   · 판정은 세션이 아니라 run-contract.sh 가 한다
#   · 사람만 답할 수 있는 항목([ASK])은 **세션을 아예 열지 않는다**
#
# 사용법: loop.sh [--dry-run] [바퀴수]
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
. tools/loop/env.sh

DRY=0
[ "${1:-}" = "--dry-run" ] && { DRY=1; shift; }
[ -n "${1:-}" ] && MAX_CYCLES="$1"

RUNS="$ROOT/.loop/runs"; mkdir -p "$RUNS"
SPEND="$ROOT/.loop/spend.txt"; [ -f "$SPEND" ] || echo 0 > "$SPEND"
STOPPED="$ROOT/.loop/STOPPED"; rm -f "$STOPPED"
PREV="$ROOT/.loop/results.prev.json"

say() { printf '%s  %s\n' "$(date '+%H:%M:%S')" "$*"; }
stop() {                                  # stop <사유>
  printf '%s\n%s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" > "$STOPPED"
  say "■ 멈춤 — $1"
  exit 0
}

# ── 백로그에서 다음 미완료 항목 한 줄 ──────────────────────────────
next_item() { grep -n -m1 '^- \[ \] ' BACKLOG.md || true; }

# ── 회귀 감지: 지난번 초록이던 기준이 지금 빨강인가 ─────────────────
regressed() {
  [ -f "$PREV" ] || return 1
  python3 - "$PREV" "$ROOT/.loop/results.json" <<'PY'
import json, sys
try:
    old = {c["id"]: c["ok"] for c in json.load(open(sys.argv[1]))["criteria"]}
    new = {c["id"]: c["ok"] for c in json.load(open(sys.argv[2]))["criteria"]}
except Exception:
    sys.exit(1)
bad = [i for i, ok in old.items() if ok and not new.get(i, True)]
if bad:
    print(",".join(bad)); sys.exit(0)
sys.exit(1)
PY
}

cycle=0
last_item=""
fails=0

while [ "$cycle" -lt "$MAX_CYCLES" ]; do
  cycle=$((cycle+1))
  say "───────── 바퀴 $cycle / $MAX_CYCLES ─────────"

  # 1) 워킹트리 — 이전 바퀴가 안 끝났으면 여기서 멈춘다
  if [ -n "$(git status --porcelain)" ]; then
    git status --short
    stop "워킹트리가 더럽다 — 이전 바퀴가 커밋 없이 끝났다"
  fi

  # 2) 다음 항목
  line="$(next_item)"
  [ -z "$line" ] && stop "ALL GREEN — 백로그에 미완료 항목이 없다"
  lineno="${line%%:*}"
  item="${line#*:}"
  say "항목: $item"

  # 3) [ASK] 는 세션을 열지 않는다 — 답을 아는 주체가 세션이 아니다
  case "$item" in
    *"[ASK]"*) stop "[ASK] 항목이다. 사람이 답해야 한다 (BACKLOG.md:$lineno)" ;;
  esac

  # 4) 같은 항목 연속 실패
  if [ "$item" = "$last_item" ] && [ "$fails" -ge "$STUCK_LIMIT" ]; then
    stop "같은 항목이 ${fails}바퀴 연속 실패했다 — 고치는 게 아니라 찍고 있다"
  fi
  [ "$item" != "$last_item" ] && fails=0
  last_item="$item"

  # 5) 예산
  spent="$(cat "$SPEND")"
  over="$(python3 -c "print(1 if float('$spent') >= float('$BUDGET_USD') else 0)")"
  [ "$over" = "1" ] && stop "누적 비용 \$$spent 이 상한 \$$BUDGET_USD 을 넘었다"
  say "누적 비용 \$$spent / \$$BUDGET_USD"

  RD="$RUNS/$(printf '%03d' "$cycle")"; mkdir -p "$RD"
  head_before="$(git rev-parse HEAD)"

  # 6) 세션
  {
    cat PROMPT.md
    printf '\n\n---\n\n## 이번 바퀴 (%d/%d)\n\n%s\n\n' "$cycle" "$MAX_CYCLES" "$item"
    printf '위 항목 **하나만** 만든다. 끝나면 BACKLOG.md 의 그 줄을 `- [x]` 로 바꾸고,\n'
    printf '`.loop/state.md` 에 잰 값과 함께 적고, 경로를 지정해서 커밋한다.\n'
  } > "$RD/prompt.txt"

  if [ "$DRY" = "1" ]; then
    say "(dry-run) 세션을 열지 않는다 → $RD/prompt.txt"
    printf '{"total_cost_usd":0,"dry_run":true}\n' > "$RD/session.json"
  else
    say "세션 시작 (상한 ${SESSION_TIMEOUT}초)"
    ARGS=(--print --permission-mode bypassPermissions --output-format json)
    [ -n "$MODEL" ] && ARGS+=(--model "$MODEL")
    bash tools/loop/withtimeout.sh "$SESSION_TIMEOUT" -- \
      claude "${ARGS[@]}" "$(cat "$RD/prompt.txt")" \
      > "$RD/session.json" 2> "$RD/session.err"
    src=$?
    cost="$(python3 -c "
import json,sys
try: print(json.load(open('$RD/session.json')).get('total_cost_usd') or 0)
except Exception: print(0)")"
    python3 -c "
s=float(open('$SPEND').read().strip() or 0); print(round(s+float('$cost'),4))" > "$SPEND.tmp"
    mv "$SPEND.tmp" "$SPEND"
    say "세션 끝 (exit $src · 이번 \$$cost · 누적 \$$(cat "$SPEND"))"
    if [ "$src" -ne 0 ]; then
      say "세션이 비정상 종료했다:"; tail -5 "$RD/session.err" | sed 's/^/    /'
    fi
  fi

  # 7) 판정 — 세션이 아니라 채점자가 한다
  [ -f "$ROOT/.loop/results.json" ] && cp "$ROOT/.loop/results.json" "$PREV"
  bash tools/loop/run-contract.sh > "$RD/contract.txt" 2>&1
  crc=$?
  sed 's/^/    /' "$RD/contract.txt"
  cp "$ROOT/.loop/results.json" "$RD/results.json" 2>/dev/null || true

  # red line — 계약을 고쳐서 통과하려 했다
  [ "$crc" -eq 77 ] && stop "계약이 무장 뒤에 변조됐다 (red line) — 바퀴 $cycle"
  [ "$crc" -eq 78 ] && stop "계약 파일이 없거나 공허하다 — 바퀴 $cycle"

  # 회귀
  if reg="$(regressed)"; then
    stop "회귀 — 통과하던 기준이 깨졌다: $reg"
  fi

  head_after="$(git rev-parse HEAD)"
  if [ "$crc" -eq 0 ]; then
    if [ "$head_after" = "$head_before" ] && [ "$DRY" = "0" ]; then
      stop "초록인데 세션이 커밋하지 않았다 — 작업이 워킹트리에 떠 있다"
    fi
    say "✔ 초록"
    fails=0
  else
    fails=$((fails+1))
    say "✘ 빨강 (연속 $fails)"
    # 초록이 아닌데 커밋했으면 되돌린다 — 빨간 것을 역사에 남기지 않는다
    if [ "$head_after" != "$head_before" ]; then
      say "빨간 상태로 커밋했다. 되돌린다."
      git reset --hard "$head_before" >/dev/null
    fi
    git checkout -- . 2>/dev/null || true
    git clean -fdq -e '.loop/' -e '.godot-home/' 2>/dev/null || true
  fi
done

say "───────── 바퀴 소진 ($MAX_CYCLES) ─────────"
stop "최대 바퀴 수 $MAX_CYCLES 소진"
