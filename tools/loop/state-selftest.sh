#!/usr/bin/env bash
# 회차 기록 자르기가 도는지 잰다 — **진짜 `.loop/state.md` 는 안 건드린다**
# (임시 디렉터리에 `tools/loop/` 모양을 세우고 거기서 돌린다).
#
# **이게 겨누는 구멍**: 기준 5(`doclen.sh`)는 판정 시점에 `.loop/state.md` 를 재는데
# 그 시점의 파일에는 **세션이 방금 붙인 절**이 들어 있다. 자르기(`state.py roll`)가
# 초록이 난 **뒤**에 돌면 그 한 절 때문에 상한을 넘어 회차가 빨개지고, 다음 회차에는
# 아무 일도 없었다는 듯 초록이 된다 — 회차 25 가 98줄 · 상한 90 으로 그렇게 걸렸다.
#
# 그래서 두 가지를 같이 묶는다:
#   · 자르기 자체가 맞게 도나 (남기는 개수 · 아카이브 · 머리말 · 멱등)
#   · **드라이버가 판정 앞에서 자르나** (`loop.sh` 의 6d 가 7 보다 앞이나)
# 그리고 **무뎌지지 않았나** — 자른 뒤에도 남는 절들이 두꺼우면 여전히 빨개야 한다.
#
# 종료 코드: 0 = 다 통과 / 1 = 하나라도 실패
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
LOOP="$ROOT/tools/loop/loop.sh"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
P=0; F=0
ok()  { P=$((P+1)); printf '  ok   %s\n' "$1"; }
bad() { F=$((F+1)); printf '  FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/         /'; }

# 가짜 루트 — `state.py` 와 `doclen.sh` 는 제 파일 위치에서 루트를 잡으므로
# 여기에 `tools/loop/` 를 세워 두면 진짜 저장소를 못 본다.
R="$TMP/root"
mkdir -p "$R/tools/loop" "$R/.loop"
cp "$ROOT/tools/loop/state.py" "$ROOT/tools/loop/doclen.sh" "$R/tools/loop/"

S="$R/.loop/state.md"
A="$R/.loop/archive/state.md"

# mkstate <절 개수> <절 한 개의 줄 수>  — 회차 N 절을 그만큼 쌓는다
mkstate() {
  python3 - "$S" "$1" "$2" <<'PY'
import io, sys
path, n, lines = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
out = ["# 회차 기록\n", "\n", "> 드라이버가 쌓고 자른다.\n", "\n"]
for i in range(1, n + 1):
    out.append("### 회차 %d — 제목\n" % i)
    out += ["- 줄 %d\n" % j for j in range(1, lines - 1)]
    out.append("\n")
io.open(path, "w", encoding="utf-8").write("".join(out))
PY
}
lines_of() { wc -l < "$1" | tr -d ' '; }
roll()     { (cd "$R" && python3 tools/loop/state.py roll "$1" 2>&1); }
tail_n()   { (cd "$R" && python3 tools/loop/state.py tail "$1" 2>&1); }
doclen()   { (cd "$R" && bash tools/loop/doclen.sh ".loop/state.md:$1" >/dev/null 2>&1); }
secs()     { local n; n="$(grep -c '^### 회차 ' "$1" 2>/dev/null)"; printf '%s' "${n:-0}"; }

num_is() { [ "$2" = "$3" ] && ok "$1" || bad "$1 (기대 $3 · 잰 값 $2)"; }
has()    { grep -qF -- "$2" "$1" && ok "$3" || bad "$3 — $1 에 없다: $2"; }
hasnt()  { grep -qF -- "$2" "$1" && bad "$3 — $1 에 남았다: $2" || ok "$3"; }

echo "== state selftest =="

# ── 1) 자르기 자체 ──────────────────────────────────────────────────
mkstate 6 10
roll 3 >/dev/null
num_is "6회차를 3으로 자른다"        "$(secs "$S")" "3"
has "$S" "### 회차 6 — 제목" "최근 절은 남는다"
has "$S" "### 회차 4 — 제목" "경계 절(끝에서 3번째)은 남는다"
hasnt "$S" "### 회차 3 — 제목" "오래된 절은 빠진다"
has "$S" "# 회차 기록"       "머리말은 안 잘린다"
num_is "잘린 절은 아카이브로 간다"   "$(secs "$A")" "3"
has "$A" "### 회차 1 — 제목" "아카이브에 제일 오래된 절이 있다"

# **아카이브는 덮어쓰면 안 된다** — 덮으면 회차 기록이 조용히 사라진다.
before="$(secs "$A")"
mkstate 5 10
roll 3 >/dev/null
num_is "아카이브는 덧붙인다 (안 덮어쓴다)" "$(secs "$A")" "$(( before + 2 ))"

# 멱등 — 이미 상한 아래면 아무것도 안 한다.
mkstate 3 10
sz="$(lines_of "$S")"
roll 3 >/dev/null
num_is "상한 아래면 그대로 둔다"     "$(lines_of "$S")" "$sz"
roll 3 | grep -q 'ROLL 유지 3회차' && ok "안 자를 때 그렇다고 찍는다" \
  || bad "안 자를 때 그렇다고 찍는다" "$(roll 3)"

# 세션에게 주입되는 꼬리는 남긴 절 안에서 나와야 한다.
mkstate 6 10
roll 3 >/dev/null
num_is "tail 2 는 절 2개다"          "$(tail_n 2 | grep -c '^### 회차 ')" "2"
tail_n 2 | grep -q '### 회차 6' && ok "tail 은 최근 절을 준다" || bad "tail 은 최근 절을 준다"

# ── 2) 회차 25 그 자체 — 세션이 붙인 절 하나가 상한을 넘긴다 ────────
#
# 절 28줄 × 3 + 머리말 4 = 88 ≤ 90. 세션이 하나 더 붙이면 116 > 90 이다.
mkstate 4 28
num_is "세션이 붙인 뒤 길이"         "$(lines_of "$S")" "116"
doclen 90 && bad "자르기 전에는 상한을 넘는다" || ok "자르기 전에는 상한을 넘는다"
roll 3 >/dev/null
num_is "자른 뒤 길이"                "$(lines_of "$S")" "88"
doclen 90 && ok "자르고 나면 상한 아래다" || bad "자르고 나면 상한 아래다"

# ── 3) **무뎌지지 않았나** — 자르기가 진짜 부풀기를 덮으면 안 된다 ──
#
# 여기가 이 검사의 절반이다. 「판정 앞에서 자른다」의 값싼 오답은 「state.md 를
# 아예 안 센다」인데, 그러면 세션이 절 하나에 300줄을 적어도 초록이 난다.
mkstate 4 40
roll 3 >/dev/null
num_is "두꺼운 절은 잘라도 남는다"   "$(lines_of "$S")" "124"
doclen 90 && bad "남은 절이 두꺼우면 자른 뒤에도 빨갛다" \
           || ok "남은 절이 두꺼우면 자른 뒤에도 빨갛다"

mkstate 1 200
roll 3 >/dev/null
doclen 90 && bad "절 하나가 두꺼워도 빨갛다 (자를 게 없다)" \
           || ok "절 하나가 두꺼워도 빨갛다 (자를 게 없다)"

# ── 4) 드라이버가 **판정 앞에서** 자르나 ────────────────────────────
#
# 자르기가 맞게 돌아도 부르는 자리가 초록 뒤면 회차 25 가 그대로 다시 난다.
# 줄 번호로 묶는다 — 6d(자르기) < 7(판정) < 초록(커밋).
lineno() { grep -n -- "$1" "$LOOP" | head -1 | cut -d: -f1; }
TRIM="$(lineno '^  trim_state$')"
JUDGE="$(lineno '^  bash tools/loop/run-contract.sh ')"
COMMIT="$(lineno '^    commit_state_roll$')"

[ -n "$TRIM" ]   && ok "드라이버가 판정 회차 안에서 자른다" \
                 || bad "드라이버가 판정 회차 안에서 자른다 — trim_state 를 부르는 데가 없다"
[ -n "$JUDGE" ]  && ok "드라이버가 채점자를 부른다" \
                 || bad "드라이버가 채점자를 부른다 — run-contract.sh 호출이 없다"
[ -n "$COMMIT" ] && ok "드라이버가 잘린 기록을 커밋한다" \
                 || bad "드라이버가 잘린 기록을 커밋한다 — commit_state_roll 호출이 없다"
[ -n "$TRIM" ] && [ -n "$JUDGE" ] && [ "$TRIM" -lt "$JUDGE" ] \
  && ok "자르기가 판정보다 앞이다 (${TRIM} < ${JUDGE})" \
  || bad "자르기가 판정보다 앞이다 — 뒤면 세션이 붙인 절이 상한을 넘겨 빨개진다" \
         "trim_state=$TRIM  run-contract=$JUDGE"
[ -n "$COMMIT" ] && [ -n "$JUDGE" ] && [ "$COMMIT" -gt "$JUDGE" ] \
  && ok "커밋은 판정보다 뒤다 (${COMMIT} > ${JUDGE})" \
  || bad "커밋은 판정보다 뒤다 — 앞이면 빨간 회차가 기록을 역사에 남긴다" \
         "commit_state_roll=$COMMIT  run-contract=$JUDGE"

# **자르기는 커밋하지 않는다.** 둘을 도로 합치면 `head_after` 가 부기 커밋을 가리켜
# 일지의 「커밋」 칸이 항목을 만든 커밋을 못 짚는다 (finish_journal 의 주석 그대로).
python3 - "$LOOP" <<'PY' && ok "자르기 함수가 커밋하지 않는다" || bad "자르기 함수가 커밋하지 않는다 — head_after 가 부기 커밋이 된다"
import io, re, sys
s = io.open(sys.argv[1], encoding="utf-8").read()
m = re.search(r"(?m)^trim_state\(\) \{\n(.*?)^\}\n", s, re.S)
sys.exit(0 if m and "git " not in m.group(1) else 1)
PY

# 세션에게 주는 꼬리가 남기는 절보다 많으면 빈 절을 달라는 것이다.
KEEP="$(sed -n 's/^STATE_KEEP=\([0-9]*\).*/\1/p' "$LOOP" | head -1)"
TAILN="$(sed -n 's/.*state\.py tail \([0-9]*\).*/\1/p' "$LOOP" | head -1)"
[ -n "$KEEP" ] && [ -n "$TAILN" ] && [ "$TAILN" -le "$KEEP" ] \
  && ok "세션에게 주는 꼬리 $TAILN 절이 남기는 $KEEP 절 안에 든다" \
  || bad "세션에게 주는 꼬리가 남기는 절보다 많다" "tail=$TAILN  keep=$KEEP"

echo
# 바닥 — 실패가 0 이어도 **개수가 줄면** 빨갛다. 검사를 지워서 초록에 가는 길을 막는다.
FLOOR=26
if [ "$F" -ne 0 ]; then echo "STATE SELFTEST $P passed, $F failed"; exit 1; fi
if [ "$P" -lt "$FLOOR" ]; then
  echo "STATE SELFTEST $P passed, 0 failed — 바닥 $FLOOR 아래다. 검사가 지워졌다"; exit 1
fi
echo "STATE SELFTEST $P passed, 0 failed (바닥 $FLOOR)"; exit 0
