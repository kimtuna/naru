# NUMBERS — 실측으로 얻은 값만

> **이 파일은 혼자 선다.** 다른 문서를 안 봐도 읽힌다.
>
> **값보다 「조건」이 중요하다.** 아래 값은 전부 어떤 기계 · 어떤 엔진 버전 위에서
> 잰 것이다. 조건이 다르면 그대로 못 쓰고, **비율로 환산해도 안 되는 것이 있다.**
>
> 값을 고치려면 **새로 재고 조건을 같이 적는다.** 「passed」는 증거가 아니다.

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

---

## 4. 이 저장소의 함정 (전부 실측)

- **`--check-only` 는 파스 에러에도 exit 0 을 준다.** 종료 코드를 믿으면 안 되고
  출력에서 `Parse Error` / `SCRIPT ERROR` 를 찾아야 한다. `check.sh` 가 그렇게 한다.
- **macOS 에 `timeout` 이 없다.** `godot.sh` 가 프로세스 **그룹째** 죽인다 —
  `kill $pid` 로는 자식이 남는다.
- **감시자 서브셸의 stdio 를 끊어야 한다.** 안 끊으면 파이프를 붙잡아서
  `$(...)` 명령 치환이 안 끝난다.
- **`project.godot` 은 엔진이 관리한다.** 임포트마다 다시 쓰면서 주석을 지운다 —
  설정의 「왜」는 이 파일에, **강제는 `tools/tests/test_project_settings.gd` 에.**
- **`import` 이 `parse` 보다 먼저다.** `class_name` 전역 클래스(`TestBase`)는
  임포트가 만드는 캐시에 들어간다. 순서를 바꾸면 멀쩡한 코드가 빨개진다.
