#!/usr/bin/env bash
# 매 바퀴 읽는 문서가 부풀지 않게 상한을 강제한다.
#
# 왜 게이트인가: 「문서를 얇게 유지하라」를 규칙으로만 적어두면 반드시 어겨진다.
# 1판은 매 바퀴 읽는 문서가 758+1012+826 줄까지 불어서 한 바퀴가 20분이 됐다.
# 상한은 계약 안에 인자로 박혀 있고 계약은 무장돼 있으므로 세션이 못 늘린다.
#
# 사용법: doclen.sh <파일>:<최대줄> ...
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
bad=0
for spec in "$@"; do
  f="${spec%%:*}"; max="${spec##*:}"
  if [ ! -f "$f" ]; then echo "DOCLEN 없는 파일: $f"; bad=1; continue; fi
  n="$(wc -l < "$f" | tr -d ' ')"
  if [ "$n" -gt "$max" ]; then
    echo "DOCLEN $f  잰 값 ${n}줄 · 상한 ${max}줄  ← 부풀었다"; bad=1
  else
    echo "DOCLEN $f  ${n}/${max}줄"
  fi
done
[ "$bad" -eq 0 ] || { echo "매 바퀴 읽는 문서가 부풀었다. 조건부로 읽는 파일로 옮겨라."; exit 1; }
