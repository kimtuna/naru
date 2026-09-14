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
  [ $rc -eq 0 ] || return 1
  # 실측: 실제 씬을 물리로 돌려 초당 몇 px 움직이는지 잰다.
  # 순수 계산이 맞아도 노드가 그걸 안 쓰면 여기서만 빨개진다.
  local mout mrc
  mout="$("$G" 60 -- --headless --path "$ROOT" --script res://tools/tests/measure_move.gd 2>&1)"; mrc=$?
  printf '%s\n' "$mout" | grep -E '^MOVE' || { printf '%s\n' "$mout" | tail -5; echo "MOVE FAIL 측정이 아무것도 안 찍었다"; return 1; }
  [ $mrc -eq 0 ] || return 1
  # 화면 실측: 논리 화면 · 창 · 배율 · 보이는 칸.
  # project.godot 의 글자가 맞아도 카메라 줌이나 content_scale_factor 로
  # 눈에 보이는 칸 수는 달라진다 — 그 구멍을 여기서 막는다.
  # **--headless 를 쓰지 않는다** — 헤드리스 드라이버는 창 크기가 (0,0) 이라 배율을 못 잰다.
  local vout vrc
  vout="$("$G" 60 -- --path "$ROOT" --script res://tools/tests/measure_view.gd 2>&1)"; vrc=$?
  printf '%s\n' "$vout" | grep -E '^VIEW ' || { printf '%s\n' "$vout" | tail -5; echo "VIEW FAIL 측정이 아무것도 안 찍었다"; return 1; }
  [ $vrc -eq 0 ] || return 1
  # 방향 실측: 진짜 커서를 옮겨 넣고 어디를 보는지 잰다.
  # PlayerFacing 이 맞아도 노드가 커서를 안 읽으면 게임은 앞만 본다 — 그 구멍을 막는다.
  # **--headless 를 쓰지 않는다** — 창이 없으면 커서를 못 옮긴다.
  # **사람의 커서를 1초쯤 뺏는다.** 끝나면 제자리로 돌려놓는다.
  local fout frc
  fout="$("$G" 60 -- --path "$ROOT" --script res://tools/tests/measure_facing.gd 2>&1)"; frc=$?
  printf '%s\n' "$fout" | grep -E '^FACE ' || { printf '%s\n' "$fout" | tail -5; echo "FACE FAIL 측정이 아무것도 안 찍었다"; return 1; }
  [ $frc -eq 0 ] || return 1
  # 월드 실측: **엔진을 두 번 띄워** 같은 씨앗이 같은 월드를 주는지 본다.
  # 한 프로세스 안의 단위 검사로는 못 잡는다 — 정적 변수에 시간을 한 번 섞어 두면
  # 그 프로세스 안에서는 늘 같은 값이 나온다 (measure_world.gd 머리말).
  local w1 w2 g1 g2 w1rc w2rc
  w1="$("$G" 120 -- --headless --path "$ROOT" --script res://tools/tests/measure_world.gd 2>&1)"; w1rc=$?
  w2="$("$G" 120 -- --headless --path "$ROOT" --script res://tools/tests/measure_world.gd 2>&1)"; w2rc=$?
  g1="$(printf '%s\n' "$w1" | grep -E '^WORLD ')"
  g2="$(printf '%s\n' "$w2" | grep -E '^WORLD ')"
  if [ -z "$g1" ] || [ -z "$g2" ]; then
    printf '%s\n' "$w1" | tail -5; echo "WORLD FAIL 측정이 아무것도 안 찍었다"; return 1
  fi
  printf '%s\n' "$g1"
  printf '%s\n' "$w1" | grep -E '^WORLDGEN '
  if [ "$g1" != "$g2" ]; then
    echo "WORLD FAIL 같은 씨앗이 프로세스마다 다른 월드를 준다"
    diff <(printf '%s\n' "$g1") <(printf '%s\n' "$g2") | sed 's/^/    잰 값 /'
    return 1
  fi
  echo "WORLD 두 프로세스 체크섬 일치"
  [ $w1rc -eq 0 ] && [ $w2rc -eq 0 ] || return 1
  # 충돌 실측: **메인 씬을 통째로** 물리로 돌려 진짜 섬의 해안에 걸어서 부딪힌다.
  # WorldCollide 가 맞아도 노드가 안 부르거나 main.gd 가 월드를 안 꽂으면
  # 플레이어는 바다 위를 걸어간다 — 그 구멍을 여기서 막는다.
  local cout crc
  cout="$("$G" 120 -- --headless --path "$ROOT" --script res://tools/tests/measure_collide.gd 2>&1)"; crc=$?
  printf '%s\n' "$cout" | grep -E '^COLLIDE' || { printf '%s\n' "$cout" | tail -5; echo "COLLIDE FAIL 측정이 아무것도 안 찍었다"; return 1; }
  [ $crc -eq 0 ]
}

case "$WHAT" in
  import) step_import ;;
  parse)  step_parse ;;
  tests)  step_tests ;;
  all)    step_import && step_parse && step_tests ;;
  *) echo "사용법: check.sh [import|parse|tests|all]" >&2; exit 2 ;;
esac
