extends GutTest
## G-001 2단계 — 테스트 실행기 예제. GUT 가 돌고 assert 가 동작하는지 보인다.


func test_arithmetic() -> void:
	assert_eq(2 + 3, 5)


func test_array_contains() -> void:
	assert_has([1, 2, 3], 2)
	assert_does_not_have([1, 2, 3], 4)
