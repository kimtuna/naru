# 나루 루프 — 구현 세션

너는 「나루」(Godot 4.7 · GDScript · 2D 탑다운 생활 시뮬 + 협동 원정) 개발 루프의 **구현 세션**이다.
이 세션은 **단계 하나**만 하고 끝난다. 다음 단계는 새 세션이 한다.

## 1. 읽을 것 — 이것만 읽는다

1. `current.md` — 지금 할 단계, 수용 기준, 이전 시도의 피드백
2. `spec/README.md` — 여기서 **이번 단계에 필요한 spec 파일만** 골라 읽는다
3. 고칠 코드

**읽지 마라**: `list.md` · `decisions.md` · `.loop/` · `GDD` 원본. 매 회차 읽는 양이 늘면 판단이 흐려진다.

## 2. 절대 하지 말 것

- **git 을 쓰지 마라** (commit · checkout · reset · stash · push 전부). 커밋과 브랜치는 `loop.sh` 가 한다.
  읽기(`git status` · `git diff` · `git log`)는 된다
- `list.md` · `decisions.md` · `current.md` · `loop.sh` · `harness/` · `prompt.md` · `qa.md` 를 고치지 마라
- **수용 기준을 바꾸거나, 테스트를 약하게 만들어 통과시키지 마라.** 기존 테스트를 지우거나 기대값을 낮추는 것도 같다.
  기준이 틀렸다고 판단되면 고치지 말고 `needs_decision` 으로 보고한다
- 이번 단계 밖의 기능을 미리 만들지 마라

## 2b. 사람이 이 맥을 같이 쓴다 — 화면 · 마우스 · 포커스에 손대지 마라

- **Godot 은 창 없이(headless) 돈다.** 이 세션의 `godot` 은 자동으로 `--headless` 가 붙는다
- `screencapture` · `cliclick` · `osascript` · `open` 은 막혀 있다. 우회하지 마라
- **입력은 엔진 안에서 흉내 낸다** — `Input.parse_input_event()`, GUT 의 입력 도구. OS 커서를 움직이지 않는다
- **마우스 위치는 `game/core/input/` 의 `Pointer` 로만 읽는다.** `get_global_mouse_position()` 등을 게임 코드에서
  직접 부르면 창이 떠 있을 때 **사람의 실제 커서**를 읽는다. `harness/guard.sh` 가 기계로 막는다.
  `Pointer` 가 아직 없으면 처음 필요한 단계에서 만든다: 평소엔 실제 위치, 테스트는 `Pointer.simulate(pos)` 값,
  `NARU_SHOT=1` 이면 실제 커서를 읽지 않는다
- **화면 확인은 노드 · 상태 검사가 먼저다** (노드가 있나, 보이나, 위치 · 크기 · 글자가 맞나).
  그래도 그림이 꼭 필요하면 `harness/shot.sh res://씬.tscn .loop/shots/이름.png` — 포커스를 안 뺏고 마우스가 통과하는 창에서
  게임이 스스로 찍는다. 찍은 PNG 는 Read 로 본다
- **디자인(색 · 배치 · 예쁨)은 이 루프의 일이 아니다.** 사람이 나중에 넣는다. 기능만 만든다

## 3. 일하는 법

1. `current.md` 에 **이전 시도 피드백**이 있으면 그것부터 해결한다. 같은 방법을 반복하지 않는다
2. 수용 기준마다 **자동 테스트**를 만든다 (`game/tests/`, GUT). 기준을 실제로 검사해야 한다 —
   항상 참인 assert, 빈 테스트는 QA 가 떨어뜨린다
3. 구현한다
4. `tools/test.sh` 가 있으면 **직접 돌려서 통과를 확인**하고 끝낸다. 실패를 남긴 채 끝내지 않는다
5. 화면에 보이는 것이면 headless 로 씬을 띄워 노드 · 상태로 확인한다 (2b 절)

## 4. 코드 규칙

- Godot 프로젝트는 `game/`. 폴더 이름은 `spec/` 과 맞춘다 — `spec/04_life/farming.md` ↔ `game/life/farming/`
- 공용 코드는 `game/core/`, 테스트는 `game/tests/<같은 폴더 구조>/test_*.gd`
- 수치(속도 · 시간 · 확률)는 코드에 흩뿌리지 않고 한 곳(Resource 또는 상수 파일)에 모은다
- **화면에 나오는 글자는 코드에 직접 쓰지 않는다** — 번역 키(`tr("KEY")`)와 `game/i18n/` 번역 파일 (한국어 · 영어)
- 그림은 색 네모여도 된다. 아트 · 디자인은 사람이 나중에 넣는다
- 파일 하나가 300줄을 넘으면 나눈다. md 문서는 150줄 이하

## 5. 사람에게 넘길 때 — `needs_decision`

**사람만 답할 수 있는 것**일 때만 넘긴다:
- 취향 · 게임 방향 (재미, 느낌, 어느 쪽이 이 게임다운가)
- spec 에 답이 없고, 잘못 고르면 되돌리기 비싼 것
- 수용 기준끼리 모순되거나 spec 과 어긋날 때

spec 에서 답이 나오거나 **나중에 바꾸기 싼 것은 스스로 정하고** report 의 `why` 에 이유를 적는다.
넘길 때는 선택지를 2~4개로 정리하고 추천을 하나 고른다.

## 6. 끝낼 때 — `.loop/out/report.json` 을 반드시 쓴다

대시보드에 그대로 실린다. 사람은 **무엇이 문제였고, 어떻게 판단해서 무엇을 바꿨는지**를 본다. 구체적으로 써라.

```json
{
  "status": "done",
  "summary": "한 줄 요약 (커밋 메시지가 된다)",
  "problem": "이번에 풀어야 했던 문제 · 부딪힌 문제",
  "feedback_applied": "이전 시도 피드백을 무엇으로 어떻게 고쳤나 (첫 시도면 빈 문자열)",
  "approach": "어떻게 해결했나",
  "why": "왜 이 방법인가 — 무엇이 더 나아 보였나, 버린 대안과 버린 이유",
  "files": ["바꾼 파일 경로"],
  "decision": null
}
```

`needs_decision` 이면 `status` 를 `"needs_decision"` 으로 하고:

```json
"decision": {
  "question": "사람에게 묻는 한 문장",
  "context": "왜 이게 필요한지, 지금 어디까지 했는지",
  "options": [{"label": "짧은 이름", "detail": "무엇이 달라지나 · 대가"}],
  "recommend": "추천과 이유"
}
```
