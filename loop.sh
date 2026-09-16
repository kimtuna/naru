#!/bin/bash
# 나루 개발 루프.
#   ./loop.sh start    백그라운드로 시작 (맥 잠자기 방지)
#   ./loop.sh stop     멈춤 — 지금 세션을 끊고 대시보드에 「사용자 중지」로 남긴다
#   ./loop.sh status   지금 상태
#   ./loop.sh log      루프 로그 따라 보기
#   ./loop.sh publish  (루프가 멈춰 있을 때) list.md 를 고친 뒤 대시보드만 갱신
#
# 한 회차 = list.md 의 단계 하나.
#   current.md 생성 → 구현 세션(새 claude) → 기계 테스트 → QA 세션(새 claude)
#   → 통과: 커밋 · 체크 / 실패: 피드백을 들고 같은 단계 재시도
# 묶음(## 헤더)은 브랜치 g/<ID> 에서 작업하고 전부 통과해야 main 에 합친다.
# 선택이 필요하거나 막히면 묶음 전체를 decisions.md 로 넘기고 다음 묶음으로 간다.

set -uo pipefail

# start 는 이 파일을 .loop/running.sh 로 복사해서 돌린다 — 도는 중에 loop.sh 가 바뀌어도
# (브랜치 전환 · 수정) bash 가 반쯤 바뀐 파일을 읽지 않게. 그래서 ROOT 는 환경변수로 받는다.
ROOT="${NARU_ROOT:-$(cd "$(dirname "$0")" && pwd)}"
L="$ROOT/.loop"
OUT="$L/out"
PAGES="$L/pages"
PY="python3 $ROOT/harness/naru.py"

STEP_TIMEOUT="${NARU_STEP_TIMEOUT:-5400}"   # 세션 하나 최대 90분
STUCK_AFTER="${NARU_STUCK_AFTER:-9}"         # 이 횟수만큼 실패하면 묶음을 decisions 로 넘긴다
# 사람이 이 맥을 같이 쓴다 — 세션은 화면·마우스·포커스에 닿지 못한다.
#   harness/shims: godot 은 강제 headless, screencapture·cliclick·osascript·open 은 거부
#   --disallowedTools: 같은 명령과 git 쓰기를 도구 단계에서 한 번 더 막는다
#   --strict-mcp-config: 브라우저·컴퓨터 조작 같은 MCP 도구를 싣지 않는다
export NARU_REAL_GODOT="${NARU_REAL_GODOT:-$(command -v godot)}"
SHIM_PATH="$ROOT/harness/shims:$PATH"
DENY=(
  "Bash(screencapture:*)" "Bash(cliclick:*)" "Bash(osascript:*)" "Bash(open:*)"
  "Bash(git commit:*)" "Bash(git push:*)" "Bash(git checkout:*)" "Bash(git switch:*)"
  "Bash(git reset:*)" "Bash(git stash:*)" "Bash(git merge:*)" "Bash(git rebase:*)" "Bash(git clean:*)"
)
MODEL_ARGS=()
[ -n "${NARU_MODEL:-}" ] && MODEL_ARGS=(--model "$NARU_MODEL")

mkdir -p "$L/runs" "$L/data" "$OUT"
cd "$ROOT" || exit 1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$L/loop.log"; }

notify() {  # 맥 알림
  local msg="${1//\"/\'}"
  [ -n "${NARU_NO_NOTIFY:-}" ] || osascript -e "display notification \"$msg\" with title \"나루 루프\" sound name \"Glass\"" >/dev/null 2>&1 || true
  log "알림: $1"
}

kill_tree() {  # 프로세스와 그 자손 전부 (claude 가 띄운 godot 등이 고아로 남지 않게)
  local p
  for p in $(pgrep -P "$1" 2>/dev/null); do kill_tree "$p"; done
  kill "$1" 2>/dev/null
}

alive() { [ -n "${1:-}" ] && kill -0 "$1" 2>/dev/null; }

# ------------------------------------------------------------------ 대시보드

pages_ok() {  # 대시보드 폴더가 진짜 gh-pages 워크트리인가 — 아니면 git 명령이 본 저장소에 닿는다
  [ -e "$PAGES/.git" ] \
    && [ "$(git -C "$PAGES" rev-parse --show-toplevel 2>/dev/null)" = "$(cd "$PAGES" && pwd -P)" ] \
    && [ "$(git -C "$PAGES" branch --show-current)" = "gh-pages" ]
}

pages_init() {
  pages_ok && return 0
  rm -rf "$PAGES"
  git worktree prune
  if git ls-remote --exit-code --heads origin gh-pages >/dev/null 2>&1; then
    git fetch -q origin gh-pages
    git worktree add -q -B gh-pages "$PAGES" origin/gh-pages
  elif git show-ref -q --verify refs/heads/gh-pages; then
    git worktree add -q "$PAGES" gh-pages
  else
    git worktree add -q --orphan -b gh-pages "$PAGES"
  fi
  pages_ok
}

publish() {  # $1 = 커밋 메시지. 실패해도 루프는 계속 간다
  if ! pages_init; then log "대시보드 워크트리를 만들지 못해 푸시를 건너뜀"; return 0; fi
  mkdir -p "$PAGES/data"
  git show main:dashboard/index.html > "$PAGES/index.html" 2>/dev/null \
    || cp "$ROOT/dashboard/index.html" "$PAGES/index.html"
  touch "$PAGES/.nojekyll"
  cp "$L/data/"*.json "$PAGES/data/" 2>/dev/null
  cp "$ROOT/list.md" "$PAGES/data/list.md" 2>/dev/null
  if [ -f "$ROOT/decisions.md" ]; then cp "$ROOT/decisions.md" "$PAGES/data/decisions.md"
  else : > "$PAGES/data/decisions.md"; fi
  git -C "$PAGES" add -A
  git -C "$PAGES" commit -qm "대시보드: $1" >/dev/null || true
  local i
  for i in 1 2 3; do
    git -C "$PAGES" push -q -u origin gh-pages 2>>"$L/loop.log" && return 0
    sleep $((i * 3))
  done
  log "대시보드 푸시 실패"
}

status() { $PY status "$@"; }
event() { $PY event "$@"; }

# ------------------------------------------------------------------ claude 세션

CHILD=""
WD=""
LAST_RUN=""

# $1 = 역할(impl|qa)  $2 = 첫 지시문
# 반환: 0 정상 / 1 실패 / 2 토큰 한도 / 3 시간 초과
run_claude() {
  local role="$1" msg="$2"
  LAST_RUN="$L/runs/$(date +%Y%m%d-%H%M%S)-$role"
  PATH="$SHIM_PATH" claude -p "$msg" --output-format json --dangerously-skip-permissions \
    --strict-mcp-config --disallowedTools "${DENY[@]}" ${MODEL_ARGS[@]+"${MODEL_ARGS[@]}"} \
    > "$LAST_RUN.json" 2> "$LAST_RUN.err" < /dev/null &
  CHILD=$!
  (  # 시간 초과 감시 — 세션이 끝나면 5초 안에 스스로 사라진다
    t=0
    while kill -0 "$CHILD" 2>/dev/null; do
      if [ "$t" -ge "$STEP_TIMEOUT" ]; then touch "$LAST_RUN.timeout"; kill_tree "$CHILD"; break; fi
      sleep 5; t=$((t + 5))
    done
  ) &
  WD=$!
  wait "$CHILD"; local rc=$?
  kill "$WD" 2>/dev/null; wait "$WD" 2>/dev/null
  CHILD=""; WD=""
  [ -f "$LAST_RUN.timeout" ] && return 3
  local is_err; is_err=$($PY get "$LAST_RUN.json" is_error 2>/dev/null)
  if [ "$rc" -ne 0 ] || [ "$is_err" = "true" ]; then
    if grep -Eiq 'usage limit|limit reached|hit your .*limit|rate.?limit|resets? (at )?[0-9]' \
        "$LAST_RUN.json" "$LAST_RUN.err"; then
      return 2
    fi
    # 판정 결과(result)조차 없으면 네트워크·CLI 문제다 — 작업 실패로 세지 않는다
    [ -z "$($PY get "$LAST_RUN.json" result 2>/dev/null)" ] && return 4
    return 1
  fi
  return 0
}

wait_for_tokens() {
  local until hh
  until=$($PY reset-epoch "$LAST_RUN.json" "$LAST_RUN.err")
  hh=$($PY hhmm "$until")
  log "토큰 한도 — $hh 까지 대기"
  status state=waiting reason="토큰 한도 — $hh 에 자동 재개" resume_at="$hh"
  event type=limit title="토큰 한도로 대기" detail="$hh 에 자동으로 다시 시작한다"
  publish "토큰 한도 대기"
  notify "토큰 한도에 걸렸습니다. $hh 에 자동으로 재개합니다."
  pause $(( until - $(date +%s) ))
  log "대기 끝 — 재개"
  status state=running reason="토큰 한도 대기 후 재개" resume_at=""
  event type=resume title="토큰 한도 대기 끝 — 재개"
  publish "재개"
  notify "토큰 한도 대기가 끝나 루프를 재개했습니다."
}

pause() {  # STOP 을 보면서 $1 초 쉰다
  local end=$(( $(date +%s) + $1 ))
  while [ "$(date +%s)" -lt "$end" ]; do
    [ -f "$L/STOP" ] && exit 0
    sleep "${NARU_PAUSE_TICK:-30}" & CHILD=$!; wait "$CHILD"; CHILD=""
  done
}

# 토큰 한도면 기다렸다가, 네트워크·CLI 오류면 잠깐 쉬었다가 같은 세션을 다시 돌린다
run_claude_retry() {
  local rc infra=0
  while true; do
    run_claude "$@"; rc=$?
    case "$rc" in
      2) wait_for_tokens; infra=0 ;;
      4)
        infra=$((infra + 1))
        log "claude 실행 오류 (${infra}회): $(tail -c 300 "$LAST_RUN.err")"
        if [ "$infra" -eq 1 ]; then
          status state=error_wait reason="claude 실행 오류 — 5분마다 다시 시도 중"
          event type=infra title="claude 실행 오류 — 재시도 대기" detail="$(tail -c 500 "$LAST_RUN.err")"
          publish "실행 오류 대기"
          notify "claude 실행 오류. 5분마다 다시 시도합니다. (네트워크/로그인 확인)"
        fi
        pause 300 ;;
      *)
        if [ "$infra" -gt 0 ]; then
          status state=running reason=""
          event type=resume title="claude 실행 오류 해소 — 재개"
        fi
        return "$rc" ;;
    esac
  done
}

# ------------------------------------------------------------------ git

branch_of() { echo "g/$1"; }

enter_group() {  # 묶음 브랜치로 (있으면 이어서)
  local br; br=$(branch_of "$1")
  [ "$(git branch --show-current)" = "$br" ] && return 0
  if git show-ref -q --verify "refs/heads/$br"; then
    git checkout -q "$br"
    git merge -q --no-edit main >/dev/null 2>&1 || git merge --abort 2>/dev/null
  else
    git checkout -q -b "$br" main
  fi
}

reset_to_last_pass() {
  git reset -q --hard
  git clean -qfd
}

finish_group() {  # 전부 통과 → main 에 합친다
  local gid="$1" title="$2" br; br=$(branch_of "$1")
  git checkout -q main
  if ! git merge -q --no-ff -m "$gid $title — 묶음 완료" "$br"; then
    git merge --abort
    git checkout -q "$br"
    return 1
  fi
  git push -q origin main 2>>"$L/loop.log" || log "main 푸시 실패"
  git branch -q -D "$br"
  git push -q origin --delete "$br" 2>/dev/null || true
  $PY mark-group "$gid" x
  event type=group_done group="$gid" title="$gid $title — 묶음 완료, main 에 합침"
  publish "$gid 완료"
  log "$gid 완료"
}

park_group() {  # 묶음 전체를 decisions.md 로
  local gid="$1" title="$2" reason="$3" step="$4" report="$5" extra="${6:--}" br; br=$(branch_of "$1")
  git add -A
  git commit -qm "$gid WIP — 결정 대기 ($reason)" >/dev/null 2>&1 || true
  git push -q -u origin "$br" 2>>"$L/loop.log" || true
  git checkout -q main
  $PY decide "$gid" "$reason" "$step" "$report" "$br" "$extra"
  $PY mark-group "$gid" ">"
  rm -f "$L/attempt-$gid-"*
  event type=parked group="$gid" step="$step" title="$gid $title — 결정 대기로 넘김" detail="$reason" \
    ${report:+--report "$report"}
  publish "$gid 결정 대기"
  notify "$gid 를 결정 대기로 넘겼습니다: $reason"
  log "$gid 넘김: $reason"
}

# ------------------------------------------------------------------ 한 단계

IMPL_MSG='prompt.md 를 읽고 그대로 따르라. 할 일은 current.md 에 있다.'
QA_MSG='qa.md 를 읽고 그대로 따르라. 검사할 일은 current.md 에 있다.'

do_step() {  # $1 gid $2 title $3 step번호 $4 단계제목 $5 단계수
  local gid="$1" title="$2" n="$3" stitle="$4" total="$5"
  local af="$L/attempt-$gid-$n" fb="$OUT/feedback.md"
  local attempt; attempt=$(cat "$af" 2>/dev/null || echo 0)
  [ "$attempt" -eq 0 ] && : > "$fb"

  while true; do
    [ -f "$L/STOP" ] && exit 0
    attempt=$((attempt + 1)); echo "$attempt" > "$af"
    if [ "$attempt" -eq 4 ] || [ "$attempt" -eq 7 ]; then reset_to_last_pass; fi
    $PY current "$gid" "$n" "$attempt" "$fb"
    rm -f "$OUT/report.json" "$OUT/qa.json" "$OUT/test.log"

    local where="$gid $n/$total · $stitle · 시도 $attempt"
    log "구현 시작: $where"
    status state=running reason="" group="$gid" group_title="$title" step="$n" \
      step_total="$total" step_title="$stitle" attempt="$attempt" phase="구현" phase_since="$(date '+%F %T')"
    publish "$where 구현"

    # 1) 구현
    run_claude_retry impl "$IMPL_MSG"; local rc=$?
    local impl_note=""
    [ "$rc" -eq 3 ] && impl_note="구현 세션이 ${STEP_TIMEOUT}초 안에 끝나지 않아 끊었다."
    [ "$rc" -eq 1 ] && impl_note="구현 세션이 오류로 끝났다: $(tail -c 500 "$LAST_RUN.err")"
    [ -f "$OUT/report.json" ] || impl_note="$impl_note report.json 이 없다 — 마지막에 반드시 써라."

    if [ "$($PY get "$OUT/report.json" status)" = "needs_decision" ]; then
      park_group "$gid" "$title" "사람 선택 필요" "$n" "$OUT/report.json"
      return 1
    fi

    # 2) 기계 테스트
    local test_ok=1
    {
      echo "\$ harness/guard.sh"; harness/guard.sh; echo "exit=$?"
      if [ -x tools/test.sh ]; then
        echo "\$ tools/test.sh"; PATH="$SHIM_PATH" tools/test.sh; echo "exit=$?"
      fi
      case "$gid" in T-*)
        echo "\$ 문서 정리 검사"; $PY tidygate "$gid"; echo "exit=$?";;
      esac
    } > "$OUT/test.log" 2>&1
    grep -Eq '^exit=[1-9]' "$OUT/test.log" && test_ok=0

    # 3) QA (새 세션)
    status phase="QA" phase_since="$(date '+%F %T')"
    publish "$where QA"
    run_claude_retry qa "$QA_MSG"; rc=$?
    local qa_pass; qa_pass=$($PY get "$OUT/qa.json" pass)
    [ -f "$OUT/qa.json" ] || qa_pass="false"

    local pass=0
    [ -z "$impl_note" ] && [ "$test_ok" -eq 1 ] && [ "$qa_pass" = "true" ] && pass=1

    if [ "$pass" -eq 1 ]; then
      git add -A
      git commit -qm "$gid.$n $stitle" -m "$($PY get "$OUT/report.json" summary)" >/dev/null
      git push -q -u origin "$(branch_of "$gid")" 2>>"$L/loop.log" || true
      $PY mark-step "$gid" "$n"
      rm -f "$af"
      event type=step_pass group="$gid" step="$n" attempt="$attempt" \
        title="$gid $n/$total $stitle — 통과 (시도 $attempt)" commit="$(git rev-parse --short HEAD)" \
        --report "$OUT/report.json" --qa "$OUT/qa.json" --test "$OUT/test.log"
      log "통과: $where"
      return 0
    fi

    # 실패 → 다음 시도에 줄 피드백
    {
      [ -n "$impl_note" ] && echo "- 구현 세션: $impl_note"
      [ "$test_ok" -eq 0 ] && { echo "- 기계 테스트 실패. 출력 끝부분:"; echo '```'; tail -n 40 "$OUT/test.log"; echo '```'; }
      [ -f "$OUT/qa.json" ] || echo "- QA 세션이 판정을 남기지 못했다 (rc=$rc)."
      local qf; qf=$($PY get "$OUT/qa.json" feedback)
      [ -n "$qf" ] && { echo "- QA 피드백:"; echo "$qf"; }
    } > "$fb"
    event type=step_fail group="$gid" step="$n" attempt="$attempt" \
      title="$gid $n/$total $stitle — 재시도 (시도 $attempt)" detail="$(cat "$fb")" \
      --report "$OUT/report.json" --qa "$OUT/qa.json" --test "$OUT/test.log"
    log "실패: $where"

    if [ "$attempt" -ge "$STUCK_AFTER" ]; then
      park_group "$gid" "$title" "막힘 — ${attempt}번 시도해도 통과 못함" "$n" "$OUT/report.json" "$fb"
      return 1
    fi
  done
}

# ------------------------------------------------------------------ 메인 루프

REASON="알 수 없는 이유로 종료"
STATE="stopped"

on_exit() {
  local code=$?
  [ -n "$CHILD" ] && kill_tree "$CHILD"
  [ -n "$WD" ] && kill_tree "$WD"
  if [ -f "$L/STOP" ]; then REASON="사용자 중지"; STATE="stopped"; fi
  if [ "$STATE" = "stopped" ] && [ "$REASON" = "알 수 없는 이유로 종료" ]; then
    STATE="crashed"
    REASON="예상하지 못한 종료 (코드 $code) — .loop/loop.log 확인"
  fi
  status state="$STATE" reason="$REASON" phase="" ended="$(date '+%F %T')"
  event type=stop title="루프 종료 — $REASON"
  publish "루프 종료: $REASON"
  notify "루프가 종료되었습니다: $REASON"
  log "종료: $REASON"
  rm -rf "$L/lock" "$L/STOP"
}

main_loop() {
  trap on_exit EXIT
  trap 'exit 143' TERM INT HUP

  if [ -n "$(git status --porcelain)" ] && [ "$(git branch --show-current)" = "main" ]; then
    STATE="crashed"; REASON="main 에 커밋 안 된 변경이 있어 시작하지 않음"
    exit 1
  fi

  status state=running reason="" started="$(date '+%F %T')" ended="" resume_at="" pid="$$"
  event type=start title="루프 시작"
  publish "루프 시작"
  notify "루프를 시작했습니다."

  while true; do
    [ -f "$L/STOP" ] && exit 0
    $PY doccheck | while read -r f; do log "문서 정리 추가: $f"; done

    local next; next=$($PY next)
    if [ -z "$next" ]; then
      local waiting; waiting=$(grep -c '^## \[>\]' list.md)
      STATE="done"; REASON="목록 완료 — list.md 의 할 일을 모두 처리함"
      [ "$waiting" -gt 0 ] && REASON="목록 완료 — 단, 결정 대기 ${waiting}개가 남음 (decisions.md)"
      git checkout -q main
      exit 0
    fi

    local gid title
    gid=$(echo "$next" | jq -r .group); title=$(echo "$next" | jq -r .title)
    if [ "$(echo "$next" | jq -r '.error // empty')" != "" ]; then
      echo '{"problem":"list.md 의 이 묶음에 단계(- [ ] 1. ...)가 없다"}' > "$OUT/empty.json"
      git checkout -q main
      $PY decide "$gid" "list.md 형식 오류 — 단계가 없음" 0 "$OUT/empty.json" "-"
      $PY mark-group "$gid" ">"
      continue
    fi

    enter_group "$gid"
    if [ "$(echo "$next" | jq -r '.complete // false')" = "true" ]; then
      if ! finish_group "$gid" "$title"; then
        park_group "$gid" "$title" "main 에 합치다 충돌" 0 "-"
      fi
      continue
    fi

    do_step "$gid" "$title" "$(echo "$next" | jq -r .step)" \
      "$(echo "$next" | jq -r .step_title)" "$(echo "$next" | jq -r .total)"
  done
}

# ------------------------------------------------------------------ 명령

case "${1:-help}" in
  start)
    if [ -d "$L/lock" ] && alive "$(cat "$L/lock/pid" 2>/dev/null)"; then
      echo "이미 돌고 있다 (pid $(cat "$L/lock/pid"))"; exit 1
    fi
    rm -rf "$L/lock" "$L/STOP"
    mkdir "$L/lock"
    cp "$0" "$L/running.sh"
    NARU_ROOT="$ROOT" nohup caffeinate -is /bin/bash "$L/running.sh" _run >> "$L/loop.log" 2>&1 < /dev/null &
    for _ in $(seq 50); do [ -s "$L/lock/pid" ] && break; sleep 0.1; done
    echo "시작함 (pid $(cat "$L/lock/pid" 2>/dev/null)) — 대시보드: https://kimtuna.github.io/naru/ · 로그: ./loop.sh log"
    ;;
  _run)
    mkdir -p "$L/lock"
    echo "$$" > "$L/lock/pid"
    main_loop
    ;;
  stop)
    pid=$(cat "$L/lock/pid" 2>/dev/null)
    if ! alive "$pid"; then echo "돌고 있지 않다"; rm -rf "$L/lock"; exit 0; fi
    touch "$L/STOP"
    kill -TERM "$pid"
    for _ in $(seq 60); do alive "$pid" || break; sleep 1; done
    echo "멈춤"
    ;;
  status)
    pid=$(cat "$L/lock/pid" 2>/dev/null)
    if alive "$pid"; then echo "실행 중 (pid $pid)"; else echo "멈춰 있음"; fi
    jq . "$L/data/status.json" 2>/dev/null
    ;;
  log)
    tail -f "$L/loop.log"
    ;;
  publish)  # 루프 밖에서 list.md 를 고친 뒤 대시보드만 갱신
    if alive "$(cat "$L/lock/pid" 2>/dev/null)"; then echo "루프가 돌고 있다 — 다음 단계에서 알아서 올라간다"; exit 0; fi
    status
    publish "${2:-목록 갱신}"
    echo "대시보드 갱신함"
    ;;
  *)
    sed -n '2,7p' "$0"
    ;;
esac
