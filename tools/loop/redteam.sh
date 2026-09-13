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
restore() {
  cp "$BAK/project.godot" project.godot 2>/dev/null || true
  cp "$BAK/criteria.tsv" .loop/criteria.tsv 2>/dev/null || true
  cp "$BAK/test_isolation.gd" tools/tests/test_isolation.gd 2>/dev/null || true
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

expect 0 "원복하면 다시 초록이다"

echo
if [ "$MISS" -eq 0 ]; then
  echo "REDTEAM ${PASS} 잡음, 0 놓침 — 게이트가 살아 있다"; exit 0
fi
echo "REDTEAM ${PASS} 잡음, ${MISS} 놓침 — 안 잡는 게이트가 있다"; exit 1
