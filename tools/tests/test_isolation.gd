extends TestBase

## 프로젝트 로컬 격리가 실제로 걸렸는지 잰다.
##
## **이 검사는 「어떻게 실행했는가」를 잰다.** tools/loop/godot.sh 를 거치지 않고
## Godot 을 직접 부르면 빨개진다 — 그게 의도다. 격리는 설정이 아니라 **입구**로
## 지켜지는 것이라, 입구를 우회한 실행은 격리가 안 된 실행이다.
##
## 2026-09-13 실측: macOS Godot 은 XDG_DATA_HOME 을 무시하고
## ~/Library/Application Support/Godot 에 쓴다. 그래서 HOME 을 돌린다.

const HOME_DIR := ".godot-home"

func test_user_data_is_project_local() -> void:
	var udir := OS.get_user_data_dir()
	check(udir.contains(HOME_DIR),
		"user:// 가 프로젝트 안에 있어야 한다 (godot.sh 를 거쳤나?) — 잰 값: %s" % udir)

func test_user_data_is_writable() -> void:
	# 격리된 자리가 실제로 쓸 수 있어야 한다. 읽기만 되면 세이브가 조용히 죽는다.
	var probe := "user://_isolation_probe.txt"
	var f := FileAccess.open(probe, FileAccess.WRITE)
	check(f != null, "user:// 에 쓸 수 있어야 한다 — %s" % error_string(FileAccess.get_open_error()))
	if f != null:
		f.store_string("ok")
		f.close()
		check(FileAccess.file_exists(probe), "쓴 파일이 실제로 있어야 한다")
		DirAccess.remove_absolute(ProjectSettings.globalize_path(probe))
