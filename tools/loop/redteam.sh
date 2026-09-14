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
cp scripts/world_gen.gd "$BAK/" 2>/dev/null || true
cp scripts/world_collide.gd "$BAK/" 2>/dev/null || true
cp scripts/player.gd "$BAK/" 2>/dev/null || true
cp scripts/main.gd "$BAK/" 2>/dev/null || true
cp scenes/main.tscn "$BAK/" 2>/dev/null || true
cp scenes/player.tscn "$BAK/" 2>/dev/null || true
restore() {
  cp "$BAK/project.godot" project.godot 2>/dev/null || true
  cp "$BAK/criteria.tsv" .loop/criteria.tsv 2>/dev/null || true
  cp "$BAK/test_isolation.gd" tools/tests/test_isolation.gd 2>/dev/null || true
  cp "$BAK/PROMPT.md" docs/PROMPT.md 2>/dev/null || true
  cp "$BAK/player_motion.gd" scripts/player_motion.gd 2>/dev/null || true
  cp "$BAK/player_facing.gd" scripts/player_facing.gd 2>/dev/null || true
  cp "$BAK/world_gen.gd" scripts/world_gen.gd 2>/dev/null || true
  cp "$BAK/world_collide.gd" scripts/world_collide.gd 2>/dev/null || true
  cp "$BAK/player.gd" scripts/player.gd 2>/dev/null || true
  cp "$BAK/main.gd" scripts/main.gd 2>/dev/null || true
  cp "$BAK/main.tscn" scenes/main.tscn 2>/dev/null || true
  cp "$BAK/player.tscn" scenes/player.tscn 2>/dev/null || true
  rm -f scripts/_redteam.gd scripts/_redteam.gd.uid
  rm -rf "$BAK"
}
trap restore EXIT

PASS=0; MISS=0; N=0
# **놓친 대조군의 증거를 남긴다.** 전에는 출력을 통째로 버려서 「놓쳤다」만 뜨고
# 무엇이 왜 빨갰는지 알 방법이 없었다 — 재현하려면 10분을 다시 태워야 했다.
EV="$ROOT/.loop/redteam"; rm -rf "$EV"; mkdir -p "$EV"
expect() {          # expect <기대 exit> <이름>
  local want="$1" name="$2" rc; N=$((N+1))
  bash tools/loop/run-contract.sh >"$EV/last.txt" 2>&1; rc=$?
  if [ "$rc" -eq "$want" ]; then
    printf '  \033[32m잡았다\033[0m  %s  (exit %d)\n' "$name" "$rc"; PASS=$((PASS+1))
  else
    printf '  \033[31m놓쳤다\033[0m  %s  (기대 exit %d · 잰 값 %d)\n' "$name" "$want" "$rc"; MISS=$((MISS+1))
    local slug; slug="$(printf '%02d' "$N")"
    cp "$EV/last.txt" "$EV/$slug-contract.txt" 2>/dev/null || true
    cp "$ROOT/.loop/results.json" "$EV/$slug-results.json" 2>/dev/null || true
    git status --short > "$EV/$slug-tree.txt" 2>&1
    # 빨간 기준만 뽑아서 그 자리에서 보여준다
    python3 - "$EV/$slug-results.json" 2>/dev/null <<'PYX'
import json, sys
try: r = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception: sys.exit(0)
for c in r.get("criteria", []):
    if not c.get("ok"):
        print(f"      기준 {c['id']} 빨강 — {c['what']}")
        for e in (c.get("evidence") or [])[:4]:
            print(f"        {e}")
PYX
    printf '      증거: .loop/redteam/%s-*\n' "$slug"
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
# **바퀴 8 에서 겨눌 곳이 바뀌었다**: 진짜 카메라가 생겼으므로 씬에 카메라를 하나 더
# 덧붙여도 먼저 트리에 들어온 플레이어의 카메라가 화면을 잡는다(선착순) — 아무 일도
# 안 일어나는 가짜 대조군이 된다. 그래서 **그 카메라의 줌을 직접** 건다.
sed -i '' 's|^zoom = Vector2(1, 1)|zoom = Vector2(2, 2)|' scenes/player.tscn
expect 1 "카메라 줌을 걸면 화면 실측이 잡는다 (보이는 칸 10 x 5.62)"
cp "$BAK/player.tscn" scenes/player.tscn

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

# **바퀴 11 에 새로 넣었다.** 게이트가 메인 씬을 SubViewport 로 옮겼으므로
# 「캔버스 변환을 타는가」가 정말 남아 있는지 물어야 한다 — 안 그러면 커서를
# 창 좌표 그대로 읽어도 통과하는 게이트가 된다. 스폰이 칸 (128,128) 이라
# 변환의 평행이동이 6000 px 대다: 빼먹으면 7구간 중 6개가 빨개진다 (실측).
sed -i '' 's|aim_at(get_global_mouse_position())|aim_at(get_viewport().get_mouse_position())|' scripts/player.gd
expect 1 "커서를 뷰포트 좌표로 읽으면 방향 실측이 잡는다 (캔버스 변환을 빼먹었다)"
cp "$BAK/player.gd" scripts/player.gd

# ── P1-4 월드 생성 ────────────────────────────────────────────────────
# **이 하나가 프로세스 간 게이트의 존재 이유다.** 정적 변수는 프로세스마다 한 번만
# 초기화되므로 **한 프로세스 안에서는 늘 같은 월드**다 — 단위 검사 35개는 전부 초록으로
# 남고 measure_world.gd 만 잡는다. 사람 눈에는 「어제 만든 섬이 오늘 다르다」로만 보인다.
python3 - <<'PYX'
import io
p='scripts/world_gen.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tvar h := world_seed & 0xFFFFFFFF",
    "\tvar h := (world_seed + _drift) & 0xFFFFFFFF", 1).replace(
    "const SIZE := 256",
    "static var _drift := int(Time.get_unix_time_from_system() * 1000.0)\nconst SIZE := 256", 1))
PYX
expect 1 "씨앗에 시간을 섞으면 프로세스 간 실측이 잡는다 (어제 섬 ≠ 오늘 섬)"
cp "$BAK/world_gen.gd" scripts/world_gen.gd

sed -i '' 's|	return FALLOFF_GAIN \* pow(minf(d, 1.0), FALLOFF_POW)|	return 0.0|' scripts/world_gen.gd
expect 1 "가장자리 감쇠를 빼면 tests 가 잡는다 (테두리가 땅이 된다)"
cp "$BAK/world_gen.gd" scripts/world_gen.gd

sed -i '' 's|^const SIZE := 256|const SIZE := 128|' scripts/world_gen.gd
expect 1 "월드를 256 → 128 로 줄이면 tests 가 잡는다"
cp "$BAK/world_gen.gd" scripts/world_gen.gd


# ── P1-5 이동 충돌 ────────────────────────────────────────────────────
# 앞의 둘은 **단위 검사 53개를 전부 초록으로 남긴다** — WorldCollide 자체는 멀쩡하고
# 그걸 쓰는 배선만 끊기기 때문이다. measure_collide.gd 만 잡는다.
sed -i '' 's|position = WorldCollide.move(position, velocity \* delta, solid)|position += velocity * delta|' scripts/player.gd
expect 1 "노드가 충돌을 안 물으면 실측이 잡는다 (바다 위를 걸어간다)"
cp "$BAK/player.gd" scripts/player.gd

python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t_player.solid = WorldCollide.solid_from_seed(WORLD_SEED)", "\tpass", 1))
PYX
expect 1 "main 이 월드를 안 꽂으면 실측이 잡는다 (막는 칸이 하나도 없다)"
cp "$BAK/main.gd" scripts/main.gd

# 벽에 닿으면 **통째로** 정지한다 — 「바다에 못 들어간다」는 그대로 맞고 미끄러짐만 죽는다.
# 사람 눈에는 「해안에 비스듬히 붙으면 걸린다」로만 보인다.
python3 - <<'PYX'
import io
p='scripts/world_collide.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tp.y = _sweep(p, motion.y, 1, solid, half)",
    "\tif not is_equal_approx(p.x, pos.x + motion.x):\n\t\treturn p\n\tp.y = _sweep(p, motion.y, 1, solid, half)", 1))
PYX
expect 1 "벽에 닿을 때 통째로 멈추면 잡는다 (해안에서 안 미끄러진다)"
cp "$BAK/world_collide.gd" scripts/world_collide.gd

# ── P1-6 카메라 ──────────────────────────────────────────────────────
# 셋 다 **단위 검사 57개를 전부 초록으로 남긴다** — 씬에 박힌 글자(zoom = 1,
# 부드럽게 따라가기 끔)는 그대로고 **실행 중의 화면**만 달라지기 때문이다.
printf 'enabled = false\n' >> scenes/player.tscn
expect 1 "카메라를 꺼 버리면 카메라 실측이 잡는다 (화면이 원점을 비춘다)"
cp "$BAK/player.tscn" scenes/player.tscn

python3 - <<'PYX'
import io
p='scripts/player.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "func _ready() -> void:\n\t_place_nose()",
    "func _ready() -> void:\n\t_place_nose()\n\t$Camera.zoom = Vector2(2, 2)", 1))
PYX
expect 1 "실행 중에 줌을 걸면 실측이 잡는다 (씬의 글자는 1 인 채 시야만 2배)"
cp "$BAK/player.gd" scripts/player.gd

python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t_player.solid = WorldCollide.solid_from_seed(WORLD_SEED)",
    "\t_player.solid = WorldCollide.solid_from_seed(WORLD_SEED)\n"
    "\tvar cam: Camera2D = _player.get_node(\"Camera\")\n"
    "\tcam.position_smoothing_enabled = true\n\tcam.position_smoothing_speed = 2.0", 1))
PYX
expect 1 "카메라가 부드럽게 끌려오면 실측이 잡는다 (걷는 동안 중심에서 밀린다)"
cp "$BAK/main.gd" scripts/main.gd

# ── 바퀴 9 월드 그리기 ────────────────────────────────────────────────
# 넷 다 **단위 검사 66개를 전부 초록으로 남긴다** — WorldView 의 순수 계산은 멀쩡하고
# main.gd 가 그걸 쓰는 방식만 망가지기 때문이다. measure_draw.gd 만 잡는다.

# 그릴 칸 수도 273 그대로다 — **픽셀을 안 보면 못 잡는다.**
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t\t\tdraw_rect(Rect2(tx * t, ty * t, t, t), _cache[i])\n", "", 1))
PYX
expect 1 "아무것도 안 그리면 그리기 실측이 잡는다 (화면이 배경색뿐)"
cp "$BAK/main.gd" scripts/main.gd

# **사람 눈에는 멀쩡한 섬이 보인다.** 파란 칸을 걸어 다니고 풀밭에서 막힌다 —
# 그림과 충돌이 한 칸씩 다른 월드를 보는 것이다.
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t\t\t_cache[i] = WorldView.color_at(WORLD_SEED, tx, ty)",
    "\t\t\t_cache[i] = WorldView.color_at(WORLD_SEED + 1, tx, ty)", 1))
PYX
expect 1 "다른 씨앗으로 그리면 잡는다 (보이는 땅에 못 선다)"
cp "$BAK/main.gd" scripts/main.gd

# **화면 픽셀은 한 점도 안 달라진다.** 화면 밖 65263칸은 아무 데도 안 보인다 —
# 그래서 main.gd 가 세어 둔 그린 칸 수를 같이 읽는다.
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tvar r := WorldView.tile_range(visible_world_rect())",
    "\tvar r := Rect2i(0, 0, WorldGen.SIZE, WorldGen.SIZE)", 1))
PYX
expect 1 "월드를 통째로 그리면 잡는다 (273 → 65536 칸)"
cp "$BAK/main.gd" scripts/main.gd

# **서 있을 때는 완벽하게 멀쩡하다.** 걸어야 화면이 월드에서 미끄러진다 —
# measure_draw.gd 가 두 번 재는 이유가 이 한 줄이다.
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tif r != _cache_range:\n\t\t_fill_cache(r)",
    "\tif _cache.is_empty():\n\t\t_fill_cache(r)", 1))
PYX
expect 1 "색 캐시를 안 버리면 잡는다 (걸으면 땅이 어긋난다)"
cp "$BAK/main.gd" scripts/main.gd

# **`[서서]` 는 한 점도 안 어긋난다 — `[걷고]` 만 잡는다.** 앞의 ④(캐시를 안 버린다)는
# 해안까지의 순간이동이 이미 캐시를 상하게 해서 `[서서]` 에서 먼저 빨개졌다.
# 여기는 **두 칸 넘게 움직였을 때만** 다시 채운다 — 순간이동(101칸)은 멀쩡히 채우고,
# 한 칸씩 걷는 동안만 한 칸 뒤처진다. **걷는 구간의 존재 이유가 이 한 줄이다.**
python3 - <<'PYZ'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tif r != _cache_range:\n\t\t_fill_cache(r)",
    "\tif r.size != _cache_range.size or (r.position - _cache_range.position).length() >= 2.0:"
    "\n\t\t_fill_cache(r)", 1))
PYZ
expect 1 "캐시를 두 칸마다 채우면 걷는 구간만 잡는다 (서서는 멀쩡하다)"
cp "$BAK/main.gd" scripts/main.gd

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
