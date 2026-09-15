#!/usr/bin/env bash
# 게이트가 살아 있는지 잰다 — 일부러 깨뜨리고 상태 검사가 빨개지는지 본다.
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
# **드라이버 몫은 빼고 본다.** 세션이 끝난 시점에 `.loop/` 와 `docs/JOURNAL.md` ·
# `docs/index.html` 은 드라이버가 방금 쓴 것이라 늘 더럽다 — 그걸 「사람이 안 치웠다」로
# 보면 **`redteam.sh` 를 verify 로 쓰는 항목이 영영 통과 못 한다** (회차 34 가 그랬다).
# 회차 25 가 `worktree.sh` 에서 가른 것과 같은 선이다.
_dirty="$(git status --porcelain 2>/dev/null \
  | grep -vE ' (\.loop/|docs/JOURNAL\.md|docs/index\.html)' || true)"
if [ -n "$_dirty" ]; then
  echo "redteam: 워킹트리가 더럽다. 커밋하거나 치우고 다시 돌려라." >&2
  printf '%s\n' "$_dirty" >&2
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
cp scripts/world_view.gd "$BAK/" 2>/dev/null || true
cp scripts/world_objects.gd "$BAK/" 2>/dev/null || true
cp scripts/inventory.gd "$BAK/" 2>/dev/null || true
cp scripts/hotbar.gd "$BAK/" 2>/dev/null || true
cp scripts/hand_swing.gd "$BAK/" 2>/dev/null || true
cp scripts/harvest.gd "$BAK/" 2>/dev/null || true
cp scripts/world_state.gd "$BAK/" 2>/dev/null || true
cp scripts/claim.gd "$BAK/" 2>/dev/null || true
cp scripts/display.gd "$BAK/" 2>/dev/null || true
cp scripts/day_cycle.gd "$BAK/" 2>/dev/null || true
cp scripts/hotbar_view.gd "$BAK/" 2>/dev/null || true
cp scripts/player.gd "$BAK/" 2>/dev/null || true
cp scripts/main.gd "$BAK/" 2>/dev/null || true
cp scenes/main.tscn "$BAK/" 2>/dev/null || true
cp scenes/player.tscn "$BAK/" 2>/dev/null || true
cp tools/loop/journal.sh "$BAK/" 2>/dev/null || true
cp tools/loop/journal-selftest.sh "$BAK/" 2>/dev/null || true
cp tools/loop/worktree.sh "$BAK/" 2>/dev/null || true
cp tools/loop/worktree-selftest.sh "$BAK/" 2>/dev/null || true
cp tools/loop/loop.sh "$BAK/" 2>/dev/null || true
cp tools/loop/state.py "$BAK/" 2>/dev/null || true
cp tools/loop/state-selftest.sh "$BAK/" 2>/dev/null || true
cp tools/tests/measure_headless.gd "$BAK/" 2>/dev/null || true
cp tools/tests/measure_collide.gd "$BAK/" 2>/dev/null || true
restore() {
  cp "$BAK/project.godot" project.godot 2>/dev/null || true
  cp "$BAK/criteria.tsv" .loop/criteria.tsv 2>/dev/null || true
  cp "$BAK/test_isolation.gd" tools/tests/test_isolation.gd 2>/dev/null || true
  cp "$BAK/PROMPT.md" docs/PROMPT.md 2>/dev/null || true
  cp "$BAK/player_motion.gd" scripts/player_motion.gd 2>/dev/null || true
  cp "$BAK/player_facing.gd" scripts/player_facing.gd 2>/dev/null || true
  cp "$BAK/world_gen.gd" scripts/world_gen.gd 2>/dev/null || true
  cp "$BAK/world_collide.gd" scripts/world_collide.gd 2>/dev/null || true
  cp "$BAK/world_view.gd" scripts/world_view.gd 2>/dev/null || true
  cp "$BAK/world_objects.gd" scripts/world_objects.gd 2>/dev/null || true
  cp "$BAK/inventory.gd" scripts/inventory.gd 2>/dev/null || true
  cp "$BAK/hotbar.gd" scripts/hotbar.gd 2>/dev/null || true
  cp "$BAK/hand_swing.gd" scripts/hand_swing.gd 2>/dev/null || true
  cp "$BAK/harvest.gd" scripts/harvest.gd 2>/dev/null || true
  cp "$BAK/world_state.gd" scripts/world_state.gd 2>/dev/null || true
  cp "$BAK/claim.gd" scripts/claim.gd 2>/dev/null || true
  cp "$BAK/display.gd" scripts/display.gd 2>/dev/null || true
  cp "$BAK/day_cycle.gd" scripts/day_cycle.gd 2>/dev/null || true
  cp "$BAK/hotbar_view.gd" scripts/hotbar_view.gd 2>/dev/null || true
  cp "$BAK/player.gd" scripts/player.gd 2>/dev/null || true
  cp "$BAK/main.gd" scripts/main.gd 2>/dev/null || true
  cp "$BAK/main.tscn" scenes/main.tscn 2>/dev/null || true
  cp "$BAK/player.tscn" scenes/player.tscn 2>/dev/null || true
  cp "$BAK/journal.sh" tools/loop/journal.sh 2>/dev/null || true
  cp "$BAK/journal-selftest.sh" tools/loop/journal-selftest.sh 2>/dev/null || true
  cp "$BAK/worktree.sh" tools/loop/worktree.sh 2>/dev/null || true
  cp "$BAK/worktree-selftest.sh" tools/loop/worktree-selftest.sh 2>/dev/null || true
  cp "$BAK/loop.sh" tools/loop/loop.sh 2>/dev/null || true
  cp "$BAK/state.py" tools/loop/state.py 2>/dev/null || true
  cp "$BAK/state-selftest.sh" tools/loop/state-selftest.sh 2>/dev/null || true
  cp "$BAK/measure_headless.gd" tools/tests/measure_headless.gd 2>/dev/null || true
  cp "$BAK/measure_collide.gd" tools/tests/measure_collide.gd 2>/dev/null || true
  rm -f scripts/_redteam.gd scripts/_redteam.gd.uid
  rm -rf "$BAK"
}
trap restore EXIT

# ── 묶음만 돌리기 ───────────────────────────────────────────────────
#
# **대조군은 「방금 만든 게이트가 진짜 잡나」를 본다.** 이미 통과한 것을 매회 다시
# 돌리는 것은 회귀 검사인데, 그건 상태 검사(기준 7개)가 매 회차 이미 한다.
# 54개를 한 판 돌리면 44.5초 × 54 = **40분**이라 30분짜리 세션이 아예 못 끝낸다.
#
#   redteam.sh --only 핫바      그 묶음만
#   redteam.sh                  전부 (드라이버가 FULL_REDTEAM_EVERY 회차마다 돌린다)
#
# **거르더라도 앞뒤 두 개는 늘 돈다** — 「손 안 댄 상태는 초록이다」와
# 「원복하면 다시 초록이다」. 이게 빠지면 무엇을 쟀는지 알 수가 없다.
ONLY=""
[ "${1:-}" = "--only" ] && { ONLY="${2:?--only 뒤에 묶음 이름}"; shift 2; }
SECTION="기본"
section() { SECTION="$1"; }
skip_section() {                          # 이번 묶음을 건너뛰나
  [ -z "$ONLY" ] && return 1
  [ "$SECTION" = "기본" ] && return 1
  case "$SECTION" in *"$ONLY"*) return 1 ;; esac
  return 0
}

PASS=0; MISS=0; N=0; SKIP=0
# **놓친 대조군의 증거를 남긴다.** 전에는 출력을 통째로 버려서 「놓쳤다」만 뜨고
# 무엇이 왜 빨갰는지 알 방법이 없었다 — 재현하려면 10분을 다시 태워야 했다.
EV="$ROOT/.loop/redteam"; rm -rf "$EV"; mkdir -p "$EV"
expect() {          # expect <기대 exit> <이름>
  local want="$1" name="$2" rc
  if skip_section; then SKIP=$((SKIP+1)); return; fi
  N=$((N+1))
  # **깨뜨렸다고 했는데 정말 깨졌나.** 대조군은 문자열 치환으로 코드를 망가뜨리는데,
  # 나중 회차가 그 사이에 줄을 끼우면 치환이 조용히 빗나간다 — 그러면 상태 검사는
  # 초록이고 「놓쳤다」로 뜬다. 「게이트가 약하다」와 「아무것도 안 깨뜨렸다」는
  # 전혀 다른 일이라 여기서 가른다. 회차 21 이 회차 20 의 대조군을 이렇게 죽였다.
  if [ "$want" -ne 0 ] && [ -z "$(git status --porcelain)" ]; then
    printf '  \033[33m헛돌았다\033[0m  %s  — 워킹트리가 그대로다. 대조군이 아무것도 안 깨뜨렸다\n' "$name"
    MISS=$((MISS+1)); return
  fi
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

# **치환은 줄 하나로 잡는다** (회차 36).
#
# 대조군은 문자열로 코드를 망가뜨리는데, 전에는 **여러 줄을 통째로 맞대거나 인자까지
# 통째로 적어** 두었다. 그러면 나중 회차가 인자를 하나 더하거나 그 사이에 줄을 끼우는
# 순간 치환이 조용히 빗나간다 — 전체 쓸기가 잡은 헛돈 넷이 전부 이것이었다:
#   · `color_at(WORLD_SEED, tx, ty)` 에 회차 29 가 `world.is_cleared(...)` 를 더했다 (둘)
#   · `ORDER` 의 구간이 다섯에서 일곱으로 늘었다 (회차 30 · 31)
#   · `world.occupied = _body_covers` 의 오른쪽이 `claim.covers` 로 바뀌었다 (회차 32)
#
# 그래서 **한 줄을 정규식으로 집고, 못 집으면 그 자리에서 죽는다.** 「게이트가 약하다」와
# 「아무것도 안 깨뜨렸다」를 `expect` 가 가르기는 하지만, 그건 빗나간 **뒤**에 44초를
# 태우고 나서다 — 여기는 빗나간 것을 곧바로 말한다.
mut() {           # mut <파일> <정규식(한 줄)> <바꿀 것.  \1 로 묶음을 되쓴다>
  python3 - "$1" "$2" "$3" <<'PYMUT'
import io, re, sys
path, pat, rep = sys.argv[1], sys.argv[2], sys.argv[3]
s = io.open(path, encoding="utf-8").read()
out, n = re.subn(pat, rep, s, count=1, flags=re.M)
if n != 1 or out == s:
    sys.stderr.write("  \033[33mmut 이 빗나갔다\033[0m  %s  /%s/  — 코드가 움직였다\n"
                     % (path, pat))
    sys.exit(3)
io.open(path, "w", encoding="utf-8").write(out)
PYMUT
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
expect 77 "무장 뒤 상태 검사 변조를 채점자가 잡는다"
cp "$BAK/criteria.tsv" .loop/criteria.tsv

# **이걸 잡는 것은 회차 18 부터 무장된 인자가 아니라 `mintests.sh` 의 HEAD 바닥이다.**
# 검사가 75개인데 무장 인자는 66 이라 하나 지워도 66 위다 — 창이 닫혔는지 여기서 잰다.
python3 - <<'PYX'
import io
p='tools/tests/test_isolation.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s[:s.index('func test_user_data_is_writable')])
PYX
expect 1 "검사를 지우면 테스트 바닥이 잡는다 (HEAD 개수를 따라 올라간 바닥)"
cp "$BAK/test_isolation.gd" tools/tests/test_isolation.gd

# ── P1-1 이동 ────────────────────────────────────────────────────────
section "P1-1 이동"
sed -i '' 's|return input.normalized() \* SPEED|return input * SPEED|' scripts/player_motion.gd
expect 1 "대각선 정규화를 빼면 tests 가 잡는다 (339.41 px/s)"
cp "$BAK/player_motion.gd" scripts/player_motion.gd

# **이 하나가 실측 게이트의 존재 이유다.** 노드가 PlayerMotion 을 부르기는 하므로
# 단위 검사 18개는 전부 초록으로 남는다 — measure_move.gd 만 잡는다 (2026-09-13 실측).
sed -i '' 's|velocity = PlayerMotion.velocity(input)|velocity = PlayerMotion.velocity(input) * 0.5|' scripts/player.gd
expect 1 "노드가 속도를 제 맘대로 바꾸면 실측이 잡는다 (120 px/s)"
cp "$BAK/player.gd" scripts/player.gd

# ── P1-2 화면 ────────────────────────────────────────────────────────
section "P1-2 화면"
# **회차 8 에서 겨눌 곳이 바뀌었다**: 진짜 카메라가 생겼으므로 씬에 카메라를 하나 더
# 덧붙여도 먼저 트리에 들어온 플레이어의 카메라가 화면을 잡는다(선착순) — 아무 일도
# 안 일어나는 가짜 대조군이 된다. 그래서 **그 카메라의 줌을 직접** 건다.
sed -i '' 's|^zoom = Vector2(1, 1)|zoom = Vector2(2, 2)|' scenes/player.tscn
expect 1 "카메라 줌을 걸면 화면 실측이 잡는다 (보이는 칸 30 x 16.88)"
cp "$BAK/player.tscn" scenes/player.tscn

# **회차 33 에 겨눌 곳을 두 번 옮겼다.** `_ready` 맨 앞에 끼우면 바로 다음 줄의
# `Display.fit_window()` 가 창을 도로 게임 크기로 돌려놔서 **아무 일도 안 일어난다** —
# 워킹트리는 더러우니 「헛돌았다」도 안 뜨고 조용히 「놓쳤다」가 된다.
# 값을 바꾼 회차는 **자기를 겨누는 대조군도 같이 옮긴다** (회차 33 이 밤빛에서 배운 것).
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tDisplay.fit_window(get_window())\n",
    "\tDisplay.fit_window(get_window())\n\tDisplayServer.window_set_size(Vector2i(1600, 900))\n", 1))
PYX
expect 1 "창을 실행 중에 줄이면 화면 실측이 잡는다 (배율 3 → 1)"
cp "$BAK/main.gd" scripts/main.gd

# ── P1-3 바라보는 방향 ────────────────────────────────────────────────
section "P1-3 바라보는 방향"
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

# **회차 11 에 새로 넣었다.** 게이트가 메인 씬을 SubViewport 로 옮겼으므로
# 「캔버스 변환을 타는가」가 정말 남아 있는지 물어야 한다 — 안 그러면 커서를
# 창 좌표 그대로 읽어도 통과하는 게이트가 된다. 스폰이 칸 (128,128) 이라
# 변환의 평행이동이 6000 px 대다: 빼먹으면 7구간 중 6개가 빨개진다 (실측).
sed -i '' 's|aim_at(get_global_mouse_position())|aim_at(get_viewport().get_mouse_position())|' scripts/player.gd
expect 1 "커서를 뷰포트 좌표로 읽으면 방향 실측이 잡는다 (캔버스 변환을 빼먹었다)"
cp "$BAK/player.gd" scripts/player.gd

# ── P1-4 월드 생성 ────────────────────────────────────────────────────
section "P1-4 월드 생성"
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
section "P1-5 이동 충돌"
# 앞의 둘은 **단위 검사 53개를 전부 초록으로 남긴다** — WorldCollide 자체는 멀쩡하고
# 그걸 쓰는 배선만 끊기기 때문이다. measure_collide.gd 만 잡는다.
sed -i '' 's|position = WorldCollide.move(position, velocity \* delta, solid)|position += velocity * delta|' scripts/player.gd
expect 1 "노드가 충돌을 안 물으면 실측이 잡는다 (바다 위를 걸어간다)"
cp "$BAK/player.gd" scripts/player.gd

python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t_player.solid = world.solid()", "\tpass", 1))
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
section "P1-6 카메라"
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
    "\t_player.solid = world.solid()",
    "\t_player.solid = world.solid()\n"
    "\tvar cam: Camera2D = _player.get_node(\"Camera\")\n"
    "\tcam.position_smoothing_enabled = true\n\tcam.position_smoothing_speed = 2.0", 1))
PYX
expect 1 "카메라가 부드럽게 끌려오면 실측이 잡는다 (걷는 동안 중심에서 밀린다)"
cp "$BAK/main.gd" scripts/main.gd

# ── 회차 9 월드 그리기 ────────────────────────────────────────────────
section "회차 9 월드 그리기"
# 넷 다 **단위 검사 66개를 전부 초록으로 남긴다** — WorldView 의 순수 계산은 멀쩡하고
# main.gd 가 그걸 쓰는 방식만 망가지기 때문이다. measure_window.gd 의 DRAW 만 잡는다.

# 그릴 칸 수도 2135 그대로다 — **픽셀을 안 보면 못 잡는다.**
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
# **씨앗 인자 하나만 집는다** — 뒤에 무엇이 더 붙든 상관없다 (회차 29 가 `is_cleared` 를
# 더하면서 이 대조군을 조용히 죽였다).
mut scripts/main.gd '^(\t+_cache\[i\] = WorldView\.color_at\()WORLD_SEED,' '\1WORLD_SEED + 1,'
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
expect 1 "월드를 통째로 그리면 잡는다 (2135 → 65536 칸)"
cp "$BAK/main.gd" scripts/main.gd

# **서 있을 때는 완벽하게 멀쩡하다.** 걸어야 화면이 월드에서 미끄러진다 —
# measure_window.gd 의 DRAW 가 두 번 재는 이유가 이 한 줄이다.
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

# ── 회차 16 몸통 1칸 · 발밑 상자 (회차 17 에 타일 16 으로 다시 잰다) ─────
section "회차 16 몸통 1칸 · 발밑 상자 (회차 17 에 타일 16 으로 다시 잰다)"
# **첫째는 단위 검사 66개를 전부 초록으로 남긴다** — 씬의 글자(16 x 32)는 그대로고
# **실행 중의 네모**만 넓어지기 때문이다. 좌표 판정 ①②③ 도 전부 맞는다:
# 멈추는 자리는 충돌 상자가 정하지 그리는 네모가 정하지 않는다.
# 사람 눈에만 「몸이 바다에 잠긴 채 서 있다」로 보인다 — `COLLIDE` 의 ④ 만 잡는다.
python3 - <<'PYX'
import io
p='scripts/player.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "func _ready() -> void:\n\t_place_nose()",
    "func _ready() -> void:\n\t_body.size = Vector2(32, 32)\n\t_place_nose()", 1))
PYX
expect 1 "실행 중에 몸통을 2칸 폭으로 넓히면 충돌 실측이 잡는다 (걸침 1.99 → 9.99 px)"
cp "$BAK/player.gd" scripts/player.gd

# 씬의 글자를 되돌리는 쪽. 이건 단위 검사가 잡아야 한다 — 안 잡으면 씬과 상수가
# 다시 갈라지고, 갈라진 채로 초록인 것이 이 회차가 고친 상태다.
sed -i '' 's|^offset_right = 8.0|offset_right = 16.0|' scenes/player.tscn
expect 1 "몸통을 2칸 폭으로 되돌리면 tests 가 잡는다 (16 → 32px)"
cp "$BAK/player.tscn" scenes/player.tscn

# 발밑 상자를 다시 네모로. 벽 앞에 서는 자리가 세로로 6px 어긋난다 —
# 위아래 벽에서 「반 칸 떨어져 멈추는」 그림으로 돌아간다.
python3 - <<'PYX'
import io
p='scripts/world_collide.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "Vector2(PlayerMotion.TILE * 0.5 - 2.0, PlayerMotion.TILE * 0.25)",
    "Vector2(PlayerMotion.TILE * 0.5 - 2.0, PlayerMotion.TILE * 0.5 - 2.0)", 1))
PYX
expect 1 "충돌 상자를 다시 네모로 만들면 tests 가 잡는다 (발밑 반 칸이 아니다)"
cp "$BAK/world_collide.gd" scripts/world_collide.gd

# ── 회차 18 인벤토리 ─────────────────────────────────────────────────
section "회차 18 인벤토리"
# 순수 클래스라 **단위 검사만 잡는다** — 화면에도 실측에도 아직 안 매달려 있다.
# 그래서 여기서 빨개지지 않으면 「가방이 물건을 먹어도 상태 검사는 초록」이 된다.

# **이 항목의 문장을 정확히 깬다**: 못 넣은 몫을 0 으로 돌려주면 부르는 쪽은
# 「다 들어갔다」고 믿고 그 개수를 버린다. 가방 안의 총합은 한 개도 안 틀린다 —
# 사라지는 것은 **가방 밖**이라 상태를 아무리 세도 안 보인다.
python3 - <<'PYX'
import io
p='scripts/inventory.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t\t\tleft -= put\n\treturn left", "\t\t\tleft -= put\n\treturn 0", 1))
PYX
expect 1 "못 넣은 몫을 0 으로 돌려주면 잡는다 (꽉 찬 가방이 물건을 먹는다)"
cp "$BAK/inventory.gd" scripts/inventory.gd

# 칸 수는 **한 군데서만 숫자다**. 조용히 커지면 「꽉 찬 가방」을 재는 검사가
# 전부 다른 상황을 재게 된다 — 넘치는 몫은 영영 안 생긴다.
sed -i '' 's|^const SLOTS := 18|const SLOTS := 36|' scripts/inventory.gd
expect 1 "가방을 36칸으로 늘리면 tests 가 잡는다 (18칸)"
cp "$BAK/inventory.gd" scripts/inventory.gd

# ── 회차 19 스택 상한 ────────────────────────────────────────────────
section "회차 19 스택 상한"
# **사람이 고른 값은 이름이 아니라 숫자로 묶여 있어야 한다.** 검사들이 전부
# `MAX := Inventory.STACK_MAX` 로만 쓰면 상한이 99 로 돌아가도 한 줄도 안 빨개진다 —
# 「꽉 찬 가방」이 그냥 다른 상황이 될 뿐이라 전부 그대로 통과한다.
sed -i '' 's|^const STACK_MAX := 999|const STACK_MAX := 99|' scripts/inventory.gd
expect 1 "스택 상한을 99 로 되돌리면 tests 가 잡는다 (사람이 정한 999)"
cp "$BAK/inventory.gd" scripts/inventory.gd

# ── 회차 20 핫바 ─────────────────────────────────────────────────────
section "회차 20 핫바"
# **앞의 셋은 단위 검사 90개를 전부 초록으로 남긴다** — 순수 계산도 씬의 글자도
# 입력 배선도 멀쩡하고 **실행 중의 픽셀만** 달라지기 때문이다.
# `measure_window.gd` 의 HOTBAR 만 잡는다. 사람 눈에는 「핫바가 없다 / 숫자를 눌러도
# 아무 일이 없다 / 어느 칸을 들었는지 모르겠다」로만 보인다.

# 씬에도 있고 자리도 맞는데 **안 보인다.** DRAW 는 그 자리를 건너뛰므로
# 「월드가 다 잘 그려졌다」로 초록이다 — HOTBAR 가 없으면 아무도 못 잡는다.
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t_hotbar_view.hotbar = hotbar\n",
    "\t_hotbar_view.hotbar = hotbar\n\t_hotbar_view.visible = false\n", 1))
PYX
expect 1 "핫바를 숨기면 실측이 잡는다 (씬에는 그대로 달려 있다)"
cp "$BAK/main.gd" scripts/main.gd

# **이 하나가 「숫자키로 손에 들기」의 게이트다.** 액션은 묶여 있고 `Hotbar.select` 도
# 멀쩡하다 — 아무도 키를 안 읽을 뿐이다.
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t_poll_hotbar()\n", "", 1))
PYX
expect 1 "숫자키를 안 읽으면 실측이 잡는다 (손이 1번 칸에 굳는다)"
cp "$BAK/main.gd" scripts/main.gd

# 손은 옮겨 가는데 **화면이 안 변한다.** 상태만 보는 검사로는 못 잡는다 —
# 9칸이 늘 똑같이 보여서 사람은 무엇을 들었는지 모른다.
python3 - <<'PYX'
import io
p='scripts/hotbar_view.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "const EDGE_HELD := Color(0.99, 0.93, 0.78)",
    "const EDGE_HELD := Color(0.35, 0.37, 0.42)", 1))
PYX
expect 1 "손에 든 칸을 똑같이 그리면 잡는다 (강조된 칸 1 → 9)"
cp "$BAK/hotbar_view.gd" scripts/hotbar_view.gd

# **사람이 정한 값은 숫자로 묶여 있어야 한다** (회차 19 와 같은 자리).
# 9칸은 숫자키 1..9 한 줄이라서 9 다 — 8칸이 되면 키 9 가 갈 곳이 없다.
sed -i '' 's|^const SLOTS := 9|const SLOTS := 8|' scripts/hotbar.gd
expect 1 "핫바를 8칸으로 줄이면 tests 가 잡는다 (숫자키 9 가 갈 곳이 없다)"
cp "$BAK/hotbar.gd" scripts/hotbar.gd

# 「화면 **아래** 상시」다. 위로 올리면 캐릭터 머리 위를 덮는다.
python3 - <<'PYX'
import io
p='scripts/hotbar_view.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "screen.y - MARGIN - SLOT, w, SLOT)", "MARGIN, w, SLOT)", 1))
PYX
expect 1 "핫바를 화면 위로 올리면 잡는다 (아래 여백 8 → 500px)"
cp "$BAK/hotbar_view.gd" scripts/hotbar_view.gd

# ── 회차 21 좌클릭 = 손에 든 것의 동작 ───────────────────────────────
section "회차 21 좌클릭 = 손에 든 것의 동작"
# **앞의 셋은 실행 중의 픽셀만 달라진다** — 씬도 배선도 순수 계산도 멀쩡하다.
# 사람 눈에는 「클릭해도 아무 일이 없다 / 무엇을 들어도 똑같다」로만 보인다.

# **이 하나가 이번 항목의 문장이다**: 「대상이 없어도 사용 모션이 나온다」.
# 맞힐 것을 먼저 찾게 만들면, 맞힐 것이 아직 월드에 없으므로 클릭이 통째로 죽는다.
python3 - <<'PYX'
import io
p='scripts/player.gd'; s=io.open(p,encoding='utf-8').read()
s = s.replace("\tif not swing.start():\n", "\tif not _has_target() or not swing.start():\n", 1)
io.open(p,'w',encoding='utf-8').write(s + "\nfunc _has_target() -> bool:\n\treturn false\n")
PYX
expect 1 "대상이 있어야만 휘두르게 하면 잡는다 (맞힐 것이 아직 월드에 없다)"
cp "$BAK/player.gd" scripts/player.gd

# 액션은 묶여 있고 `Player.use` 도 멀쩡하다 — 아무도 버튼을 안 읽을 뿐이다.
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace("\t_poll_use()\n", "", 1))
PYX
expect 1 "좌클릭을 안 읽으면 실측이 잡는다 (모션이 한 번도 안 나온다)"
cp "$BAK/main.gd" scripts/main.gd

# 모션은 도는데 **화면에 안 나온다.** 상태만 보는 검사로는 못 잡는다.
python3 - <<'PYX'
import io
p='scripts/player.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t_tool.visible = swing.is_swinging()", "\t_tool.visible = false", 1))
PYX
expect 1 "휘두르는 네모를 안 그리면 잡는다 (상태는 도는데 화면이 그대로다)"
cp "$BAK/player.gd" scripts/player.gd

# 「**손에 든 것**의 동작」이다 — 무엇을 들어도 같은 색이면 그냥 아무 네모다.
python3 - <<'PYX'
import io
p='scripts/hand_swing.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\treturn BARE if held_id == Inventory.EMPTY else HotbarView.item_color(held_id)",
    "\treturn BARE", 1))
PYX
expect 1 "무엇을 들든 같은 색으로 휘두르면 잡는다 (손에 든 것이 화면에 안 보인다)"
cp "$BAK/hand_swing.gd" scripts/hand_swing.gd

# **모션은 「네모가 뜬다」가 아니라 「네모가 움직인다」다.** 부채꼴이 0 이면 한 자리에 붙박인다.
sed -i '' 's|^const ARC_DEG := 90.0|const ARC_DEG := 0.0|' scripts/hand_swing.gd
expect 1 "부채꼴을 0 도로 만들면 잡는다 (네모가 한 자리에 붙박인다)"
cp "$BAK/hand_swing.gd" scripts/hand_swing.gd

# ── 회차 24 월드 오브젝트 배치 ───────────────────────────────────────
section "회차 24 월드 오브젝트 배치"
# 배치는 순수 계산이라 **거의 다 단위 검사가 잡는다** — 그래서 두 개를 일부러
# 딴 데로 겨눈다: ③ 은 단위 검사 113개를 전부 초록으로 남기고(프로세스 간 비교만 잡는다),
# ⑥ 은 순수 계산이 멀쩡한 채 **화면에만** 안 나온다.

# ① 물 위에 뜬 나무. **지형 체크섬은 한 글자도 안 변한다** — 지형을 안 건드렸으니까.
python3 - <<'PYX'
import io
p='scripts/world_objects.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tif WorldGen.kind_at_height(h) != WorldGen.LAND:", "\tif false:", 1))
PYX
expect 1 "바다에도 놓으면 tests 가 잡는다 (물 위에 뜬 나무)"
cp "$BAK/world_objects.gd" scripts/world_objects.gd

# ② 스폰 빈터를 없앤다. 상수는 3 그대로라 **검사가 읽는 값은 안 변한다** —
#    사람 눈에는 「어떤 씨앗에서는 시작하자마자 나무에 갇힌다」로만 보인다.
python3 - <<'PYX'
import io
p='scripts/world_objects.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tvar sp := WorldGen.spawn_tile()\n"
    "\tif absi(x - sp.x) <= SPAWN_CLEAR and absi(y - sp.y) <= SPAWN_CLEAR:\n"
    "\t\treturn NONE\n", "", 1))
PYX
expect 1 "스폰 빈터를 없애면 tests 가 잡는다 (나무 속에서 시작한다)"
cp "$BAK/world_objects.gd" scripts/world_objects.gd

# ③ **이 하나가 배치까지 프로세스 간 게이트에 태운 이유다** (회차 6 과 같은 모양).
#    한 프로세스 안에서는 늘 같은 자리라 단위 검사 113개가 전부 초록으로 남는다 —
#    사람 눈에는 「어제 심은 나무가 오늘 딴 자리」로만 보이고 섬은 똑같다.
python3 - <<'PYX'
import io
p='scripts/world_objects.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "const NONE := 0",
    "static var _drift := int(Time.get_unix_time_from_system() * 1000.0)\nconst NONE := 0", 1).replace(
    "WorldGen.unit(world_seed ^ PLACE_SALT, x, y)",
    "WorldGen.unit(world_seed ^ PLACE_SALT ^ _drift, x, y)", 1))
PYX
expect 1 "배치에 시간을 섞으면 프로세스 간 실측이 잡는다 (어제 심은 나무 ≠ 오늘)"
cp "$BAK/world_objects.gd" scripts/world_objects.gd

# ④ 나무를 고르게 흩뿌린다. **밀도도 종류도 그대로다** — 뭉침 배수만 2.3 에서 1.0 으로
#    내려간다. 사람 눈에는 「어디를 가도 똑같아서 갈 곳이 없다」로 보인다.
python3 - <<'PYX'
import io
p='scripts/world_objects.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tvar f := FOREST_CELLS / float(WorldGen.SIZE)\n"
    "\tvar n := WorldGen.value(world_seed ^ FOREST_SALT, x * f, y * f)\n"
    "\treturn TREE_MAX * clampf(inverse_lerp(FOREST_FLOOR, 1.0, n), 0.0, 1.0)",
    "\treturn 0.09", 1))
PYX
expect 1 "나무를 고르게 흩뿌리면 tests 가 잡는다 (숲이 없다 · 밀도는 그대로)"
cp "$BAK/world_objects.gd" scripts/world_objects.gd

# ⑤ 광물을 해안에도 놓는다. 개수는 거의 안 변한다 — 「산에 간다」가 없어질 뿐이다.
sed -i '' 's|^const ORE_MIN_HEIGHT := 0.55|const ORE_MIN_HEIGHT := 0.0|' scripts/world_objects.gd
expect 1 "광물 높이 문턱을 없애면 tests 가 잡는다 (해안에서 줍는다)"
cp "$BAK/world_objects.gd" scripts/world_objects.gd

# ⑥ 나무를 통과해 걸어간다. **화면은 한 픽셀도 안 달라진다** — 그려지기는 그려진다.
python3 - <<'PYX'
import io
p='scripts/world_collide.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t\treturn WorldObjects.at_height(world_seed, tx, ty, h) != WorldObjects.NONE",
    "\t\treturn false", 1))
PYX
expect 1 "놓인 것이 안 막으면 tests 가 잡는다 (나무를 통과해 걷는다)"
cp "$BAK/world_collide.gd" scripts/world_collide.gd

# ⑦ **놓기는 놓았는데 화면에 없다.** 순수 계산은 한 줄도 안 틀렸다 —
#    `main.gd` 가 지형색만 칠할 뿐이라 단위 검사 113개가 전부 초록이다.
#    구운 픽셀을 `color_at` 과 맞추는 DRAW 만 잡는다.
#    **오른쪽을 통째로 갈아 끼운다** — `color_at` 의 인자가 몇 개든 `terrain_color` 의
#    셋으로 바뀐다 (여기도 회차 29 의 `is_cleared` 에 빗나가 있었다).
mut scripts/main.gd '^(\t+_cache\[i\] = )WorldView\.color_at\(WORLD_SEED, tx, ty.*$' \
    '\1WorldView.terrain_color(WORLD_SEED, tx, ty)'
expect 1 "놓인 것을 화면에 안 그리면 그리기 실측이 잡는다 (배치는 멀쩡하다)"
cp "$BAK/main.gd" scripts/main.gd

# ── 회차 22 일지를 세션의 마지막 답변에서 뽑는다 ─────────────────────
section "회차 22 일지를 세션의 마지막 답변에서 뽑는다"
#
# 여기가 겨누는 것은 하나다: **일지가 조용히 비는 길.** 회차 12 · 21 이 그 길로 갔다.
#
# **재는 자리가 승격을 따라 옮겨 간다** (회차 23): 뽑기 게이트가 무장된 기준에 올라가 있으면
# `journal-selftest.sh` 를 직접 부르지 않고 **상태 검사로** 잰다 — 진짜 질문은 「검사가
# 빨개지나」가 아니라 「**무장된 채점자가** 빨개지나」이기 때문이다. 직접 부르는 동안에는
# 기준에서 그 줄이 빠져도 대조군은 여전히 초록이라 아무도 모른다.
# 아직 승격 전이면(첫 회차) 예전처럼 직접 부르고, 그렇다고 말한다.
if bash tools/loop/journal.sh promoted >/dev/null 2>&1; then
  VIA_CONTRACT=1; echo "  (뽑기 게이트는 무장된 기준이다 — 상태 검사로 잰다)"
else
  VIA_CONTRACT=0; echo "  (뽑기 게이트가 아직 기준이 아니다 — journal-selftest.sh 를 직접 부른다)"
fi

expect_journal() {  # expect_journal <기대 exit> <이름>
  local want="$1" name="$2" rc
  if skip_section; then SKIP=$((SKIP+1)); return; fi
  N=$((N+1))
  if [ "$want" -ne 0 ] && [ -z "$(git status --porcelain)" ]; then
    printf '  \033[33m헛돌았다\033[0m  %s  — 워킹트리가 그대로다. 대조군이 아무것도 안 깨뜨렸다\n' "$name"
    MISS=$((MISS+1)); return
  fi
  if [ "$VIA_CONTRACT" = "1" ]; then
    bash tools/loop/run-contract.sh >"$EV/journal.txt" 2>&1; rc=$?
  else
    bash tools/loop/journal-selftest.sh >"$EV/journal.txt" 2>&1; rc=$?
  fi
  if [ "$rc" -eq "$want" ]; then
    printf '  \033[32m잡았다\033[0m  %s  (exit %d)\n' "$name" "$rc"; PASS=$((PASS+1))
  else
    printf '  \033[31m놓쳤다\033[0m  %s  (기대 exit %d · 잰 값 %d)\n' "$name" "$want" "$rc"; MISS=$((MISS+1))
    grep -E '^  FAIL|^JOURNAL SELFTEST|빨강' "$EV/journal.txt" | sed 's/^/      /'
  fi
}

expect_journal 0 "손 안 댄 뽑기는 초록이다"

# **블록이 없는데 조용히 넘어가는 것**이 제일 비싼 고장이다 — 일지가 비어도 초록이라
# 며칠 뒤에야 보인다. 회차 12 · 21 이 정확히 이 모양이었다.
python3 - <<'PYX'
import io
p='tools/loop/journal.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    '    print(f"마지막 답변에 `## 회차 {n}` 블록이 없다 — 세션이 일지를 안 적었다")\n    sys.exit(1)',
    '    sys.exit(0)', 1))
PYX
expect_journal 1 "블록이 없는데 조용히 넘어가면 잡는다 (일지가 빈 채로 초록)"
cp "$BAK/journal.sh" tools/loop/journal.sh

# 세션이 「결과: 됐습니다 · 채점: 전부 초록입니다」를 써 보내는 것을 그대로 받으면
# 일지가 **증거가 아니라 자기 보고**가 된다. 줄의 주인이 지워지는 자리다.
python3 - <<'PYX'
import io
p='tools/loop/journal.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    '        dropped.append(k)                       # 줄의 주인이 아니다. 버린다',
    '        got[k] = v[0].rstrip()', 1))
PYX
expect_journal 1 "드라이버 줄을 안 버리면 잡는다 (세션의 「됐습니다」가 결과 칸에 들어간다)"
cp "$BAK/journal.sh" tools/loop/journal.sh

# 답변에 일지 블록**만** 들어 있지 않다 — 앞에 요약이 있고 뒤에 diff 가 있다.
python3 - <<'PYX'
import io
p='tools/loop/journal.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    '    for m in head.finditer(t):',
    '    for m in ([head.match(t)] if head.match(t) else []):', 1))
PYX
expect_journal 1 "답변 맨 앞의 블록만 보면 잡는다 (요약 뒤의 일지를 못 찾는다)"
cp "$BAK/journal.sh" tools/loop/journal.sh

# 뽑기는 **덮어쓴다**. 그냥 끼우면 한 번 다시 뽑는 것만으로 같은 회차 절이 둘이 되고
# `journal.sh next` 가 세는 번호부터 어긋난다.
python3 - <<'PYX'
import io
p='tools/loop/journal.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace('m = sec.search(jt)', 'm = None', 1))
PYX
expect_journal 1 "두 번 뽑으면 절이 둘이 되는 것을 잡는다"
cp "$BAK/journal.sh" tools/loop/journal.sh

# 템플릿을 그대로 되돌려 보낸 것은 일지가 아니다. `check` 는 자리표시자도 글자로 보고
# 통과시키므로 거르는 자리는 여기뿐이다.
python3 - <<'PYX'
import io
p='tools/loop/journal.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    '    return v.startswith("<") and v.endswith(">")', '    return False', 1))
PYX
expect_journal 1 "자리표시자를 안 거르면 잡는다 (템플릿이 그대로 일지가 된다)"
cp "$BAK/journal.sh" tools/loop/journal.sh

# 일지 줄은 거의 다 여러 줄이다. 첫 줄만 받으면 「왜 그랬나」가 통째로 날아간다.
python3 - <<'PYX'
import io
p='tools/loop/journal.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    '        val = "\\n".join(["  " + x for x in v[1:]])', '        val = ""', 1))
PYX
expect_journal 1 "이어지는 줄을 버리면 잡는다 (일지의 절반이 날아간다)"
cp "$BAK/journal.sh" tools/loop/journal.sh

# 검사 자신을 무르게 만드는 길도 막는다 — 실패가 0 이어도 **개수가 줄면** 빨개진다.
python3 - <<'PYX'
import io
p='tools/loop/journal-selftest.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    'rc_is "블록이 없으면 exit 1" 1 $JSH extract 22 "$TMP/c.txt"', 'true', 1))
PYX
expect_journal 1 "뽑기 검사를 지우면 검사 바닥이 잡는다"
cp "$BAK/journal-selftest.sh" tools/loop/journal-selftest.sh

# **승격을 안 하고 「올렸다」고 말하는 길** (회차 23). `promoted` 가 늘 초록이면
# 기준에서 줄이 빠져도 아무도 모른다 — 게이트는 있는데 아무도 안 돌리는 상태가 굳는다.
python3 - <<'PYX'
import io
p='tools/loop/journal.sh'; s=io.open(p,encoding='utf-8').read()
i=s.index('  promoted)\n')
io.open(p,'w',encoding='utf-8').write(s[:i] + '  promoted)\n    exit 0\n' + s[i+len('  promoted)\n'):])
PYX
expect_journal 1 "승격 확인이 늘 초록이면 잡는다 (안 올리고 올렸다고 한다)"
cp "$BAK/journal.sh" tools/loop/journal.sh

expect_journal 0 "원복하면 뽑기도 다시 초록이다"

# ── 회차 25 세션이 흘린 것을 되돌린다 ────────────────────────────────
section "회차 25 세션이 흘린 것을 되돌린다"
#
# 겨누는 것은 하나다: **세션이 손으로 깨뜨린 것이 커밋 없이 떠 있는 채로 회차가 닫히는 길.**
# 회차 24 가 그 길로 갔다 — 대조군으로 `inventory.gd` 의 `return left` 를 `return 0` 으로
# 바꿔 놓고 원복을 안 했다. 커밋엔 안 들어갔지만 채점자는 그 상태를 쟀고, 다음 회차가
# 경로를 넓게 잡아 커밋했으면 꽉 찬 인벤토리가 아이템을 조용히 삼켰다.
#
# **여기는 `run-contract.sh` 가 아니라 `worktree-selftest.sh` 로 잰다.** 되돌리기는
# 게임 코드가 아니라 **드라이버의 회차 진행**에 붙어 있어서 상태 검사가 볼 수 있는
# 자리가 아니다 (기준으로 승격되면 `promoted` 처럼 옮겨 갈 자리다).
expect_worktree() {  # expect_worktree <기대 exit> <이름>
  local want="$1" name="$2" rc
  if skip_section; then SKIP=$((SKIP+1)); return; fi
  N=$((N+1))
  if [ "$want" -ne 0 ] && [ -z "$(git status --porcelain)" ]; then
    printf '  \033[33m헛돌았다\033[0m  %s  — 워킹트리가 그대로다. 대조군이 아무것도 안 깨뜨렸다\n' "$name"
    MISS=$((MISS+1)); return
  fi
  bash tools/loop/worktree-selftest.sh >"$EV/worktree.txt" 2>&1; rc=$?
  if [ "$rc" -eq "$want" ]; then
    printf '  \033[32m잡았다\033[0m  %s  (exit %d)\n' "$name" "$rc"; PASS=$((PASS+1))
  else
    printf '  \033[31m놓쳤다\033[0m  %s  (기대 exit %d · 잰 값 %d)\n' "$name" "$want" "$rc"; MISS=$((MISS+1))
    grep -E '^  FAIL|^WORKTREE SELFTEST' "$EV/worktree.txt" | sed 's/^/      /'
  fi
}

expect_worktree 0 "손 안 댄 되돌리기는 초록이다"

# **아무것도 안 세는 길** — 제일 비싼 고장이다. `check` 가 늘 초록이면 드라이버는
# 「세션이 흘린 게 없다」고 믿고 그대로 채점한다. 회차 24 가 정확히 그 모양이었다.
python3 - <<'PYX'
import io
p='tools/loop/worktree.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "    [ \"$n\" -eq 0 ] && { echo \"WORKTREE 깨끗하다 — 세션이 흘린 것 없음\"; exit 0; }",
    "    echo \"WORKTREE 깨끗하다 — 세션이 흘린 것 없음\"; exit 0", 1))
PYX
expect_worktree 1 "흘린 것을 안 세면 잡는다 (늘 깨끗하다고 한다)"
cp "$BAK/worktree.sh" tools/loop/worktree.sh

# **찍기만 하고 안 되돌리는 길.** 「빨갛게는 하는데 고치지는 않는」 게이트다 —
# 드라이버는 6c 에서 `restore` 뒤에 다시 묻지만, restore 가 거짓 초록이면 그 질문이
# 통과한다. 여기서 원복이 진짜 일어났는지를 파일 내용으로 묶는다.
python3 - <<'PYX'
import io
p='tools/loop/worktree.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    'restore_one() {                            # restore_one <XY> <경로>',
    'restore_one() { printf \'  되돌림  %s\\n\' "$2"; return 0; }\n_unused_restore_one() {', 1))
PYX
expect_worktree 1 "되돌리는 시늉만 하면 잡는다 (찍기만 하고 파일은 그대로)"
cp "$BAK/worktree.sh" tools/loop/worktree.sh

# **드라이버 몫까지 쓸어 버리는 길.** 되돌리기가 `docs/JOURNAL.md` 를 같이 지우면
# 6b 가 방금 답변에서 뽑은 일지가 6c 에서 날아간다 — 그러면 초록인데 일지가 비었다고
# 루프가 멈추고, 왜 비었는지는 아무 데도 안 남는다.
python3 - <<'PYX'
import io
p='tools/loop/worktree.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    '    .loop|.loop/*|docs/JOURNAL.md|docs/index.html) return 0 ;;',
    '    .loop|.loop/*) return 0 ;;', 1))
PYX
expect_worktree 1 "일지를 드라이버 몫에서 빼면 잡는다 (되돌리기가 일지를 지운다)"
cp "$BAK/worktree.sh" tools/loop/worktree.sh

# HEAD 에 없는 것(세션이 새로 만든 파일)은 되돌릴 판본이 없어서 **지워야** 한다.
# 그냥 두면 다음 회차의 워킹트리가 더러운 채로 시작한다.
python3 - <<'PYX'
import io
p='tools/loop/worktree.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace('    rm -rf -- "$p"\n', '', 1))
PYX
expect_worktree 1 "새로 만든 파일을 안 지우면 잡는다"
cp "$BAK/worktree.sh" tools/loop/worktree.sh

# 되돌리기가 제 일을 했는지 **다시 묻는** 자리를 없애는 길 (회차 23 과 같은 모양이다).
python3 - <<'PYX'
import io
p='tools/loop/worktree.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace('    rest="$(leftovers)"', '    rest=""', 1))
PYX
expect_worktree 1 "되돌린 뒤 다시 안 물으면 잡는다"
cp "$BAK/worktree.sh" tools/loop/worktree.sh

# 검사 자신을 무르게 만드는 길 — 실패가 0 이어도 **개수가 줄면** 빨개진다.
python3 - <<'PYX'
import io
p='tools/loop/worktree-selftest.sh'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    'rc_is "고쳐만 두고 커밋 안 하면 잡는다" 1 check', 'true', 1))
PYX
expect_worktree 1 "되돌리기 검사를 지우면 검사 바닥이 잡는다"
cp "$BAK/worktree-selftest.sh" tools/loop/worktree-selftest.sh

expect_worktree 0 "원복하면 되돌리기도 다시 초록이다"

sed -i '' 's|"events": \[Object(InputEventKey,"physical_keycode":68)\]|"events": []|' project.godot
expect 1 "WASD 배선이 끊기면 tests 가 잡는다"
cp "$BAK/project.godot" project.godot

for i in $(seq 1 40); do echo "부풀리는 줄 $i" >> docs/PROMPT.md; done
expect 1 "매 회차 읽는 문서를 부풀리면 잡는다"
cp "$BAK/PROMPT.md" docs/PROMPT.md

expect 0 "원복하면 다시 초록이다"



# ── 회차 26 판정 앞에서 회차 기록을 굴린다 ──────────────────────────
section "회차 26 판정 앞에서 회차 기록을 굴린다"
#
# 겨누는 것은 하나다: **채점자가 재는 `.loop/state.md` 와 다음 회차가 읽는 것이 달라지는 길.**
# 자르기가 초록 **뒤**에 있으면 세션이 방금 붙인 절 하나가 상한을 넘겨 그 회차만 빨갛고,
# 다음 회차엔 저절로 초록이 된다 — 고칠 것이 없는데 빨간 회차라 정지 규칙 3(같은 실패
# 두 회차)이 엉뚱하게 울린다. 회차 25 가 98줄 · 상한 90 으로 그 길을 갔다.
#
# **여기도 `run-contract.sh` 가 아니라 `state-selftest.sh` 로 잰다** — 자르는 자리는
# 게임 코드가 아니라 드라이버의 회차 진행이라 상태 검사가 볼 수 있는 데가 아니다
# (회차 25 의 `worktree-selftest.sh` 와 같은 자리다).
expect_state() {   # expect_state <기대 exit> <이름>
  local want="$1" name="$2" rc
  if skip_section; then SKIP=$((SKIP+1)); return; fi
  N=$((N+1))
  if [ "$want" -ne 0 ] && [ -z "$(git status --porcelain)" ]; then
    printf '  \033[33m헛돌았다\033[0m  %s  — 워킹트리가 그대로다. 대조군이 아무것도 안 깨뜨렸다\n' "$name"
    MISS=$((MISS+1)); return
  fi
  bash tools/loop/state-selftest.sh >"$EV/state.txt" 2>&1; rc=$?
  if [ "$rc" -eq "$want" ]; then
    printf '  \033[32m잡았다\033[0m  %s  (exit %d)\n' "$name" "$rc"; PASS=$((PASS+1))
  else
    printf '  \033[31m놓쳤다\033[0m  %s  (기대 exit %d · 잰 값 %d)\n' "$name" "$want" "$rc"; MISS=$((MISS+1))
    grep -E '^  FAIL|^STATE SELFTEST' "$EV/state.txt" | sed 's/^/      /'
  fi
}

expect_state 0 "손 안 댄 자르기는 초록이다"

# **회차 25 를 그대로 되풀이하는 길** — 자르기를 판정 뒤(초록 자리)로 도로 옮긴다.
# 자르기 자체는 멀쩡해서 state.py 검사는 전부 초록이다. 순서만 틀린다.
python3 - <<'PYX'
import io
p='tools/loop/loop.sh'; s=io.open(p,encoding='utf-8').read()
s = s.replace('  trim_state\n\n  # 7) 판정', '  # 7) 판정', 1)
s = s.replace('    commit_state_roll\n', '    trim_state\n    commit_state_roll\n', 1)
io.open(p,'w',encoding='utf-8').write(s)
PYX
expect_state 1 "자르기를 판정 뒤로 옮기면 잡는다 (회차 25 가 간 길)"
cp "$BAK/loop.sh" tools/loop/loop.sh

# **자르기가 커밋까지 하는 길.** 둘을 도로 합치면 `head_after` 가 「회차 기록 롤링」을
# 가리켜서, 일지의 커밋 칸이 항목을 만든 커밋을 못 짚는다 (회차 12 · 21 이 잃은 것).
python3 - <<'PYX'
import io
p='tools/loop/loop.sh'; s=io.open(p,encoding='utf-8').read()
s = s.replace('  say "$(python3 tools/loop/state.py roll "$STATE_KEEP")"\n',
              '  say "$(python3 tools/loop/state.py roll "$STATE_KEEP")"\n'
              '  git add .loop/state.md .loop/archive 2>/dev/null || true\n', 1)
io.open(p,'w',encoding='utf-8').write(s)
PYX
expect_state 1 "자르기가 커밋까지 하면 잡는다"
cp "$BAK/loop.sh" tools/loop/loop.sh

# **아무것도 안 자르는 길** — 제일 비싼 고장이다. 순서를 앞으로 옮겨 놓고 자르기가
# 헛돌면, 판정은 통째로 자란 파일을 재고 회차는 영영 빨갛다.
python3 - <<'PYX'
import io
p='tools/loop/state.py'; s=io.open(p,encoding='utf-8').read()
s = s.replace('        if len(cycles) <= n:', '        if True:', 1)
io.open(p,'w',encoding='utf-8').write(s)
PYX
expect_state 1 "아무것도 안 자르면 잡는다"
cp "$BAK/state.py" tools/loop/state.py

# **반대쪽 고장 — 통째로 비우는 길.** doclen 은 기뻐하지만 다음 회차가 읽을 꼬리가
# 없어진다. 「짧으면 초록」만 재면 이 길이 열린다.
python3 - <<'PYX'
import io
p='tools/loop/state.py'; s=io.open(p,encoding='utf-8').read()
s = s.replace('        old, keep = cycles[:-n], cycles[-n:]', '        old, keep = cycles, []', 1)
io.open(p,'w',encoding='utf-8').write(s)
PYX
expect_state 1 "통째로 비우면 잡는다 (짧아지기만 하면 된다가 아니다)"
cp "$BAK/state.py" tools/loop/state.py

# **아카이브를 덮어쓰는 길.** 잘린 회차가 조용히 사라진다 — 초록이라 아무도 안 본다.
python3 - <<'PYX'
import io
p='tools/loop/state.py'; s=io.open(p,encoding='utf-8').read()
s = s.replace('with io.open(ARCH, "a", encoding="utf-8") as f:',
              'with io.open(ARCH, "w", encoding="utf-8") as f:', 1)
io.open(p,'w',encoding='utf-8').write(s)
PYX
expect_state 1 "아카이브를 덮어쓰면 잡는다"
cp "$BAK/state.py" tools/loop/state.py

# 머리말을 같이 버리는 길 — 파일이 짧아져서 doclen 은 초록이다.
python3 - <<'PYX'
import io
p='tools/loop/state.py'; s=io.open(p,encoding='utf-8').read()
s = s.replace('io.open(STATE, "w", encoding="utf-8").write(head + "".join(keep))',
              'io.open(STATE, "w", encoding="utf-8").write("".join(keep))', 1)
io.open(p,'w',encoding='utf-8').write(s)
PYX
expect_state 1 "머리말을 버리면 잡는다"
cp "$BAK/state.py" tools/loop/state.py

# 검사 자신을 무르게 만드는 길 — 실패가 0 이어도 **개수가 줄면** 빨개진다.
python3 - <<'PYX'
import io
p='tools/loop/state-selftest.sh'; s=io.open(p,encoding='utf-8').read()
s = s.replace('doclen 90 && bad "남은 절이 두꺼우면 자른 뒤에도 빨갛다" \\\n           || ok "남은 절이 두꺼우면 자른 뒤에도 빨갛다"', 'true', 1)
io.open(p,'w',encoding='utf-8').write(s)
PYX
expect_state 1 "무뎌짐 검사를 지우면 검사 바닥이 잡는다"
cp "$BAK/state-selftest.sh" tools/loop/state-selftest.sh

expect_state 0 "원복하면 자르기도 다시 초록이다"


section "회차 27 헤드리스 실측을 한 프로세스로"
#
# 겨누는 것은 하나다: **합치면 열리는 「반쪽만 돌고 죽어도 초록」.** 구간 넷이 한
# 프로세스를 나눠 쓰므로 앞 구간이 죽으면 뒤 구간은 **아예 안 돈다** — 그런데
# 프로세스는 exit 0 으로 끝난다. 회차 14 가 창 넷을 합칠 때 `WINGATE` 로 막은 자리고,
# **여기가 그 두 번째다.** 아래 셋은 전부 「프로세스가 exit 0 인데 게이트가 침묵한」
# 경우라, 종료 코드만 보는 게이트는 하나도 못 잡는다.

# ① **구간이 조용히 죽는다.** COLLIDE 가 서기 직전에 프로세스를 끝낸다 —
#    MOVE·WORLD 는 찍히고 COLLIDE·CAMERA·HEADGATE 만 침묵한다. **exit 0 이다.**
python3 - <<'PYX'
import io
p='tools/tests/measure_collide.gd'; s=io.open(p,encoding='utf-8').read()
old = 'func begin(t: SceneTree) -> void:\n\tsuper(t)\n\tvar scene'
new = 'func begin(t: SceneTree) -> void:\n\tsuper(t)\n\ttree.quit(0)\n\treturn\n\tvar scene'
io.open(p,'w',encoding='utf-8').write(s.replace(old, new, 1))
PYX
expect 1 "앞 구간이 죽어 뒤가 통째로 침묵하면 tests 가 잡는다 (프로세스는 exit 0)"
cp "$BAK/measure_collide.gd" tools/tests/measure_collide.gd

# ② **구간을 조용히 뺀다.** 남은 여섯은 전부 초록이고 프로세스도 exit 0 이다.
#    `HEADGATE` 가 `구간 7/7` 대신 `6/6` 을 찍는 것 하나만 다르다 —
#    **세는 수를 게이트와 check.sh 가 나눠 가지는 이유가 이것이다.**
#    **맨 뒤 하나를 이름 모르게 떼어낸다**: 구간 이름을 여기 적어 두면 구간이 늘 때마다
#    (회차 30 이 `regrow`, 31 이 `day` 를 더했다) 치환이 조용히 빗나간다.
mut tools/tests/measure_headless.gd '^(const ORDER := \[.*), "[a-z]+"\]$' '\1]'
expect 1 "구간을 조용히 빼면 tests 가 잡는다 (나머지는 다 초록이고 exit 0)"
cp "$BAK/measure_headless.gd" tools/tests/measure_headless.gd

# ③ **앞 구간이 제 씬을 두고 간다.** 합치기 전에는 없던 고장이다 — 프로세스가 갈렸으니까.
#    메인 씬이 둘이면 카메라도 둘이고, 먼저 들어온 쪽이 current 로 남는다:
#    CAMERA 는 제 플레이어를 **딴 카메라의 변환**으로 찍어 보게 된다.
python3 - <<'PYX'
import io
p='tools/tests/measure_collide.gd'; s=io.open(p,encoding='utf-8').read()
old = 'func cleanup() -> void:\n\tsuper()\n\tdrop(_main)'
new = 'func cleanup() -> void:\n\tsuper()'
io.open(p,'w',encoding='utf-8').write(s.replace(old, new, 1))
PYX
expect 1 "앞 구간이 씬을 두고 가면 tests 가 잡는다 (카메라가 둘이 된다)"
cp "$BAK/measure_collide.gd" tools/tests/measure_collide.gd

expect 0 "원복하면 한 프로세스 실측도 다시 초록이다"

# ── 회차 29 벌목 ──────────────────────────────────────────────────────
section "회차 29 벌목"
#
# 겨누는 것은 **판정이 게임에 안 꽂힌 채로 초록인 상태**다. `Harvest` 는 순수 계산이라
# 단위 검사 132개로 구석까지 물을 수 있는데, **main.gd 가 그걸 한 줄도 안 부르면**
# 좌클릭은 모션만 나오고 나무는 그대로다 — 그런데 132개가 전부 초록이다.
# 회차 3(속도) · 5(방향) · 24(배치)와 같은 모양의 구멍이고, CHOP 이 그 자리다.

# ① **판정을 아예 안 부른다.** 모션은 그대로 나오므로 USE 도 초록이고,
#    단위 검사도 전부 초록이다 — **CHOP 하나만** 빨갛다.
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tHarvest.hit(world, hotbar.held_id(), _player.position, _player.facing)", "\tpass", 1))
PYX
expect 1 "판정을 안 부르면 tests 가 잡는다 (좌클릭이 모션만 내고 나무는 그대로)"
cp "$BAK/main.gd" scripts/main.gd

# ② **베고 나서 화면을 안 다시 칠한다.** 나무는 진짜로 없어지고 그 칸도 안 막으므로
#    단위 검사는 물론 CHOP 의 ②③④ 도 전부 초록이다 — 사람 눈에만 **벤 자리에 나무가
#    그대로 남는다.** 색 캐시가 「보이는 범위가 바뀔 때만」 채우기 때문이다.
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "func _on_world_changed(_tile: Vector2i) -> void:\n\t_cache_range = Rect2i()",
    "func _on_world_changed(_tile: Vector2i) -> void:", 1))
PYX
expect 1 "벤 뒤 캐시를 안 버리면 tests 가 잡는다 (화면에 나무가 그대로 남는다)"
cp "$BAK/main.gd" scripts/main.gd

# ③ **맨손으로도 베인다.** 도구가 판정을 가르는 것이 벌목의 절반이다 —
#    빈 손이 「아무 도구나」가 되면 도끼를 만들 이유가 없어진다 (BACKLOG P3 제작).
python3 - <<'PYX'
import io
p='scripts/harvest.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tif held_id == Inventory.EMPTY or kind == WorldObjects.NONE:",
    "\tif kind == WorldObjects.NONE:", 1).replace(
    "\treturn tool_for(kind) == held_id",
    "\treturn tool_for(kind) == held_id or held_id == Inventory.EMPTY", 1))
PYX
expect 1 "맨손으로도 베이면 tests 가 잡는다 (도구가 판정을 안 가른다)"
cp "$BAK/harvest.gd" scripts/harvest.gd

# ④ **베는데 아무것도 안 떨어진다.** 나무는 없어지고 칸도 뚫리므로 「베였다」는
#    맞는데 산출이 통째로 증발한다 — 인벤토리가 삼키는 것(회차 25)과 같은 종류다.
python3 - <<'PYX'
import io
p='scripts/harvest.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tworld.add_drop(drop_for(kind), drop_amount(kind),\n\t\tPlayerMotion.tile_center(tile.x, tile.y))\n", "", 1))
PYX
expect 1 "벤 것이 바닥에 안 떨어지면 tests 가 잡는다 (산출이 증발한다)"
cp "$BAK/harvest.gd" scripts/harvest.gd

expect 0 "원복하면 벌목도 다시 초록이다"

# ── 회차 30 벤 나무가 다시 자란다 ─────────────────────────────────────
section "회차 30 다시 자란다"
#
# 겨누는 것은 **시계가 안 꽂힌 채로 초록인 상태**다. `WorldState.tick()` 은 순수 계산이라
# 단위 검사가 구석까지 물을 수 있는데, **main.gd 가 그걸 한 줄도 안 부르면** 게임 안에서는
# 시간이 영영 0 초다 — 섬은 그루터기밭이 되는데 141개가 전부 초록이다.
# 나머지 셋은 **다시 자라는 것이 사람을 끼우지 않는가**를 본다.

# ① **시계를 안 돌린다.** 벌목도 모션도 그대로라 CHOP 도 USE 도 초록이고,
#    단위 검사도 전부 초록이다 — **REGROW 하나만** 빨갛다.
python3 - <<'PYY'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace("\tworld.tick(delta)\n", "", 1))
PYY
expect 1 "시계를 안 돌리면 tests 가 잡는다 (벤 나무가 영영 안 자란다)"
cp "$BAK/main.gd" scripts/main.gd

# ② **몸이 선 칸을 아무도 안 묻는다.** 월드는 플레이어를 모르므로 main.gd 가 그 물음을
#    안 꽂으면 나무가 사람 안에서 자란다 — 회차 29 가 막은 「벤 자리에 몸이 낀다」의
#    반대편이다. 단위 검사는 제 Callable 을 손으로 꽂으므로 전부 초록이다.
#    **오른쪽이 무엇이든 그 줄을 지운다** — 회차 32 가 `_body_covers` 를 `claim.covers`
#    로 바꾸면서 이 대조군이 헛돌기 시작했다.
mut scripts/main.gd '^\tworld\.occupied = .*\n' ''
expect 1 "몸이 선 칸을 안 물으면 tests 가 잡는다 (나무가 사람 안에서 자란다)"
cp "$BAK/main.gd" scripts/main.gd

# ③ **몸이 서 있어도 밀고 자란다.** 규칙 쪽에서 같은 구멍을 낸다 — 위가 배선이면
#    이쪽은 판정이다. 둘 다 결과는 「낀다」인데 고칠 자리가 다르다.
python3 - <<'PYY'
import io
p='scripts/world_state.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t\tif occupied.is_valid() and occupied.call(tile):", "\t\tif false:", 1))
PYY
expect 1 "몸이 선 칸을 밀고 자라면 tests 가 잡는다"
cp "$BAK/world_state.gd" scripts/world_state.gd

# ④ **자란 것을 아무에게도 안 알린다.** 칸은 진짜로 나무로 돌아오고 다시 막으므로
#    「자랐다」는 맞는데, 색 캐시가 안 버려져서 **화면에는 그루터기가 그대로 남는다.**
#    회차 29 의 ② 와 같은 모양이고, 헤드리스에서 보이는 자리는 `cache_fills` 뿐이다.
python3 - <<'PYY'
import io
p='scripts/world_state.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\t\tchanged.emit(tile)             # 화면을 다시 칠하게 한다 (main.gd 의 색 캐시)\n", "", 1))
PYY
expect 1 "자란 것을 안 알리면 tests 가 잡는다 (화면에 그루터기가 남는다)"
cp "$BAK/world_state.gd" scripts/world_state.gd

# ⑤ **나무도 안 자라는 것으로 적는다.** 균형값 한 줄이 0 이 되면 GDD A-4 가 통째로
#    사라지는데, 배선도 판정도 멀쩡해서 **아무 데도 안 터지는 것처럼 보인다.**
python3 - <<'PYY'
import io
p='scripts/world_objects.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace("\tTREE: 1.0,", "\tTREE: 0.0,", 1))
PYY
expect 1 "나무의 날 수를 0 으로 만들면 tests 가 잡는다 (한 번 캐고 끝난다)"
cp "$BAK/world_objects.gd" scripts/world_objects.gd

# ⑥ **시계가 10% 느리다** (회차 35 가 얹었다). ① 처럼 아예 안 부르는 것이 아니라
#    **델타를 깎아서** 부른다 — 게임은 멀쩡히 돌아가고 나무도 자라므로 ①~⑤ 도 단위
#    검사도 전부 초록이다. 어긋나는 것은 **하루의 길이**뿐이다: 20분이 22분이 된다.
#    **이게 회차 35 의 대조군이다.** 오차 0.034 / 0.34초라, 회차 30~34 의 허용치
#    0.05·0.10 으로는 **초록**이었다 — 구간을 프레임에 맞춰 0.01 로 조인 값만 잡는다.
#    (허용치를 다시 키우려는 회차는 이 줄에서 먼저 빨개진다.)
python3 - <<'PYY'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tworld.tick(delta)\n", "\tworld.tick(delta * 0.9)\n", 1))
PYY
expect 1 "시계를 10% 느리게 돌리면 tests 가 잡는다 (하루가 20분이 아니라 22분이 된다)"
cp "$BAK/main.gd" scripts/main.gd

expect 0 "원복하면 다시 자라는 것도 초록이다"

# ── 회차 31 낮과 밤 ───────────────────────────────────────────────────
section "회차 31 낮과 밤"
#
# 겨누는 것은 **시계는 도는데 화면이 그걸 모르는 상태**다. 회차 30 이 `WorldState.now` 를
# 놓았고 `DayCycle` 은 순수 계산이라 단위 검사가 구석까지 물을 수 있는데,
# **main.gd 가 `Sky` 를 한 줄도 안 물들이면 섬은 영영 한낮**이고 154개가 전부 초록이다.
# 회차 3(속도) · 5(방향) · 24(배치) · 29(벌목) · 30(시계)와 같은 모양의 구멍이다.
#
# 나머지는 **이 회차가 일부러 고르지 않은 길들**이다: 하늘을 핫바와 같은 캔버스에 두는 것,
# 밤을 칸 색에 섞는 것, 밤빛을 파랗게 하는 것, 낮밤을 딱 끊는 것, 하루를 반반이 아니게
# 가르는 것. 다섯 다 **사람 눈에는 그럴듯해 보이고 대부분의 검사는 초록이다.**

# ① **하늘을 안 물들인다.** 시계는 그대로 돌아서 나무도 다시 자라므로 REGROW 도 초록이고,
#    단위 검사 154개도 전부 초록이다 — **DAY 와 DRAW[밤] 만** 빨갛다.
python3 - <<'PYZ'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tsky.color = DayCycle.light_at(world.now)\n", "", 1))
PYZ
expect 1 "하늘을 안 물들이면 tests 가 잡는다 (시계는 도는데 섬은 영영 한낮이다)"
cp "$BAK/main.gd" scripts/main.gd

# ② **하늘을 핫바와 같은 캔버스에 둔다.** `CanvasModulate` 는 제가 속한 캔버스를
#    물들이므로, `UI` 안으로 옮기면 **월드는 안 어두워지고 가방만 깜깜해진다** —
#    정확히 뒤집힌 화면인데 씬은 여전히 「하늘이 있다」고 읽히고 단위 검사도 전부 초록이다.
#    **main.gd 도 같이 옮긴다**: 노드만 옮기면 `$Sky` 가 null 이 되어 `_process` 가
#    매 프레임 터지고 화면이 통째로 회색이 된다 — 그건 **다른 고장**이라, 그걸로는
#    「엉뚱한 캔버스의 하늘」을 한 번도 못 본다 (회차 31 이 여기서 게이트를 고쳤다).
python3 - <<'PYZ'
import io
p='scenes/main.tscn'; s=io.open(p,encoding='utf-8').read()
s = s.replace('[node name="Sky" type="CanvasModulate" parent="."]\n\n', '', 1)
s = s.replace('[node name="UI" type="CanvasLayer" parent="."]\n',
              '[node name="UI" type="CanvasLayer" parent="."]\n\n[node name="Sky" type="CanvasModulate" parent="UI"]\n', 1)
io.open(p,'w',encoding='utf-8').write(s)
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "@onready var sky: CanvasModulate = $Sky", "@onready var sky: CanvasModulate = $UI/Sky", 1))
PYZ
expect 1 "하늘을 UI 캔버스에 두면 tests 가 잡는다 (월드는 밝고 가방만 깜깜해진다)"
cp "$BAK/main.tscn" scenes/main.tscn
cp "$BAK/main.gd" scripts/main.gd

# ③ **밤을 칸 색에 섞는다** — 이 회차가 일부러 안 고른 길이다. 빛이 매 프레임 변하므로
#    색 캐시를 프레임마다 버려야 하고, 한 화면 2135칸 × 3.32 µs = 7.9 ms 가 16667 µs
#    예산에서 매 프레임 빠진다. **화면은 똑같이 어두워져서 픽셀로는 안 보인다** —
#    그래서 DRAW[밤] 이 채운 횟수를 같이 읽는다. 여기서 빨개지는 줄은 그 하나뿐이다.
python3 - <<'PYZ'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tsky.color = DayCycle.light_at(world.now)\n",
    "\tsky.color = DayCycle.light_at(world.now)\n\t_cache_range = Rect2i()\n", 1))
PYZ
expect 1 "밤이 색 캐시를 버리면 tests 가 잡는다 (화면은 똑같은데 프레임마다 7.9 ms)"
cp "$BAK/main.gd" scripts/main.gd

# ④ **밤빛을 파랗게 한다.** 달빛다워 보이지만 곱하기가 `WorldView` 의 부등식을 뒤집는다 —
#    돌 색(0.58, 0.57, 0.54)은 r 과 b 가 9% 밖에 안 벌어져 있어서, 밤빛의 b/r 이 그걸
#    넘는 순간 **달빛 아래 바위가 웅덩이로 보인다.** 화면 게이트는 전부 초록이다:
#    픽셀은 여전히 「칸 색 × 하늘빛」과 정확히 맞기 때문이다.
python3 - <<'PYZ'
import io
p='scripts/day_cycle.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "const NIGHT_LIGHT := Color(0.174, 0.180, 0.186)",
    "const NIGHT_LIGHT := Color(0.144, 0.180, 0.252)", 1))
PYZ
expect 1 "밤빛을 파랗게 하면 tests 가 잡는다 (달빛 아래 바위가 웅덩이가 된다)"
cp "$BAK/day_cycle.gd" scripts/day_cycle.gd

# ⑤ **낮밤을 딱 끊는다.** 여명을 없애면 해가 지는 프레임에 화면이 통째로 튄다 —
#    「하루가 있다」는 여전히 참이고 낮 10분 · 밤 10분도 그대로라 DAY 도 초록이다.
python3 - <<'PYZ'
import io
p='scripts/day_cycle.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "const TWILIGHT := 0.08", "const TWILIGHT := 0.0001", 1))
PYZ
expect 1 "여명을 없애면 tests 가 잡는다 (해가 지는 한 프레임에 화면이 튄다)"
cp "$BAK/day_cycle.gd" scripts/day_cycle.gd

# ⑥ **하루를 반반이 아니게 가른다.** GDD G-1b 의 「낮 10 + 밤 10」이 깨지는데
#    화면은 멀쩡히 밝아졌다 어두워져서 **눈으로는 못 본다** — 조건부 스폰(B-3)이
#    기대는 문장이라 숫자로 못을 박는다.
python3 - <<'PYZ'
import io
p='scripts/day_cycle.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\treturn phase(now) < 0.5", "\treturn phase(now) < 0.45", 1))
PYZ
expect 1 "낮을 9분으로 줄이면 tests 가 잡는다 (GDD 의 낮 10 + 밤 10 이 깨진다)"
cp "$BAK/day_cycle.gd" scripts/day_cycle.gd

# ⑧ **기존 문들의 틈으로 밤을 내린다** (회차 33). 밝기 0.110 · b/r 1.0893 —
#    **낡은 문 넷이 전부 초록이다**: 밝기 바닥 0.1 초과 · b/r 문턱 1.09 미만 ·
#    float 여유 0.00316 으로 양수 · DRAW 의 밤 상한 0.30 미만. 그런데 **구운 픽셀에서는
#    땅 한 칸의 r 과 b 가 같은 값으로 반올림돼 순서가 사라진다** — float 로만 보는 검사가
#    못 보는 자리다. 여기서 빨개지는 줄은 회차 33 의 8비트 검사 **하나뿐**이라,
#    그 검사를 지우면 이 대조군이 곧바로 「놓쳤다」가 된다.
python3 - <<'PYZ'
import io
p='scripts/day_cycle.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "const NIGHT_LIGHT := Color(0.174, 0.180, 0.186)",
    "const NIGHT_LIGHT := Color(0.1053, 0.1100, 0.1147)", 1))
PYZ
expect 1 "낡은 문 넷의 틈으로 밤을 내리면 tests 가 잡는다 (8비트에서 땅의 순서가 사라진다)"
cp "$BAK/day_cycle.gd" scripts/day_cycle.gd

expect 0 "원복하면 낮과 밤도 다시 초록이다"


# ── 회차 32 사람이 차지한 칸 ──────────────────────────────────────────
section "회차 32 사람이 차지한 칸"
#
# 겨누는 것은 **다음 회차가 등록을 빼먹는 것**이다. 회차 30 이 재생을 넣을 때 게임에
# 설치물이 하나도 없어서 `occupied` 는 「몸이 서 있나」 하나였다. P3 제작대·P4 밭을
# 만드는 회차가 `Claim` 에 제 출처를 안 꽂으면 **자고 일어난 집 거실에 나무가 선다** —
# 그런데 그 회차의 검사는 전부 초록이다. 사람이 겪는 것은 반 년 뒤다.
#
# 그래서 **선언(`Claim.KINDS`)과 배선(`add`)을 갈라 놓고 둘이 안 맞는 것을 센다.**
# ①②는 그 계약이고, ③④는 목록이 있어도 **안 묻거나 되돌릴 수 없는** 길이다.

# ① **선언만 하고 안 꽂는다** — 이 묶음의 요점이다. 제작대를 만드는 회차가
#    `Claim.KINDS` 에 이름은 적고 `main.gd` 의 `add()` 를 빼먹은 모양 그대로다.
#    게임은 멀쩡히 돌고 **단위 검사도 전부 초록**이다 (선언을 세는 검사는 KINDS 를
#    같이 읽으니까) — REGROW 의 `missing()` 하나만 빨갛다.
python3 - <<'PYW'
import io
p='scripts/claim.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    '\tBODY: "플레이어가 서 있는 칸',
    '\t&"제작대": "사람이 놓은 제작대 — 그 위에 나무가 자라면 집 안에 숲이 선다",\n'
    '\tBODY: "플레이어가 서 있는 칸', 1))
PYW
expect 1 "차지 종류를 선언만 하고 안 꽂으면 tests 가 잡는다 (집 거실에 나무가 선다)"
cp "$BAK/claim.gd" scripts/claim.gd

# ② **월드가 목록을 안 거친다.** `Claim` 은 멀쩡히 서 있고 몸도 제대로 꽂혀 있어서
#    `missing()` 은 비어 있고 회차 30 의 「몸이 선 칸」도 그대로 초록인데,
#    월드가 묻는 것은 **목록이 아니라 몸 하나**라 나중에 꽂는 설치물은 영영 안 물어진다.
python3 - <<'PYW'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tworld.occupied = claim.covers\n", "\tworld.occupied = _body_covers\n", 1))
PYW
expect 1 "월드가 차지 목록을 안 거치면 tests 가 잡는다 (설치물을 영영 안 묻는다)"
cp "$BAK/main.gd" scripts/main.gd

# ③ **첫 출처에서 멈춘다.** 몸이 목록의 첫 줄이라 회차 30 이 재던 것은 전부 초록이고,
#    **두 번째부터 꽂는 것만** 조용히 안 물어진다 — 늘 나중에 온 쪽이 진다.
python3 - <<'PYW'
import io
p='scripts/claim.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "	for name in _order:", "	for name in _order.slice(0, 1):", 1))
PYW
expect 1 "첫 출처만 물으면 tests 가 잡는다 (나중에 꽂은 설치물이 늘 진다)"
cp "$BAK/claim.gd" scripts/claim.gd

# ④ **차지한 칸을 「영영 안 자라는 칸」으로 적는다.** 줄을 다시 안 세우니 싸 보이고
#    「차지한 칸에는 안 자란다」도 참인데, **집을 헐어도 숲이 안 돌아온다** —
#    비켜선 몸도 마찬가지라 회차 30 의 ③ 이 같이 빨개진다.
python3 - <<'PYW'
import io
p='scripts/world_state.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "			_schedule(tile, now + RETRY_SEC)", "			_schedule(tile, INF)", 1))
PYW
expect 1 "차지한 칸을 영영 안 자라게 적으면 tests 가 잡는다 (집을 헐어도 숲이 안 온다)"
cp "$BAK/world_state.gd" scripts/world_state.gd

expect 0 "원복하면 차지한 칸도 다시 초록이다"

# ── 회차 33 창을 게임 크기에 ──────────────────────────
section "회차 33 창을 게임 크기에"

# ① **배선을 빼먹는다.** `Display` 는 순수 계산이라 **단위 검사 175개가 전부 초록**으로
#    남는다 — 창을 안 맞추면 아무도 「띠가 있다」를 못 본다.
#    **이것이 이 회차가 걸린 함정이다**: override 1920x1080 은 정확히 2배라 **띠가 0 이다.**
#    「띠 0」만 묻는 게이트는 여기서 초록이고, **배율이 최대인지**를 같이 묻는 줄만 빨개진다.
python3 - <<'PYX'
import io
p='scripts/main.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace("\tDisplay.fit_window(get_window())\n", "", 1))
PYX
expect 1 "창을 안 맞추면 VIEW 가 잡는다 (띠는 0 인데 배율 2 → 기대 3)"
cp "$BAK/main.gd" scripts/main.gd

# ② **창 대신 전체 화면으로 돌아간다.** 앞 회차가 하던 그대로다 — 배율은 3 그대로라
#    「배율이 맞나」만 묻는 게이트는 초록이고, **띠를 재는 줄만** 576x548 로 빨개진다.
#    사람이 두 번 지적한 그 화면이 정확히 이것이다.
python3 - <<'PYX'
import io
p='scripts/display.gd'; s=io.open(p,encoding='utf-8').read()
io.open(p,'w',encoding='utf-8').write(s.replace(
    "\tw.mode = Window.MODE_WINDOWED\n\tw.size = size\n\tw.position = rect.position + (rect.size - size) / 2\n",
    "\tw.mode = Window.MODE_FULLSCREEN\n", 1))
PYX
expect 1 "전체 화면으로 돌아가면 VIEW 가 띠에서 잡는다 (0x0 → 576x548)"
cp "$BAK/display.gd" scripts/display.gd

# ③ **한 단계 작은 창으로 잡는다.** 띠는 **여전히 0 이다**(1920x1080 도 정확히 2배다) —
#    「띠가 없다」만 묻는 게이트는 통째로 초록이고, 사람은 화면의 3할짜리 창을 본다.
#    **「제일 큰 창인가」가 이 줄을 잡는다** — 단위·실측 양쪽에 그 물음을 같이 넣었다.
sed -i '' 's|^	var size := drawn(rect.size, logical())|	var size := logical() * maxi(1, max_scale(rect.size, logical()) - 1)|' scripts/display.gd
expect 1 "창을 한 단계 작게 잡으면 VIEW 가 배율에서 잡는다 (띠는 0 인데 3 → 2)"
cp "$BAK/display.gd" scripts/display.gd

# ④ **내림을 반올림으로 바꾼다.** 3.6 이 4 가 되어 창 3840x2160 이 화면 3456x2168 밖으로
#    나간다 — 잘린 만큼은 「남이 보는 것을 내가 못 보는 것」이라 ⓒ 가 깨진다.
sed -i '' 's|return maxi(1, mini(avail_size.x / logical_size.x, avail_size.y / logical_size.y))|return maxi(1, mini(int(roundf(float(avail_size.x) / logical_size.x)), int(roundf(float(avail_size.y) / logical_size.y))))|' scripts/display.gd
expect 1 "배율을 반올림하면 단위와 VIEW 가 같이 잡는다 (3.6 → 4 · 창이 화면 밖으로)"
cp "$BAK/display.gd" scripts/display.gd

# ⑤ **쓸 수 있는 화면 대신 화면 전체를 쓴다.** macOS 는 메뉴 막대·노치 띠를 안 준다 —
#    세로 66px 을 더 크게 보고 자리도 (0,0) 으로 본다. **창 크기는 안 바뀐다**(2168 이든
#    2234 이든 배율은 3) — 바뀌는 것은 **자리**다. 창이 위로 33px 밀린다 (340 → 307).
#    **두 번 놓쳤다.** ① 게이트가 크기만 재고 자리를 안 봤다. ② 자리를 재게 했더니
#    기대값을 `Display.avail_rect()` 로 냈다 — **이 대조군이 고치는 바로 그 함수**라
#    「틀린 값과 틀린 값이 같다」로 초록이었다. VIEW 가 이제 OS 에 직접 묻는다.
#    **재는 쪽은 재이는 쪽의 말을 빌리면 안 된다.**
sed -i '' 's|return DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())|return Rect2i(Vector2i.ZERO, DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()))|' scripts/display.gd
expect 1 "쓸 수 있는 화면 대신 화면 전체를 재면 잡는다 (자리가 33px 위로)"
cp "$BAK/display.gd" scripts/display.gd

expect 0 "원복하면 창 크기도 다시 초록이다"


echo
SKIPMSG=""
[ "$SKIP" -gt 0 ] && SKIPMSG=" · ${SKIP}개 건너뜀 (--only ${ONLY})"
if [ "$MISS" -eq 0 ]; then
  echo "REDTEAM ${PASS} 잡음, 0 놓침${SKIPMSG} — 게이트가 살아 있다"; exit 0
fi
echo "REDTEAM ${PASS} 잡음, ${MISS} 놓침${SKIPMSG} — 안 잡는 게이트가 있다"; exit 1
