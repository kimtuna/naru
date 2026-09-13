#!/usr/bin/env bash
# 계약을 실행한다. **이것만이 .loop/results.json 을 쓴다 — 유일한 증거다.**
#
# 종료 코드
#   0  ALL GREEN
#   1  기준 하나 이상 빨강
#   77 무장 뒤 계약이 변조됨   ← 세션이 검사를 고쳐서 통과하려 한 경우
#   78 계약 파일이 없음 / 비어 있음
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CRIT="$ROOT/.loop/criteria.tsv"
ARMED="$ROOT/.loop/armed.sha256"
OUT="$ROOT/.loop/results.json"

[ -f "$CRIT" ] || { echo "계약 파일이 없다: $CRIT" >&2; exit 78; }
CUR="$(shasum -a 256 "$CRIT" | awk '{print $1}')"

if [ -f "$ARMED" ]; then
  WANT="$(cat "$ARMED")"
  if [ "$CUR" != "$WANT" ]; then
    echo "계약이 무장 뒤에 바뀌었다 — 검사를 고쳐서 통과하려는 것은 red line 이다." >&2
    echo "  무장: $WANT" >&2
    echo "  현재: $CUR" >&2
    exit 77
  fi
else
  WANT=""
fi

# 주석과 빈 줄을 뺀 기준만 센다. 전부 주석이면 「공허한 계약」이라 실패다.
# macOS 는 bash 3.2 라 mapfile 이 없다. while-read 로 읽는다.
ROWS=()
while IFS= read -r l; do ROWS+=("$l"); done \
  < <(grep -v '^[[:space:]]*#' "$CRIT" | grep -v '^[[:space:]]*$')
if [ "${#ROWS[@]}" -eq 0 ]; then
  echo "공허한 계약 — 기준이 하나도 없다." >&2
  exit 78
fi

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
FAILED=0; IDX=0
echo "== 계약 실행 (기준 ${#ROWS[@]}개) =="
for row in "${ROWS[@]}"; do
  IDX=$((IDX+1))
  id="$(printf '%s' "$row" | cut -f1)"
  what="$(printf '%s' "$row" | cut -f2)"
  cmd="$(printf '%s' "$row" | cut -f3-)"
  out="$( cd "$ROOT" && eval "$cmd" 2>&1 )"; rc=$?
  # 증거는 「잰 값」이 있는 줄만 남긴다 — 「passed」 한 단어는 증거가 아니다.
  ev="$(printf '%s' "$out" | grep -E 'TESTS |PARSE |IMPORT |FAIL|잰 값' | tail -6)"
  [ -z "$ev" ] && ev="$(printf '%s' "$out" | tail -3)"
  if [ $rc -eq 0 ]; then
    printf '  \033[32m초록\033[0m  %s  %s\n' "$id" "$what"
  else
    FAILED=$((FAILED+1))
    printf '  \033[31m빨강\033[0m  %s  %s  (exit %d)\n' "$id" "$what" "$rc"
    printf '%s\n' "$ev" | sed 's/^/         /'
  fi
  printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$what" "$cmd" "$rc" "$(printf '%s' "$ev" | tr '\n' '\037')" >> "$TMP/rows"
done

python3 - "$TMP/rows" "$OUT" "$CUR" "$WANT" "$FAILED" <<'PY'
import sys, json, datetime, io
rows_path, out_path, cur, want, failed = sys.argv[1:6]
crit = []
for line in io.open(rows_path, encoding='utf-8'):
    i, what, cmd, rc, ev = line.rstrip('\n').split('\t', 4)
    crit.append({"id": i, "what": what, "cmd": cmd,
                 "exit": int(rc), "ok": int(rc) == 0,
                 "evidence": [e for e in ev.split('\x1f') if e]})
json.dump({
    "ts": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
    "armed_sha256": want or None,
    "current_sha256": cur,
    "all_green": int(failed) == 0,
    "criteria": crit,
}, io.open(out_path, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
PY

if [ "$FAILED" -eq 0 ]; then echo "ALL GREEN  → $OUT"; exit 0; fi
echo "빨강 ${FAILED}개  → $OUT"; exit 1
