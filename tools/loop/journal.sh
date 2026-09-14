#!/usr/bin/env bash
# 바퀴 일지 (docs/JOURNAL.md) 를 읽고 쓴다.
#
#   journal.sh next               다음 바퀴 번호
#   journal.sh check <n>          세션이 사람 판단 줄을 채웠나 (안 채웠으면 exit 1)
#   journal.sh stamp <n> <항목> <결과> <커밋>
#                                 기계가 아는 것만 찍는다 — 날짜 · 결과 · 채점 · 비용 · 커밋.
#                                 절이 없으면 만들어 둔다 (사람 판단 줄은 비운 채로).
#
# **줄의 주인이 갈려 있다.** 세션은 「문제·원인·고친 것·바꾼 결정·잰 값·남긴 것」을 쓰고,
# 드라이버는 「날짜·결과·채점·비용·커밋」을 쓴다. 세션의 「됐습니다」가 결과 칸에 들어가면
# 일지가 증거가 아니라 자기 보고가 된다.
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
J="docs/JOURNAL.md"

case "${1:-}" in
  next)
    n="$(grep -o '^## 바퀴 [0-9]\+' "$J" 2>/dev/null | grep -o '[0-9]\+' | sort -n | tail -1)"
    echo $(( ${n:-0} + 1 ))
    ;;

  check)
    python3 - "$J" "${2:?바퀴 번호}" <<'PY'
import re, sys
path, n = sys.argv[1], sys.argv[2]
try: text = open(path, encoding="utf-8").read()
except OSError: print("일지 파일이 없다"); sys.exit(1)

m = re.search(r"^## 바퀴 %s(?: |·).*?$(.*?)(?=^## |\Z)" % re.escape(n), text, re.M | re.S)
if not m:
    print(f"바퀴 {n} 절이 없다"); sys.exit(1)
body = m.group(1)
missing = []
for f in ("문제", "원인", "고친 것", "남긴 것"):
    v = re.search(r"^- %s:[ \t]*(.*)$" % re.escape(f), body, re.M)
    if not v or not v.group(1).strip() or v.group(1).strip().startswith("—"):
        missing.append(f)
if missing:
    print("세션이 안 채운 줄: " + " · ".join(missing)); sys.exit(1)
print(f"JOURNAL 바퀴 {n} ok")
PY
    ;;

  stamp)
    python3 - "$J" "${2:?바퀴}" "${3:?항목}" "${4:?결과}" "${5:-}" <<'PY'
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
head = re.compile(r"^## 바퀴 %s(?: |·)" % re.escape(n), re.M)
if not head.search(text):
    stub = (f"## 바퀴 {n} · {item}\n"
            "- 날짜: \n- 결과: \n"
            "- 문제: \n- 원인: \n- 고친 것: \n- 바꾼 결정: \n- 잰 값: \n- 남긴 것: \n"
            "- 채점: \n- 비용: \n- 커밋: \n\n")
    anchor = "\n---\n\n"
    i = text.find(anchor)
    text = (text[:i + len(anchor)] + stub + text[i + len(anchor):]) if i >= 0 else text + "\n" + stub

m = re.search(r"(^## 바퀴 %s(?: |·).*?$)(.*?)(?=^## |\Z)" % re.escape(n), text, re.M | re.S)
body = m.group(2)
for k, v in fields.items():
    line = f"- {k}: {v}"
    if re.search(r"^- %s:" % re.escape(k), body, re.M):
        body = re.sub(r"^- %s:.*$" % re.escape(k), line.replace("\\", "\\\\"), body, count=1, flags=re.M)
    else:
        body = body.rstrip("\n") + "\n" + line + "\n"
text = text[:m.start(2)] + body + text[m.end(2):]
open(path, "w", encoding="utf-8").write(text)
print(f"JOURNAL 바퀴 {n} 찍음 — {result}")
PY
    ;;

  *) echo "사용법: journal.sh next | check <n> | stamp <n> <항목> <결과> [커밋]" >&2; exit 2 ;;
esac
