#!/usr/bin/env bash
# `worktree.sh` 가 도는지 잰다 — **진짜 워킹트리는 안 건드린다**
# (`NARU_WORKTREE_ROOT` 로 임시 git 저장소를 가리킨다).
#
# **이게 겨누는 구멍**: 세션이 손으로 깨뜨린 것이 커밋 없이 워킹트리에 떠 있는 채로
# 회차가 초록으로 닫히는 길 (회차 24). 그래서 「되돌렸나」만 묻지 않는다 —
# **무엇을 되돌리고 무엇을 그냥 두는가**까지 글자로 묶는다. 드라이버 몫(일지 · 회차
# 기록)을 같이 지워 버리면 방금 뽑은 일지가 날아가므로 그 경계가 검사의 절반이다.
#
# 종료 코드: 0 = 다 통과 / 1 = 하나라도 실패
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
WSH="$ROOT/tools/loop/worktree.sh"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
P=0; F=0
ok()  { P=$((P+1)); printf '  ok   %s\n' "$1"; }
bad() { F=$((F+1)); printf '  FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/         /'; }

R="$TMP/repo"
W() { NARU_WORKTREE_ROOT="$R" bash "$WSH" "$@"; }

fresh() {                                  # 회차 시작 모양의 깨끗한 저장소
  rm -rf "$R"; mkdir -p "$R/scripts" "$R/docs" "$R/.loop"
  git -C "$R" init -q
  git -C "$R" config user.name loop; git -C "$R" config user.email loop@local
  printf '.godot-home/\n' > "$R/.gitignore"
  printf 'func add(n):\n\treturn left\n' > "$R/scripts/inventory.gd"
  printf 'func draw():\n\tpass\n'        > "$R/scripts/main.gd"
  printf '# JOURNAL\n'                   > "$R/docs/JOURNAL.md"
  printf '<html></html>\n'               > "$R/docs/index.html"
  printf '# state\n'                     > "$R/.loop/state.md"
  git -C "$R" add -A >/dev/null; git -C "$R" commit -qm base
}

rc_is() {                                  # rc_is <이름> <기대 exit> <인자...>
  local name="$1" want="$2"; shift 2
  local out rc; out="$(W "$@" 2>&1)"; rc=$?
  [ "$rc" -eq "$want" ] && ok "$name" || bad "$name (기대 exit $want · 잰 값 $rc)" "$out"
}
says()   { local out; out="$(W "$1" 2>&1)"; printf '%s' "$out" | grep -qF -- "$3" \
             && ok "$2" || bad "$2 — 출력에 없다: $3" "$out"; }
saysnt() { local out; out="$(W "$1" 2>&1)"; printf '%s' "$out" | grep -qF -- "$3" \
             && bad "$2 — 출력에 남았다: $3" "$out" || ok "$2"; }
file_is(){ local got; got="$(cat "$R/$2" 2>&1)"
           [ "$got" = "$3" ] && ok "$1" || bad "$1 — $2 내용이 다르다" "$got"; }
gone()   { [ -e "$R/$1" ] && bad "$2 — 아직 있다: $1" || ok "$2"; }
there()  { [ -e "$R/$1" ] && ok "$2" || bad "$2 — 없다: $1"; }

echo "== worktree selftest =="

# ── 1) 깨끗한 회차는 아무 말도 안 한다 ──────────────────────────────
fresh
rc_is "손 안 댄 저장소는 check 초록" 0 check
rc_is "적을 게 없으면 save 는 exit 1" 1 save "$TMP/p1.patch"
rc_is "깨끗해도 restore 는 초록"      0 restore

# ── 2) 회차 24 그 자체 — 세션이 손으로 깨뜨리고 안 되돌렸다 ─────────
fresh
printf 'func add(n):\n\treturn 0\n' > "$R/scripts/inventory.gd"
rc_is "고쳐만 두고 커밋 안 하면 잡는다" 1 check
says  check "흘린 파일 이름을 찍는다" "scripts/inventory.gd"
rc_is "증거를 적는다"                  0 save "$TMP/p2.patch"
grep -qF 'return left' "$TMP/p2.patch" && grep -qF 'return 0' "$TMP/p2.patch" \
  && ok "증거에 지운 줄과 넣은 줄이 다 있다" \
  || bad "증거에 지운 줄과 넣은 줄이 다 있다" "$(cat "$TMP/p2.patch")"
rc_is "되돌린다"                       0 restore
file_is "되돌리면 HEAD 내용이다" scripts/inventory.gd "$(printf 'func add(n):\n\treturn left')"
rc_is "되돌린 뒤 check 초록"           0 check

# ── 3) 새로 만든 것 · 지운 것 · 인덱스에 올린 것 ────────────────────
fresh
printf 'tmp\n' > "$R/scripts/_scratch.gd"
rc_is "추적 안 되는 새 파일도 잡는다"  1 check
rc_is "새 파일도 되돌린다"             0 restore
gone scripts/_scratch.gd "되돌릴 판본이 없는 것은 지운다"

fresh
printf 'tmp\n' > "$R/scripts/_staged.gd"; git -C "$R" add scripts/_staged.gd >/dev/null
rc_is "git add 만 하고 커밋 안 한 것도 잡는다" 1 check
rc_is "인덱스에 올린 것도 되돌린다"    0 restore
gone scripts/_staged.gd "인덱스에 올린 새 파일을 지운다"
[ -z "$(git -C "$R" status --porcelain)" ] && ok "인덱스에서도 뗀다" \
  || bad "인덱스에서도 뗀다" "$(git -C "$R" status --porcelain)"

fresh
rm "$R/scripts/main.gd"
rc_is "지운 파일도 잡는다"             1 check
rc_is "지운 파일도 되돌린다"           0 restore
there scripts/main.gd "지운 파일이 돌아온다"

fresh
git -C "$R" mv scripts/main.gd scripts/renamed.gd >/dev/null
rc_is "이름 바꾼 것도 잡는다"          1 check
rc_is "이름 바꾼 것도 되돌린다"        0 restore
there scripts/main.gd "옛 이름이 돌아온다"
gone  scripts/renamed.gd "새 이름은 지워진다"

# ── 4) **드라이버 몫은 건드리지 않는다** — 여기가 검사의 절반이다 ───
#
# 세션이 끝난 시점에 일지(`docs/JOURNAL.md` · `docs/index.html`)와 회차 기록(`.loop/`)은
# 아직 커밋 전이다. 드라이버가 뒤에서 제 손으로 커밋한다 — 이걸 「흘린 것」으로 보면
# 되돌리기가 **방금 답변에서 뽑은 일지를 지운다.**
fresh
printf '# JOURNAL\n\n## 회차 25 · 방금 뽑았다\n' > "$R/docs/JOURNAL.md"
printf '<html>새로 구웠다</html>\n'              > "$R/docs/index.html"
printf '# state\n\n### 회차 25\n'                > "$R/.loop/state.md"
printf 'x\n'                                     > "$R/.loop/새파일.txt"
rc_is "드라이버 몫만 더러우면 check 초록" 0 check
rc_is "드라이버 몫만 있으면 save 는 exit 1" 1 save "$TMP/p4.patch"
rc_is "드라이버 몫은 restore 가 안 센다"  0 restore
file_is "일지를 안 지운다"   docs/JOURNAL.md "$(printf '# JOURNAL\n\n## 회차 25 · 방금 뽑았다')"
file_is "대시보드를 안 지운다" docs/index.html "<html>새로 구웠다</html>"
there ".loop/새파일.txt" "회차 기록의 새 파일을 안 지운다"

# ── 5) 섞여 있을 때 — 세션 것만 골라낸다 ────────────────────────────
fresh
printf 'func add(n):\n\treturn 0\n' > "$R/scripts/inventory.gd"
printf '# JOURNAL\n\n## 회차 25\n' > "$R/docs/JOURNAL.md"
says    check "섞여 있으면 세션 것을 찍고"   "scripts/inventory.gd"
saysnt  check "드라이버 것은 안 찍는다"      "docs/JOURNAL.md"
rc_is   "섞여 있으면 빨갛다"              1 check
rc_is   "섞여 있어도 되돌린다"            0 restore
file_is "세션 것만 되돌아간다" scripts/inventory.gd "$(printf 'func add(n):\n\treturn left')"
file_is "일지는 그대로 남는다" docs/JOURNAL.md "$(printf '# JOURNAL\n\n## 회차 25')"

# ── 6) 무시되는 것은 흘린 것이 아니다 ───────────────────────────────
fresh
mkdir -p "$R/.godot-home"; printf 'cache\n' > "$R/.godot-home/x.dat"
rc_is "gitignore 된 것은 안 센다"      0 check
there ".godot-home/x.dat" "gitignore 된 것을 안 지운다"

# ── 7) 공백이 든 경로에서도 안 쪼개진다 ─────────────────────────────
fresh
printf 'x\n' > "$R/scripts/두 칸 이름.gd"
rc_is "공백·유니코드 경로도 잡는다"    1 check
rc_is "공백·유니코드 경로도 되돌린다"  0 restore
gone "scripts/두 칸 이름.gd" "공백 든 경로를 통째로 지운다"

echo
# **바닥이 없으면 검사를 지워서 초록에 갈 수 있다** — 실패가 0 이면 통과 개수가 줄어도
# 그냥 초록이기 때문이다. 단위 검사의 `mintests.sh` 와 같은 자리다.
FLOOR=41
if [ "$F" -ne 0 ]; then echo "WORKTREE SELFTEST $P passed, $F failed"; exit 1; fi
if [ "$P" -lt "$FLOOR" ]; then
  echo "WORKTREE SELFTEST $P passed, 0 failed — 바닥 $FLOOR 아래다. 검사가 지워졌다"; exit 1
fi
echo "WORKTREE SELFTEST $P passed, 0 failed (바닥 $FLOOR)"; exit 0
