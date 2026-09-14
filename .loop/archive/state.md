### 바퀴 1 — P0-1 · P0-2 (Godot 뼈대 + 헤드리스 러너 + 프로젝트 로컬 격리)
- 만든 것: `project.godot` · `scenes/main.tscn` · `scripts/main.gd` ·
  `tools/loop/godot.sh` · `tools/loop/check.sh` · `tools/tests/`(러너 + TestBase + 검사 8개)
- 검사: `IMPORT ok` · `PARSE 5개 실패 0` · `TESTS 8 passed, 0 failed`
- 실제 창: **VIEWPORT 960x540 · WINDOW 1920x1080 · SCALE 2.00x**
- **발견: macOS Godot 은 XDG_* 를 무시한다.** `HOME` 을 프로젝트 안으로 돌려서 고쳤고,
  격리 자체를 검사로 박았다 (NUMBERS 2절).
- 대조군 5종 전부 빨개짐 → 원복 후 초록.
- 두 항목을 한 바퀴에 넣었다 (P0-1 의 verify 가 P0-2 없이는 성립하지 않는다).

