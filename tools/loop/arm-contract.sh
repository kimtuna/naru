#!/usr/bin/env bash
# 계약을 무장한다 — 지금의 criteria.tsv 해시를 잠가둔다.
#
# 무장 뒤에 세션이 기준을 고치면 run-contract.sh 가 exit 77 로 죽는다.
# **이것이 자율 루프의 유일한 진짜 방어선이다** — 「검사를 약하게 하지 마세요」라고
# 부탁하는 게 아니라 구조로 막는 것이다.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CRIT="$ROOT/.loop/criteria.tsv"
ARMED="$ROOT/.loop/armed.sha256"

[ -f "$CRIT" ] || { echo "arm: 계약 파일이 없다: $CRIT" >&2; exit 78; }
shasum -a 256 "$CRIT" | awk '{print $1}' > "$ARMED"
echo "무장됨: $(cat "$ARMED")"
echo "  기준 $(grep -cv '^\s*#' "$CRIT" | tr -d ' ')개"
