# docs — 나루의 문서 전부

**대시보드 → https://kimtuna.github.io/naru/**  (`index.html`. 이 폴더가 GitHub Pages 의 소스다)

md 는 전부 여기 있다. **딱 하나 예외가 `/CLAUDE.md`** — Claude Code 가 저장소 루트만
자동으로 읽어서, 옮기면 매 바퀴 운영 지침이 안 들어간다.

## 층 — 「누가 언제 읽나」가 파일마다 다르다

매 바퀴 읽는 것이 부풀면 바퀴가 갈수록 비싸진다. 그래서 문서를 네 층으로 갈랐다.

| 층 | 파일 | 누가 | 언제 |
|---|---|---|---|
| **고정** | [`/CLAUDE.md`](../CLAUDE.md) | Claude Code 자동 로드 | 매 바퀴 · 41줄 |
| **주입** | [`PROMPT.md`](PROMPT.md) | **드라이버가 넣는다.** 세션은 안 연다 | 매 바퀴 · 60줄 |
| **주입** | [`BACKLOG.md`](BACKLOG.md) | 드라이버가 **한 줄만** 뽑는다 | 매 바퀴 · 한 줄 |
| **조건부** | [`NUMBERS.md`](NUMBERS.md) | 세션 | 값을 쓸 때 · **절 목차 보고 그 절만** |
| **조건부** | [`GOTCHAS.md`](GOTCHAS.md) | 세션 | **에러가 났을 때만** · grep |
| **조건부** | [`GDD.md`](GDD.md) | 세션 | 그 영역을 처음 만들 때 · 해당 절만 |
| **사람** | [`JOURNAL.md`](JOURNAL.md) | **세션은 읽지 않는다** | 바퀴 끝에 절을 하나 덧붙인다 |
| 롤링 | `../.loop/state.md` | **드라이버** | 3바퀴 넘으면 아카이브 |

**얇음은 계약이 강제한다.** `doclen.sh` 가 계약 기준 5로 무장돼 있어서,
세션이 `CLAUDE.md` 나 `PROMPT.md` 를 부풀리면 그 자리에서 빨개진다.

## 무엇이 어디에

| 궁금한 것 | 파일 |
|---|---|
| 이 게임이 무슨 게임인가 · 경제는 왜 그렇게 도는가 | `GDD.md` (922줄, A~G) |
| 지금 어디까지 왔나 · 다음에 뭘 하나 | `BACKLOG.md` · [대시보드](https://kimtuna.github.io/naru/) |
| 그 숫자는 어디서 나왔나 (240 px/s · 48px · 960×540) | `NUMBERS.md` |
| 왜 자꾸 이 에러가 나나 | `GOTCHAS.md` |
| **저번 바퀴에 뭐가 막혔고 그래서 뭘 바꿨나** | `JOURNAL.md` |
| 세션이 무슨 지시를 받고 도나 | `PROMPT.md` |

## 대시보드를 다시 굽기

```bash
tools/loop/ctl.sh report      # = python3 tools/loop/report.py
```

`.loop/results.json` · `spend.txt` · `STOPPED` 는 `.gitignore` 라 GitHub 에 안 올라간다.
그래서 **생성기가 값을 페이지에 구워 넣는다** — 페이지는 아무것도 fetch 하지 않는다.

루프가 돌면 드라이버가 **초록으로 닫힌 바퀴**마다 굽고 커밋하고 **푸시한다.**
계약 · 항목 verify · 일지를 다 통과한 뒤에만 나가므로 **빨간 상태는 바깥에 안 보인다.**
끄려면 `PUSH=0 tools/loop/ctl.sh start 5`. 푸시가 실패해도 루프는 계속 돈다 —
네트워크는 이 루프의 판정 대상이 아니다.
