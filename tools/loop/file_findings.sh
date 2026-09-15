#!/usr/bin/env bash
# 대조군 전체 쓸기가 **놓친 것을 할 일로 적는다** — 사람을 기다리지 않는다.
#
# **왜 있나** (2026-09-15 사람이 정했다). 쓸기가 빨개지면 예전엔 루프가 `stop` 했다.
# 사람이 `.loop/runs/NNN/redteam-full.txt` 를 읽고 백로그에 항목을 손으로 적어야
# 했고, 그 「사람이 올 때까지」가 로그에서 몇 시간이었다 — 루프가 **스스로 고칠 수
# 있는 일**을 안 하고 서 있는 시간이다. 여기가 그 손일을 대신한다.
#
# **적는 자리가 「다음 항목 바로 앞」인 것이 요점이다.** 맨 아래에 적으면 38개 뒤에나
# 차례가 와서 죽은 게이트가 그때까지 살아 있다. 바로 앞에 적으면 **다음 회차가 이것부터
# 집는다** — 눈이 먼 상태가 한 회차로 끝난다.
#
# 두 종류를 가른다. 고칠 자리가 다르다:
#   놓쳤다    게이트가 **안 잡는다** — 깨뜨렸는데 초록이다. 게이트를 고쳐야 한다
#   헛돌았다  **대조군이** 아무것도 안 깨뜨렸다 — 치환 자리가 움직였다. 대조군을 고친다
#
# 사용법: file_findings.sh <쓸기결과.txt> <회차번호>
# 종료 코드: 0 = 적었다(또는 적을 게 없다) / 1 = 못 적었다 (사람이 봐야 한다)
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
SRC="${1:?사용법: file_findings.sh <쓸기결과.txt> <회차번호>}"
TURN="${2:?회차번호}"
BL="docs/BACKLOG.md"

[ -f "$SRC" ] || { echo "FINDINGS 쓸기 결과가 없다: $SRC" >&2; exit 1; }

python3 - "$SRC" "$TURN" "$BL" <<'PY'
import io, re, sys, datetime

src, turn, bl = sys.argv[1], sys.argv[2], sys.argv[3]
# ANSI 색을 벗긴다 — redteam.sh 가 색을 넣어 찍는다
raw = io.open(src, encoding='utf-8', errors='replace').read()
txt = re.sub(r'\x1b\[[0-9;]*m', '', raw)

miss, idle, section = [], [], ''
for ln in txt.splitlines():
    m = re.match(r'^── (.+?) ─+$|^== (.+?) ==$', ln.strip())
    if m:
        section = (m.group(1) or m.group(2) or '').strip()
    m = re.match(r'^\s*놓쳤다\s+(.+?)\s*\(기대', ln)
    if m: miss.append(m.group(1).strip()); continue
    m = re.match(r'^\s*헛돌았다\s+(.+?)\s*—', ln)
    if m: idle.append(m.group(1).strip()); continue

if not miss and not idle:
    print("FINDINGS 적을 게 없다 — 놓친 것도 헛돈 것도 없다")
    sys.exit(0)

tail = [l for l in txt.splitlines() if l.startswith('REDTEAM ')]
summary = tail[-1].strip() if tail else '(요약 줄 없음)'
today = datetime.date.today().isoformat()

lines = []
lines.append("- [ ] **대조군 전체 쓸기가 %d개를 놓쳤다 — 게이트가 안 잡는다** (회차 %s 가 자동으로 적었다)"
             % (len(miss) + len(idle), turn))
lines.append("      `%s` · 증거 `.loop/runs/*/redteam-full.txt` (%s)" % (summary, today))
if miss:
    lines.append("      **놓쳤다 (%d개) — 깨뜨렸는데 초록이다. 게이트를 고친다**:" % len(miss))
    for m in miss:
        lines.append("      - %s" % m)
if idle:
    lines.append("      **헛돌았다 (%d개) — 대조군이 아무것도 안 깨뜨렸다. 치환 자리가 움직였다**:" % len(idle))
    for m in idle:
        lines.append("      - %s" % m)
lines.append("      **하나씩 확인한다**: 고친 뒤 `redteam.sh --only <그 묶음>` 으로 그 묶음만 돌려")
lines.append("      **빨개지는지** 본다. 게이트를 약하게 해서 초록에 도달하면 안 된다.")
lines.append("      | verify: `tools/loop/check.sh tests`")

body = io.open(bl, encoding='utf-8').read().splitlines(keepends=True)

# **이미 적어 둔 같은 항목이 있으면 두 번 적지 않는다.** 쓸기가 여러 번 실패해도
# 백로그가 같은 줄로 불어나면 안 된다 — 앞의 것이 아직 미완료면 그것이 곧 이 일이다.
for l in body:
    if l.startswith('- [ ] **대조군 전체 쓸기가') and '게이트가 안 잡는다**' in l:
        print("FINDINGS 이미 적혀 있다 — 두 번 적지 않는다")
        sys.exit(0)

# **다음 미완료 항목 바로 앞**에 끼운다
at = None
for i, l in enumerate(body):
    if l.startswith('- [ ] '):
        at = i; break
if at is None:
    print("FINDINGS 백로그에 미완료 항목이 없다 — 맨 끝에 붙인다")
    at = len(body)

body[at:at] = [l + "\n" for l in lines]
io.open(bl, 'w', encoding='utf-8').write(''.join(body))
print("FINDINGS 할 일로 적었다 — 놓쳤다 %d · 헛돌았다 %d · %s:%d" % (len(miss), len(idle), bl, at + 1))
PY
