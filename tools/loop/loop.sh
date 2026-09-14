#!/usr/bin/env bash
# 드라이버 — 무인으로 회차를 돈다.
#
#   백로그 한 줄 뽑기 → 세션 열기 → 상태 검사 실행 → 초록이면 다음 → 정지 규칙에 걸리면 멈춘다
#
# 세션에게 「검사를 약하게 하지 마세요」라고 부탁하지 않는다. 구조로 막는다:
#   · 상태 검사는 해시로 잠겨 있고, 고치면 exit 77 로 죽는다
#   · 판정은 세션이 아니라 run-contract.sh 가 한다
#   · 사람만 답할 수 있는 항목([ASK])은 **세션을 아예 열지 않는다**
#
# 사용법: loop.sh [--dry-run] [회차수]
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
next_item() { grep -n -m1 '^- \[ \] ' docs/BACKLOG.md || true; }

# 항목 줄에서 설명과 verify 명령을 가른다.
desc_of()   { printf '%s' "${1%%| verify:*}" | sed 's/^- \[[ x]\] *//; s/[[:space:]]*$//'; }
verify_of() {
  local v="${1#*| verify:}"
  [ "$v" = "$1" ] && { printf ''; return; }
  printf '%s' "$v" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^`//; s/`$//'
}

# **항목은 여러 줄일 수 있다.** `next_item` 은 한 줄만 뽑으므로 `| verify:` 가 이어지는
# 줄에 있으면 못 본다 — 그러면 **verify 없는 회차**가 되고 기준 승격도 조용히 건너뛴다.
# 「항목을 진짜로 했나」를 아무도 안 묻는 회차다. 회차 22 항목이 바로 그 모양이었다.
verify_in_block() {                       # verify_in_block <백로그 줄번호>
  awk -v s="$1" 'NR<s {next} NR>s && (/^- \[[ x]\] /||/^#/) {exit} {print}' docs/BACKLOG.md \
    | grep -o '| verify:.*' | head -1 \
    | sed 's/^| verify:[[:space:]]*//; s/[[:space:]]*$//; s/^`//; s/`$//'
}

# ── 초록으로 끝난 항목의 verify 를 상태 검사에 영구 기준으로 승격한다 ──────
#
# **이게 없으면 항목 일을 하나도 안 해도 초록이 나온다** — 상태 검사가
# import/parse/tests 셋뿐이라 그 항목과 무관하게 통과하기 때문이다.
# 승격한 뒤 다시 무장하므로 세션은 그 기준을 건드릴 수 없고,
# 다음 회차부터 회귀도 자동으로 잡힌다.
promote() {                               # promote <설명> <verify 명령>
  [ "$DRY" = "1" ] && return 0
  local d="$1" v="$2"
  [ -z "$v" ] && return 0
  # **재귀 차단.** 상태 검사 자신을 부르는 verify 를 기준으로 올리면 무한히 겹쳐 돈다
  # (redteam.sh 는 상태 검사를 6번 부른다).
  case "$v" in
    *run-contract*|*redteam*|*loop.sh*) say "기준 승격 건너뜀 (상태 검사를 다시 부른다): $v"; return 0 ;;
  esac
  grep -qF "	$v" .loop/criteria.tsv && return 0     # 이미 있다
  local id
  id="$(( $(grep -cv '^[[:space:]]*#' .loop/criteria.tsv) + 1 ))"
  printf '%s\t%s\t%s\n' "$id" "$d" "$v" >> .loop/criteria.tsv
  bash tools/loop/arm-contract.sh >/dev/null
  git add .loop/criteria.tsv .loop/armed.sha256
  git -c user.name=loop -c user.email=loop@local commit -q \
    -m "상태 검사에 기준 $id 추가 — $d" || true
  say "기준 $id 승격: $v"
}

# ── 테스트 개수 바닥을 지금 개수로 올린다 ────────────────────────────
#
# 상태 검사 안에 인자로 박혀 있고 상태 검사는 무장돼 있으므로 세션이 못 낮춘다.
# 다음 회차에 검사를 지우면 그 자리에서 빨개진다.
bump_mintests() {
  [ "$DRY" = "1" ] && return 0
  local now cur
  # `unit` 이다 — 여기서 필요한 건 개수 한 줄뿐인데 `tests` 는 실측 7종을 달고 온다.
  now="$(bash tools/loop/check.sh unit 2>&1 | sed -n 's/^TESTS \([0-9]*\) passed.*/\1/p' | tail -1)"
  [ -z "$now" ] && return 0
  cur="$(sed -n 's/.*mintests\.sh \([0-9]*\).*/\1/p' .loop/criteria.tsv | tail -1)"
  [ -z "$cur" ] && return 0
  [ "$now" -le "$cur" ] && return 0
  sed -i '' "s|mintests\.sh $cur|mintests.sh $now|" .loop/criteria.tsv
  bash tools/loop/arm-contract.sh >/dev/null
  git add .loop/criteria.tsv .loop/armed.sha256
  git -c user.name=loop -c user.email=loop@local commit -q \
    -m "테스트 바닥 $cur → $now" || true
  say "테스트 바닥 $cur → $now"
}

# ── 회차 기록을 잘라낸다 ─────────────────────────────────────────────
# state.md 는 회차마다 자란다. 통째로 읽게 두면 회차 비용이 계속 는다
# (1판은 매 회차 읽는 문서가 758+1012+826 줄까지 갔다).
roll_state() {
  [ "$DRY" = "1" ] && return 0
  local out; out="$(python3 tools/loop/state.py roll 3)"
  say "$out"
  if [ -n "$(git status --porcelain .loop/state.md .loop/archive 2>/dev/null)" ]; then
    git add .loop/state.md .loop/archive 2>/dev/null || true
    git -c user.name=loop -c user.email=loop@local commit -q -m "회차 기록 롤링" || true
  fi
}

# ── 일지를 닫고 대시보드를 굽는다 ────────────────────────────────────
#
# 세션은 「문제·원인·고친 것·남긴 것」을 쓰고, 여기서 「날짜·결과·채점·비용·커밋」을 찍는다.
# **줄의 주인을 갈라 놓지 않으면** 세션이 결과 칸에 「됐습니다」를 쓰고, 일지가 증거가
# 아니라 자기 보고가 된다. 채점 칸에는 `results.json` — 채점자가 쓴 것 — 만 들어간다.
finish_journal() {                        # finish_journal <회차> <항목> <결과> <커밋>
  [ "$DRY" = "1" ] && return 0
  # 찍히는 커밋은 **항목을 만든 커밋**이다. 이 함수는 roll_state 뒤에 도는데
  # 그 사이 부기 커밋(기준 승격 · 바닥 올림 · 롤링)이 끼면 그게 찍힌다.
  bash tools/loop/journal.sh stamp "$1" "$2" "$3" "${4:-$(git rev-parse --short HEAD)}" | sed 's/^/    /'
  # **대시보드가 안 구워지면 멈춘다.** 바깥에서 볼 수 있는 유일한 창인데
  # 조용히 실패하면 페이지가 낡은 채로 며칠을 간다 — 실제로 문법 하나가 깨져서 그랬다.
  if ! python3 tools/loop/report.py | sed 's/^/    /'; then
    stop "대시보드를 못 구웠다 — tools/loop/report.py (회차 $1)"
  fi
  if [ -n "$(git status --porcelain docs/JOURNAL.md docs/index.html 2>/dev/null)" ]; then
    git add docs/JOURNAL.md docs/index.html docs/.nojekyll 2>/dev/null || true
    git -c user.name=loop -c user.email=loop@local commit -q \
      -m "회차 $1 일지 · 대시보드 갱신" || true
  fi
}

# ── 초록으로 닫힌 회차만 바깥으로 내보낸다 ──────────────────────────
#
# **빨간 것은 안 나간다.** 상태 검사도 항목 verify 도 일지도 다 통과한 뒤에만 부른다.
# 대시보드가 GitHub Pages 라, 커밋만 하고 안 밀면 페이지가 낡은 채로 남는다.
# 푸시가 실패해도 루프는 계속 돈다 — 네트워크는 이 루프의 판정 대상이 아니다.
push_state() {
  [ "$DRY" = "1" ] && return 0
  [ "$PUSH" = "0" ] && { say "푸시 꺼짐 (PUSH=0)"; return 0; }
  git remote get-url origin >/dev/null 2>&1 || { say "origin 이 없다 — 푸시 건너뜀"; return 0; }
  if git push -q origin HEAD 2>"$RD/push.err"; then
    say "푸시됨 → $(git remote get-url origin)"
  else
    say "푸시 실패 (로컬은 멀쩡하다):"; tail -3 "$RD/push.err" | sed 's/^/    /'
  fi
}

# ── 회귀 감지: 지난번 초록이던 기준이 지금 빨강인가 ─────────────────
# **항목의 verify 가 상태 검사를 다시 부를 수 있다** — `redteam.sh` 는 30번 부른다.
# 그러면 `.loop/results.json` 이 verify 안쪽의 마지막 판으로 덮여서, 회귀 감지가
# 「상태 검사가 깬 것」이 아니라 「대조군이 일부러 깬 것」을 보고 멈춘다. 실제로 그랬다.
# 그래서 채점 직후의 판본을 따로 떠 두고 그것과 비교한다.
regressed() {
  [ -f "$PREV" ] || return 1
  [ -f "${GRADED:-}" ] || return 1
  python3 - "$PREV" "$GRADED" <<'PY'
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
  say "───────── 회차 $cycle / $MAX_CYCLES ─────────"

  # 1) 워킹트리 — 이전 회차가 안 끝났으면 여기서 멈춘다
  if [ -n "$(git status --porcelain)" ]; then
    git status --short
    stop "워킹트리가 더럽다 — 이전 회차가 커밋 없이 끝났다"
  fi

  # 2) 다음 항목
  line="$(next_item)"
  [ -z "$line" ] && stop "ALL GREEN — 백로그에 미완료 항목이 없다"
  lineno="${line%%:*}"
  item="${line#*:}"
  say "항목: $item"

  # 3) [ASK] 는 세션을 열지 않는다 — 답을 아는 주체가 세션이 아니다
  case "$item" in
    *"[ASK]"*) stop "[ASK] 항목이다. 사람이 답해야 한다 (docs/BACKLOG.md:$lineno)" ;;
  esac

  # 4) 같은 항목 연속 실패
  if [ "$item" = "$last_item" ] && [ "$fails" -ge "$STUCK_LIMIT" ]; then
    stop "같은 항목이 ${fails}회차 연속 실패했다 — 고치는 게 아니라 찍고 있다"
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

  # 일지의 회차 번호는 **이 실행이 아니라 프로젝트 전체의 몇 번째 회차인가**다.
  # loop.sh 를 다시 부를 때마다 1 로 돌아가면 일지가 겹쳐 쓰인다.
  turn="$(bash tools/loop/journal.sh next)"
  say "일지 회차 $turn"

  # 6) 세션
  # 문맥은 **드라이버가 조립한다** — 세션이 파일을 여는 횟수를 줄이는 것이
  # 회차 비용을 줄이는 가장 큰 자리다. state.md 는 자라므로 꼬리만 넣는다.
  {
    cat docs/PROMPT.md
    printf '\n\n---\n\n## 이번 회차 — 일지 번호 %s (이 실행의 %d/%d)\n\n%s\n' \
      "$turn" "$cycle" "$MAX_CYCLES" "$item"
    printf '\n### 끝나면 일지를 적는다 — **이 답변의 맨 끝에**\n\n'
    printf '**`docs/JOURNAL.md` 를 열지 마라. 쓰지도 마라.** 아래 블록을 **마지막 답변에 그대로** 적으면\n'
    printf '드라이버가 뽑아서 제가 넣는다 (`journal.sh extract`). 회차 12 · 21 은 일을 다 끝내고\n'
    printf '커밋까지 하고도 **옮기는 것만** 빼먹었다 — 그 자리를 없앴다.\n\n'
    printf '```markdown\n## 회차 %s · %s\n' "$turn" "$(desc_of "$item")"
    printf -- '- 문제: <이번 회차에 실제로 막힌 것. 없으면 「없음」>\n'
    printf -- '- 원인: <왜 그랬나. 증상이 아니라 이유>\n'
    printf -- '- 고친 것: <무엇을 어떻게 바꿨나. 파일 이름을 적는다>\n'
    printf -- '- 바꾼 결정: <설계·규칙이 바뀌었으면. 없으면 「없음」>\n'
    printf -- '- 잰 값: <숫자 + 조건>\n'
    printf -- '- 남긴 것: <다음으로 넘긴 것 / 사람이 정할 것. 없으면 「없음」>\n```\n'
    printf '\n`날짜`·`결과`·`채점`·`비용`·`커밋` 은 **드라이버가 찍는다** — 써 보내도 뽑을 때 버려진다.\n'
    printf '`문제`·`원인`·`고친 것`·`남긴 것` 이 비어 있으면 **초록이어도 루프가 멈춘다.**\n'
    printf '막힌 게 없었으면 `문제: 없음` 이라고 적는다 — 빈 회차와 안 적은 회차는 다르다.\n' 
    printf '\n### 최근 회차 (state.md 를 열지 마라 — 이게 전부다)\n\n'
    python3 tools/loop/state.py tail 2
    printf '\n### 지금 상태 검사\n\n```\n'
    grep -v '^[[:space:]]*#' .loop/criteria.tsv | cut -f1,2
    printf '```\n'
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

  # 6b) 일지를 **드라이버가 쓴다.** 세션은 마지막 답변에 블록을 적을 뿐 파일을 안 연다.
  # 회차 12 · 21 은 일을 끝내고 커밋까지 하고도 일지만 빼먹었다 — 둘 다 커밋 메시지에는
  # 다 적혀 있었고 **옮기는 것만** 빠졌다. 파일을 여는 것이 별도의 일이라, 예산이 마르면
  # 제일 먼저 잘리는 자리였다. 여기서는 안 멈춘다 — 빨간 회차의 일지도 받아야 하고,
  # 초록인데 못 뽑았으면 아래 `journal.sh check` 가 어차피 멈춘다.
  if [ "$DRY" = "0" ]; then
    if jx="$(bash tools/loop/journal.sh extract "$turn" "$RD/session.json" 2>&1)"; then
      say "$jx"
    else
      say "일지를 답변에서 못 뽑았다 — $jx"
    fi
  fi

  # 7) 판정 — 세션이 아니라 채점자가 한다
  [ -f "$ROOT/.loop/results.json" ] && cp "$ROOT/.loop/results.json" "$PREV"
  bash tools/loop/run-contract.sh > "$RD/contract.txt" 2>&1
  crc=$?
  sed 's/^/    /' "$RD/contract.txt"
  # 채점 직후의 판본. verify 가 상태 검사를 다시 불러 results.json 을 덮어도 이건 산다.
  GRADED="$RD/results.json"
  cp "$ROOT/.loop/results.json" "$GRADED" 2>/dev/null || true

  # red line — 상태 검사를 고쳐서 통과하려 했다
  [ "$crc" -eq 77 ] && stop "상태 검사가 무장 뒤에 변조됐다 (red line) — 회차 $cycle"
  [ "$crc" -eq 78 ] && stop "상태 검사 파일이 없거나 공허하다 — 회차 $cycle"

  # 7b) 이 항목 자신의 verify 도 돌린다. 상태 검사만으로는 항목을 안 해도 초록이 난다.
  vcmd="$(verify_of "$item")"
  [ -z "$vcmd" ] && vcmd="$(verify_in_block "$lineno")"
  vrc=0
  if [ -n "$vcmd" ]; then
    if ! command -v "${vcmd%% *}" >/dev/null 2>&1; then
      stop "이 항목의 verify 가 명령이 아니다 — 사람이 봐야 한다: $vcmd"
    fi
    say "verify: $vcmd"
    if eval "$vcmd" > "$RD/verify.txt" 2>&1; then
      say "  verify 초록"
    else
      vrc=1; say "  verify 빨강"; tail -5 "$RD/verify.txt" | sed 's/^/      /'
    fi
  fi

  # verify 가 상태 검사를 다시 불렀으면 증거를 채점 시점으로 되돌린다 —
  # 일지의 「채점」과 대시보드가 대조군의 빨강을 물려받으면 안 된다.
  cp "$GRADED" "$ROOT/.loop/results.json" 2>/dev/null || true

  # 회귀
  if reg="$(regressed)"; then
    stop "회귀 — 통과하던 기준이 깨졌다: $reg"
  fi

  head_after="$(git rev-parse HEAD)"
  [ "$vrc" -ne 0 ] && crc=1
  if [ "$crc" -eq 0 ]; then
    if [ "$head_after" = "$head_before" ] && [ "$DRY" = "0" ]; then
      stop "초록인데 세션이 커밋하지 않았다 — 작업이 워킹트리에 떠 있다"
    fi
    say "✔ 초록"
    promote "$(desc_of "$item")" "$vcmd"
    bump_mintests
    roll_state
    finish_journal "$turn" "$item" "초록" "$(git rev-parse --short "$head_after")"
    if [ "$DRY" = "0" ] && ! jmsg="$(bash tools/loop/journal.sh check "$turn")"; then
      stop "초록인데 일지를 안 적었다 — $jmsg (docs/JOURNAL.md 회차 $turn)"
    fi
    push_state
    fails=0
  else
    fails=$((fails+1))
    say "✘ 빨강 (연속 $fails)"
    # 빨간 작업은 역사에 안 남긴다. **일지는 예외다** — 왜 빨갰는지가 제일 비싼 기록이라
    # 되돌리기 전에 빼뒀다가 도로 넣는다.
    jsave="$(mktemp)"; cp docs/JOURNAL.md "$jsave" 2>/dev/null || true
    if [ "$head_after" != "$head_before" ]; then
      say "빨간 상태로 커밋했다. 되돌린다."
      git reset --hard "$head_before" >/dev/null
    fi
    git checkout -- . 2>/dev/null || true
    git clean -fdq -e '.loop/' -e '.godot-home/' 2>/dev/null || true
    [ -s "$jsave" ] && cp "$jsave" docs/JOURNAL.md; rm -f "$jsave"
    finish_journal "$turn" "$item" "빨강" "$(git rev-parse --short HEAD)"
  fi
done

say "───────── 회차 소진 ($MAX_CYCLES) ─────────"
stop "최대 회차 수 $MAX_CYCLES 소진"
