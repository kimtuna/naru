extends GutTest
## G-005 1단계 — 하루 20분 시계: 20분이면 날짜가 넘어가고 10분 경계에서 낮/밤이 바뀐다. 시간은 빠르게 돌릴 수 있다.

const DAY := 1200.0
const HALF := 600.0

var clock: WorldClock
var days: Array = []
var nights: Array = []


func before_each() -> void:
	days.clear()
	nights.clear()
	clock = WorldClock.new()
	add_child_autofree(clock)
	clock.day_changed.connect(func(d: int) -> void: days.append(d))
	clock.night_changed.connect(func(n: bool) -> void: nights.append(n))


func test_config_is_twenty_minute_day_split_in_half() -> void:
	var cfg := DayNightConfig.load_default()
	assert_eq(cfg.day_seconds, DAY)
	assert_eq(cfg.daytime_seconds, HALF)
	assert_eq(RegrowthConfig.load_default().day_seconds, DAY, "regrowth counts days with the same length")


func test_starts_on_day_one_in_daytime() -> void:
	assert_eq(clock.day(), 1)
	assert_false(clock.is_night())
	assert_eq(clock.time_of_day(), 0.0)


func test_day_turns_after_twenty_minutes() -> void:
	clock.advance(DAY - 0.1)
	assert_eq(clock.day(), 1, "just before 20 minutes it is still the first day")
	assert_eq(days, [])
	clock.advance(0.1)
	assert_eq(clock.day(), 2)
	assert_eq(days, [2])
	assert_almost_eq(clock.time_of_day(), 0.0, 0.001)
	assert_false(clock.is_night(), "a new day starts in daytime")


func test_night_starts_at_ten_minutes_and_ends_at_twenty() -> void:
	clock.advance(HALF - 0.1)
	assert_false(clock.is_night())
	assert_eq(nights, [])
	clock.advance(0.1)
	assert_true(clock.is_night(), "10 minutes in, it is night")
	assert_eq(nights, [true])
	clock.advance(HALF - 0.1)
	assert_true(clock.is_night())
	clock.advance(0.1)
	assert_false(clock.is_night(), "20 minutes in, day again")
	assert_eq(nights, [true, false])


func test_big_jump_reports_every_boundary() -> void:
	clock.advance(DAY * 3 + HALF + 1.0)
	assert_eq(clock.day(), 4)
	assert_true(clock.is_night())
	assert_eq(days, [2, 3, 4])
	assert_eq(nights, [true, false, true, false, true, false, true])


func test_speed_runs_time_fast_in_process() -> void:
	clock.speed = DAY * 60.0  # 한 프레임(1/60초 이상)이면 하루가 넘는다
	await wait_process_frames(3)
	assert_gt(clock.day(), 1, "sped-up clock passed a day within a few frames")
	assert_false(days.is_empty())
	clock.speed = 0.0
	var t := clock.time
	await wait_process_frames(2)
	assert_eq(clock.time, t, "speed 0 stops the clock")


func test_time_lives_in_island_map() -> void:
	var map := IslandMap.new(IslandGenerator.new(3), true)
	map.time = DAY + HALF + 5.0
	clock.setup(map)
	assert_eq(clock.day(), 2)
	assert_true(clock.is_night())
	assert_eq(days, [], "loading a time is not a day change")
	clock.advance(10.0)
	assert_almost_eq(map.time, DAY + HALF + 15.0, 0.001, "clock moves the island's time")
