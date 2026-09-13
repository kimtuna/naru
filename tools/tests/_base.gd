class_name TestBase
extends RefCounted

## 검사의 바닥. 실패는 예외가 아니라 목록으로 쌓인다 —
## 한 검사가 여러 값을 재고 **전부** 보고할 수 있어야 하기 때문이다.
##
## 「passed」는 증거가 아니다. 실패 메시지에 **잰 값과 기대값을 같이** 적는다.

var failures: Array[String] = []

func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)

func eq(actual: Variant, expected: Variant, what: String) -> void:
	if actual != expected:
		failures.append("%s — 잰 값 %s · 기대 %s" % [what, str(actual), str(expected)])
