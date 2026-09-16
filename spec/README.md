# spec 목차 — 필요한 파일만 골라 읽는다

## 00_core
- vision.md — 설계 원칙 · 타깃 · 게임 개요 · 개발 순위 (판단 기준)  ·  glossary.md — 용어집
- roadmap.md — 로드맵 · 프로토타입 범위(넣는 것/빼는 것)  ·  tech.md — 엔진 · 2D · 시드 생성 · 번역 키 원칙
- art-sound.md — 아트·사운드 (보류)
## 01_settings
- display.md — 기준 화면 640×360 · 보이는 범위 고정 · 검은 띠  ·  world-settings.md — 월드 설정 (서버장만 · 데스 페널티)  ·  input.md — 키 배치 · InputMap
- save.md — 캐릭터/월드 분리 저장  ·  language.md — 한국어·영어, 문자열 하드코딩 금지
- audio.md — 음량 (미정)
## 02_player
- movement-controls.md — 8방향 이동 · 마우스 조준 · 좌클릭 평타 · 우클릭 상호작용  ·  inventory-hotbar.md — 핫바 · 빈손 시작
- pickup.md — 밟으면 줍기 · 펫 반경  ·  level-skills.md — 캐릭터 레벨·스킬 (대부분 미정)
- equipment.md — 장비 스탯 · 포인트 예산제 · 세트
## 03_world
- island-generation.md — 시드 생성 · 비율 배치 · 지형별 광물 · 보장  ·  resources-regrowth.md — 재생 규칙 · 설치물 둘레 금지
- day-night.md — 하루 20분 · 밤의 의미  ·  lighting.md — 반경 조명
- weather-season.md — 날씨·계절 (나중에 한 덩어리)  ·  spawn-conditions.md — 조건부 스폰 · 이로치
## 04_life
- gathering.md — 타이밍 스킬체크 · 빈손 시작  ·  logging.md — 벌목 · 수액
- mining.md — 야생 채광  ·  farming.md — 개간·파종·물·수확
- hunting.md — 사살/마취 포획  ·  fishing.md — 작살총 물속 사냥
- ranching-breeding.md — 목장 · 브리딩 · 등급 규칙  ·  pets-mounts.md — 일손 펫 · 전설 펫 능력 · 탈것
- climbing.md — 고도 타일 등반  ·  codex.md — 도감 (보상 없음, 전설 직업 조건)
## 05_craft
- crafting-stations.md — 타이머 · 출력 버퍼 · 방-상자 연동 · 단계  ·  recipes.md — 얕고 넓게 (최대 3단계)
- enhancement.md — 비파괴 · 천장  ·  professions.md — 직업 사다리 · 전설 직업 · 상한 없음
## 06_build
- building.md — 실외 건축  ·  rooms.md — 방 판정 · 방 종류표 · 잡실
- mine-room.md — 광산 오브젝트 + 방  ·  decoration.md — 꾸미기 (보상 없음)
## 07_automation
- power.md — 인프라 체인  ·  drones.md — 거치대 드론
- npc-villagers.md — 주민
## 08_combat
- tools-as-weapons.md — 도구=근접 무기 · 총  ·  mob-ai.md — 몰려오는 적 · 때릴 수 없는 적
- damage-death.md — 죽음 페널티 · 환경 피해
## 09_expedition
- common.md — 탑승 · 티켓 · 보험 · 섬 설계 뼈대  ·  sunken-village.md — 침몰한 마을 (프로토타입)
- volcano.md · jungle-ruins.md · snow-mountain.md — 나머지 섬
## 10_economy
- currency-layers.md — 내부/경계 재화 · 경제가 핵심인 이유  ·  item-lineage.md — ID 계보 · 원정 검증 · 에스크로
- currency.md — 광물 본위 · 순환  ·  auction.md — 경매장
- commissions.md — 의뢰
## 11_multiplayer
- listen-server.md — 리슨 서버 · 정원  ·  character-world.md — 캐릭터/월드 분리
- permissions.md — 방문자 권한  ·  central-gateway.md — 중앙 관문
## 12_ui
- hud.md · menu.md — HUD · 메뉴
