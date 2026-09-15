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

# 단위 검사만 — `run_tests.gd` 하나. 실측 게이트는 안 부른다.
#
# **왜 따로 있나** (회차 12): 상태 검사 기준 3 은 「개수가 줄지 않는다」를 물을 뿐인데
# `mintests.sh` 가 `tests` 를 부르는 바람에 기준 4 와 **같은 실측 7종을 두 번** 돌았다.
# 한 판이 두 배로 길고 **흔들릴 기회도 두 배**였다. 기준 3 은 이제 이걸 부른다 —
# 실측이 깨지면 기준 4 가 여전히 빨개지므로 상태 검사가 잡는 범위는 그대로다.
step_unit() {
  echo "== tests (단위) =="
  local out rc
  out="$("$G" 120 -- --headless --path "$ROOT" --script res://tools/tests/run_tests.gd 2>&1)"; rc=$?
  printf '%s\n' "$out" | grep -E '^\s*(ok|FAIL)|^TESTS'
  [ $rc -eq 0 ]
}

# 실측 게이트 13종 (MOVE·FACE·WORLD×2·COLLIDE·CAMERA·CHOP·REGROW·DAY·FOCUS·GRAB·VIEW+DRAW·BAG) — **엔진을 4번 띄운다.**
# 회차 27 까지는 7번이었다. 합칠 수 있는 것은 두 갈래로 이미 합쳐져 있다:
#   `measure_headless.gd`  MOVE·WORLD·COLLIDE·CAMERA·CHOP·REGROW·DAY·FOCUS·GRAB — 창이 필요 없는 아홉 (27·29·30·31·43·44)
#   `measure_window.gd`    VIEW·DRAW·HOTBAR·USE·BAG — 창이 필요한 다섯 (회차 14 · 40)
# 남은 둘은 **합칠 수 없어서** 따로 돈다: WORLD 의 두 번째 프로세스(「다른 프로세스에서도
# 같은가」가 묻는 것 자체다)와 FACE(제 SubViewport 를 세우고 `gui_disable_input` 을 끈다).
# 상태 검사에서 가장 긴 구간이다. **여기를 두 번 돌리지 마라.**
#
# **한 프로세스가 여러 구간을 재면 「반쪽만 돌고 죽어도 초록」이 열린다** (회차 14 가
# `WINGATE` 로 배운 것): 앞 구간이 조용히 죽으면 뒤 구간은 아예 안 돌고 프로세스는
# exit 0 으로 끝난다. 그래서 **구간마다 제 요약 줄을 찍었는지 전부 본다** — 그리고
# 「아홉 다 돌았다」를 찍는 줄(`HEADGATE ... 구간 9/9`)까지 본다.
# **아홉이라는 수를 여기가 안다**: 게이트 쪽은 「몇 구간을 돌았나」만 찍으므로
# 한 파일만 고쳐서는 초록이 안 된다.
_need() {   # _need <출력> <정규식> <이름>
  local out="$1" re="$2" name="$3"
  printf '%s\n' "$out" | grep -qE "$re" && return 0
  printf '%s\n' "$out" | tail -5
  echo "$name FAIL 측정이 아무것도 안 찍었다 (없는 줄: $re)"
  return 1
}

step_measure() {
  echo "== tests (실측) =="
  # ── 헤드리스 넷을 한 프로세스에서 (회차 27) ────────────────────────
  #   MOVE     실제 씬을 물리로 돌려 초당 몇 px 움직이는지. 순수 계산이 맞아도
  #            노드가 그걸 안 쓰면 여기서만 빨개진다.
  #   WORLD    같은 씨앗이 같은 섬을 주나. **여기서는 한 번만 찍는다** — 비교는 아래.
  #   COLLIDE  **메인 씬을 통째로** 물리로 돌려 진짜 섬의 해안에 걸어서 부딪힌다.
  #            WorldCollide 가 맞아도 main.gd 가 월드를 안 꽂으면 바다 위를 걸어간다.
  #   CAMERA   네 방향으로 걸으면서 **매 프레임** 플레이어가 화면 한가운데인지 · 줌이 1인지.
  #            씬에 zoom=1 이 박혀 있어도 실행 중에 코드가 줌을 걸면 단위 검사는 초록이다.
  #   CHOP     **좌클릭을 쥐고 나무를 벤다.** 맨손으로는 안 베이고, 도끼를 들면 나무가
  #            없어지고, 벤 칸이 안 막고, 목재가 바닥에 떨어지고, 화면을 다시 칠한다.
  #            Harvest 가 맞아도 main.gd 가 그걸 안 부르면 단위 검사는 전부 초록이다.
  #   REGROW   **시계가 프레임을 따라 흐르나**, 벤 자리에 선 몸이 나무를 밀어내나,
  #            비키면 자라서 다시 막나, 화면을 다시 칠하나 (GDD A-4).
  #            main.gd 가 `world.tick` 을 안 부르면 섬은 영영 그루터기밭인데
  #            단위 검사는 전부 초록이다.
  #   DAY      **그 시계가 하늘빛으로 나오나** (GDD G-1b 하루 20분 = 낮 10 + 밤 10).
  #            하루 한 바퀴를 돌며 `Sky.color` 를 그 시각의 빛과 맞춘다. DayCycle 이
  #            맞아도 main.gd 가 `Sky` 를 안 물들이면 섬은 영영 한낮인데 단위 검사는
  #            전부 초록이다. **픽셀은 여기서 안 본다** — 구운 화면이 정말 어두워지는지는
  #            아래 DRAW 의 `[밤]` 구간이 잰다.
  #   FOCUS    **가방을 연 채로** 좌클릭·숫자키·WASD 를 눌러 무엇이 사는지 (회차 43).
  #            걷기는 살고 좌클릭은 한 프레임도 안 휘두르고 숫자키는 손을 안 바꾼다.
  #            **대조군이 안에 있다**: 창을 닫고 같은 키를 같은 길이로 다시 눌러
  #            둘 다 나오는지 본다 — 없으면 「안 휘둘렀다」가 공허한 말이 된다.
  #            `InputRoute` 가 맞아도 main.gd 가 그 표를 안 물으면 단위 검사는 전부 초록이다.
  #   GRAB     **가방을 열고 커서를 칸 위로 옮겨** 좌클릭으로 집고 놓는다 (회차 44).
  #            가방 ↔ 핫바를 오가고, **꽉 찬 칸에 놓아도 손에 그대로 남고**, 집은 채로
  #            창을 닫아도 안 잃는다 — BACKLOG 의 대조판 둘이 그대로 구간이다.
  #            **제 SubViewport 를 세우는 유일한 헤드리스 구간이다**: 루트 뷰포트의
  #            커서는 OS 를 되묻는데 헤드리스면 늘 (0,0) 이라 칸을 겨눌 수가 없다
  #            (FACE 와 같은 이유 · 회차 8~11). **대조군이 안에 있다**: 창을 닫고 같은
  #            칸 자리를 같은 길이로 눌러 **안 집히고 휘두르는지**를 본다.
  #            `Grab` 이 맞아도 main.gd 가 클릭을 안 이으면 단위 검사는 전부 초록이다.
  local hout hrc miss=0
  hout="$("$G" 180 -- --headless --path "$ROOT" --script res://tools/tests/measure_headless.gd 2>&1)"; hrc=$?
  # `^WORLD [0-9]` 인 이유: 메인 씬이 `_ready` 에서 `WORLD    씨앗 ...` 를 찍는다 —
  # COLLIDE·CAMERA 가 그 씬을 세우므로 같은 출력에 섞인다 (회차 27).
  printf '%s\n' "$hout" | grep -E '^(MOVE |WORLD [0-9]|WORLDGEN |COLLIDE |CAMERA |CHOP |REGROW |DAY |FOCUS |GRAB |HEADGATE )'
  _need "$hout" '^MOVE (ok|FAIL)'      MOVE     || miss=1
  _need "$hout" '^WORLDGEN '           WORLD    || miss=1
  _need "$hout" '^COLLIDE (ok|FAIL)'   COLLIDE  || miss=1
  _need "$hout" '^CAMERA (ok|FAIL)'    CAMERA   || miss=1
  _need "$hout" '^CHOP (ok|FAIL)'      CHOP     || miss=1
  _need "$hout" '^REGROW (ok|FAIL)'    REGROW   || miss=1
  _need "$hout" '^DAY (ok|FAIL)'       DAY      || miss=1
  _need "$hout" '^FOCUS (ok|FAIL)'     FOCUS    || miss=1
  _need "$hout" '^GRAB (ok|FAIL)'      GRAB     || miss=1
  _need "$hout" '^HEADGATE .*구간 9/9' HEADGATE || miss=1
  [ "$miss" -eq 0 ] || return 1
  [ $hrc -eq 0 ] || return 1

  # ── 월드만 한 번 더, **다른 프로세스에서** ─────────────────────────
  # 한 프로세스 안의 단위 검사로는 못 잡는다 — 정적 변수에 시간을 한 번 섞어 두면
  # 그 프로세스 안에서는 늘 같은 값이 나온다 (measure_world.gd 머리말).
  # 그래서 이것만은 합칠 수 없다. `-- world` 로 **그 구간만** 부른다.
  local w2 w2rc g1 g2
  w2="$("$G" 120 -- --headless --path "$ROOT" --script res://tools/tests/measure_headless.gd -- world 2>&1)"; w2rc=$?
  g1="$(printf '%s\n' "$hout" | grep -E '^WORLD [0-9]')"
  g2="$(printf '%s\n' "$w2" | grep -E '^WORLD [0-9]')"
  if [ -z "$g2" ]; then
    printf '%s\n' "$w2" | tail -5; echo "WORLD FAIL 두 번째 프로세스가 아무것도 안 찍었다"; return 1
  fi
  if [ "$g1" != "$g2" ]; then
    echo "WORLD FAIL 같은 씨앗이 프로세스마다 다른 월드를 준다"
    diff <(printf '%s\n' "$g1") <(printf '%s\n' "$g2") | sed 's/^/    잰 값 /'
    return 1
  fi
  echo "WORLD 두 프로세스 체크섬 일치"
  [ $w2rc -eq 0 ] || return 1

  # ── 방향 (제 SubViewport 가 필요해서 따로 돈다) ────────────────────
  # 메인 씬을 **제 SubViewport 에** 세우고 합성 마우스 이벤트를 밀어 넣어
  # 어디를 보는지 잰다. PlayerFacing 이 맞아도 노드가 커서를 안 읽으면 게임은 앞만
  # 본다 — 그 구멍을 막는다. 카메라가 그 안에 있어 캔버스 변환도 그대로 탄다.
  # **사람의 커서를 안 뺏는다** (회차 11): 예전엔 `warp_mouse` 로 진짜 커서를 옮겨서
  # 사람이 마우스를 건드리면 튀었다 — 회차 8·9·10 · 사람 세션, 네 번.
  # 그래서 **헤드리스로 돈다** — 창도 커서도 필요 없다.
  # **위의 넷에 안 섞는다** (회차 27): 루트의 `gui_disable_input` 을 끄는 유일한
  # 게이트고 흔들림으로 네 회차를 잡아먹은 자리라, 섞으면 빨강이 어느 구간 탓인지 흐려진다.
  local fout frc
  fout="$("$G" 60 -- --headless --path "$ROOT" --script res://tools/tests/measure_facing.gd 2>&1)"; frc=$?
  printf '%s\n' "$fout" | grep -E '^FACE ' || { printf '%s\n' "$fout" | tail -5; echo "FACE FAIL 측정이 아무것도 안 찍었다"; return 1; }
  [ $frc -eq 0 ] || return 1

  # ── 창 실측 (VIEW + DRAW + HOTBAR + USE + BAG) — **한 프로세스다** (회차 14) ─
  # 실측 게이트 중 창이 필요한 것은 이것뿐이고, 다섯 다 메인 씬을 세운다.
  # **창을 띄우면 macOS 가 앱을 맨 앞으로 올린다 — 막을 길이 없다** (회차 13 · NUMBERS 11절).
  # 못 막으니 **횟수를 줄인다**: `NARU_FOCUS_RESTORE=1` 로 끝나고 되돌려 주는 것과 짝이다.
  #   VIEW  논리 화면 · 창 · 배율 · 보이는 칸. project.godot 의 글자가 맞아도 카메라 줌이나
  #         content_scale_factor 로 눈에 보이는 칸 수는 달라진다 — 그 구멍을 막는다.
  #   HOTBAR 화면 아래 9칸을 구운 픽셀에서 읽고 **숫자키를 눌러 강조가 옮겨 가는지** 다시 굽는다.
  #         DRAW 는 핫바가 덮은 자리를 건너뛰므로 **여기가 그 자리의 유일한 판정**이다.
  #   USE   좌클릭을 쥐고 **모션이 도는 동안 프레임마다** 네모의 자리와 픽셀을 읽는다.
  #         맞힐 것이 하나도 없는 자리에서 잰다 — 「대상이 없어도 모션이 나온다」가 그 문장이다.
  #   BAG   `E` 로 가방을 열고 닫으며 **세 번 굽는다** (회차 40): 닫힌 채 그 자리가 월드인가 ·
  #         연 채 18칸이 제 색인가(찬 칸과 빈 칸이 다른가) · 다시 닫으면 픽셀 하나까지
  #         돌아오는가. **가방이 떠 있는 동안의 픽셀은 여기 말고 보는 눈이 없다** —
  #         DRAW 는 닫힌 화면만 본다. **네 번째는 든 채로 굽는다** (회차 45):
  #         커서 자리에 든 무더기가 보이나 · 칸 위에 뜨나 · 커서를 따라가나.
  #         그 한 구간만 **제 SubViewport 에 씬을 한 벌 더 세운다** — 루트의 커서는
  #         OS 를 되묻는데 `warp_mouse` 로 뺏으면 회차 8~11 의 흔들림이 돌아온다.
  #         헤드리스 묶음에 못 넣는 이유는 그 반대다: 더미 렌더러는 텍스처를 안 준다.
  #   DRAW  해안에 세우고 **구운 픽셀을 그 자리의 월드 칸 색과 맞춘다.** WorldView 가 맞아도
  #         main 이 안 그리거나 다른 씨앗으로 그리면 단위 검사는 전부 초록이다.
  #         **서서 한 번 · 걷고 한 번 · 밤에 한 번** — 색 캐시는 걸어야 상하고,
  #         **화면이 하루를 아는 것은 픽셀로만 증명된다** (회차 31 · GDD G-1b):
  #         시계를 반 바퀴 돌려 칸 색 × 하늘빛과 맞추고, 그 김에 핫바가 안 어두워지는지와
  #         밤이 색 캐시를 안 버리는지까지 본다.
  # **--headless 를 쓰지 않는다** — 헤드리스는 창 크기가 (0,0) 이고 렌더러가 더미라
  # 배율도 뷰포트 텍스처도 안 나온다.
  # **여섯 줄을 다 본다**: VIEW·DRAW·HOTBAR·USE·BAG 이 각각 찍었는지, 그리고 다섯 다 돌았다는 WINGATE 까지.
  # 한 프로세스라 앞이 죽으면 뒤가 통째로 안 돈다 — 그 침묵을 초록으로 보면 안 된다.
  local wout wrc
  wout="$(NARU_FOCUS_RESTORE=1 "$G" 120 -- --path "$ROOT" --script res://tools/tests/measure_window.gd 2>&1)"; wrc=$?
  printf '%s\n' "$wout" | grep -E '^VIEW |^DRAW (\[|ok|FAIL)|^HOTBAR (\[|ok|FAIL)|^USE (\[|ok|FAIL)|^BAG (\[|ok|FAIL)|^WINGATE '
  miss=0
  _need "$wout" '^VIEW (ok|FAIL)'    VIEW    || miss=1
  _need "$wout" '^DRAW (ok|FAIL)'    DRAW    || miss=1
  _need "$wout" '^HOTBAR (ok|FAIL)'  HOTBAR  || miss=1
  _need "$wout" '^USE (ok|FAIL)'     USE     || miss=1
  _need "$wout" '^BAG (ok|FAIL)'     BAG     || miss=1
  _need "$wout" '^WINGATE '          WINGATE || miss=1
  [ "$miss" -eq 0 ] || return 1
  [ $wrc -eq 0 ]
}

step_tests() { step_unit && step_measure; }

case "$WHAT" in
  import) step_import ;;
  parse)  step_parse ;;
  unit)   step_unit ;;
  tests)  step_tests ;;
  all)    step_import && step_parse && step_tests ;;
  *) echo "사용법: check.sh [import|parse|unit|tests|all]" >&2; exit 2 ;;
esac
