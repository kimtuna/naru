#!/usr/bin/env python3
"""바퀴 기록을 다룬다.

  state.py tail <n>   최근 n 바퀴만 찍는다 (드라이버가 세션에게 주입한다)
  state.py roll <n>   최근 n 바퀴만 남기고 나머지는 .loop/archive/state.md 로 옮긴다

**세션은 state.md 를 열지 않는다.** 이 파일은 바퀴마다 자라므로, 통째로 읽게 두면
바퀴 비용이 계속 는다 — 1판이 그렇게 죽었다.
"""
import io, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
STATE = os.path.join(ROOT, ".loop", "state.md")
ARCH  = os.path.join(ROOT, ".loop", "archive", "state.md")

def split():
    if not os.path.exists(STATE):
        return "", []
    s = io.open(STATE, encoding="utf-8").read()
    parts = re.split(r"(?m)^(?=### )", s)
    return parts[0], parts[1:]

def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "tail"
    n = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    head, cycles = split()
    if cmd == "tail":
        sys.stdout.write("".join(cycles[-n:]) if cycles else "(아직 기록 없음)\n")
    elif cmd == "roll":
        if len(cycles) <= n:
            print("ROLL 유지 %d바퀴 (상한 %d)" % (len(cycles), n)); return
        old, keep = cycles[:-n], cycles[-n:]
        os.makedirs(os.path.dirname(ARCH), exist_ok=True)
        with io.open(ARCH, "a", encoding="utf-8") as f:
            f.write("".join(old))
        io.open(STATE, "w", encoding="utf-8").write(head + "".join(keep))
        print("ROLL %d바퀴를 아카이브로, %d바퀴 유지" % (len(old), len(keep)))
    else:
        print("사용법: state.py tail <n> | roll <n>", file=sys.stderr); sys.exit(2)

main()
