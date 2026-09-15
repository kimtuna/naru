#!/usr/bin/env bash
# **허용치를 감이 아니라 「잰 흔들림」에서 정하기 위한 자.** (회차 39)
#
# 실측 게이트를 **같은 조건에서 N번** 돌리고, 게이트가 실제로 견주는 수(`TOLOBS` 줄)를
# 모아 자리마다 min · max · **폭**을 낸다. 허용치는 그 폭 **위**에 있어야 한다.
#
# 왜 필요한가: 회차 11 `FACE` · 26 `USE` · 34 `REGROW` · 35 `COLLIDE` — **네 번**
# 같은 실수를 했다. 전부 「폭을 안 재고 허용치를 감으로 적었다가, 터지면 키웠다」다.
# 폭을 모르면 「잡음을 덮었나」와 「고장까지 덮었나」를 가를 길이 없다.
#
#   tools/loop/jitter.sh [N] [--keep]     기본 7판. 한 판 ≈ 12초
#
# **이것은 게이트가 아니다** — 상태 검사에 안 들어간다. 여기서 잰 폭을
# `test_tolerances.gd` 의 표에 옮겨 적으면, 누가 허용치를 폭 아래로 조이거나
# 고장의 1/3 위로 벌릴 때 **단위 검사가** 빨개진다.
#
# **날것 로그를 `.loop/` 밖(`$TMPDIR`)에 쓴다**: 옆 세션의 `worktree.sh restore` 가
# 도는 동안 `.loop/jitter/` 가 통째로 사라져 9판이 0줄로 끝났다 (회차 39 · GOTCHAS).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
G="$ROOT/tools/loop/godot.sh"
N="${1:-7}"
KEEP="${2:-}"
DIR="$(mktemp -d "${TMPDIR:-/tmp}/naru-jitter.XXXXXX")"

echo "== 흔들림 재기 ${N}판 =="
for i in $(seq 1 "$N"); do
  {
    "$G" 180 -- --headless --path "$ROOT" --script res://tools/tests/measure_headless.gd
    "$G" 60  -- --headless --path "$ROOT" --script res://tools/tests/measure_facing.gd
    NARU_FOCUS_RESTORE=1 "$G" 120 -- --path "$ROOT" --script res://tools/tests/measure_window.gd
  } > "$DIR/run-$i.log" 2>&1
  printf '  %d판  TOLOBS %d줄\n' "$i" "$(grep -c '^TOLOBS' "$DIR/run-$i.log")"
done

python3 - "$DIR" "$N" <<'PY'
import sys, io, glob, os
d, n = sys.argv[1], int(sys.argv[2])
obs = {}   # 자리 -> [꼴, 허용치, [잰 값...]]
for f in sorted(glob.glob(os.path.join(d, "run-*.log"))):
    for line in io.open(f, encoding='utf-8', errors='replace'):
        if not line.startswith("TOLOBS\t"):
            continue
        _, name, kind, v, tol = line.rstrip("\n").split("\t")
        obs.setdefault(name, [kind, float(tol), []])[2].append(float(v))
if not obs:
    print("TOLOBS 가 한 줄도 없다 — 게이트가 안 돌았거나 Tol.obs 를 안 부른다")
    sys.exit(1)

w = max(len(k) for k in obs)
print()
print("%-*s %-5s %4s %12s %12s %12s %10s %10s" % (
    w, "자리", "꼴", "판", "최소", "최대", "폭", "허용치", "남은여유"))
risky = 0
for name in sorted(obs):
    kind, tol, vs = obs[name]
    lo, hi = min(vs), max(vs)
    width = hi - lo
    # band·cap 은 허용치가 잰 값 **위**에, floor 는 **아래**에 있어야 한다.
    room = (tol - hi) if kind in ("band", "cap") else (lo - tol)
    flag = ""
    if room <= 0:
        flag = "  ← 허용치가 잰 값을 못 덮는다"; risky += 1
    elif room < width:
        flag = "  ← 남은 여유가 폭보다 좁다"; risky += 1
    print("%-*s %-5s %4d %12.6f %12.6f %12.6f %10.4f %10.6f%s" % (
        w, name, kind, len(vs), lo, hi, width, tol, room, flag))
print()
print("JITTER %d자리 · %d판 · 위태로운 자리 %d" % (len(obs), n, risky))
short = [k for k, e in obs.items() if len(e[2]) % n]
if short:
    print("JITTER 판마다 수가 다른 자리: %s (구간이 안 돌았을 수 있다)" % ", ".join(sorted(short)))
PY

if [ "$KEEP" = "--keep" ]; then echo "날것 로그: $DIR"; else rm -rf "$DIR"; fi
exit 0
