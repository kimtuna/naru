#!/usr/bin/env bash
# game/tests/ 아래 GUT 테스트를 headless 로 전부 돌린다.
# 모두 통과하면 0, 실패·스크립트 오류·테스트 0개면 0 이 아닌 값.
set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GAME="$ROOT/game"
GODOT="${GODOT:-godot}"
TEST_DIR="${TEST_DIR:-res://tests}"  # 실행기 자체 테스트가 바꿔 쓴다

# class_name 캐시(.godot/)가 없으면 GutTest 를 못 찾는다 — 먼저 import.
"$GODOT" --headless --path "$GAME" --import >/dev/null 2>&1

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

"$GODOT" --headless --path "$GAME" -s res://addons/gut/gut_cmdln.gd \
	-gdir="$TEST_DIR" -ginclude_subdirs -gprefix=test_ -gsuffix=.gd \
	-gdisable_colors -gexit 2>&1 | tee "$LOG"
code=${PIPESTATUS[0]}

# GUT 는 문법 오류로 못 읽은 테스트 파일을 건너뛰고도 0 으로 끝날 수 있다.
if grep -Eq '^(SCRIPT ERROR|ERROR: Failed to load script)' "$LOG"; then
	echo "test.sh: 스크립트 오류가 있다" >&2
	[ "$code" -eq 0 ] && code=1
fi
if ! grep -Eq '^Passing Tests +[1-9]' "$LOG"; then
	echo "test.sh: 통과한 테스트가 없다" >&2
	[ "$code" -eq 0 ] && code=1
fi

exit "$code"
