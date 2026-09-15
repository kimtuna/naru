# GOTCHAS — 엔진·셸의 함정

> **매 회차 읽지 마라.** 실행 결과가 예상과 다르거나 에러가 나면,
> **원인을 스스로 조사하기 전에 여기부터 grep 한다.**
>
> 쓸 때 규칙 셋: ① 추가 전 중복 확인 ② **「사실 + 대응법」 형식 고정**(서술형 금지)
> ③ 계속 쌓이는 파일이므로 한 줄로 적는다.

## Godot

- **`--check-only` 는 파스 에러에도 exit 0 을 준다.** 종료 코드를 믿지 말고 출력에서
  `Parse Error` / `SCRIPT ERROR` 를 찾는다. `check.sh parse` 가 그렇게 한다.
- **`import` 이 `parse` 보다 먼저다.** `class_name` 전역 클래스는 임포트가 만드는 캐시에
  들어간다. 순서를 바꾸면 멀쩡한 코드가 빨개진다.
- **`project.godot` 은 엔진이 관리한다.** 임포트마다 다시 쓰면서 주석을 지운다 —
  설정의 「왜」는 `NUMBERS.md` 에, 강제는 `tools/tests/test_project_settings.gd` 에.
- **`--headless` 로는 화면을 못 굽는다.** 렌더러가 더미라 뷰포트 텍스처가 빈다.
  `tools/loop/shot.sh` 는 그래서 창을 띄운다 (NUMBERS 3b절).
- **`--headless` 는 창 크기가 `(0, 0)` 이다.** `DisplayServer.window_get_size()` 가 0 을 준다 —
  **배율은 창을 띄워야 잰다.** `tools/tests/measure_window.gd` 가 `--headless` 없이 도는 이유다.
- **`scale_mode=integer` 에서 `content_scale_factor` 는 먹지 않는다.** 실행 중에 1.5 를 넣어도
  배율이 2.00 그대로다 (2026-09-14 실측) — 배율은 `get_final_transform()` 에서 잰다.
- **정수 배율은 창이 논리 화면의 정확한 배수가 아니면 아래로 떨어진다.** 1600×900 창에서
  960×540 은 배율 **1**(1.66 이 아니다)이 되고 화면 절반이 여백이 된다 (2026-09-14 실측).
- **`Input.parse_input_event(InputEventMouseMotion)` 로는 커서 위치가 안 움직인다.**
  `get_mouse_position()` 이 그대로다 (2026-09-14 실측) — **`Input.warp_mouse()` 를 쓴다.**
  `tools/tests/measure_facing.gd` 가 그렇게 잰다.
- **`Input.warp_mouse()` 는 창 좌표를 받는다.** 월드 좌표를 넣으면 배율만큼 어긋난다 —
  `world * root.get_final_transform().get_scale().x` 로 바꿔서 넣는다 (배율 2.00x 실측).
- **`root.add_child()` 로 붙인 씬의 `_ready` 는 `_initialize()` 안에서 아직 안 돌았다.**
  거기서 배선(`player.solid` 같은 것)을 읽으면 늘 비어 있다 — **몇 프레임 기다렸다가**
  `_process` 에서 본다 (`measure_collide.gd` 의 `WARMUP`).
- **단위 검사(`run_tests.gd`)에는 프레임이 아예 없다.** `root.is_inside_tree()` 가 `false` 라
  `add_child` 를 해도 `_ready` 가 안 오고 **`@onready` 가 전부 `null`** 이다 (2026-09-14 실측) —
  씬 노드를 헤드리스로 시험하려면 `p.notification(Node.NOTIFICATION_READY)` 로 손수 깨운다
  (`test_player_scene.gd`).
- **`measure_facing.gd` 는 사람이 마우스를 만지면 빨개진다.** 진짜 커서를 뺏는 게이트라
  그렇다 — `FACE FAIL 커서 각 … 잰 값 14.93°` 처럼 **커서 각부터 어긋난다**(2026-09-14 실측).
  코드 문제가 아니다. 마우스에서 손을 떼고 다시 돌린다.
- **`main.gd` 의 시작 배너가 게이트의 grep 과 부딪힌다.** 메인 씬은 `_ready` 에서
  `WORLD    씨앗 …` · `WINDOW   1920 x 1080` 을 찍는다 — 게이트를 **한 프로세스로
  합치면** 그 씬을 세우는 구간 때문에 같은 출력에 섞인다. `^WORLD ` / `^WINDOW ` 로
  긁으면 **게이트가 한 줄도 안 찍어도 배너가 걸린다.** `^WORLD [0-9]` 처럼 재는 줄의
  모양에 못을 박거나 `WINGATE` 처럼 부딪히지 않는 머리말을 쓴다 (NUMBERS 13절 · 11절).
- **`SceneTree.quit(0)` 은 `_process` 가 `false` 를 돌려줘도 먹는다.** 합친 게이트의
  한 구간이 그걸 부르면 **뒤 구간은 아예 안 돌고 프로세스는 exit 0 으로 끝난다** —
  종료 코드만 보는 검사에는 초록으로 보인다 (회차 27 대조군 ①).
- **타입 추론이 안 되는 대입은 파스 에러다.** `var s := load(...).instantiate()` 는
  실패한다 — `var s: Node = packed.instantiate()` 처럼 타입을 적는다.

- **파스가 깨진 `test_*.gd` 는 러너가 조용히 건너뛴다.** `run_tests.gd` 는 파일을
  `load()` 해서 `test_` 메서드를 찾는데, 파스가 깨진 스크립트는 메서드가 하나도 없는
  객체로 와서 **`0 passed, 0 failed` 도 아니고 아예 안 세어진다** — 회차 29 가 새 검사
  11개를 넣고 `TESTS 121 passed, 0 failed` 를 초록으로 받았다(기대 132).
  **잡는 것은 `check.sh parse` 다** — `unit` 만 돌리는 동안에는 개수가 안 는 것으로만 보인다.
  새 검사 파일을 만든 회차는 **개수가 는 것을 눈으로 확인해라.**

- **람다는 바깥 변수를 값으로 복사해 간다.** `var on := true` 를 잡은 람다는
  나중에 `on = false` 로 바꿔도 **영영 true 를 본다** — 검사가 「켰다 껐다」로 조건을
  흔들 때 바로 걸린다 (회차 30 의 `occupied` 대조군). 배열 한 칸(`[true]`)에 담아
  참조로 들어라.

## macOS

- **`timeout` 이 없다.** `tools/loop/godot.sh` / `withtimeout.sh` 가 프로세스 **그룹째**
  죽인다. `kill $pid` 로는 자식이 남는다.
- **Godot 이 `XDG_*` 를 무시한다.** `~/Library/Application Support/Godot` 에 그대로 쓴다.
  `godot.sh` 가 **`HOME` 자체를 프로젝트 안으로 돌린다** (NUMBERS 2절).
- **`screencapture` 는 화면 기록 권한에 막힌다** (`could not create image from display`).
  무인 루프는 못 쓴다 — `tools/loop/shot.sh` 로 Godot 프레임버퍼를 읽는다.
- **창을 띄우면 Godot 이 무조건 맨 앞으로 온다.** 끌 손잡이가 없다 —
  `no_focus` · 화면 밖 `--position`(물려 들어온다) · `LSUIElement` 번들 · `open -g` ·
  최소화(프레임버퍼가 단색이 된다) **6가지 전부 뺏겼다** (NUMBERS 11절).
  막지 말고 **끝나고 되돌려라**: `NARU_FOCUS_RESTORE=1` 를 `godot.sh` 에 건다.
- **CLI 로 프로젝트 설정을 못 덮는다.** `--display/window/size/no_focus=true` 는
  에러 없이 **인자로 통과만 되고** 설정은 그대로다. 조용히 아무 일도 안 일어난다.
- **맨 앞 앱은 `lsappinfo` 로 잰다.** `osascript` + System Events 는 접근성 권한을
  물어서 무인 루프가 못 쓴다 — `tools/loop/focus.sh`.
- **BSD `tr` 은 `\x1f` 를 못 읽는다.** 8진수 `\037` 을 쓴다.
- **bash 3.2 라 `mapfile` 이 없다.** `while IFS= read -r` 로 읽는다.

## 대조군

- **문자열 치환으로 깨뜨리는 대조군은 조용히 빗나간다.** 나중 회차가 그 사이에 줄을
  끼우면 치환이 아무것도 못 찾고 상태 검사가 초록으로 남아 **「놓쳤다」로 뜬다** —
  게이트가 약한 게 아니라 **대조군이 헛돈 것**이다 (회차 21 이 회차 20 의 것을 이렇게 죽였다).
  `expect` 가 **깨뜨린 뒤 워킹트리가 더러운지 먼저 본다**. 치환 자리는 **줄 하나**로 잡아라 —
  두 줄을 붙여 잡으면 사이에 뭐가 끼는 순간 죽는다.
- **대조군을 python 으로 써 넣을 때 `\n` 은 바깥이 먼저 먹는다.** `redteam.sh` 안의
  대조군은 python heredoc 인데 그걸 써 넣는 것도 python 이면 **이스케이프가 두 번 풀린다** —
  파일에는 진짜 줄바꿈이 박히고 안쪽이 `SyntaxError` 로 죽는다. 코드는 멀쩡히 남으므로
  「헛돌았다」로만 뜬다 (회차 32). 써 넣는 쪽을 **raw 문자열**(`r"""..."""`)로 두거나
  `sed -n` 으로 그 자리를 눈으로 확인해라. **탭은 살아남아서** 일부만 깨진다.

## 셸

- **`[ ... ] && { ... }` 를 스크립트의 마지막 문장으로 두지 마라.** 판정이 거짓이면
  그 종료 코드가 스크립트의 종료 코드가 되어 **성공한 실행이 실패로 나간다.**
  끝에 `exit 0` 을 둔다.
- **`git commit -m "…\`명령\`…"` 은 백틱이 명령 치환된다.** 메시지에 백틱을 쓰지 말거나
  따옴표 친 히어독(`-F - <<'EOF'`)을 쓴다.
- **감시자 서브셸의 stdio 를 끊어라.** 안 끊으면 파이프를 붙잡아서 `$(...)` 가 안 끝난다.
- **`grep -q "$pat"` 에서 `$pat` 이 `-` 로 시작하면 옵션으로 먹는다.** 일지 줄(`- 문제: …`)을
  찾을 때 바로 터진다 — `grep -qF -- "$pat"` 로 쓴다.
- **돌고 있는 `loop.sh` 를 고쳐도 이번 회차에는 안 먹는다.** bash 는 `while … done` 을
  통째로 파스한 뒤 실행한다 — 드라이버 변경은 **다음 실행부터**다.
