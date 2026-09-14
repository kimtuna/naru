#!/usr/bin/env bash
# 게이트가 살아 있는지 잰다 — 일부러 깨뜨리고 계약이 빨개지는지 본다.
#
# **왜 스크립트인가**: 대조군은 「습관」으로 두면 무인 루프가 반드시 건너뛴다.
# 안 돌리면 아무것도 안 잡는 게이트가 쌓이고, 며칠 뒤 「전부 초록인데 게임은 안 도는」
# 상태로 나타난다.
#
# 종료 코드: 0 = 게이트가 살아 있다 / 1 = 안 잡는 게이트가 있다
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# 워킹트리가 더러우면 원복을 보장할 수 없다.
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
  echo "redteam: 워킹트리가 더럽다. 커밋하거나 치우고 다시 돌려라." >&2
  git status --short >&2
  exit 2
fi

BAK="$(mktemp -d)"
cp project.godot "$BAK/" 2>/dev/null || true
cp .loop/criteria.tsv "$BAK/" 2>/dev/null || true
cp tools/tests/test_isolation.gd "$BAK/" 2>/dev/null || true
cp docs/PROMPT.md "$BAK/" 2>/dev/null || true
cp scripts/player_motion.gd "$BAK/" 2>/dev/null || true
cp scripts/player_facing.gd "$BAK/" 2>/dev/null || true
cp scripts/player.gd "$BAK/" 2>/dev/null || true
cp scripts/main.gd "$BAK/" 2>/dev/null || true
cp scenes/main.tscn "$BAK/" 2>/dev/null || true
restore() {
  cp "$BAK/project.godot" project.godot 2>/dev/null || true
  cp "$BAK/criteria.tsv" .loop/criteria.tsv 2>/dev/null || true
  cp "$BAK/test_isolation.gd" tools/tests/test_isolation.gd 2>/dev/null || true
  cp "$BAK/PROMPT.md" docs/PROMPT.md 2>/dev/null || true
  cp "$BAK/player_motion.gd" scripts/player_motion.gd 2>/dev/null || true
  cp "$BAK/player_facing.gd" scripts/player_facing.gd 2>/dev/null || true
  cp "$BAK/player.gd" scripts/player.gd 2>/dev/null || true
  cp "$BAK/main.gd" scripts/main.gd 2>/dev/null || true
  cp "$BAK/main.tscn" scenes/main.tscn 2>/dev/null || true
  rm -f scripts/_redteam.gd scripts/_redteam.gd.uid
  rm -rf "$BAK"
}
trap restore EXIT

PASS=0; MISS=0
expect() {          # expect <기대 exit> <이름>
  local want="$1" name="$2" rc
  bash tools/loop/run-contract.sh >/dev/null 2>&1; rc=$?
  if [ "$rc" -eq "$want" ]; then
    printf '  \033[32m잡았다\033[0m  %s  (exit %d)\n' "$name" "$rc"; PASS=$((PASS+1))
  else
    printf '  \033[31m놓쳤다\033[0m  %s  (기대 exit %d · 잰 값 %d)\n' "$name" "$want" "$rc"; MISS=$((MISS+1))
  fi
}

echo "== 대조군 =="
expect 0 "손 안 댄 상태는 초록이다"

printf 'extends Node\nfunc broken(\n' > scripts/_redteam.gd
expect 1 "문법이 깨진 스크립트를 parse 가 잡는다"
rm -f scripts/_redteam.gd scripts/_redteam.gd.uid

sed -i '' 's/viewport_width=960/viewport_width=1280/' project.godot
expect 1 "논리 해상도 변조를 tests 가 잡는다"
cp "$BAK/project.godot" project.godot

sed -i '' 's/default_texture_filter=0/default_texture_filter=1/' project.godot
expect 1 "텍스처 필터 변조를 tests 가 잡는다"
cp "$BAK/project.godot" project.godot

printf '9\t검사를 무르게 하려는 가짜 기준\ttrue\n' >> .loop/criteria.tsv
expect 77 "무장 뒤 계약 변조를 채점자가 잡는다"
cp "$BAK/criteria.tsv" .loop/criteria.tsv

python3 - <<'PYX'
import io
p='tools/tests/test_isolation.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s[:s.index('func test_user_data_is_writable')])
PYX
expect 1 "검사를 지우면 테스트 바닥이 잡는다"
cp "$BAK/test_isolation.gd" tools/tests/test_isolation.gd

# ── P1-1 이동 ────────────────────────────────────────────────────────
sed -i '' 's|return input.normalized() \* SPEED|return input * SPEED|' scripts/player_motion.gd
expect 1 "대각선 정규화를 빼면 tests 가 잡는다 (339.41 px/s)"
cp "$BAK/player_motion.gd" scripts/player_motion.gd

# **이 하나가 실측 게이트의 존재 이유다.** 노드가 PlayerMotion 을 부르기는 하므로
# 단위 검사 18개는 전부 초록으로 남는다 — measure_move.gd 만 잡는다 (2026-09-13 실측).
sed -i '' 's|velocity = PlayerMotion.velocity(input)|velocity = PlayerMotion.velocity(input) * 0.5|' scripts/player.gd
expect 1 "노드가 속도를 제 맘대로 바꾸면 실측이 잡는다 (120 px/s)"
cp "$BAK/player.gd" scripts/player.gd

# ── P1-2 화면 ────────────────────────────────────────────────────────
# 구조가 P1-1 과 같다: **project.godot 의 글자는 그대로라** 단위 검사 18개는
# 전부 초록으로 남고 measure_view.gd 만 잡는다 (2026-09-14 실측).
printf '\n[node name="Cam" type="Camera2D" parent="."]\nzoom = Vector2(2, 2)\n' >> scenes/main.tscn
expect 1 "카메라 줌을 걸면 화면 실측이 잡는다 (보이는 칸 10 x 5.62)"
cp "$BAK/main.tscn" scenes/main.tscn

python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "func _ready() -> void:\n",
    "func _ready() -> void:\n\tDisplayServer.window_set_size(Vector2i(1600, 900))\n", 1))
PYX
expect 1 "창을 실행 중에 줄이면 화면 실측이 잡는다 (배율 2 → 1)"
cp "$BAK/main.gd" scripts/main.gd

# ── P1-3 바라보는 방향 ────────────────────────────────────────────────
# 셋 다 **단위 검사 26개는 전부 초록으로 남는다** — measure_facing.gd 만 잡는다.
# PlayerFacing 자체는 안 건드리고 노드가 그걸 쓰는 방식만 망가뜨리기 때문이다.
sed -i '' 's|aim_at(get_global_mouse_position())|pass|' scripts/player.gd
expect 1 "노드가 커서를 안 읽으면 방향 실측이 잡는다 (계속 오른쪽만 본다)"
cp "$BAK/player.gd" scripts/player.gd

sed -i '' 's|PlayerFacing.resolve(point - global_position, facing)|PlayerFacing.nearest(point - global_position)|' scripts/player.gd
expect 1 "히스테리시스를 건너뛰면 방향 실측이 잡는다 (46° 에서 벌써 아래를 본다)"
cp "$BAK/player.gd" scripts/player.gd

python3 - <<'PYX'
import io
p='scripts/player.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tfacing = PlayerFacing.resolve(point - global_position, facing)\n\t_place_nose()",
    "\tfacing = PlayerFacing.resolve(point - global_position, facing)", 1))
PYX
expect 1 "방향은 맞는데 코가 안 돌면 방향 실측이 잡는다 (사람 눈엔 안 보인다)"
cp "$BAK/player.gd" scripts/player.gd


sed -i '' 's|"events": \[Object(InputEventKey,"physical_keycode":68)\]|"events": []|' project.godot
expect 1 "WASD 배선이 끊기면 tests 가 잡는다"
cp "$BAK/project.godot" project.godot

for i in $(seq 1 40); do echo "부풀리는 줄 $i" >> docs/PROMPT.md; done
expect 1 "매 바퀴 읽는 문서를 부풀리면 잡는다"
cp "$BAK/PROMPT.md" docs/PROMPT.md

expect 0 "원복하면 다시 초록이다"

echo
if [ "$MISS" -eq 0 ]; then
  echo "REDTEAM ${PASS} 잡음, 0 놓침 — 게이트가 살아 있다"; exit 0
fi
echo "REDTEAM ${PASS} 잡음, ${MISS} 놓침 — 안 잡는 게이트가 있다"; exit 1
