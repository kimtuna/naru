#!/usr/bin/env bash
# 세션이 **커밋하지 않고 남긴 변경**을 잰다 · 증거로 뜬다 · HEAD 로 되돌린다.
#
# **왜 있나** (회차 24). 세션이 대조군으로 `scripts/inventory.gd` 의 `return left` 를
# `return 0` 으로 바꿔 놓고 **원복을 안 하고 끝냈다.** 커밋엔 안 들어갔지만 워킹트리에
# 떠 있었고 아무도 안 물었다. 여기서 두 가지가 동시에 샌다:
#   ① 채점자가 **커밋되지도 않을 상태**를 잰다 — 초록의 근거가 역사에 안 남는다
#   ② 다음 회차가 경로를 넓게 잡아 커밋하면 그 고장이 그대로 굳는다
#      (꽉 찬 인벤토리가 아이템을 조용히 삼킨다)
# `redteam.sh` 는 제가 깨뜨린 것을 `trap restore EXIT` 로 제 손으로 막는다.
# **세션이 손으로 고친 것은 아무도 안 되돌린다** — 그 자리가 여기다.
#
# **드라이버 몫과 세션 몫을 가른다.** 세션이 끝난 시점에 아직 커밋 안 된 것 중에는
# 드라이버 자신이 쓴 것이 있다 — 일지(`docs/JOURNAL.md` · `docs/index.html`)와
# 회차 기록(`.loop/`). 그건 뒤에서 드라이버가 제 손으로 커밋하므로 흘린 것이 아니다.
# 이걸 안 가르면 되돌리기가 **방금 뽑은 일지를 지운다.**
#
#   worktree.sh check            세션이 흘린 것을 찍는다. 0 = 깨끗 / 1 = 남았다
#   worktree.sh save <파일>      되돌리기 전에 증거를 적는다. 0 = 적었다 / 1 = 적을 게 없다
#   worktree.sh restore          흘린 것만 HEAD 로 되돌린다 (커밋은 안 건드린다)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${NARU_WORKTREE_ROOT:-$ROOT}" || exit 2

# 드라이버가 제 손으로 커밋하는 자리. 여기 것은 「세션이 흘린 것」이 아니다.
is_driver() {
  case "$1" in
    .loop|.loop/*|docs/JOURNAL.md|docs/index.html) return 0 ;;
    *) return 1 ;;
  esac
}

# "XY<TAB>경로" 를 한 줄씩. `-z` 라 공백·유니코드 경로에서도 안 쪼개진다
# (`--porcelain` 은 기본으로 비ASCII 를 따옴표로 싸서 경로가 달라진다).
leftovers() {
  local entry x p old
  while IFS= read -r -d '' entry; do
    x="${entry:0:2}"; p="${entry:3}"
    # 이름이 바뀐 것은 **옛 이름이 NUL 뒤에 따로 온다.** 안 읽으면 다음 줄로 새고
    # 옛 이름이 지워진 채로 남는다 — 둘 다 되돌려야 한다.
    old=""
    case "$x" in R*|C*) IFS= read -r -d '' old || true ;; esac
    is_driver "$p" || printf '%s\t%s\n' "$x" "$p"
    [ -n "$old" ] && { is_driver "$old" || printf '%s\t%s\n' "$x" "$old"; }
  done < <(git -c core.quotePath=false status --porcelain -z 2>/dev/null)
}

restore_one() {                            # restore_one <XY> <경로>
  local p="$2"
  if git cat-file -e "HEAD:$p" 2>/dev/null; then
    git reset -q HEAD -- "$p" >/dev/null 2>&1 || true
    git checkout -q HEAD -- "$p" >/dev/null 2>&1 || true
    printf '  되돌림  %s\n' "$p"
  else
    # HEAD 에 없는 것은 되돌릴 판본이 없다 — 세션이 새로 만든 것이라 지운다.
    # 인덱스에 올라가 있을 수도 있어서(`git add` 만 하고 커밋 안 함) 거기서도 뗀다.
    git rm -q -f --cached -- "$p" >/dev/null 2>&1 || true
    rm -rf -- "$p"
    printf '  지움    %s\n' "$p"
  fi
}

case "${1:-check}" in
  check)
    n=0
    while IFS=$'\t' read -r x p; do n=$((n+1)); printf '  %s %s\n' "$x" "$p"; done < <(leftovers)
    [ "$n" -eq 0 ] && { echo "WORKTREE 깨끗하다 — 세션이 흘린 것 없음"; exit 0; }
    printf 'WORKTREE 커밋 안 된 변경 %d 건 — 세션이 흘렸다\n' "$n"
    exit 1 ;;

  save)
    out="${2:?save <파일>}"; : > "$out" || exit 2
    n=0
    while IFS=$'\t' read -r x p; do
      n=$((n+1))
      if git cat-file -e "HEAD:$p" 2>/dev/null; then
        printf '=== %s %s ===\n' "$x" "$p" >> "$out"
        git --no-pager diff HEAD -- "$p" >> "$out" 2>/dev/null
      else
        printf '=== %s %s (HEAD 에 없다 — 새로 만든 것) ===\n' "$x" "$p" >> "$out"
        [ -f "$p" ] && sed 's/^/+/' "$p" >> "$out" 2>/dev/null
      fi
    done < <(leftovers)
    [ "$n" -eq 0 ] && { printf 'WORKTREE 적을 게 없다\n'; exit 1; }
    printf 'WORKTREE 증거 %d 건 → %s\n' "$n" "$out"; exit 0 ;;

  restore)
    n=0
    while IFS=$'\t' read -r x p; do n=$((n+1)); restore_one "$x" "$p"; done < <(leftovers)
    # **되돌렸다고 말하지 말고 다시 묻는다.** 아무것도 안 되돌리고 초록을 내는 것이
    # 이 스크립트가 만들 수 있는 유일하고 가장 비싼 고장이다 (회차 23 과 같은 자리).
    rest="$(leftovers)"
    if [ -n "$rest" ]; then
      printf 'WORKTREE 되돌렸는데 아직 남아 있다:\n%s\n' "$rest" >&2; exit 1
    fi
    printf 'WORKTREE 세션이 흘린 %d 건을 HEAD 로 되돌렸다\n' "$n"; exit 0 ;;

  *) echo "쓰기: worktree.sh check|save <파일>|restore" >&2; exit 2 ;;
esac
