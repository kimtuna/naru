#!/usr/bin/env bash
# 세션이 왜 끝났나를 가른다 — 드라이버가 「다시 걸까 / 실패로 칠까」를 정하는 자리.
#
#   session-class.sh <session.json> <session.err> <exit code>
#
# 한 줄을 찍는다:
#   ok                 정상
#   limit <에폭> <말>  토큰·사용량 한도. 에폭이 0 이면 언제 풀리는지 모른다
#   retry <말>         일시적인 것 (과부하 · 5xx · 네트워크)
#   timeout            시간 상한에 걸려 죽었다
#   fail <말>          그 밖
#
# **왜 가르나**: 한도에 걸린 것을 「세션 실패」로 세면 같은 항목을 두 번 더 태우고
# 「같은 항목이 연속 실패했다」로 멈춘다 — 사유도 틀리고 돈도 버린다.
set -uo pipefail
python3 - "$@" <<'PY'
import json, re, sys
js, err, rc = sys.argv[1], sys.argv[2], int(sys.argv[3])

def read(p):
    try: return open(p, encoding="utf-8", errors="replace").read()
    except OSError: return ""

raw = read(js) + "\n" + read(err)
blob = raw
try:
    d = json.loads(read(js))
    blob += "\n" + json.dumps(d, ensure_ascii=False)
except Exception:
    d = {}

low = blob.lower()

# 한도 — 「언제 풀리나」가 같이 오는 경우가 있다 (Claude AI usage limit reached|<에폭>)
LIMIT = ("usage limit", "rate limit", "rate_limit", "quota", "insufficient_quota",
         "credit balance", "too many requests", "429")
if any(k in low for k in LIMIT):
    m = re.search(r"usage limit reached\|(\d{9,})", blob, re.I)
    epoch = m.group(1) if m else "0"
    m2 = re.search(r"[^\n]*(?:usage limit|rate limit|quota|credit balance)[^\n]*", blob, re.I)
    print("limit", epoch, (m2.group(0).strip()[:120] if m2 else "사용량 한도"))
    sys.exit(0)

TRANSIENT = ("overloaded", "529", "502", "503", "504", "econnreset", "etimedout",
             "fetch failed", "socket hang up", "network error", "internal server error")
if any(k in low for k in TRANSIENT):
    m = re.search(r"[^\n]*(?:overloaded|529|50[234]|econnreset|etimedout|fetch failed)[^\n]*",
                  blob, re.I)
    print("retry", (m.group(0).strip()[:120] if m else "일시적인 오류"))
    sys.exit(0)

if rc == 143 or rc == 124:
    print("timeout"); sys.exit(0)
if rc != 0:
    print("fail", "exit %d" % rc); sys.exit(0)
if d.get("is_error"):
    print("fail", str(d.get("result", ""))[:120]); sys.exit(0)
print("ok")
PY
