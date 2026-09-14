# GOTCHAS — 엔진·셸의 함정

> **매 바퀴 읽지 마라.** 실행 결과가 예상과 다르거나 에러가 나면,
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
  **배율은 창을 띄워야 잰다.** `tools/tests/measure_view.gd` 가 `--headless` 없이 도는 이유다.
- **`scale_mode=integer` 에서 `content_scale_factor` 는 먹지 않는다.** 실행 중에 1.5 를 넣어도
  배율이 2.00 그대로다 (2026-09-14 실측) — 배율은 `get_final_transform()` 에서 잰다.
- **정수 배율은 창이 논리 화면의 정확한 배수가 아니면 아래로 떨어진다.** 1600×900 창에서
  960×540 은 배율 **1**(1.66 이 아니다)이 되고 화면 절반이 여백이 된다 (2026-09-14 실측).
- **`Input.parse_input_event(InputEventMouseMotion)` 로는 커서 위치가 안 움직인다.**
  `get_mouse_position()` 이 그대로다 (2026-09-14 실측) — **`Input.warp_mouse()` 를 쓴다.**
  `tools/tests/measure_facing.gd` 가 그렇게 잰다.
- **`Input.warp_mouse()` 는 창 좌표를 받는다.** 월드 좌표를 넣으면 배율만큼 어긋난다 —
  `world * root.get_final_transform().get_scale().x` 로 바꿔서 넣는다 (배율 2.00x 실측).
- **타입 추론이 안 되는 대입은 파스 에러다.** `var s := load(...).instantiate()` 는
  실패한다 — `var s: Node = packed.instantiate()` 처럼 타입을 적는다.

## macOS

- **`timeout` 이 없다.** `tools/loop/godot.sh` / `withtimeout.sh` 가 프로세스 **그룹째**
  죽인다. `kill $pid` 로는 자식이 남는다.
- **Godot 이 `XDG_*` 를 무시한다.** `~/Library/Application Support/Godot` 에 그대로 쓴다.
  `godot.sh` 가 **`HOME` 자체를 프로젝트 안으로 돌린다** (NUMBERS 2절).
- **`screencapture` 는 화면 기록 권한에 막힌다** (`could not create image from display`).
  무인 루프는 못 쓴다 — `tools/loop/shot.sh` 로 Godot 프레임버퍼를 읽는다.
- **BSD `tr` 은 `\x1f` 를 못 읽는다.** 8진수 `\037` 을 쓴다.
- **bash 3.2 라 `mapfile` 이 없다.** `while IFS= read -r` 로 읽는다.

## 셸

- **`[ ... ] && { ... }` 를 스크립트의 마지막 문장으로 두지 마라.** 판정이 거짓이면
  그 종료 코드가 스크립트의 종료 코드가 되어 **성공한 실행이 실패로 나간다.**
  끝에 `exit 0` 을 둔다.
- **`git commit -m "…\`명령\`…"` 은 백틱이 명령 치환된다.** 메시지에 백틱을 쓰지 말거나
  따옴표 친 히어독(`-F - <<'EOF'`)을 쓴다.
- **감시자 서브셸의 stdio 를 끊어라.** 안 끊으면 파이프를 붙잡아서 `$(...)` 가 안 끝난다.
