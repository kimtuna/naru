extends SceneTree
## harness/shot.sh 가 부른다. 사람의 마우스·포커스와 섞이지 않는 창에서 씬 하나를 찍는다.
## 인자 (-- 뒤): <씬 res 경로> <출력 png 절대 경로> <프레임 수>

var _frames := 30
var _out := ""
var _n := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("shot: 인자 부족 — <scene> <out.png> [frames]")
		quit(2)
		return
	_out = args[1]
	if args.size() > 2:
		_frames = int(args[2])
	var w := root
	w.mouse_passthrough = true
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MOUSE_PASSTHROUGH, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	w.gui_disable_input = false
	var packed := load(args[0]) as PackedScene
	if packed == null:
		printerr("shot: 씬을 못 읽음 — ", args[0])
		quit(2)
		return
	change_scene_to_packed(packed)

func _process(_delta: float) -> bool:
	_n += 1
	if _n == _frames:
		var img := root.get_texture().get_image()
		var err := img.save_png(_out)
		print("shot: ", _out, " ", img.get_width(), "x", img.get_height(), " err=", err)
		quit(0 if err == OK else 1)
	return false
