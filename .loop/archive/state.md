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

