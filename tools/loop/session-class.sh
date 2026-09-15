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

# **정상으로 끝났으면 거기서 끝이다.** 아래 낱말 찾기를 JSON 전체에 돌리면
# session_id 나 비용 숫자에 우연히 든 「503」 같은 것이 걸린다 — 실제로 걸렸다
# (2026-09-15: stop_reason end_turn · exit 0 인 회차를 retry 로 잘못 봤다).
if rc == 0 and isinstance(d, dict) and d and not d.get("is_error"):
    print("ok"); sys.exit(0)

# 낱말은 **stderr 와 오류 필드에서만** 찾는다. 성공한 JSON 본문은 안 본다.
blob = read(err)
if isinstance(d, dict):
    for k in ("error", "result", "message", "subtype"):
        v = d.get(k)
        if isinstance(v, str):
            blob += "\n" + v
        elif v is not None:
            blob += "\n" + json.dumps(v, ensure_ascii=False)
low = blob.lower()

# 한도 — 「언제 풀리나」가 같이 오는 경우가 있다 (Claude AI usage limit reached|<에폭>)
LIMIT = ("usage limit", "rate limit", "rate_limit", "quota", "insufficient_quota",
         "credit balance", "too many requests")
if any(k in low for k in LIMIT) or re.search(r"(?:status|code|http|error)\D{0,8}429", blob, re.I):
    m = re.search(r"usage limit reached\|(\d{9,})", blob, re.I)
    epoch = m.group(1) if m else "0"
    m2 = re.search(r"[^\n]*(?:usage limit|rate limit|quota|credit balance)[^\n]*", blob, re.I)
    print("limit", epoch, (m2.group(0).strip()[:120] if m2 else "사용량 한도"))
    sys.exit(0)

# **맨 숫자로 판단하지 않는다.** 앞에 상태·오류를 뜻하는 말이 붙어야 한다.
CODE = r"(?:status|code|http|error|오류)\D{0,8}(?:429|5\d\d)"
# **와이파이가 끊기면 제일 흔한 것이 DNS 실패다.** 이걸 빼놓으면 끊긴 순간
# 「세션 실패」로 세서 같은 항목을 STUCK_LIMIT 번 태우고 멈춘다 — 재시도를 아예 안 한다.
WORDS = ("overloaded", "econnreset", "etimedout", "econnrefused", "econnaborted",
         "enotfound", "eai_again", "enetunreach", "ehostunreach", "enetdown",
         "getaddrinfo", "fetch failed", "socket hang up", "network error",
         "offline", "internal server error", "service unavailable", "bad gateway",
         "connection refused", "could not resolve", "temporary failure in name resolution")
if any(k in low for k in WORDS) or re.search(CODE, blob, re.I):
    m = re.search(r"[^\n]*(?:" + "|".join(re.escape(w) for w in WORDS) + "|" + CODE + r")[^\n]*",
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
