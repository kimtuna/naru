# Naru — 운영 지침

> **이 파일은 운영용만이다.** 이 기계에서 무엇을 어떤 명령으로 돌리는가만 적는다.
> 여기가 부풀면 매 회차의 문맥이 오염된다.

## 무엇을 읽나

**md 는 전부 `docs/` 에 있다.** 이 파일만 루트다 — Claude Code 가 루트만 자동으로 읽는다.

| 파일 | 무엇 | 언제 |
|---|---|---|
| `docs/BACKLOG.md` | **할 일. 한 줄 = 한 회차** | 매 회차 — 번호가 가장 작은 미완료 항목 하나만 |
| `docs/NUMBERS.md` | **실측값. 진실의 출처** | 값을 쓰거나 고칠 때 |
| `docs/GOTCHAS.md` | 엔진·셸의 함정 | **에러가 났을 때 먼저 grep** |
| `docs/GDD.md` | 게임 기획서 — 「왜」 | 그 영역을 처음 만들 때만. **매 회차 읽지 마라** |
| `docs/JOURNAL.md` | 회차 일지 | **읽지도 쓰지도 않는다. 답변 끝의 블록을 드라이버가 뽑아 넣는다** |

**통째로 읽는 파일은 없다.** 절 목차나 grep 으로 필요한 만큼만 연다.

## 명령

```bash
tools/loop/check.sh all            # import → parse → tests  (순서 중요)
tools/loop/check.sh import|parse|unit|tests   # unit = 단위만 (실측 7종 없이)
tools/loop/godot.sh <초> -- <인자>  # Godot 의 유일한 입구
tools/loop/godot.sh 5 -- --path .  # 사람이 직접 띄워 보기
tools/loop/shot.sh <out.png> [씬] [프레임] [--max-flat N]   # 화면을 PNG 로 굽는다
tools/loop/ctl.sh start [회차수] | stop | status | report   # 루프 · 대시보드
```

## 규칙

- **한 회차는 백로그 한 항목.** 두 개를 합쳤으면 커밋 메시지에 왜인지 적는다.
- **새 검사를 만든 회차는 대조군을 돌린다** — 일부러 깨뜨려서 빨개지는지.
  안 하면 아무것도 안 잡는 가짜 게이트가 쌓인다.
- **`[ASK]` 항목은 세션을 열지 않는다.** 사람이 답해야 하는 것이다.
- **잰 값은 `NUMBERS.md` 에 조건과 함께 적는다.** 「passed」는 증거가 아니다.
- **`git add -A` 금지.** 경로를 지정해서 커밋한다.
- **회차 끝에 일지 블록을 답변에 적는다** — 막힌 것 · 왜 · 그래서 무엇을 바꿨나.
  `journal.sh extract` 가 뽑아 넣는다. 안 적으면 초록이어도 드라이버가 멈춘다.
- **`*.gd.uid` 와 `*.import` 는 커밋한다.** 스크립트를 지우면 짝도 같이 지운다.
