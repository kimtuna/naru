extends TestBase

## project.godot 은 엔진이 관리해서 주석이 지워진다.
## 그래서 「이 값이어야 하는 이유」는 NUMBERS.md 에 적고, **강제는 여기서 한다.**

func test_logical_resolution() -> void:
	# 960x540 은 1080p 정수 2배 · 4K 정수 4배다. 소수 배율은 도트를 뭉갠다.
	eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 960, "논리 가로")
	eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 540, "논리 세로")

func test_window_override() -> void:
	# 논리 화면을 정확히 2배로 늘려 붙인다.
	eq(ProjectSettings.get_setting("display/window/size/window_width_override"), 1920, "창 가로")
	eq(ProjectSettings.get_setting("display/window/size/window_height_override"), 1080, "창 세로")

func test_stretch_is_integer_viewport() -> void:
	# viewport + integer 라야 화면 전체가 한 덩어리로 정수배만 늘어난다.
	# aspect=keep 이 아니면 창을 넓혔을 때 월드가 더 보여서 공정성이 깨진다.
	eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport", "stretch mode")
	eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "keep", "stretch aspect")
	eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer", "stretch scale_mode")

func test_texture_filter_is_nearest() -> void:
	# 0 = Nearest. 선형 보간이 걸리면 도트가 흐려진다.
	eq(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"), 0, "기본 텍스처 필터")

func test_main_scene_exists() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	eq(main, "res://scenes/main.tscn", "메인 씬 경로")
	check(ResourceLoader.exists(main), "메인 씬 파일이 실제로 있어야 한다: %s" % main)

func test_visible_tiles_at_48px() -> void:
	# 타일 48px 기준 보이는 칸. 이 값이 곧 시야다.
	var w: int = ProjectSettings.get_setting("display/window/size/viewport_width")
	var h: int = ProjectSettings.get_setting("display/window/size/viewport_height")
	eq(float(w) / 48.0, 20.0, "가로로 보이는 타일 칸")
	eq(float(h) / 48.0, 11.25, "세로로 보이는 타일 칸")
