extends SceneTree
## test_main_menu.gd 가 별도 프로세스로 돌린다 — 실제 씬 전환과 종료를 검사한다.
## 한 줄씩 "STEP <현재 씬 경로>" 를 찍고, 종료 버튼으로 스스로 끝나야 한다.

const WAIT_FRAMES := 3
const TIMEOUT_FRAMES := 60


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene"))
	await _report()
	await _press("Start")
	await _report()
	change_scene_to_file(Screens.MAIN_MENU)
	await _report()
	await _press("Settings")
	await _report()
	await _press("Back")
	await _report()
	await _press("Quit")
	# 종료 요청이 먹었으면 여기까지 오기 전에 프로세스가 끝난다.
	for i in TIMEOUT_FRAMES:
		await process_frame
	print("STEP still-running")
	quit(3)


func _press(button_name: String) -> void:
	var button := current_scene.find_child(button_name, true, false) as Button
	if button == null:
		print("STEP missing-button ", button_name)
		quit(2)
		return
	button.pressed.emit()


func _report() -> void:
	for i in WAIT_FRAMES:
		await process_frame
	print("STEP ", current_scene.scene_file_path if current_scene else "none")
