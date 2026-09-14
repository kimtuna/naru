#!/usr/bin/env bash
# 회차 일지 (docs/JOURNAL.md) 를 읽고 쓴다. **세션은 이 파일을 열지 않는다.**
#
#   journal.sh next                 다음 회차 번호
#   journal.sh extract <n> <파일>    세션의 마지막 답변에서 절을 뽑아 일지에 넣는다
#   journal.sh check <n>            세션이 사람 판단 줄을 채웠나 (안 채웠으면 exit 1)
#   journal.sh stamp <n> <항목> <결과> <커밋>
#                                   기계가 아는 것만 찍는다 — 날짜 · 결과 · 채점 · 비용 · 커밋.
#                                   절이 없으면 만들어 둔다 (사람 판단 줄은 비운 채로).
#   journal.sh selftest             뽑기·찍기가 도는지. 대조군이 겨누는 자리다.
#
# **줄의 주인이 갈려 있다.** 세션은 「문제·원인·고친 것·바꾼 결정·잰 값·남긴 것」을 쓰고,
# 드라이버는 「날짜·결과·채점·비용·커밋」을 쓴다. 세션의 「됐습니다」가 결과 칸에 들어가면
# 일지가 증거가 아니라 자기 보고가 된다. **이제 그 경계를 말이 아니라 `extract` 가 지운다** —
# 세션이 드라이버 줄을 써 보내도 뽑을 때 버려진다.
#
# **왜 세션이 파일을 안 쓰나** (회차 22): 회차 12 · 21 이 일을 끝내고 커밋까지 하고도
# 일지만 빼먹었다. 둘 다 커밋 메시지에는 다 적혀 있었고 **옮기는 것만** 빠졌다 —
# 파일을 여는 것이 별도의 일이라 예산이 마르면 제일 먼저 잘리는 자리였다.
# 마지막 답변에 적는 것은 잘리지 않는다. 세션은 어차피 그 답변을 쓴다.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
# 검사가 진짜 일지를 건드리지 않게 하는 유일한 손잡이다. 드라이버는 안 쓴다.
J="${NARU_JOURNAL:-docs/JOURNAL.md}"

case "${1:-}" in
  next)
    n="$(grep -o '^## 회차 [0-9]\+' "$J" 2>/dev/null | grep -o '[0-9]\+' | sort -n | tail -1)"
    echo $(( ${n:-0} + 1 ))
    ;;

  extract)
    python3 - "$J" "${2:?회차 번호}" "${3:?세션 파일}" <<'PY'
import io, json, os, re, sys
path, n, src = sys.argv[1:4]

SESSION = ["문제", "원인", "고친 것", "바꾼 결정", "잰 값", "남긴 것"]
DRIVER  = ["날짜", "결과", "채점", "비용", "커밋"]
ORDER   = ["날짜", "결과"] + SESSION + ["채점", "비용", "커밋"]
KNOWN   = set(SESSION) | set(DRIVER)

# ── 1) 마지막 답변의 글자를 꺼낸다 ────────────────────────────────
try:
    raw = io.open(src, encoding="utf-8", errors="replace").read()
except OSError as e:
    print(f"세션 파일을 못 읽었다: {e}"); sys.exit(1)
text = None
try:
    d = json.loads(raw)
except Exception:
    d = None
if isinstance(d, dict) and isinstance(d.get("result"), str):
    text = d["result"]
elif isinstance(d, list):                      # 스트리밍 로그 — 마지막 result
    for x in reversed(d):
        if isinstance(x, dict) and isinstance(x.get("result"), str):
            text = x["result"]; break
if text is None:
    text = raw                                  # 그냥 글자 파일이어도 받는다

# ── 2) `## 회차 n` 블록을 찾는다 ──────────────────────────────────
# 코드 울타리 안에 있어도 된다 — 울타리 줄이 아니라 머리글을 겨눈다.
head = re.compile(r"^##\s*회차\s*%s(?![0-9])[ \t]*[·:\-]?[ \t]*(.*)$" % re.escape(n), re.M)
STOP = re.compile(r"^(?:\s*$|```|##\s|---\s*$)")
FIELD = re.compile(r"^[ \t]*[-*][ \t]+([^:\n]{1,12}):[ \t]?(.*)$")

def blocks(t):
    for m in head.finditer(t):
        title, fields = m.group(1).strip(), []
        for line in t[m.end():].split("\n")[1:]:
            if STOP.match(line):
                break
            f = FIELD.match(line)
            if f and f.group(1).strip() in KNOWN:
                fields.append([f.group(1).strip(), [f.group(2).rstrip()]])
            elif fields:
                fields[-1][1].append(line.strip())
        yield title, fields

def placeholder(v):                             # `<이번 회차에 …>` 는 안 채운 것이다
    v = v.strip()
    return v.startswith("<") and v.endswith(">")

found = None
for title, fields in blocks(text):
    live = [(k, v) for k, v in fields
            if k in SESSION and v[0].strip() and not placeholder(v[0])]
    if live:
        found = (title, fields)                 # **마지막** 것을 쓴다 (초고 위에 결정고)
if not found:
    print(f"마지막 답변에 `## 회차 {n}` 블록이 없다 — 세션이 일지를 안 적었다")
    sys.exit(1)
title, fields = found

got = {}
dropped = []
for k, v in fields:
    if k in SESSION:
        val = "\n".join(["  " + x for x in v[1:]])
        got[k] = v[0].rstrip() + (("\n" + val) if val else "")
    elif k in DRIVER:
        dropped.append(k)                       # 줄의 주인이 아니다. 버린다

# ── 3) 일지에 넣는다 — 있으면 세션 줄만 갈고, 드라이버 줄은 살린다 ──
jt = io.open(path, encoding="utf-8").read() if os.path.exists(path) else "# JOURNAL\n\n---\n\n"
sec = re.compile(r"(^##\s*회차\s*%s(?![0-9]).*?$)(.*?)(?=^## |\Z)" % re.escape(n), re.M | re.S)
m = sec.search(jt)

old = {}
if m:
    cur = None
    for line in m.group(2).split("\n"):
        f = FIELD.match(line)
        if f and f.group(1).strip() in KNOWN:
            cur = f.group(1).strip(); old[cur] = f.group(2).rstrip()
        elif cur and line.strip():
            old[cur] += "\n  " + line.strip()
        elif not line.strip():
            cur = None
for k in DRIVER:
    if k in old and k not in got:
        got[k] = old[k]

body = "\n" + "\n".join("- %s: %s" % (k, got[k]) for k in ORDER if k in got) + "\n\n"
if m:
    jt = jt[:m.start(2)] + body + jt[m.end(2):]
else:
    heading = "## 회차 %s · %s" % (n, title or "(제목 없음)")
    anchor = "\n---\n\n"
    i = jt.find(anchor)
    stub = heading + body
    jt = (jt[:i + len(anchor)] + stub + jt[i + len(anchor):]) if i >= 0 else jt + "\n" + stub
io.open(path, "w", encoding="utf-8").write(jt)

msg = f"JOURNAL 회차 {n} 뽑음 — " + " · ".join(k for k in ORDER if k in got and k in SESSION)
if dropped:
    msg += f"  (버림: {' '.join(dropped)} — 드라이버 줄이다)"
print(msg)
PY
    ;;

  check)
    python3 - "$J" "${2:?회차 번호}" <<'PY'
import re, sys
path, n = sys.argv[1], sys.argv[2]
try: text = open(path, encoding="utf-8").read()
except OSError: print("일지 파일이 없다"); sys.exit(1)

m = re.search(r"^## 회차 %s(?: |·).*?$(.*?)(?=^## |\Z)" % re.escape(n), text, re.M | re.S)
if not m:
    print(f"회차 {n} 절이 없다"); sys.exit(1)
body = m.group(1)
missing = []
for f in ("문제", "원인", "고친 것", "남긴 것"):
    v = re.search(r"^- %s:[ \t]*(.*)$" % re.escape(f), body, re.M)
    if not v or not v.group(1).strip() or v.group(1).strip().startswith("—"):
        missing.append(f)
if missing:
    print("세션이 안 채운 줄: " + " · ".join(missing)); sys.exit(1)
print(f"JOURNAL 회차 {n} ok")
PY
    ;;

  stamp)
    python3 - "$J" "${2:?회차}" "${3:?항목}" "${4:?결과}" "${5:-}" <<'PY'
import json, os, re, subprocess, sys, datetime
path, n, item, result, commit = sys.argv[1:6]

item = re.sub(r"^- \[[ x]\] *", "", item).split("| verify:")[0].strip()

# 채점 — 세션 말이 아니라 채점자가 쓴 것만 읽는다
evid = "—"
try:
    r = json.load(open(".loop/results.json", encoding="utf-8"))
    parts = []
    for c in r["criteria"]:
        mark = "" if c["ok"] else " ✘"
        parts.append(f"{c['id']}{mark} " + " / ".join(c.get("evidence") or ["—"]))
    evid = " · ".join(parts)
except Exception:
    pass

cost = "—"
try:
    cost = "$" + open(".loop/spend.txt", encoding="utf-8").read().strip() + " 누적"
except OSError:
    pass

today = datetime.date.today().isoformat()
fields = {"날짜": today, "결과": result, "채점": evid, "비용": cost,
          "커밋": f"`{commit}`" if commit else "—"}

text = open(path, encoding="utf-8").read()
head = re.compile(r"^## 회차 %s(?: |·)" % re.escape(n), re.M)
if not head.search(text):
    stub = (f"## 회차 {n} · {item}\n"
            "- 날짜: \n- 결과: \n"
            "- 문제: \n- 원인: \n- 고친 것: \n- 바꾼 결정: \n- 잰 값: \n- 남긴 것: \n"
            "- 채점: \n- 비용: \n- 커밋: \n\n")
    anchor = "\n---\n\n"
    i = text.find(anchor)
    text = (text[:i + len(anchor)] + stub + text[i + len(anchor):]) if i >= 0 else text + "\n" + stub

m = re.search(r"(^## 회차 %s(?: |·).*?$)(.*?)(?=^## |\Z)" % re.escape(n), text, re.M | re.S)
body = m.group(2)
# 세션이 절 끝에 `---` 를 덧붙이는 일이 있다. 그냥 이어 붙이면 드라이버 줄이
# 그 구분선 **아래**로 떨어져 절 밖으로 나간다 — 회차 4 에서 실제로 그랬다.
# 그래서 **마지막 `- 무엇:` 줄 바로 뒤**에 끼운다.
lines = body.split("\n")
for k, v in fields.items():
    line = f"- {k}: {v}"
    hit = next((i for i, L in enumerate(lines) if re.match(r"^- %s:" % re.escape(k), L)), None)
    if hit is not None:
        lines[hit] = line
    else:
        last = max((i for i, L in enumerate(lines) if re.match(r"^- \S", L)), default=-1)
        lines.insert(last + 1, line)
body = "\n".join(lines)
text = text[:m.start(2)] + body + text[m.end(2):]
open(path, "w", encoding="utf-8").write(text)
print(f"JOURNAL 회차 {n} 찍음 — {result}")
PY
    ;;

  selftest) exec bash "$ROOT/tools/loop/journal-selftest.sh" ;;

  *) echo "사용법: journal.sh next | extract <n> <파일> | check <n> | stamp <n> <항목> <결과> [커밋] | selftest" >&2; exit 2 ;;
esac
