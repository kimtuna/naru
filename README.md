# 나루 · Naru

파밍 · PvE · PvP 와 **플레이어끼리의 거래**가 한 경제 안에서 맞물리는 2D 게임.
Godot 4.7 · macOS. 지금은 프로토타입 단계다.

**[📊 루프 대시보드 — kimtuna.github.io/naru](https://kimtuna.github.io/naru/)**
· [문서 전부 (`docs/`)](docs/) · [기획서](docs/GDD.md) · [회차 일지](docs/JOURNAL.md)

## 어떻게 만들고 있나 — 루프 엔지니어링

한 회차에 백로그 **한 줄**을 만든다. 사람이 아니라 **기계가 채점한다.**

```
BACKLOG.md 한 줄  →  세션(claude -p)  →  run-contract.sh  →  초록이면 다음
                                              ↓ 빨강이면 되돌리고 멈춘다
```

세션에게 「검사를 약하게 하지 마세요」라고 **부탁하지 않는다. 구조로 막는다:**

- `.loop/criteria.tsv` 는 **해시로 잠겨 있다.** 고치면 채점자가 `exit 77` 로 죽는다
- 판정은 세션이 아니라 `run-contract.sh` 가 한다 — 이것만 `results.json` 을 쓴다
- **새 검사를 만든 회차는 대조군을 돌린다** (`redteam.sh`). 일부러 깨뜨려서 빨개지는지 —
  안 하면 아무것도 안 잡는 가짜 게이트가 쌓인다
- 초록으로 끝난 항목의 verify 는 **상태 검사에 영구 기준으로 승격**된다. 다음 회차부터 회귀도 잡힌다
- 사람만 답할 수 있는 `[ASK]` 항목은 **세션을 아예 열지 않는다**

```bash
tools/loop/ctl.sh start 5     # 5회차, 예산 안에서
tools/loop/ctl.sh status      # 상태 · 누적 비용 · 남은 항목
tools/loop/ctl.sh report      # 대시보드를 다시 굽는다
tools/loop/check.sh all       # import → parse → tests (순서 중요)
tools/loop/redteam.sh         # 게이트가 살아 있는지 잰다
```

## 문서

**매 회차 읽는 것이 부풀면 회차가 갈수록 비싸진다.** 그래서 층을 갈랐다 — [docs/README.md](docs/README.md).

| | | |
|---|---|---|
| 고정 | [`CLAUDE.md`](CLAUDE.md) | 무엇을 어떤 명령으로 돌리나 |
| 주입 | [`docs/PROMPT.md`](docs/PROMPT.md) · [`docs/BACKLOG.md`](docs/BACKLOG.md) | 드라이버가 넣는다 |
| 조건부 | [`docs/NUMBERS.md`](docs/NUMBERS.md) · [`docs/GOTCHAS.md`](docs/GOTCHAS.md) · [`docs/GDD.md`](docs/GDD.md) | 필요한 절만 |
| 사람 | [`docs/JOURNAL.md`](docs/JOURNAL.md) | **무엇이 막았고 왜 그랬고 그래서 무엇을 바꿨나** |
