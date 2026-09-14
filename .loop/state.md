# 루프 상태

과제: `BACKLOG.md` 순서대로. 지금은 P0.

## 바퀴

### 바퀴 1 — P0-1 · P0-2 (Godot 뼈대 + 헤드리스 러너 + 프로젝트 로컬 격리)
- 만든 것: `project.godot` · `scenes/main.tscn` · `scripts/main.gd` ·
  `tools/loop/godot.sh` · `tools/loop/check.sh` · `tools/tests/`(러너 + TestBase + 검사 8개)
- 검사: `IMPORT ok` · `PARSE 5개 실패 0` · `TESTS 8 passed, 0 failed`
- 실제 창: **VIEWPORT 960x540 · WINDOW 1920x1080 · SCALE 2.00x**
- **발견: macOS Godot 은 XDG_* 를 무시한다.** `HOME` 을 프로젝트 안으로 돌려서 고쳤고,
  격리 자체를 검사로 박았다 (NUMBERS 2절).
- 대조군 5종 전부 빨개짐 → 원복 후 초록.
- 두 항목을 한 바퀴에 넣었다 (P0-1 의 verify 가 P0-2 없이는 성립하지 않는다).

### 바퀴 2 — P0-3 계약 배선 (증거를 기계가 쓴다)
- 만든 것: `PROMPT.md`(세션 지시서) · `.loop/criteria.tsv`(기준 3) ·
  `tools/loop/arm-contract.sh`(해시 잠금) · `tools/loop/run-contract.sh`(유일한 증거) ·
  `.loop/state.md`
- **`contract.md` 를 따로 두지 않았다** — 정지 규칙·red lines 를 `PROMPT.md` 에 합쳤다.
  매 바퀴 읽는 문서 수를 하나라도 줄이는 쪽이 낫다.
- 검사: `ALL GREEN` (기준 3개)
- 대조군 5종: 정상 0 / 기준 실패 1 / 변조 **77** / 공허 **78** / 파일 없음 **78**
- **고친 것 둘**: BSD `tr` 이 `\x1f` 를 못 읽어 증거가 한 줄로 뭉쳤다(→ `\037`).
  「공허한 계약」 게이트가 죽은 코드인지 확인하려고 무장을 풀고 다시 쟀다.
- 다음: P0-4 대조군을 스크립트로 (`redteam.sh`) → 그다음 **드라이버**

### 바퀴 3 — P1-1 (색 네모 플레이어 · 48px 타일 · 240 px/s · WASD)
- 만든 것: `scripts/player_motion.gd`(순수 계산 · `class_name PlayerMotion`) ·
  `scripts/player.gd` + `scenes/player.tscn`(CharacterBody2D + 48x48 ColorRect) ·
  `scenes/main.tscn` 에 배치 · `scripts/main.gd` 에 48px 격자(임시, 월드 생성은 P1-4) ·
  `project.godot` 에 WASD 입력 액션(물리 키코드) ·
  검사 10개(`test_player_motion.gd` 6 · `test_player_scene.gd` 4) ·
  **실측 게이트 `tools/tests/measure_move.gd`** (`check.sh tests` 가 단위 검사 뒤에 부른다)
- 검사: `TESTS 18 passed, 0 failed` (바닥 8) · `PARSE 9개 실패 0` · `IMPORT ok` · `ALL GREEN`
- **실측(헤드리스 · 물리 60Hz · 구간 1초)**:
  `MOVE 가로 238.97 px/s · 4.979 칸/s` · `MOVE 대각 239.91 px/s · 4.998 칸/s`
  (둘 다 실제 이동 거리 **240.00 px**, 기대 240 ±5)
- 실제 창: `VIEWPORT 960x540 · WINDOW 1920x1080 · SCALE 2.00x · TILE 48px · 보이는 칸 20.00 x 11.25`
- **대조군 3종을 새로 넣었다** (`redteam.sh` 에 박아 뒀다):
  정규화 제거 → `339.41` 잡음 / WASD 배선 끊기 → 잡음 /
  **노드가 속도를 절반으로 → 단위 검사 18개가 전부 초록으로 남고 실측만 잡았다(119.36)**.
  이 하나가 실측 게이트를 만든 이유다 (NUMBERS 5절).
- **판단 하나**: 「4방향 이동」이지만 **대각선을 정규화**해서 사실상 8방향이 됐다.
  WASD 두 개를 동시에 누를 수 있는 이상 대각선은 생기고, 막는 것보다 속력을 240 으로
  고정하는 쪽을 골랐다. 코어 키퍼(GDD A-4)도 8방향이다. **사람이 아니라면 되돌린다.**
- **못 한 것**: 화면을 눈으로 못 봤다. `screencapture` 가 화면 기록 권한에 막힌다
  (`could not create image from display`). 창은 떴고 숫자는 찍혔지만 **그림 판정은 사람 몫**이다.
- 다음: P1-2 논리 960x540 · 정수 2배 · 보이는 칸 20 x 11.25
  (이미 `test_project_settings.gd` 가 강제 중이라 **항목이 거의 끝나 있다** — 확인부터 한다)
- **대조군 자동화 결과: `REDTEAM 9 잡음, 1 놓침`.** 새로 넣은 3종은 전부 잡았는데,
  **기존의 「검사를 지우면 테스트 바닥이 잡는다」가 놓쳤다** (기대 exit 1 · 잰 값 0).
  이유: 검사가 8 → 18 로 늘었는데 계약의 바닥은 아직 `mintests.sh 8` 이라,
  검사를 하나 지워 17 이 돼도 바닥 위다. **가짜 게이트가 된 건 아니고 헐거워졌다.**
  고치는 자리는 `.loop/criteria.tsv` 인데 무장 중이고 세션의 red line 이다 —
  **드라이버의 `bump_mintests` (loop.sh) 가 초록 뒤에 8 → 18 로 올리고 다시 무장한다.**
  이 바퀴는 사람이 직접 부른 것이라 그게 안 돌았다. 사람이 `loop.sh` 로 돌리거나
  `bash tools/loop/arm-contract.sh` 로 직접 올려야 한다. **세션은 손대지 않았다.**

### 바퀴 4 — P1-2 (논리 960×540 · 정수 2배 · 보이는 칸 20 × 11.25)
- **항목은 이미 끝나 있었다** — `test_project_settings.gd` 가 값을 전부 강제 중.
  더한 것은 **실측 게이트 `tools/tests/measure_view.gd`**: 실제 창을 띄워 5프레임 뒤
  논리 화면·창·배율(`get_final_transform`)·카메라 배율·보이는 칸(`get_canvas_transform`)을 잰다.
  `check.sh tests` 가 `MOVE` 뒤에 **`--headless` 없이** 부른다.
- 검사: `IMPORT ok` · `PARSE 12개 실패 0` · `TESTS 18 passed, 0 failed` ·
  `MOVE 가로 238.41 / 대각 238.35 px/s` (실이동 240.00 px) ·
  `VIEW 논리 960x540 · 창 1920x1080 · 배율 2.00x · 카메라 1.00x · 보이는 칸 20.00 x 11.25` ·
  `ALL GREEN` (기준 5개)
- **대조군 2종을 새로 넣었다** (`redteam.sh` P1-2 절): 카메라 `zoom=(2,2)` → 보이는 칸 10.00 x 5.62 /
  실행 중 `window_set_size(1600,900)` → 배율 1.00x. **둘 다 단위 검사 18개는 전부 초록**이고
  새 게이트만 잡았다 — 바퀴 3 의 속도 게이트와 같은 모양의 구멍이다.
  전체: **`REDTEAM 13 잡음, 0 놓침`** — 바퀴 3 이 놓친 「검사를 지우면 바닥이 잡는다」도
  이제 잡는다 (사람이 `mintests` 바닥을 8 → 18 로 올렸다).
- 알게 된 것 둘: `--headless` 는 창 크기가 `(0,0)` 이라 배율을 못 잰다 /
  `scale_mode=integer` 에서 `content_scale_factor=1.5` 는 **먹지 않는다**(배율 2.00 그대로).
  정수 배율은 1600×900 창에서 1.66 이 아니라 **1** 로 떨어진다. 둘 다 GOTCHAS 에 넣었다.
- **남은 위험**: 기준 4 가 이제 **GUI 세션을 필요로 한다.** 화면 없는 기계에서는 빨개진다.
- 다음: P1-3 마우스가 방향을 정한다 (4방향 스냅 + 히스테리시스)
