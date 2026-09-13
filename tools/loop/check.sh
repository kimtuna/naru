#!/usr/bin/env bash
# import → parse → tests.  순서가 중요하다.
#
# `class_name` 으로 등록되는 전역 클래스는 임포트가 만드는 캐시에 들어간다.
# parse 를 먼저 돌리면 새로 추가한 class_name 이 「Identifier not declared」로 잡혀
# 멀쩡한 코드가 빨갛게 나온다.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
G="$HERE/godot.sh"
WHAT="${1:-all}"

step_import() {
  echo "== import =="
  local out rc
  out="$("$G" 180 -- --headless --path "$ROOT" --import 2>&1)"; rc=$?
  if [ $rc -ne 0 ]; then echo "$out"; echo "IMPORT 실패 (exit $rc)"; return 1; fi
  echo "IMPORT ok"
}

step_parse() {
  echo "== parse =="
  # `--check-only` 는 파스 에러에도 exit 0 을 준다. 출력을 봐야 한다.
  local n=0 bad=0 f out
  while IFS= read -r f; do
    n=$((n+1))
    out="$("$G" 60 -- --headless --path "$ROOT" --check-only --script "res://${f#./}" 2>&1)"
    if printf '%s' "$out" | grep -qE 'Parse Error|SCRIPT ERROR|Failed to load script|Compile Error'; then
      bad=$((bad+1)); echo "  FAIL $f"; printf '%s\n' "$out" | grep -E 'Parse Error|SCRIPT ERROR|Failed to load script|Compile Error' | head -5
    fi
  done < <(cd "$ROOT" && find . -name '*.gd' -not -path './.godot/*' -not -path './.godot-xdg/*' | sort)
  echo "PARSE ${n}개 스크립트, 실패 ${bad}"
  [ "$bad" -eq 0 ]
}

step_tests() {
  echo "== tests =="
  local out rc
  out="$("$G" 120 -- --headless --path "$ROOT" --script res://tools/tests/run_tests.gd 2>&1)"; rc=$?
  printf '%s\n' "$out" | grep -E '^\s*(ok|FAIL)|^TESTS'
  [ $rc -eq 0 ]
}

case "$WHAT" in
  import) step_import ;;
  parse)  step_parse ;;
  tests)  step_tests ;;
  all)    step_import && step_parse && step_tests ;;
  *) echo "사용법: check.sh [import|parse|tests|all]" >&2; exit 2 ;;
esac
