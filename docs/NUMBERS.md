# NUMBERS — 실측으로 얻은 값만

> **이 파일은 혼자 선다.** 다른 문서를 안 봐도 읽힌다.
>
> **값보다 「조건」이 중요하다.** 아래 값은 전부 어떤 기계 · 어떤 엔진 버전 위에서
> 잰 것이다. 조건이 다르면 그대로 못 쓰고, **비율로 환산해도 안 되는 것이 있다.**
>
> 값을 고치려면 **새로 재고 조건을 같이 적는다.** 「passed」는 증거가 아니다.

---

## 절 목차 — **통째로 읽지 마라. 필요한 절만 grep 한다**

| 절 | 무엇 |
|---|---|
| 0 | 환경 — 엔진 버전 · 경로 · 렌더러 |
| 1 | 화면 — 논리 해상도 · 창 · 배율 · 보이는 칸 |
| 2 | 격리 — macOS 는 XDG 를 무시한다 |
| 3 | 검사 — 계약 · 대조군 결과 |
| 3b | 화면 캡처 — 헤드리스로는 안 된다 |
| 4 | (함정은 `GOTCHAS.md` 로 옮겼다) |
| 5 | 이동 — 속도 실측 |

---

## 0. 환경 (2026-09-13 실측)

| | |
|---|---|
| 엔진 | **Godot 4.7.2.stable.official.ed1daf0bf** |
| 경로 | `/Applications/Godot.app/Contents/MacOS/Godot` — **PATH 에 없다.** 전체 경로로 부른다 |
| 기계 | macOS · Apple M5 Pro |
| 렌더러 | `OpenGL API 4.1 Metal - 90.5 - Compatibility` (`gl_compatibility`) |

---

## 1. 화면 (2026-09-13 실측)

**조건: `stretch/mode=viewport` + `scale_mode=integer` + `aspect=keep`, 창 override 1920×1080**

실제로 창을 띄워서 잰 값이다 (`scripts/main.gd` 가 찍는다):

```
VIEWPORT 960 x 540
WINDOW   1920 x 1080
SCALE    2.00 x
```

| 값 | 무엇 | 왜 그 값인가 |
|---|---|---|
| **960 × 540** | 논리 해상도 (= 보이는 월드 범위) | **1080p 정수 2배 · 4K 정수 4배.** 소수 배율은 도트 하나를 화면에서 어떤 건 1px, 어떤 건 2px 로 만들어 걸을 때 얼룩이 흐른다 |
| **1920 × 1080** | 창 크기 | 논리 화면을 정확히 2배로 늘려 붙인다 |
| **2.00 ×** | 실측 배율 | 정수다 |
| **20 × 11.25 칸** | 보이는 타일 수 | 타일 48px 기준. `test_visible_tiles_at_48px` 가 강제한다 |

**대가**: UI 도 960×540 좌표계에서 만들어야 하고, 폰트가 통째로 2배로 늘어나므로
**비트맵 픽셀 폰트가 필요하다** — 기본 폰트는 늘리면 뭉갠다.

### 실측 게이트 `tools/tests/measure_view.gd` (2026-09-14 실측)

위 표는 `test_project_settings.gd` 가 **project.godot 의 글자**를 읽어 강제한다.
글자가 맞아도 실행 중에 카메라 줌이나 창 크기를 만지면 눈에 보이는 칸은 달라진다 —
그래서 **실제 창을 띄워** 다시 잰다 (`check.sh tests` 가 `--headless` 없이 부른다).

```
VIEW 논리 960x540 · 창 1920x1080 · 배율 2.00x · 카메라 1.00x · 타일 48px · 보이는 칸 20.00 x 11.25
VIEW ok (드라이버 macOS · 프레임 5)
```

- 배율은 나눗셈이 아니라 **`root.get_final_transform()`** 에서 잰다.
- 보이는 칸은 **`get_canvas_transform()`** 으로 월드 좌표로 환산해서 잰다 —
  카메라 줌이 곧 시야 이득이라 여기를 막아야 한다 (BACKLOG P1 「줌 없음」).

**대조군 2종 — 둘 다 단위 검사 18개는 전부 초록으로 남는다** (`redteam.sh` 에 박아 뒀다):

| 일부러 깨뜨린 것 | 단위 검사 | 화면 실측 |
|---|---|---|
| `main.tscn` 에 `Camera2D zoom=(2,2)` | `18 passed, 0 failed` | **잰 값 보이는 칸 10.00 x 5.62** ✅ |
| 실행 중 `window_set_size(1600, 900)` | `18 passed, 0 failed` | **잰 값 창 1600x900 · 배율 1.00x** ✅ |

두 번째가 정수 배율의 성질을 그대로 보여준다: 1600/960 = 1.66 이 아니라 **1** 로 떨어진다.

---

## 2. 격리 — **macOS 는 XDG 를 무시한다** (2026-09-13 실측)

**이걸 안 재고 넘어갈 뻔했다.** `XDG_DATA_HOME` 등을 설정해두고 「격리했다」고 믿는 것이
정확히 가짜 게이트다.

| 방법 | `user://` 가 실제로 간 곳 | 홈의 Godot 디렉터리 |
|---|---|---|
| `XDG_*` 만 설정 | `~/Library/Application Support/Godot/app_userdata/Naru` | **mtime 이 실행 시각으로 갱신됨** ❌ |
| **`HOME` 을 돌린다** | `.godot-home/Library/Application Support/Godot/app_userdata/Naru` | **mtime 안 바뀜** ✅ |

- 그래서 `tools/loop/godot.sh` 는 **`HOME` 자체를 프로젝트 안으로 돌린다.**
  `XDG_*` 도 같이 두는 것은 리눅스에서 도는 경우를 위해서다.
- **격리는 설정이 아니라 「입구」로 지켜진다.** `test_isolation.gd` 가
  `OS.get_user_data_dir()` 이 프로젝트 안인지 재므로, **`godot.sh` 를 우회한 실행은
  그 자리에서 빨개진다.** 실측:

  ```
  FAIL test_isolation.gd :: test_user_data_is_project_local
       — 잰 값: /Users/tuna/Library/Application Support/Godot/app_userdata/Naru
  ```

---

## 3. 검사 (P0-1 시점)

`bash tools/loop/check.sh all` → `IMPORT ok` · `PARSE 5개 스크립트, 실패 0` ·
`TESTS 8 passed, 0 failed`

### 대조군 — 게이트가 진짜로 잡는지 잰 값

**검사를 만든 바퀴에 이걸 안 돌리면, 아무것도 안 잡는 게이트가 쌓인다.**

| # | 일부러 깨뜨린 것 | 결과 |
|---|---|---|
| 1 | 문법이 깨진 `.gd` 를 하나 넣음 | `PARSE 5개, 실패 1` ✅ |
| 2 | 논리 가로 960 → 1280 | `TESTS 4 passed, 2 failed` — 잰 값 26.67칸 ✅ |
| 3 | 텍스처 필터 nearest → linear | `TESTS 5 passed, 1 failed` ✅ |
| 4 | stretch integer → fractional | `TESTS 5 passed, 1 failed` ✅ |
| 5 | `godot.sh` 를 우회해서 직접 실행 | `TESTS 7 passed, 1 failed` ✅ |

전부 원복하면 다시 `TESTS 8 passed, 0 failed`.

### 계약 채점자의 대조군 (2026-09-13)

**채점자가 진짜로 잡는지 재야 한다** — 안 재면 「전부 초록인데 게임은 안 도는」 상태로 며칠을 간다.

| 상황 | 결과 |
|---|---|
| 정상 | `exit 0` · `all_green true` |
| 기준 하나 실패 | `exit 1` · **증거에 잰 값**(`잰 값 1280 · 기대 960`) |
| 무장 뒤 계약 변조 | **`exit 77`** · 무장/현재 해시를 둘 다 기록 |
| 공허한 계약 (전부 주석) | **`exit 78`** — 무장 중에는 77 이 먼저 걸린다(변조가 우선). 무장을 풀고 재서 확인했다 |
| 계약 파일 없음 | **`exit 78`** |

- **BSD `tr` 은 `\x1f` 를 못 읽는다.** 증거 줄을 이어붙이는 구분자가 문자 `x` 가 되어
  results.json 의 증거가 한 줄로 뭉쳐 있었다. 8진수 `\037` 로 고쳤다.

## 3b. 화면 캡처 (2026-09-13 실측)

**`screencapture` 는 못 쓴다** — macOS 화면 기록 권한에 막힌다
(`could not create image from display`). 무인 루프가 권한 대화상자를 넘길 방법이 없다.

**Godot 자신의 프레임버퍼를 읽는다** (`tools/qa/shot.gd`). 권한이 필요 없고,
화면에 보이는 것이 아니라 **게임이 그린 것**을 읽으므로 다른 창이 겹쳐도 상관없다.

| 방식 | 결과 |
|---|---|
| `--headless` + 뷰포트 텍스처 | **안 된다** — 렌더러가 더미라 텍스처가 빈다 (출력 없음) |
| **창을 띄우고 뷰포트 텍스처** | **된다** — `SHOT 960x540 색 3개 가장 넓은 한 색 50.0%` |

- 그래서 `tools/loop/shot.sh` 는 `--headless` 를 **쓰지 않는다.** 창이 잠깐 떴다 사라진다.
- **「저장됨」은 증거가 아니다** — 크기 · 색 수 · 가장 넓은 한 색의 비율을 같이 찍는다.
  `--max-flat <퍼센트>` 로 「거의 단색인 화면」을 빨갛게 만들 수 있다.
- 대조군: 상한 40% → 빈 씬(50%)이 잡힘 / 없는 씬 → `SHOT ERROR` / 헤드리스 → 출력 없음.

---

## 4. 함정은 `GOTCHAS.md` 로 옮겼다

엔진·셸의 함정은 **계속 쌓이는 파일**이라 여기 두면 이 문서가 무한히 는다.
**에러가 났을 때만** `GOTCHAS.md` 를 grep 한다.
