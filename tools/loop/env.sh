# 루프 설정. loop.sh 가 읽는다.
MODEL="${MODEL:-}"                       # 비우면 claude 기본 모델
MAX_CYCLES="${MAX_CYCLES:-5}"            # 한 번 시작에 최대 몇 회차
BUDGET_USD="${BUDGET_USD:-15}"           # 누적 비용 상한 (.loop/spend.txt)
STUCK_LIMIT="${STUCK_LIMIT:-2}"          # 같은 항목 연속 실패 허용치
SESSION_TIMEOUT="${SESSION_TIMEOUT:-1800}"   # 세션 한 번의 벽시계 상한 (초)
PUSH="${PUSH:-1}"                        # 초록으로 닫힌 회차를 origin 으로 내보낸다
