# 루프 설정. loop.sh 가 읽는다.
MODEL="${MODEL:-}"                       # 비우면 claude 기본 모델
MAX_CYCLES="${MAX_CYCLES:-5}"            # 한 번 시작에 최대 몇 회차
BUDGET_USD="${BUDGET_USD:-15}"           # 누적 비용 상한 (.loop/spend.txt)
STUCK_LIMIT="${STUCK_LIMIT:-2}"          # 같은 항목 연속 실패 허용치
SESSION_TIMEOUT="${SESSION_TIMEOUT:-1800}"   # 세션 한 번의 벽시계 상한 (초)
PUSH="${PUSH:-1}"                        # 초록으로 닫힌 회차를 origin 으로 내보낸다
MAX_WAIT_SEC="${MAX_WAIT_SEC:-21600}"    # 한도가 풀리기를 기다리는 상한 (초 · 6시간)
LIMIT_WAIT_SEC="${LIMIT_WAIT_SEC:-1800}" # 언제 풀리는지 모를 때 기다리는 시간 (초 · 30분)
MAX_RETRIES="${MAX_RETRIES:-5}"          # 일시적인 오류를 몇 번까지 다시 걸까
FULL_REDTEAM_EVERY="${FULL_REDTEAM_EVERY:-8}"  # 몇 회차마다 대조군 전체를 쓸까 (0 이면 안 함)
