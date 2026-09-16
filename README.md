# 나루 · Naru

Godot 4.7 로 만드는 2D 탑다운 생활 시뮬레이션 + 협동 PvE 원정 게임.
사람이 방향을 정하고, AI 루프가 만들고, 별도 QA 세션이 판정한다.

| 파일 | 무엇 |
|---|---|
| `spec/` | 게임 내용 — 카테고리별 기획 (`spec/README.md` 가 목차) |
| `list.md` | 할 일 목록 (git 밖, 대시보드에 올라감) |
| `decisions.md` | 사람 결정 대기 (git 밖, 대시보드에 올라감) |
| `prompt.md` · `qa.md` | 구현 세션 · QA 세션이 처음 읽는 지시 |
| `loop.sh` | 루프 — `start` · `stop` · `status` · `log` |
| `harness/` | loop.sh 도우미 · 세션용 godot(강제 headless) · 금지 명령 차단 · 커서 직접 읽기 검사(guard) · 캡처 도구(shot) |
| `dashboard/` | 진행 상황 페이지 원본 (gh-pages 로 복사됨) |
| `game/` | Godot 프로젝트 |
| `archive/` | 옛 기획서 원본 — 루프는 읽지 않는다 |

## 루프 한 회차

```
list.md 의 다음 단계 → current.md
→ 구현 세션 (새 claude) → tools/test.sh → QA 세션 (새 claude)
→ 통과: 커밋 · 체크   /  실패: QA 피드백을 들고 재시도 (4·7회째엔 되돌리고 다른 방법)
```

- 묶음(`## [ ] G-xxx`)은 브랜치 `g/G-xxx` 에서 하고, 전부 통과하면 main 에 합친다
- 사람 선택이 필요하거나 9회 실패하면 묶음 전체를 `decisions.md` 로 넘기고 다음 묶음으로 간다
- 토큰 한도면 재개 시각까지 기다렸다가 이어간다. 대기 · 재개 · 종료마다 대시보드 푸시 + 맥 알림
- md 문서가 150줄을 넘으면 정리 묶음을 자동으로 끼워 넣는다

**루프가 도는 동안에는 `list.md` · `decisions.md` 만 고친다** — 나머지는 루프와 같은 워킹트리를 쓴다.
