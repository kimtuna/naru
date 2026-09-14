#!/usr/bin/env bash
# **포커스 도둑질을 잰다.** 명령이 도는 동안 macOS 의 맨 앞 앱 이름을 계속 샘플한다.
#
# 왜 필요한가: 「창이 사람의 타이핑을 가져간다」는 눈으로만 보였다.
# 「안 뺏는 것 같다」는 증거가 아니다 — **표본 수 · 뺏은 표본 수 · 앞뒤의 맨 앞 앱**을 찍는다.
#
# `lsappinfo` 는 macOS 기본 도구이고 **권한을 안 묻는다.**
# `osascript` + System Events 는 접근성 권한을 묻는다 — 무인 루프가 못 쓴다.
#
# 사용법: focus.sh <표본간격ms> -- <명령...>
# 종료 코드: 뺏김 0 이면 0. **헤드리스 실행이 대조군이다** (NUMBERS 11절):
#   --headless 는 표본 9개 중 0, 창을 띄우면 7개 중 4.
set -uo pipefail
MS="${1:?사용법: focus.sh <표본간격ms> -- <명령...>}"
shift
[ "${1:-}" = "--" ] && shift

front() { lsappinfo info -only name "$(lsappinfo front)" 2>/dev/null | sed -n 's/.*"LSDisplayName"="\(.*\)"/\1/p'; }

SAMPLES="$(mktemp)"
OUT="${FOCUS_OUT:-/tmp/focus-cmd.out}"
trap 'rm -f "$SAMPLES"' EXIT

before="$(front)"
"$@" > "$OUT" 2>&1 &
cmd=$!
while kill -0 "$cmd" 2>/dev/null; do
  front >> "$SAMPLES"
  perl -e "select(undef,undef,undef,$MS/1000)"
done
wait "$cmd"; rc=$?
after="$(front)"

n="$(wc -l < "$SAMPLES" | tr -d ' ')"
stolen="$(grep -c -i 'godot' "$SAMPLES" || true)"
echo "FOCUS 표본 ${n} · 뺏김 ${stolen} · 시작 앞 [${before}] · 끝 앞 [${after}] · 되돌아옴 $([ "$before" = "$after" ] && echo yes || echo NO) · 명령 종료 ${rc}"
[ "$stolen" -eq 0 ]
