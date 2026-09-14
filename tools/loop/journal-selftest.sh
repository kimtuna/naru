#!/usr/bin/env bash
# `journal.sh extract` 가 도는지 잰다 — **진짜 일지는 안 건드린다** (NARU_JOURNAL).
#
# **이게 겨누는 구멍**: 뽑기가 조용히 실패하면 일지가 비고, 비어도 커밋은 초록이라
# 며칠 뒤에야 보인다. 회차 12 · 21 이 그랬다 (그때는 세션이 직접 썼다).
# 그래서 「뽑혔나」가 아니라 **무엇이 뽑히고 무엇이 버려지는가**까지 글자로 묶는다.
#
# 종료 코드: 0 = 다 통과 / 1 = 하나라도 실패
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; cd "$ROOT"
JSH="bash $ROOT/tools/loop/journal.sh"

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
export NARU_JOURNAL="$TMP/J.md"
P=0; F=0

fresh() {                                  # 앞 회차가 하나 든 빈 일지
  cat > "$NARU_JOURNAL" <<'MD'
# JOURNAL

---

## 회차 21 · 앞 회차
- 날짜: 2026-09-14
- 결과: 초록
- 문제: 앞 회차의 문제
- 원인: 까닭
- 고친 것: 무엇
- 남긴 것: 없음
- 커밋: `aaaaaaa`
MD
}
ok()   { P=$((P+1)); printf '  ok   %s\n' "$1"; }
bad()  { F=$((F+1)); printf '  FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '%s\n' "$2" | sed 's/^/         /'; }

rc_is() {                                  # rc_is <이름> <기대 exit> <명령...>
  local name="$1" want="$2"; shift 2
  local out rc; out="$("$@" 2>&1)"; rc=$?
  [ "$rc" -eq "$want" ] && ok "$name" || bad "$name (기대 exit $want · 잰 값 $rc)" "$out"
}
has()  { grep -qF -- "$2" "$NARU_JOURNAL" && ok "$1" || bad "$1 — 일지에 없다: $2"; }
hasnt(){ grep -qF -- "$2" "$NARU_JOURNAL" && bad "$1 — 일지에 남았다: $2" || ok "$1"; }
count(){                                   # count <이름> <패턴> <기대 개수>
  local n; n="$(grep -c -- "$2" "$NARU_JOURNAL")"
  [ "$n" -eq "$3" ] && ok "$1" || bad "$1 (기대 $3개 · 잰 값 $n개)"
}

echo "== journal selftest =="

# ── 1) 평범한 블록 — 답변 한가운데에 있어도 뽑는다 ────────────────
fresh
cat > "$TMP/a.txt" <<'MD'
diff 를 보인다.

## 회차 22 · 일지를 답변에서 뽑는다
- 문제: 세션이 일지를 두 번 빼먹었다
- 원인: 파일을 여는 것이 별도의 일이라 예산이 마르면 먼저 잘린다
- 고친 것: tools/loop/journal.sh 에 extract
- 바꾼 결정: 세션은 일지 파일을 안 연다
- 잰 값: 안 적은 회차 2건 (12 · 21)
- 남긴 것: 없음

끝.
MD
rc_is "평범한 블록을 뽑는다" 0 $JSH extract 22 "$TMP/a.txt"
has   "제목이 들어간다"              "## 회차 22 · 일지를 답변에서 뽑는다"
has   "문제가 들어간다"              "- 문제: 세션이 일지를 두 번 빼먹었다"
has   "남긴 것이 들어간다"           "- 남긴 것: 없음"
rc_is "뽑은 절을 check 가 받는다" 0 $JSH check 22
count "앞 회차를 안 건드린다"        '^## 회차 21 ' 1

# ── 2) 뽑기는 **덮어쓴다** — 두 번 돌려도 절은 하나다 ─────────────
rc_is "두 번째 뽑기도 exit 0" 0 $JSH extract 22 "$TMP/a.txt"
count "절이 하나뿐이다"              '^## 회차 22 ' 1

# ── 3) 코드 울타리 · 이어지는 줄 · **드라이버 줄은 버린다** ────────
# 세션이 「결과: 됐습니다」를 써 보내도 들어가면 안 된다.
# 일지가 증거가 아니라 자기 보고가 되는 자리가 정확히 여기다.
fresh
cat > "$TMP/b.txt" <<'MD'
```markdown
## 회차 22 · 울타리 안
- 날짜: 2999-01-01
- 결과: 됐습니다
- 문제: 첫 줄
  이어지는 둘째 줄
- 원인: 까닭
- 고친 것: 무엇
- 남긴 것: 없음
- 채점: 전부 초록입니다
- 커밋: `deadbee`
```
MD
rc_is "울타리 안에서도 뽑는다" 0 $JSH extract 22 "$TMP/b.txt"
has   "이어지는 줄이 살아남는다"     "  이어지는 둘째 줄"
hasnt "세션의 결과를 버린다"         "됐습니다"
hasnt "세션의 채점을 버린다"         "전부 초록입니다"
hasnt "세션의 날짜를 버린다"         "2999-01-01"
hasnt "세션의 커밋을 버린다"         "deadbee"

# ── 4) 이미 찍힌 절에 뽑으면 **드라이버 줄이 살아남는다** ──────────
fresh
rc_is "먼저 찍는다" 0 $JSH stamp 22 "- [ ] 아무 항목" "초록" "cafef00"
rc_is "그 위에 뽑는다" 0 $JSH extract 22 "$TMP/a.txt"
has   "드라이버 커밋이 살아남는다"   "- 커밋: \`cafef00\`"
has   "드라이버 결과가 살아남는다"   "- 결과: 초록"
has   "세션 줄이 갈렸다"             "- 문제: 세션이 일지를 두 번 빼먹었다"

# ── 5) 블록이 없으면 **조용히 넘어가지 않는다** ───────────────────
fresh
printf '일은 다 끝냈습니다. 커밋했습니다.\n' > "$TMP/c.txt"
rc_is "블록이 없으면 exit 1" 1 $JSH extract 22 "$TMP/c.txt"
count "절을 만들지 않는다"           '^## 회차 22 ' 0

# ── 6) 템플릿을 그대로 되돌려 보낸 것은 일지가 아니다 ─────────────
fresh
cat > "$TMP/d.txt" <<'MD'
## 회차 22 · 항목 이름
- 문제: <이번 회차에 실제로 막힌 것. 없으면 「없음」>
- 원인: <왜 그랬나. 증상이 아니라 이유>
- 고친 것: <무엇을 어떻게 바꿨나. 파일 이름을 적는다>
- 남긴 것: <다음으로 넘긴 것 / 사람이 정할 것. 없으면 「없음」>
MD
rc_is "자리표시자만 있으면 exit 1" 1 $JSH extract 22 "$TMP/d.txt"

# ── 7) 초고 위에 결정고 — 같은 번호가 두 번이면 **뒤엣것**이다 ────
fresh
cat > "$TMP/e.txt" <<'MD'
## 회차 22 · 초고
- 문제: 초고의 문제
- 원인: 초고
- 고친 것: 초고
- 남긴 것: 초고

다시 적는다.

## 회차 22 · 결정고
- 문제: 결정고의 문제
- 원인: 결정고
- 고친 것: 결정고
- 남긴 것: 결정고
MD
rc_is "두 번 적었으면 뒤엣것" 0 $JSH extract 22 "$TMP/e.txt"
has   "결정고가 들어간다"            "- 문제: 결정고의 문제"
hasnt "초고는 안 들어간다"           "초고의 문제"

# ── 8) 번호가 앞자리만 같은 절을 잡아채지 않는다 (2 ≠ 22) ─────────
fresh
rc_is "회차 2 를 회차 22 로 안 본다" 1 $JSH extract 2 "$TMP/a.txt"

# ── 9) 진짜 세션 파일 모양 — `result` 를 읽는다 ───────────────────
fresh
python3 - "$TMP/a.txt" "$TMP/s.json" <<'PY'
import io, json, sys
io.open(sys.argv[2], "w", encoding="utf-8").write(json.dumps(
    {"type": "result", "total_cost_usd": 1.5,
     "result": io.open(sys.argv[1], encoding="utf-8").read()}, ensure_ascii=False))
PY
rc_is "session.json 에서 뽑는다" 0 $JSH extract 22 "$TMP/s.json"
has   "session.json 의 문제가 들어간다" "- 문제: 세션이 일지를 두 번 빼먹었다"

# ── 10) 세션 파일이 없으면 죽지 말고 빨개진다 ─────────────────────
rc_is "없는 파일은 exit 1" 1 $JSH extract 22 "$TMP/없다.json"

echo
# **바닥이 없으면 검사를 지워서 초록에 갈 수 있다.** 통과 개수가 줄어도 실패가 0 이면
# 그냥 초록이기 때문이다 — 단위 검사에 `mintests.sh` 가 있는 것과 같은 자리다.
FLOOR=29
if [ "$F" -ne 0 ]; then echo "JOURNAL SELFTEST $P passed, $F failed"; exit 1; fi
if [ "$P" -lt "$FLOOR" ]; then
  echo "JOURNAL SELFTEST $P passed, 0 failed — 바닥 $FLOOR 아래다. 검사가 지워졌다"; exit 1
fi
echo "JOURNAL SELFTEST $P passed, 0 failed (바닥 $FLOOR)"; exit 0
