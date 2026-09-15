# 루프 설정. loop.sh 가 읽는다.
MODEL="${MODEL:-}"                       # 비우면 claude 기본 모델
MAX_CYCLES="${MAX_CYCLES:-5}"            # 한 번 시작에 최대 몇 회차
BUDGET_USD="${BUDGET_USD:-15}"           # 누적 비용 상한 (.loop/spend.txt)
STUCK_LIMIT="${STUCK_LIMIT:-2}"          # 같은 항목 연속 실패 허용치
SESSION_TIMEOUT="${SESSION_TIMEOUT:-2700}"   # 세션 한 번의 벽시계 상한 (초 · 45분). 30분에 3번 죽었고 죽으면 100% 낭비다
PUSH="${PUSH:-1}"                        # 초록으로 닫힌 회차를 origin 으로 내보낸다
MAX_WAIT_SEC="${MAX_WAIT_SEC:-21600}"    # 한도가 풀리기를 기다리는 상한 (초 · 6시간)
LIMIT_WAIT_SEC="${LIMIT_WAIT_SEC:-1800}" # 언제 풀리는지 모를 때 기다리는 시간 (초 · 30분)
MAX_RETRIES="${MAX_RETRIES:-20}"         # 일시적인 오류를 몇 번까지 다시 걸까.
                                         # **네트워크 오류는 돈이 0원이다** — 요청이 API 에 닿지도
                                         # 못했으니 토큰을 안 쓴다. 인색할 이유가 없다.
RETRY_CAP_SEC="${RETRY_CAP_SEC:-300}"    # 재시도 간격 상한 (초). 20번 × 5분 ≈ 1시간 40분을 버틴다
FULL_REDTEAM_EVERY="${FULL_REDTEAM_EVERY:-8}"  # 몇 회차마다 대조군 전체를 쓸까 (0 이면 안 함)
                                         # **단계(P0·P1…)가 끝나면 그때도 쓴다.** 이 숫자는
                                         # 「단계가 길어질 때」의 보험이다 (둘 중 먼저)
IDLE_FOR_SWEEP="${IDLE_FOR_SWEEP:-600}"  # 전체 쓸기를 시작하기 전에 사람이 이만큼 쉬었어야
                                         # 한다 (초 · 10분). 쓸기는 창을 100번 넘게 띄워
                                         # 50분간 화면을 뺏는다 — 자리를 비운 때에 돈다.
                                         # FULL_REDTEAM_EVERY 의 3배가 지나면 그래도 돈다
