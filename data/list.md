# 할 일 목록

사람과 Claude 가 대화로 채운다. `loop.sh` 가 위에서부터 **순서대로** 처리하고 체크한다.
Claude 루프 세션은 이 파일을 읽지 않는다 — `loop.sh` 가 지금 할 단계만 `current.md` 로 뽑아 준다.

## 형식

- `## [ ] ID 제목` — 묶음. 한 묶음 = 브랜치 하나. 단계가 전부 통과해야 main 에 합친다
- `- [ ] 1. 단계 제목` — 단계. 한 단계 = 루프 한 회차
- `  - 기준: ...` — 수용 기준 (QA 채점표). 단계 밑에 들여 쓴다
- `  - ...` — 기준이 아닌 참고
- 묶음 제목 바로 밑 `- spec: ...` · `- 결정: ...` — 묶음 전체에 붙는 정보
- 표시: `[ ]` 할 일 · `[x]` 끝남 · `[>]` 결정 대기로 넘어감 (`decisions.md`)
- 결정이 나면 `[>]` 를 `[ ]` 로 되돌리고 `- 결정: ...` 을 적는다. 브랜치에 남은 작업에서 이어간다

## [x] G-001 프로젝트 기반
- spec: spec/01_settings/, spec/00_core/roadmap.md
- [x] 1. Godot 프로젝트 만들기
  - `game/project.godot`, 메인 씬 하나 (빈 화면이어도 된다)
  - 기준: `godot --headless --path game --quit` 가 오류 없이 0 으로 끝난다
  - 기준: `game/` 아래 폴더가 spec/ 과 같은 이름으로 있다 (core, settings, player, world, life, craft, build, automation, combat, expedition, economy, multiplayer, ui, tests, i18n)
  - 기준: `.gitignore` 가 `game/.godot/` 를 제외한다
- [x] 2. 테스트 실행기
  - GUT 를 `game/addons/gut/` 에 설치한다. Godot 4.7.2 에서 안 돌면 GUT 대신 최소한의 자체 러너를 만들고 report 에 이유를 적는다
  - 기준: `tools/test.sh` 가 `game/tests/` 아래 테스트를 headless 로 전부 돌린다
  - 기준: 테스트가 모두 통과하면 0, 하나라도 실패하면 0 이 아닌 값으로 끝난다 — QA 는 일부러 실패하는 테스트를 임시로 넣어 확인한다
  - 기준: 예제 테스트가 1개 이상 있고 통과한다
- [x] 3. 번역 뼈대
  - 기준: `game/i18n/` 에 한국어 · 영어 번역 파일이 있고 프로젝트에 등록되어 있다
  - 기준: 메인 씬에 번역 키로 된 글자가 하나 있고, 언어를 바꾸면 글자가 바뀌는 것을 테스트가 확인한다
