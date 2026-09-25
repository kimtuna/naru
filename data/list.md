# 할 일 목록

사람과 Claude 가 대화로 채운다. 루프가 위에서부터 **순서대로** 처리하고 체크한다.
루프 세션은 이 파일을 읽지 않는다 — 루프가 지금 할 단계만 차선마다 제 `current.md` 로 뽑아 준다.

**이 목록은 하나다** — 코드 브랜치가 아니라 `plan` 브랜치(본 저장소의 `plan/` 폴더)에 있다.
루프가 몇 개 돌든 모두 여기를 읽고 쓴다. 체크 · 결정 대기 · 차선 표시가 그 자리에서 바로 적히고 커밋된다.

## 형식

- `## [ ] ID 제목` — 묶음. 한 묶음 = 코드 브랜치 하나. 단계가 전부 통과해야 루프를 시작한 줄기(`3d-start` · `3d-lane2` …)에 합친다
- `- [ ] 1. 단계 제목` — 단계. 한 단계 = 루프 한 회차
- `  - 기준: ...` — 수용 기준 (QA 채점표). 단계 밑에 들여 쓴다
- `  - ...` — 기준이 아닌 참고
- 묶음 제목 바로 밑 `- spec: ...` · `- 결정: ...` — 묶음 전체에 붙는 정보
- 표시: `[ ]` 할 일 · `[x]` 끝남 · `[>]` 결정 대기로 넘어감 (`decisions.md`)
- 묶음 머리 밑 `- 차선: 3d-lane2` — 그 묶음을 맡은 차선(루프를 띄운 줄기 이름). 적혀 있으면 그 차선만 한다.
  없으면 처음 집는 차선이 적는다. **같은 파일을 고치는 묶음은 같은 차선에 둔다** — 다르면 줄기를 합칠 때 부딪힌다
  결정 대기 `[>]` 를 풀 때 차선 줄은 그대로 두면 그 차선이 이어 한다. 다른 차선에 맡기려면 이 줄을 고치거나 지운다
  (그 차선이 꺼져 있으면 아무도 안 집는다)
- 결정이 나면 `[>]` 를 `[ ]` 로 되돌리고 `- 결정: ...` 을 적는다. 브랜치에 남은 작업에서 이어간다

## [x] 끝난 묶음 — 단계와 기준은 archive/list-3d-done.md
- G-101 프로젝트 기반 · G-104 시험 섬 · G-102 메인 화면 · 캐릭터 · 월드 · G-103 3인칭 캐릭터 · 카메라 · 핫바 · ESC 설 · G-105 자원 · 도구 · 채집 · G-106 제작 · G-107 농사 · G-108 하루 20분 · 버프 음식 · G-109 섬에 들어가기 · G-110 전투 뼈대 · G-111 등반 · G-112 약초 · G-113 개척 섬 · G-114 막힌 진행을 푼다 · G-115 HUD · 조작 · G-117 진행이 또 끊겼다 · G-119 설치물 부수기 · G-120 보관 상자 · G-118 총

## [x] G-121 제작 창 — 게임 안에서 만들 수 있게
- spec: spec/05_craft/crafting-stations.md, recipes.md
- **레시피 22종이 다 있는데 게임에서 만들 길이 없다** (사람이 확인 2026-09-22).
  `station_window.gd` 가 제작대 이름만 띄운다 — 「레시피 · 타이머 · 출력 버퍼는 다음 단계에」라고
  적혀 있는데 **그 단계가 없었다**. `start_craft` · `collect` 를 부르는 곳이 테스트뿐이다
- [x] 1. 레시피를 골라 만든다
  - 기준: 제작대를 열면 **그 제작대의 레시피 목록**이 뜬다. 재료와 나오는 것이 보인다 (테스트)
  - 기준: 재료가 모자란 레시피는 고를 수 없다고 보인다 (테스트)
  - 기준: 고르면 재료가 빠지고 타이머가 돈다. 이미 돌고 있으면 새로 시작하지 않는다 (테스트)
  - 기준: 글자는 전부 번역 키다 (ko · en 둘 다)
- [x] 2. 남은 시간과 출력 버퍼
  - 기준: 만드는 중에 **남은 시간**이 보인다 (막대든 숫자든)
  - 기준: 끝나면 결과물이 버퍼 칸에 보인다. 눌러서 가방으로 가져온다 (테스트)
  - 기준: 버퍼가 가득 차면 다음 제작이 시작되지 않는다고 보인다 (테스트)
  - 기준: 창을 닫았다 다시 열어도 타이머와 버퍼가 그대로다 (테스트)

## [x] G-122 갈고리총 — 벽에만 걸린다 · 탄이 보인다
- spec: spec/04_life/climbing.md, spec/12_ui/hud.md
- 사람이 플레이해 보고 짚었다 (2026-09-22) — **허공에 쏴도 걸린다**.
  `climbing.gd:163` 이 아무것도 안 맞으면 최대 거리 지점을 그냥 걸어 버리고, 맞아도 기울기를 안 본다
- 결정: **갈고리 탄은 총알과 다른 것이다** (2026-09-22). 둘 다 제작대에서 만든다
- [x] 1. 벽에만 걸린다
  - 기준: 허공에 쏘면 걸리지 않는다 — 줄이 헛나가고 매달리지 않는다 (테스트)
  - 기준: 걸어 오를 수 있는 비탈 · 평지에도 걸리지 않는다. 절벽 벽면에만 걸린다 (테스트)
  - 기준: 헛나가도 탄은 준다 (허공에 마구 쏘는 것이 공짜가 아니게)
- [x] 2. 갈고리 탄과 탄약 표시
  - 기준: 「갈고리 탄」을 제작대에서 만든다. **총알로는 갈고리총이 채워지지 않는다** (테스트)
  - 기준: 갈고리총을 들면 남은 탄/탄창이 총과 같은 자리에 보인다. 다른 것을 들면 사라진다
  - 기준: R 로 재장전하고, 인벤토리의 갈고리 탄이 준다. 없으면 재장전되지 않는다 (테스트)

## [x] G-123 저장에서 빠진 것 — 부순 것 · 데스 상자
- spec: spec/01_settings/save.md, spec/08_combat/damage-death.md
- 결정: **밭 · 횃불은 뺀다** (사람 결정 2026-09-22) — 농사는 사람이 다시 설계 중이고(farming.md:7),
  횃불은 놓는 길 자체가 없다(lighting.md 미정). 저장은 이미 섬별로 된다 (world/frontier_islands/island_state.gd)
- [x] 1. 부순 것이 되살아나지 않는다
  - 기준: 부순 제작대 · 상자 · 선착장이 나갔다 들어와도 되살아나지 않는다 (테스트)
  - 기준: `game/settings/save/world_data.gd:6` 의 낡은 주석을 사실대로 고친다 —
    설치물 · 상자(안의 것까지) · 선착장 · 밝힌 지도는 이미 담긴다
- [x] 2. 데스 상자
  - 기준: 데스 상자가 남은 시간과 함께 저장되고, 불러온 뒤 이어서 줄어든다 (테스트)
  - 기준: 30분이 다 된 데스 상자는 불러올 때 상자와 안의 것이 같이 사라진다 (테스트)

## [x] G-124 총 네 계통 — 탄을 들고 다닌다 · 계통마다 네 단
- spec: spec/08_combat/tools-as-weapons.md, spec/05_craft/recipes.md
- 결정: **가방에 드는 것은 탄이고, 탄창은 총마다 따로 붙는다** (사람 결정 2026-09-22).
  권총 · 산탄총 · 돌격소총 · 저격총 네 계통, 계통마다 네 단 — 표는 spec 에 있다
- 이름은 나중에 바꿀 수 있다 (번역 키) — 지금은 표대로 박는다
- [x] 1. 탄창을 총에 붙인다
  - 기준: 총 A 로 쏜 뒤 총 B 를 들면 B 의 남은 탄이 그대로다 (테스트)
  - 기준: 총을 내려놓았다 다시 들어도 남은 탄이 그대로다 (테스트)
  - 기준: 들어가는 탄 수가 총마다 다르고, 값은 한 곳에 있다 (테스트)
- [x] 2. 탄 네 종 — 제 탄으로만 채워진다
  - 기준: 권총탄 · 산탄 · 돌격소총탄 · 저격탄을 제작대에서 만든다 (테스트)
  - 기준: 총은 제 계통의 탄으로만 재장전된다. 다른 탄으로는 채워지지 않는다 (테스트)
  - 기준: 갈고리총은 갈고리 탄만 쓴다 — 총알로는 채워지지 않는다 (테스트)
  - 기준: 글자는 전부 번역 키다 (ko · en 둘 다)
- [x] 3. 열여섯 자루와 사다리
  - 기준: 계통마다 네 단이 제작 사다리에 있다 — 윗단일수록 재료가 비싸다 (테스트)
  - 기준: 단이 오를수록 재장전에 손이 덜 간다 — 들어가는 탄 수 · 재장전 시간이 단마다 다르다 (테스트)
  - 기준: HUD 의 남은 탄 표시가 **든 총에 맞게** 바뀐다
  - 기준: 총알 레시피의 재료 · 개수가 spec 표와 같다 (사람 결정 2026-09-22) —
    단계 2 가 지어낸 값(권총탄 30 · 산탄 16 …)을 표대로 고친다 (테스트)
  - 3단 재료는 임시다 — 개척 섬 금속이 정해지면 바꾼다 (spec 미정)

## [x] G-125 선착장 — 기둥을 겨눈다 · 개척 섬은 부서진 채로 시작한다
- spec: spec/03_world/frontier-islands.md, spec/06_build/building.md
- 결정: 기둥을 겨눠 부순다 · 개척 섬 선착장은 부서진 채로 시작하고 **연구대 해금 아이템**으로 연다
  (사람 결정 2026-09-22 — 처음부터 배로 오가는 것을 막는다)
- [x] 1. 기둥을 겨눈다
  - 기준: 내가 지은 선착장은 물가 쪽 기둥을 겨눠 부순다. 부수면 선착장이 그대로 돌아온다 (테스트)
  - 기준: 널판에는 몸통이 없다 — 배에서 내린 캐릭터가 끼이지 않는다 (테스트)
  - 기준: 맵에 박힌 선착장은 부술 수 없다 (테스트)
- [x] 2. 개척 섬은 부서진 채로 시작한다
  - 기준: 새 월드에서 개척 섬 선착장은 기둥만 서 있다 (테스트)
  - 기준: 잠긴 섬으로는 배가 가지 않는다 — 내 섬 선착장에서 타도 안 간다 (테스트)
  - 기준: 글자는 전부 번역 키다 (ko · en 둘 다)
  - 기준: (앞 단계 QA) 커밋 안 된 .uid 하나 — game/core/debug/ui_shots.gd.uid 가 추적되지 않은 채 남아 있다 (이번 단계가 아니라 앞 커밋 12f4894 이 빠뜨렸다). 같은 폴더의 다른 .gd.uid 는 전부 추적되고 있어 이것만 빠졌다 — Godot 이 다시 만들면 uid 가 달라진다. git add game/core/debug/ui_shots.gd.uid 로 다음 커밋에 넣어라
- [x] 3. 연구대 열쇠로 연다
  - 기준: 해금 아이템은 **연구대에서만** 만들어진다 — 다른 제작대에서는 나오지 않는다 (테스트)
  - 기준: 그것을 선착장에 넣으면 널판이 깔리고 배가 간다 (테스트)
  - 기준: 열린 것이 저장본에 남는다 — 나갔다 들어와도 열려 있다 (테스트)
  - 해금 아이템의 재료는 임시다 (spec 미정)
  - 기준: (앞 단계 QA) 잠긴 섬으로 타려 해도 아무 말이 없다 — 내 섬 선착장은 성해 보이는데(널판이 깔려 있다) 우클릭하면 GameRoot.sail_to 가 조용히 return 만 한다 (game_root.gd:164). 소리도 글자도 없어 「고장났나」로 읽힌다. 다음 단계(G-125.3 연구대 열쇠로 연다)에서 같이 갚아라: sail_to 가 island_open 에 걸려 돌아설 때 HUD 에 한 줄 띄우고(번역 키 ko · en 둘 다 — 예 DOCK_ISLAND_LOCKED), tests/world/frontier_islands/test_locked_island.gd 에 「잠긴 섬으로 우클릭하면 그 글자가 뜬다 · 열린 섬으로 타면 안 뜬다」를 견주는 단언을 더해라

## [x] G-900 루프가 찾은 것 — 스스로 갚는다
- QA 가 통과시키면서 찾은 것이다. **물어볼 것이 아니면 여기로 온다** (사람 결정 2026-09-22).
  루프가 제 손으로 갚는다 — 사람은 순서를 바꾸고 싶을 때만 손댄다
- 기능을 더하지 않는다. 지키는 것이 없던 자리에 지키는 것을 넣는 일이다
- [x] 1. test_enter_game.gd:109 test_the_other_world_did_not_get_t… (G-102 단계 3)
  - 기준: test_enter_game.gd:109 test_the_other_world_did_not_get_the_items 는 늘 참인 테스트다 — WorldData.to_dict() 는 {name, seed, created_at} 리터럴을 돌려주므로 'inventory' in w.to_dict() 는 어떤 코드에서도 false 다. 기준 3 은 다른 테스트가 제대로 막고 있어 통과지만, 이 테스트는 아무것도 지키지 않는다. 인벤토리가 캐릭터에만 붙는다는 것을 정말 보려면 '월드 A 에서 넣고 저장한 뒤 다른 캐릭터로 같은 월드 A 에 들어가면 인벤토리가 비어 있다'를 확인하게 고쳐라
- [x] 2. 「비우면 무작위」를 UI 를 거쳐 확인하는 테스트가 없다 (G-102 단계 3)
  - 기준: 「비우면 무작위」를 UI 를 거쳐 확인하는 테스트가 없다. test_empty_seed_is_random 은 WorldCreate.seed_from('') 를 직접 부르고, test_empty_seed_still_saves_the_world 는 이름과 오류 표시만 볼 뿐 저장된 world_seed 를 보지 않는다. _on_create_pressed 가 w.world_seed 넣는 줄을 빠뜨려도 두 테스트 다 통과한다. test_empty_seed_still_saves_the_world 에 '시드 칸을 비우고 만든 월드 둘을 저장본에서 읽으면 world_seed 가 서로 다르다'를 더해라
- [x] 3. Player._ready() 가 조건 없이 Pointer.set_captured(true) 를 한다 (G-103 단계 5)
  - 기준: (기준은 통과했다 — 다음 단계에서 터질 것들이다) Player._ready() 가 조건 없이 Pointer.set_captured(true) 를 한다. 설정 창이 떠 있는 동안 플레이어가 씬에 들어오면 커서를 도로 뺏는다. 지금은 GameRoot 안에 플레이어가 없어 드러나지 않지만, 섬·플레이어를 GameRoot 에 붙이는 단계에서 「창이 떴는데 커서가 사라진다」로 나온다. 붙일 때 GameRoot 가 창 상태를 보고 커서를 정하게 하고, 그 경우를 보는 테스트를 같이 짜라.
- [x] 4. GameRoot.set_menu_open(false) 이 씬 안 모든 Player 의 controls_… (G-103 단계 5)
  - 기준: GameRoot.set_menu_open(false) 이 씬 안 모든 Player 의 controls_enabled 를 무조건 true 로 되돌린다. debug_tools.gd:65 도 같은 값을 쓰므로, 디버그 비행 카메라를 켠 채 ESC 를 열었다 닫으면 꺼 뒀던 조작이 되살아난다. 지금은 디버그 도구가 시험 섬에만 있어 부딪히지 않는다 — 두 곳이 한 씬에 모이는 단계에서 「누가 껐나」를 세는 방식(이유별 잠금)으로 바꾸고 테스트를 붙여라.
- [x] 5. 클릭 차단은 창이 실제로 삼키는 것을 확인하지 못했다 (G-103 단계 5)
  - 기준: 클릭 차단은 창이 실제로 삼키는 것을 확인하지 못했다. headless 에는 커서가 없어 Godot GUI 판정이 안 돌기 때문에, 지금 테스트는 「좌클릭의 유일한 효과인 커서 재잡기가 안 일어난다」로 대신 본다. G-105 에서 좌클릭이 평타가 되면 이 확인이 비어 버린다 — 평타를 넣을 때 「창이 떠 있으면 평타가 안 나간다」를 직접 보는 테스트를 같이 짜라.
- [x] 6. 막 색 Color(0,0,0,0.55) 가 pause_menu.tscn 안에 있어 「임시」 표시를 달… (G-103 단계 5)
  - 기준: 막 색 Color(0,0,0,0.55) 가 pause_menu.tscn 안에 있어 「임시」 표시를 달 수 없다. report.json 에만 적혀 있어 다음 사람이 보기 어렵다 — pause_menu.gd 머리말에 「막 색은 임시, 디자인은 사람이 나중에」 한 줄을 남겨라.
- [x] 7. bag.tscn 안의 수치 두 개에 「임시」 표시가 없다 (G-105 단계 2)
  - 기준: 막는 것은 아니다. bag.tscn 안의 수치 두 개에 「임시」 표시가 없다 — Dim 의 알파 0.55 와 Window CanvasLayer 의 layer = 5 다. report.json 의 temporary 에는 적혀 있지만 .tscn 을 여는 사람은 그걸 못 본다. bag.gd 머리글 주석에 덮개 색과 레이어 값이 임시라는 줄을 한 줄 보태라 (SLOT_SIZE 는 이미 잘 적혀 있다).
- [x] 8. 「임시」 표시를 붙인다 ① — 밭 · 작물 · 섬 설계 값
  - 기준: 절벽 기울기 45° (Farmland.MAX_SLOPE_DEG, game/life/farming/farmland.gd:28-30) 가 report.json 에는 임시 수치로 적혀 있는데 코드 주석에는 「임시」가 없다. REACH · 흙판 두께 · 설치물 한 칸 주석은 전부 「임시 — … 미정이다」 꼴로 적혀 있으니(stations.gd:24 · harvest.gd:31 과 같은 투) 같은 꼴로 고쳐라: spec/04_life/farming.md 에 절벽 수치가 없다는 것과, 걸어 오르지 못하는 기울기(IslandShape.is_step_walkable)에 맞춰 둔 값이라는 것을 주석에 적으면 된다. 값 자체는 바꿀 것 없다.
  - 기준: 「물은 하루치다 — 준 다음 날 다시 마른다」가 임시라고 코드에 적혀 있지 않다. spec/04_life/farming.md 미정 줄이 「물 마름 규칙 미정」이라고 적고 있고 report.json 도 임시로 꼽았는데, crops.gd:133~134 의 next_day() 주석은 그냥 규칙처럼 적혀 있다. 같은 파일의 count(31줄) · 크기와 색(37줄)처럼 「임시다 — 물 마름 규칙 미정 (spec/04_life/farming.md)」 한 줄을 next_day() 주석에 넣어라. 코드 동작은 고치지 않는다.
  - 기준: 막는 것은 아니다 — 유황 섬 설계 값 game/world/frontier_islands/sulfur_island_blueprint.tres 가 「회색 초안」이라는 표시가 파일 쪽 어디에도 없다. report.json 에만 적혀 있는데 report 는 다음 회차에 지워진다. islands.json 의 _temporary 줄에 「sulfur 설계 값은 전부 임시 — 섬 모양은 사람이 같이 빚는다 (list.md G-113)」를 한 줄 더 적어라. 다른 임시 수치(Dock.REACH 7m · PLANK · dock_angle_deg · 제작대가 만들던 것을 안 담는다)는 코드와 islands.json 에 「임시」로 적혀 있어 문제없다.
  - 기준: (막는 것 아님) 임시 표시가 분화구 값에만 붙어 있다. island_blueprint.gd 의 crater_* 에는 「임시」가 적혀 있지만 화산 몸통(mountain_height 170 · mountain_radius 200 · mountain_profile 1.0 · ridge_strength 0.35)과 둘레 절벽(cliff_step 32 · cliff_coverage 0.9 · path_angle_deg 20)은 어디에도 임시라고 적혀 있지 않다. spec/03_world/frontier-islands.md 의 「분화구 크기 · 깊이는 임시」를 「설계 값은 모두 임시 — 사람이 같이 다듬는다」로 넓혀라.
  - 기준: bag.gd 의 임시 표시가 SLOT_SIZE 설명에 붙었다 — current.md 는 「bag.gd 머리글 주석에 한 줄 보태라」고 했는데, 덮개 알파 · 레이어 세 줄이 bag.gd:19~22 의 `## 칸 크기. 임시 …` 와 `const SLOT_SIZE` 사이에 들어가 버려 GDScript 가 이것을 SLOT_SIZE 의 doc 주석으로 읽는다. 칸 크기 설명과 창 모양 설명이 한 덩어리가 되어 어긋난다. 세 줄을 위쪽 머리글 블록(bag.gd:17 의 `## 모양은 아직 …` 다음, 빈 줄 앞)으로 옮겨라. 내용 자체는 맞다 — layer = 5 가 bag.tscn 이 아니라 core/game_root.tscn:22~23 의 Window CanvasLayer 에 있다는 report 의 정정도 확인했다.
- [x] 9. 「임시」 표시를 붙인다 ② — 상자 · 제작 창 · 갈고리총 · spec 미정
  - 기준: Chests.REACH 에 「임시」 표시가 없다 — report.json 은 놓는 거리(4m)를 임시로 꼽았는데 chests.gd:19 주석은 「제작대를 놓는 거리와 같은 값으로 뒀다」까지만 적혀 있다. 값이 미정이라는 말이 코드에 없으면 다음 사람이 정해진 값으로 읽는다. 「임시 — 도달 거리 값은 미정이다」 한 마디를 붙여라. stations.gd:26 의 REACH 도 같은 처지다(Harvest.REACH 와 같게 뒀다는 말만 있다)
  - 기준: 막대 크기와 소수 자릿수에 「임시」 표시가 없다 — station_window.tscn:37 의 ProgressBar custom_minimum_size = Vector2(400, 16) 과 station_window.gd:183 의 "%.1f" (남은 초를 소수 첫째 자리까지) 가 사람이 나중에 정할 값인데 코드에는 「임시」가 한 줄도 없다. report.json 의 temporary 에만 적혀 있어 .tscn 을 여는 사람은 못 본다 — G-900 6·7번과 똑같은 자리다. station_window.gd 머리글의 ROW_SIZE·BUFFER_SLOT_SIZE 주석과 같은 투로 「남은 시간 막대 크기(tscn)와 적는 소수 자릿수는 임시 — 사람이 보고 정한다」 한 줄을 보태라. 값은 바꿀 것 없다
  - 기준: 갈고리총이 가득 찬 채 손에 들어오는 것이 임시라고 안 적혀 있다 — grapple.gd 의 `_init()` 이 `_left = magazine` 으로 첫 탄창을 공짜로 준다. 같은 임시 규칙을 쓰는 총은 magazine.gd:27 에 「총은 가득 찬 채로 손에 들어온다 — 임시다」 라고 적어 두었다. grapple.gd 의 `_init` 위에 같은 뜻의 한 줄을 적어라
  - 기준: 땅에서 기력이 차는 규칙이 spec 에 없다. stamina.gd recover_per_second = 20/초 로 땅을 딛고 있으면 기력이 차게 해 두었고 코드에는 임시라 적혀 있지만, spec/04_life/climbing.md 는 회복을 앵커로만 적고 「미정」에도 땅 회복이 없다. spec/04_life/climbing.md 의 「미정」에 한 줄을 넣어라 — 예: 「땅에서도 기력이 차나 (임시: 찬다 — 안 그러면 한 번 지친 뒤 영영 못 오른다)」.
  - 기준: 제작대가 전부 workbench 인 것이 임시인데 데이터 파일에 안 적혀 있다 — 새 레시피 일곱이 모두 station=workbench 다. 제작대 계통 수 · 단계 수가 미정이라(F-16) 도끼 자리에 같이 둔 것이고, 단계가 정해지면 금속 도구는 위 단계로 옮겨야 한다. 이 말이 report.json 에만 있어 다음 사람이 recipes.json 만 보면 확정된 값으로 읽는다. recipes.json 의 _temporary 에 「제작대는 전부 임시로 workbench 다 — 제작대 단계가 정해지면 금속 도구는 위 단계로 옮긴다 (F-16)」 한 줄을 더해라.
  - 기준: (앞 단계 QA) report.json 이 안 돈 전체 테스트를 돌았다고 적었다 — how 의 마지막 줄이 「전체를 한 번 돌렸다 — test.log 가 말한 것: Scripts 94 · Tests 836 · Asserts 12290 · 518.28초」라고 적었는데, .loop/out/test.log 의 첫 줄은 「--- 바뀐 곳만: 9 개 ---」이고 합계는 Scripts 9 · Tests 78 · Asserts 451 · 56.202초다. 더구나 report.json 은 21:09, test.log 는 21:11 에 쓰였으니 세션이 읽을 수 있는 파일도 아니었다. 채점을 막지는 않았다 — 기준 다섯은 바뀐 곳 검사와 직접 깨 본 것으로 다 확인했다. 다음 구현 세션은 report.json 의 how 에 전체 실행 결과를 적지 마라: 전체를 돌리는 것은 묶음 마지막 단계의 loop.sh 이고, 세션은 test.log 를 실제로 읽어 그 숫자만 그대로 옮긴다. 안 돈 전체를 돌았다고 적으면 QA 가 확인 없이 통과시키게 된다.
  - 기준: (앞 단계 QA) G-900 단계 기준이 이미 갚힌 것을 다시 시킨다 — 단계 8 의 기준 다섯 중 셋(islands.json 의 _temporary_sulfur · spec/03_world/frontier-islands.md 의 「전부 임시다」 · bag.gd 머리말의 덮개·layer 줄)은 회차가 시작될 때 이미 되어 있었다. 865f2b2 가 앞 G-900 의 결과를 가져온 뒤 d2c44ad 가 옛 QA problems 로 단계를 다시 짜서 생긴 어긋남이다. list.md 의 남은 G-900 단계 9(Chests.REACH · station_window · grapple.gd · climbing.md 미정 · recipes.json _temporary)와 10(island_shape.gd marks() 주석 · player.gd 주석 두 줄)도 같은 처지일 수 있다. 구현 세션은 고치기 전에 그 파일을 먼저 열어 보고, 이미 되어 있으면 report 의 how 에 「이미 되어 있었다」를 적은 뒤 그 글을 지키는 테스트만 보태라 — 이번 회차가 한 방식이 옳았다.
- [x] 10. 낡은 주석을 사실대로 ① — 섬 · 캐릭터 · 키 표
  - 기준: (막는 문제 아님 · 낡은 줄) game/world/terrain/island_shape.gd 의 marks() 앞 주석이 아직 「굽는 동안 쓰는 표시」라고 적혀 있다. 바로 위 _raw · _beach · _wet 필드 주석은 「땅을 읽는 표시 … 저장본에도 담는다」로 고쳐졌으니 둘이 어긋난다. marks() 주석도 「자원을 다시 깔 때 쓰는 표시」로 맞춰라
  - 기준: (통과를 막는 문제는 아니다 — 다음에 이 파일을 건드릴 때 같이 고치면 된다) player.gd 의 주석 두 줄이 어긋났다. 첫째, 「## 이 캐릭터의 절벽 등반 (spec/04_life/climbing.md) — 붙어 있나 · 기력이 얼마나 남았나.」는 원래 climbing() 의 설명인데 새 skill_check_ring() 위로 밀려 올라갔다. 지금 climbing() 은 설명이 없고, skill_check_ring() 은 절벽 등반 설명을 달고 있다. 등반 줄을 climbing() 바로 위로 되돌려라 (player.gd:179 · 186). 둘째, skill_check_ring() 에 남은 「무엇을 들여다볼지는 섬이 이어 준다 (world/terrain/test_island.gd 의 _build_gathering)」는 사실과 다르다 — _build_gathering 은 gathering.player 만 넣고 watch() 를 부르지 않으며, 이어 붙이는 것은 Gathering._ready 다 (gathering.gd:42~43). gathering.gd:40~41 이 「이어 주는 일을 섬에 맡기면 섬 밖에서 세울 때마다 빠뜨린다」고 일부러 적어 둔 것과 정면으로 어긋나, 이 주석을 믿고 섬에 watch() 를 넣으려 드는 다음 세션을 함정에 빠뜨린다. 「채집(life/gathering/gathering.gd)이 제 _ready 에서 스스로 이어 붙는다」로 고쳐라.
  - 기준: 키 표에 M 이 없다 — spec/01_settings/input.md 의 키 표에 E 줄은 있는데 M 줄이 없다. 「맵은 M」은 spec/12_ui/hud.md 에만 있다. input.md 는 「키 배치의 기본값」을 맡는 곳이라, 다음 세션이 이 표만 보고 M 을 딴 데 묶을 수 있다. E 줄 아래에 「| **M** | 지도 열기 · 닫기 (사람 결정 2026-09-21, 12_ui/hud.md) |」를 한 줄 더해라
  - 기준: 잔손질한 spec 한 줄에 「설계 값은」이 두 번 — spec/03_world/frontier-islands.md:18 이 「설계 값은 `world/frontier_islands/sulfur_island_blueprint.tres` — 설계 값은 모두 임시 — 사람이 같이 다듬는다」가 됐다. 뜻은 맞지만 같은 말이 겹쳤다. 「설계 값은 `world/frontier_islands/sulfur_island_blueprint.tres` — 전부 임시다, 사람이 같이 다듬는다」로 줄여라
  - 기준: 곡괭이가 광물을 막는다는 말을 아무도 확인하지 않는다 — test_from_empty_hands.gd:281 주석이 「곡괭이를 들고 돌 일곱 · 철광석을 캔다 — 곡괭이가 없으면 여기서 막힌다」라고 하고 묶음의 머리말(current.md:6)도 「곡괭이가 없어 광물을 못 캔다」에서 출발하는데, 실제 코드에는 도구 관문이 없다. game/life/harvest/harvest.gd:91 은 맞는 도구면 GOOD_HIT, 아니면(맨손 포함) POOR_HIT 로 **빠르기만** 다르고 못 캐게 막지 않는다. 위에서 곡괭이를 못 만들게 막고 돌려 보니 철광석·돌 관련 단언은 하나도 떨어지지 않았다 — 도끼를 든 채 MAX_SWINGS=60 안에 철광석까지 다 캤다. 즉 이 테스트는 곡괭이를 **만들 수 있다**는 것만 보이고 곡괭이가 무엇을 열어 준다는 것은 보이지 않는다. 고칠 방향: 주석을 사실대로(맞는 도구는 빠를 뿐이다) 고치거나, 같은 광물을 맨손·도끼·곡괭이로 칠 때 드는 대수를 비교해 곡괭이가 확실히 적게 드는 것을 단언으로 남겨라.
  - 기준: (앞 단계 QA) G-900 단계 10 도 이미 되어 있을 수 있다 — 단계 9 의 기준 다섯 중 둘(stations.gd REACH · recipes.json _temporary)이 회차 시작 때 이미 되어 있었다. 865f2b2 가 앞 G-900 결과를 가져온 뒤 d2c44ad 가 옛 QA problems 로 단계를 다시 짜서 생긴 어긋남이라 단계 10(island_shape.gd 의 marks() 주석 · player.gd 주석 두 줄)도 같은 처지일 수 있다. 다음 구현 세션은 고치기 전에 그 두 파일을 먼저 열어 보고, 글이 이미 있으면 파일은 손대지 말고 report 의 how 에 「이미 되어 있었다」를 적은 뒤 그 글을 지키는 테스트만 보태라 — 단계 9 가 한 방식이 옳았다
- [x] 11. 낡은 주석을 사실대로 ② — 제작 창 · 갈고리총 · 저장
  - 기준: 제작대·상자가 칸을 나눠 갖는 검사가 on_cell 을 지나지 않는다 — test_chest_place.gd/test_a_station_and_a_chest_do_not_share_a_cell 는 주석에 「(Placeable.on_cell)」이라 적었지만, 제작대 몸통에 광선이 걸려 aimed_spot 의 앞쪽 종류 거르기에서 이미 막힌다. on_cell 을 무력화한 채 돌려도 이 검사는 통과했다. 막는 것은 아니다 — 그 길은 tests/build/test_placeable.gd 가 따로 본다. 주석의 「(Placeable.on_cell)」을 「광선이 제작대를 짚는 길」로 고치거나, 제작대 옆 칸 가장자리 땅을 겨누는 꼴로 바꿔라
  - 기준: 칸 하나를 눌러도 버퍼째로 가져오는 것이 spec 에 없다 — station_window.gd 의 _collect 은 어느 칸을 눌러도 Stations.collect 로 버퍼 전체를 가져온다 (코드 주석에는 까닭이 적혀 있다). 가방이 모자랄 때 2번 칸을 눌렀는데 0번 칸 것만 들어오는 일이 생긴다. 지금 기준을 막지는 않는다 — spec/05_craft/crafting-stations.md 의 「미정」에 「칸마다 따로 수령하나, 버퍼째로 가져오나 (지금은 버퍼째)」 한 줄을 적어 두어라
  - 기준: spec 미정 줄이 낡았다 — spec/04_life/climbing.md:51 「갈고리총 탄창을 어디서 채우나 (제작 · 줍기 · 자동)」 은 이번 단계에서 정해졌다 (제작대에서 만들고 R 로 채운다, 사람 결정 2026-09-22). 그 줄을 지우고, 대신 아직 안 정해진 「갈고리총 재장전에 걸리는 시간 (지금은 임시로 0초 — 총은 2초)」 을 미정에 한 줄 적어라
  - 기준: 갈고리총 주석이 없어진 상수를 가리킨다 — game/life/climbing/grapple.gd:14 가 「총알(Magazine.AMMO_ITEM)로는 채워지지 않는다」고 적었는데 Magazine.AMMO_ITEM 은 이번 단계에서 없어졌다. 읽는 사람이 없는 것을 찾게 된다. 그 줄을 「총알(탄 네 종, tools.json 의 ammo_kinds)로는 채워지지 않는다」로 고쳐라
  - 기준: 같은 파일에 낡은 주석이 하나 더 남았다 — game/settings/save/world_data.gd:23 의 `var islands` 주석이 아직 `{gone(캔 자리), taken(캔 날), stations(지은 것), map(밝힌 지도)}` 넷만 센다. 두 줄 위에서 새로 고친 주석(상자 · 선착장도 담긴다)과 바로 어긋난다. island_state.gd 의 of() 가 담는 여섯 키(gone · taken · stations · chests · docks · map)를 그대로 적어라. 단계는 통과시켰다 — 기준이 6번 줄만 짚었다
  - 기준: (앞 단계 QA) 늘 참인 줄이 빈 검사 자리에 들어갔다 — game/tests/world/frontier_islands/test_island_design_notes.gd:125 의 `assert_eq(doubled.count("설계 값은"), 2, "겹친 말을 세지 못한다")` 는 바로 윗줄에서 만든 글자열 상수를 세는 것이라 저장소가 어떻게 바뀌어도 늘 참이다 — 지키는 것이 없다. 같은 파일의 다른 빈 검사들은 가짜 입력을 _header() · _notes() 같은 제 도우미에 넣어 도우미가 정말 걸러 내는지를 보는데, 이 줄만 도우미를 거치지 않는다 (진짜 검사인 test_the_spec_line_does_not_repeat_itself 가 count() 를 그 자리에서 바로 부르기 때문이다). 고치는 법: 세는 일을 도우미로 빼고(예: `func _repeats(line: String, phrase: String) -> int`) 진짜 검사와 빈 검사가 **같은 도우미**를 부르게 하거나, 지키는 것이 없으니 그 두 줄을 지워라
  - 기준: (앞 단계 QA) 테스트 상수를 report 는 임시라 꼽았는데 파일에는 그 말이 없다 — report.json 의 temporary 가 game/tests/world/terrain/test_island_shape_marks_note.gd 의 COARSE_SIZE=128 · COARSE_SPACING=16.0 을 임시로 올렸는데, 파일(17~20줄)에는 「굽는 시간을 줄이려고 점을 성기게 잡았다 … 성겨도 된다」라는 까닭만 있고 「임시」라는 말이 없다. G-900 이 줄곧 잡아 온 「report 에만 적혀 있어 파일을 여는 사람은 못 본다」와 같은 자리다. 통과를 막지는 않는다 — 사람이 골라야 할 값이 아니라 세션이 빠르기를 보고 정한 테스트용 손잡이고, 까닭도 적혀 있다. 다음 세션은 둘 중 하나만 하면 된다: 임시가 아니라고 보면 report.json 의 temporary 에서 빼고, 임시로 두겠다면 COARSE_SIZE 주석에 「임시 — 굽는 빠르기를 보고 정한 값이다」 한 마디를 붙여라
- [x] 12. 쓰레기와 죽은 코드를 지운다
  - 기준: CraftingStation.craft_progress() 와 craft_recipe() 는 부르는 곳도 테스트도 없다 (craft_progress 는 쓰는 곳 0). 제작 창을 만들 때 쓸 것이면 그때 테스트와 함께 살리고, 안 쓸 것이면 지워라.
  - 기준: 쓰레기 파일이 남았다 — game/tests/ui/hud/test_zz_probe.gd.uid 가 짝이 되는 .gd 없이 혼자 남아 있다. 구현 중에 헤드리스 마우스를 떠보던 검사를 지우면서 .uid 만 안 지운 것이다. 그대로 두면 다음 커밋에 쓸모없는 파일이 섞여 들어간다 — rm game/tests/ui/hud/test_zz_probe.gd.uid 로 지워라
  - 기준: 쓰는 곳이 없는 clock() 접근자 — game_root.gd:226 에 func clock() -> GameClock 을 새로 냈는데 게임에도 테스트에도 부르는 곳이 한 곳도 없다 (clock_label() 은 테스트가 쓴다). 다음 단계에서 쓸 자리가 확실치 않으면 지워라.
  - 기준: 쓰지 않는 station() 접근자가 남았다 — 막는 것은 아니다. ui/hud/station_window.gd 에 새로 들어온 `func station() -> CraftingStation` 를 부르는 곳이 코드에도 테스트에도 하나도 없다 (game/ 전체 grep 결과 0건). 같은 자리의 station_kind() 는 세 테스트가 쓰고 있다. station() 를 지워라.
  - 기준: 쓰이지 않는 gun_at() 이 남았다 — game/combat/tools_as_weapons/tool_catalog.gd:170 의 gun_at(계통, 단) 을 부르는 곳이 게임 코드에도 테스트에도 없다 (grep 결과 정의 한 줄뿐). guns_of() · tier() 만으로 사다리가 다 읽힌다. 그 함수를 지워라 — 쓸 곳이 생기면 그때 다시 붙이면 된다
  - 기준: (앞 단계 QA) 정해진 규칙이 spec 미정 줄에만 있다 — climbing.md 에서 「갈고리총 탄창을 어디서 채우나」를 지웠는데(기준 3, 옳다), 그 답인 「제작대에서 갈고리 탄을 만들고 R 로 채운다」(사람 결정 2026-09-22)를 규칙 쪽에 못 박은 줄이 없다. 25줄은 「갈고리 탄은 총알과 다른 것이다 … 따로 만든다」까지만 말해 **어디서** 만들고 **무엇으로** 채우는지는 없고, R 은 51줄 「미정」 안에 곁들여 있을 뿐이다. 게다가 새 검사 test_the_spec_no_longer_asks_where_the_magazine_is_filled 는 물음이 돌아오는 것을 막기만 하고 답이 적혀 있으라고는 하지 않아, spec 만 읽는 사람은 이제 채우는 길을 알 수 없다. 고치는 법: spec/04_life/climbing.md:25 의 「갈고리 탄」 줄에 「**제작대에서 만든다**(craft/recipes/recipes.json 의 grapple_ammo — 철괴1+나무2 → 4개) · **R 로 채운다**(사람 결정 2026-09-22)」를 붙이고, test_climbing_temporary_notes.gd 에 그 줄이 「제작대」와 「R」을 말하는지 보는 단언을 더해라 — 이미 있는 test_the_grapple_ammo_is_really_made_at_a_station 이 레시피 쪽은 지키고 있으니 spec 쪽만 보태면 된다
  - 기준: (앞 단계 QA) R 키 줄이 갈고리총을 빼놓는다 — spec/01_settings/input.md:12 가 「**R** | 재장전 (총을 들었을 때) (사람 결정 2026-09-22)」인데, 이번 단계로 R 은 갈고리총도 채운다 (game/life/climbing/climb_gear.gd:48~50 · 58~68, 이 코드 주석은 바로 그 input.md 를 가리킨다). climbing.md:25 가 「갈고리 탄은 총알과 다른 것이다」라고 일부러 갈라 놓았기 때문에, 키 표의 「총」을 총알 쓰는 총으로만 읽는 사람이 생긴다 — input.md 는 「키 배치의 기본값」을 맡는 곳이라 다음 세션이 이 표만 보고 갈고리총 재장전을 딴 키에 묶을 수 있다. 막는 것은 아니다. 고치는 법: 그 줄을 「재장전 (총 · 갈고리총을 들었을 때) (사람 결정 2026-09-22, 04_life/climbing.md)」로 고치고, 이미 InputActions.RELOAD 를 쓰는 곳이 둘(magazine 쪽 · climb_gear)이라는 것을 보는 단언을 test_climbing_temporary_notes.gd 나 키 표 검사에 한 줄 더해라
- [x] 13. 겹친 것을 하나로 — 테스트 안 중복 · 이름에 매인 단언
  - 기준: 원자재에서 몇 단계인지 세는 코드가 테스트 두 곳에 따로 있다 — test_station_recipes.gd:71 _steps_of() 는 되돌아가며 재귀로 세고, test_recipes.gd:292~313 은 더 정해지지 않을 때까지 되돌아 훑는 방식으로 센다. 같은 spec 수치(MAX_STEPS=3)를 두 알고리즘이 따로 지키고 있어, 한쪽만 고치면 둘이 어긋나도 아무도 모른다. 제작대만 보는 쪽은 모든 아이템을 보는 test_recipes.gd 쪽에 이미 포함되므로, 깊이 세는 함수를 한 곳(예: tests 공용 헬퍼)으로 모으거나 제작대 쪽 검사를 지워도 기준은 그대로 지켜진다.
  - 기준: 음성 대조 테스트가 loom 이라는 이름에 매여 있다 — test_a_station_added_to_the_file_without_a_recipe_is_caught(test_station_recipes.gd:111~123)이 assert_eq(missing, ["loom"]) 으로 정확히 한 이름만 나오기를 바란다. 사람이 언젠가 진짜 베틀(loom)을 stations.json 에 적으면 검사 장치가 멀쩡한데도 이 줄이 실패한다. 실제로 위 확인 중에 이 이름이 겹쳐 엉뚱한 이유로 떨어졌다. 이름을 실제로 쓰일 리 없는 것(예: __qa_no_recipe__)으로 바꾸거나, assert_true("loom" in missing) 으로 눅여라.
  - 기준: 두 섬 크기가 같아지면 지도 테스트가 헛되게 깨진다 (막는 것은 아니다) — test_voyage.gd 의 `assert_ne(_sulfur_map.size(), _home_map.size())`(157줄 무렵)와 `assert_ne(int(home_map.get("cells")), int(sulfur_map.get("cells")))`(218줄 무렵)는 「섬마다 제 크기의 지도다」를 두 섬의 크기가 **다르다**는 데 기대어 본다. 그런데 유황 섬 설계 값은 이제 spec 에 「전부 임시 — 사람이 같이 다듬는다」로 적혀 있어, 사람이 size 를 내 섬과 같게 고르면 섬 갈림이 멀쩡한데도 이 두 줄이 실패한다. 섬마다 갈라 담기는 것은 같은 시험의 gone · stations · map 비교가 이미 확인하므로, 이 두 줄은 빼거나 「크기가 다를 때만 견준다」로 눅여라
  - 기준: tools.json 의 gun 30발이 spec 표에 없는 총이다 — tools.json 의 _temporary 는 「탄창 크기는 spec 표의 값이고 권총 9발만 사람이 정했다」고 적었는데, gun 은 그 표(권총·산탄총·돌격소총·저격총 4계통 16자루) 어디에도 없는 예전 총이다. 30발도 표에서 온 값이 아니라 전에 코드에 박혀 있던 값을 옮긴 것이다. 단계 3 「열여섯 자루와 사다리」에서 이것을 지워야 할지 남겨야 할지가 지금 파일만 봐서는 안 보인다. tools.json 의 _temporary 에 「gun 은 표에 없는 예전 총이고 30발은 표가 아니라 옛 코드에서 온 값이다 — 계통이 붙으면 없어질 자리」를 한 줄 더 적어라
  - 기준: (앞 단계 QA) 늘 참인 단언이 빈 검사 자리에 또 들어갔다 — game/tests/core/input/test_input_spec_table.gd:124 의 `assert_false(_row(elsewhere, "R").contains("갈고리총"), …)` 는 지키는 것이 없다. elsewhere 는 바로 윗줄에서 만든 `"| **R** | 재장전. M 은 여기 없다 |"` 라 「갈고리총」이라는 글자가 애초에 없다 — _row() 가 그 줄을 그대로 돌려주든 빈 글을 돌려주든 contains() 는 늘 false 라서, 저장소가 어떻게 바뀌어도 이 단언은 통과한다. 같은 함수의 116 · 117 · 120 · 123 줄은 _row() 가 망가지면 걸리는데 이 한 줄만 아니다. G-900.11 QA 가 잡은 test_island_design_notes.gd:125 의 `doubled.count(...)` 와 똑같은 자리다. 고치는 법: 「R 줄이 갈고리총을 말하나」를 도우미로 빼고(예: `func _names(row: String, word: String) -> bool`) 진짜 검사 test_the_reload_row_names_the_grapple_gun_too 와 이 빈 검사가 **같은 도우미**를 부르게 한 뒤, 빈 검사에서는 갈고리총을 말하는 가짜 줄로 assert_true · 말하지 않는 가짜 줄로 assert_false 를 짝지어 두 갈래를 다 걸어라. 그럴 생각이 없으면 124~125 두 줄을 지워라 — 없는 편이 낫다
- [x] 14. 번역 키를 지키는 테스트 넷
  - 기준: 제작대 이름 다섯(ITEM_workbench · smelter · cook_table · cook_stove · research_bench)이 ko.po · en.po 에 있는지 보는 테스트가 없다. 지금 두 파일에 다 들어 있어 게임 글자는 맞지만, stations.json 은 「한 줄 더 적으면 코드를 안 고쳐도 나타난다」가 설계다 — 다음에 한 줄 더 적으면 화면에 번역 안 된 ITEM_xxx 날글자가 그대로 뜨고 아무도 안 잡는다. 도구 쪽에는 이미 그 테스트가 있다 (game/tests/combat/tools_as_weapons/test_tools.gd:90-94 — 카탈로그를 훑어 po 두 개에 ITEM_<이름> 이 있는지 본다). 같은 모양으로 StationCatalog.load_from().keys() 를 훑어 ko.po · en.po 둘 다에 ITEM_<key> 가 있는지 보는 테스트를 test_stations.gd 에 하나 더 짜라.
  - 기준: (앞 단계 QA) 주석을 줄바꿈하면 테스트가 깨진다 — 막는 것은 아니다. test_bag_temporary_note.gd 의 _note_line 은 「덮개 색」이 있는 **한 줄**만 집어 거기서 임시·사람·layer·Color 를 다 찾는다. 그래서 bag.gd:18 은 210바이트짜리 한 줄로 남을 수밖에 없다 — 같은 머리글의 다른 줄은 전부 130바이트 안쪽에서 접혀 있어 이 줄만 튄다. 실제로 값은 그대로 두고 줄만 둘로 접어 돌려 보니 4개 중 2개가 깨졌다(「누가 나중에 정하는지가 없다」·「적어 둔 layer 가 씬과 다르다: -1 expected to equal 5」). 적어 둔 말이 멀쩡한데 모양만 고쳤다고 깨지는 것은 지키는 것이 아니라 걸리적거리는 것이다. _note_line 이 한 줄이 아니라 **머리글 전체**(_header 가 이미 모아 둔 것)를 돌려주게 고치고, 세 검사(임시·사람·layer·Color·layer 숫자)를 그 머리글 전체에서 찾게 바꿔라. 그러면 bag.gd:18 을 이웃 줄처럼 두 줄로 접어도 통과해야 한다 — 고친 뒤 접어서 돌려 4/4 가 나오는지, 값을 0.4·3 으로 낡혀 여전히 깨지는지 둘 다 확인하라
  - 기준: 레시피 결과물의 번역 키를 지켜 주는 테스트가 없다. recipes.json 에 줄을 하나 더 적으면(이번 기준이 바로 그것이다) ITEM_<output> 이 ko.po · en.po 에 없어도 아무도 안 잡고, 화면에는 번역 키가 그대로 뜬다. game/tests/combat/tools_as_weapons/test_tools.gd:94 가 하는 방식대로 recipes.json 의 output 마다 두 po 파일에 키가 있는지 보는 테스트를 짜라. (지금 있는 네 개 plank · stone_block · iron_ingot · sulfur 는 한국어 · 영어 둘 다 들어 있다.)
  - 기준: 작물 아이템의 번역을 지키는 테스트가 없다. ko.po · en.po 에 ITEM_wheat · ITEM_wheat_seed 가 둘 다 들어 있지만(확인함), 도구 쪽은 test_tools.gd:94 가 tools.json 의 모든 key 에 대해 ko·en 둘 다 있는지 세는 반면 작물 쪽은 아무도 안 본다. test_crops.gd 에 Crops.CROPS 의 작물 이름과 씨앗 이름마다 ITEM_<이름> 이 두 po 에 다 있는지 세는 테스트를 하나 더해라 — 작물을 늘릴 때 번역 빠진 것이 그때 잡힌다.
  - 기준: HUD 에 새로 선 한 줄이 spec 에 없다 — ui/hud/notice.gd 가 핫바·시계처럼 HUD 에 상시 붙는 새 요소인데 spec/12_ui/hud.md 의 「규칙」에 한 줄도 없고 「미정」도 기력·체력·맵만 적고 있다. notice.gd:13 은 「spec/12_ui/hud.md 미정」을 가리키는데 정작 그 문서엔 이 한 줄 이야기가 없어 서로 안 맞는다. spec/12_ui/hud.md 의 「규칙」에 '게임이 조용히 돌아서는 자리에 까닭을 한 줄 띄운다 — 잠깐 떴다 스스로 사라진다 (번역 키)' 를, 「미정」에 '떴다 사라지는 한 줄을 화면 어디에 두나 · 머무는 시간 미정' 을 더해라. 막는 것은 아니다 — 코드·테스트는 다 있고 값도 임시로 적혀 있다
- [x] 15. 섬 배선을 지키는 테스트 ① — 물 · 죽음 · 조작 잠금
  - 기준: 진짜 섬에서 물 자리가 막히는지 보는 테스트가 없다. 물 판정은 두 조각으로 나뉘어 각각만 확인된다 — Farmland 쪽은 가짜 is_water 를 꽂아서(test_water_cannot_be_tilled), 섬 쪽은 Farmland 없이(test_island_shape.test_water_spots_are_under_water). 둘을 잇는 줄(game/world/terrain/test_island.gd:181 의 is_water 람다)은 어느 테스트도 지나가지 않는다 — 좌표를 잘못 넘기거나(Vector2(pos.x, pos.z)) 배선을 빠뜨려도 286개가 다 통과한다. test_island_walk 에 한 줄짜리 테스트를 더해라: 연못 한가운데 섬 좌표를 골라 island.farmland.is_water.call(Vector3(c.x, 아무 높이, c.z)) 가 참이고 스폰 자리는 거짓인지 본다. 다음 단계(심기 · 물 주기)가 이 배선 위에 얹히므로 지금 박아 두는 편이 싸다.
  - 기준: 진짜 섬의 배선(world/terrain/test_island.gd 의 _build_death)을 보는 테스트가 하나도 없다. death.player 와 death.spawn = spawn_position() 이 거기서만 정해지는데, 그 두 줄이 틀려도(예: spawn 을 안 넣어 Vector3.ZERO 로 남아 바다 한가운데서 살아나도) 415개가 전부 통과한다. tests/world/terrain/test_island_in_game.gd 에 섬을 세운 채 죽여서 상자가 떨어지고 섬의 spawn_position() 자리에 다시 서는지 보는 검사를 하나 붙여라
  - 기준: GameRoot 가 붙이는 death.respawned → _apply_input_block(창을 열어 둔 채 죽었다 살아나면 조작을 도로 막는다)을 확인하는 테스트가 없다. 설정 창을 연 채 죽이고 살아난 뒤 player.controls_enabled 가 false 인지 보는 검사를 tests/settings/test_world_settings_in_game.gd 또는 test_island_in_game.gd 에 붙여라
  - 기준: (앞 단계 QA) 머리말에 「사람」이 딴 데도 있어 그 단언이 헛돈다 — test_bag_temporary_note.gd:98 의 assert_true(note.contains("사람")) 는 이제 bag.gd 에서 아무것도 지키지 않는다. _note 가 머리말 전체를 돌려주는데 bag.gd 머리말에는 「사람 결정 2026-09-21」이 7줄 · 11줄에 이미 두 번 나온다. 실제로 bag.gd:19 의 「— 디자인은 사람이 나중에 정한다」를 통째로 지우고 TEST_DIR=res://tests/ui/hud 로 돌려 보니 134/134 가 그대로 통과했다(되돌려 놓았다). 머리말 전체로 넓힌 것은 이번 기준이 시킨 것이라 기준 자체는 지켜졌지만, 「누가 나중에 정하는가」를 지키던 힘은 사라졌다. 고치는 법: _note 가 머리말 전체가 아니라 「덮개 색」이 든 자리부터 그 문장이 끝나는 곳(마침표)까지의 토막을 돌려주게 하라 — 줄바꿈은 먼저 공백으로 이어 붙이면 되니 두 줄로 접어도 통과한다. 고친 뒤 위 시험을 다시 해 「사람」을 지우면 걸리는지 확인하라. 「임시」와 「layer」는 머리말에 이 한 군데뿐이라 지금도 걸린다(0.4 · 3 으로 낡혀 2 실패 확인)
  - 기준: (앞 단계 QA) po 읽는 도우미가 열두 곳에 똑같이 복사돼 있다 — 이번에 test_stations.gd · test_recipes.gd · test_crops.gd 에 각각 붙인 func _po(path: String) -> Dictionary 열한 줄은 글자 하나 안 다르고 같다. 이제 game/tests 안에 같은 함수가 열두 벌이다(combat/tools_as_weapons 의 test_tools · test_ammo_kinds · test_gun_ladder, craft/recipes 의 test_recipes · test_hand_craft, craft/stations/test_stations, life/farming/test_crops, life/food/test_food, ui/hud 의 test_clock_label · test_station_output · test_station_window, ui/menu/test_menu_text). po 모양이 바뀌면 열두 곳을 따로 고쳐야 하고 한 곳만 고치면 어긋나도 아무도 모른다 — 바로 앞 단계 G-900.13 이 없앤 것과 같은 종류다. 고치는 법: G-900.13 이 만든 res://tests/craft/recipes/recipe_depth.gd 와 같은 모양으로 res://tests/po.gd 를 만들어 static func of(path: String) -> Dictionary 하나만 두고, 열두 파일이 const Po := preload("res://tests/po.gd") 로 그것을 부르게 하라. 구현 세션은 이번에 「열두 파일을 건드리는 일이라 기준 밖」이라고 적어 두었다
- [x] 16. 섬 배선을 지키는 테스트 ② — 예광탄 · 붙이는 차례 · 음식
  - 기준: 섬의 붙이는 차례를 지키는 테스트가 없다 — 「총이면 우클릭이 상호작용으로 안 간다」는 Aiming 이 우클릭을 받는 아홉(stations·chests·farmland·crops·food·climb_gear·death·dock_builder·dock)보다 **뒤에 붙는다**는 것에만 기대어 있다. test_aiming.gd 는 그 차례를 손으로 다시 세워 검사할 뿐 test_island.gd 의 진짜 차례를 읽지 않는다. 누가 _build_aiming() 을 앞으로 옮기거나 우클릭 받는 노드를 뒤에 새로 붙이면 테스트는 전부 통과한 채 게임에서 총 우클릭이 상자를 연다. 진짜 섬을 세우고 Aiming 이 INTERACT 를 받는 자식들 가운데 맨 뒤인지 보는 구조 테스트를 하나 짜라 (또는 _build_aiming 을 맨 뒤로 옮기고 그것을 검사하라)
  - 기준: 섬에 붙인 자리가 테스트에 안 잡힌다 — test_island.gd:256 _build_bullet_trace() 가 예광탄을 진짜 게임에 이어 주는 유일한 줄인데 이것을 확인하는 테스트가 없다. test_bullet_trace.gd 는 before_each 에서 BulletTrace 를 손으로 만들어 붙이므로, 섬 쪽 줄을 통째로 지워도 47개가 다 통과한다. 막는 것은 아니다 — 앞 단계의 _build_aiming 도 같은 처지고 섬 하위 계통은 원래 테스트가 없다. 고치려면 tests/world/terrain/test_island_in_game.gd 에 island.bullet_trace 가 서 있고 그 attack 이 island.attack 인지 보는 단언 두 줄이면 된다
  - 기준: 막는 것은 아니지만 다음에 메우면 좋다 — 섬 배선을 지키는 테스트가 없다. test_island.gd 의 _build_food() 가 하는 두 가지(player.buffs = buffs 로 걸음에 버프를 잇는 것, Food 를 밭 · 제작대보다 뒤에 붙여 먹은 우클릭이 작물까지 가지 않게 하는 것)를 어떤 테스트도 보지 않는다. test_food.gd 의 ClickWatcher 는 제 손으로 지은 나무에서만 순서를 확인하므로, 누가 _build_food() 를 _build_crops() 앞으로 옮기거나 player.buffs 줄을 지워도 326개가 전부 통과한다(report.json 의 「그 순서가 깨지면 걸리도록 테스트를 뒀다」는 섬까지는 덮지 못한다). 고치는 법: test_island_walk.gd 에 G-107.1 의 test_tilling_bare_ground_on_the_real_terrain 과 같은 꼴로 한 개를 더한다 — 스폰 앞 밭에 다 자란 밀을 하나 두고, 빵을 손에 든 채 우클릭해서 (가) 빵이 한 개 줄고 island.player.speed_multiplier() 가 파일 값이 되고 (나) 그 작물은 그대로 남아 있는지 본다.
- [x] 17. 껍데기 테스트를 고친다 ① — 절벽 · 약초 수 · 화산 띠
  - 기준: 게임 기준과 별개로 껍데기 테스트가 하나 있다 — game/tests/life/climbing/test_climbing.gd:87 test_a_walkable_slope_is_not_a_cliff 는 비탈에 닿지도 못한다. before_each(13줄)가 z=-3 에 80m 높이 벽(x -20..20, 앞면 z=-2)을 이미 세워 두는데, 이 테스트는 그 벽을 그대로 둔 채 30° 비탈을 z=-22 에 놓고 플레이어를 (20, 0.3, 0) 에 세워 1.0초만 앞(-z)으로 걷게 한다. 비탈은 기울어 파묻혀 있어 땅 위로 드러나는 곳이 z≈-20 부터인데, move_speed 6.0 으로 1.0초면 최대 6m 라 z≈-6 까지밖에 못 가고 그마저 z=-2 의 벽이 막는다. 즉 assert_false 는 비탈과 아무 상관 없이 참이다. 그래서 climbing.gd _wall_ahead 의 「n.angle_to(Vector3.UP) < floor_max_angle_deg 면 절벽이 아니다」 걸러내기를 확인하는 테스트가 하나도 없다 — 그 줄을 지워도 433개가 전부 통과한다. 고칠 것: 앞을 막는 벽이 없는 자리에 비탈을 두고(또는 플레이어를 비탈이 땅 위로 드러난 발치에 바로 세우고) 걸어 붙어 보게 하라. 짠 뒤에는 _wall_ahead 의 각도 검사 줄을 잠깐 지워서 그 테스트가 실제로 실패하는지 확인해 껍데기가 아님을 보여라. 플레이어를 x=20 — 벽의 정확히 모서리 — 에 세우는 것도 걷어라, 붙고 안 붙고가 광선이 모서리를 스치느냐에 달려 있어 흔들린다.
  - 기준: 작은 것 · 다음 단계를 막지는 않는다: 「20」이라는 사람 결정 수를 어느 테스트도 못 박지 않는다. test_my_island_grows_twenty_herbs:30 도 test_ledges_are_carved_into_cliffs:123 도 blueprint.herb_spot_count 와 견줄 뿐이라, 누가 island_blueprint.gd:83 을 12 로 바꿔도 테스트가 다 통과한다 — spec/04_life/gathering.md:11 의 「내 섬에 20곳 (사람 결정 2026-09-19)」이 소리 없이 무너질 수 있다. 고치는 법: test_herbs.gd 나 test_project_setup 류에 assert_eq(IslandBlueprint.new().herb_spot_count, 20, "사람 결정 2026-09-19") 한 줄을 넣어 숫자 자체를 못 박아라. (이 저장소에 이미 있던 관례라 이번 단계에서 새로 생긴 흠은 아니다.)
  - 기준: (막는 것 아님) test_cliffs_ring_the_volcano 는 절벽 띠 설정에 둔하다 — cliff_coverage 를 0.9→0 으로 놓아 절벽 띠를 통째로 꺼도 11개가 그대로 통과했다 (335/360). 가파른 원뿔 비탈만으로도 45°+ 8m 벽면이 서기 때문이라 기준(둘레에 절벽) 자체는 지켜지지만, cliff_step · cliff_coverage 가 사라져도 아무도 못 알아챈다. 화산 모양을 다시 만질 때 「걸어 오를 수 없는 벽면이 단으로 끊겨 있다」를 보는 잣대(예: walk_reach 로 산비탈 대부분이 스폰에서 닿지 않는다)를 하나 더하면 좋다.
- [x] 18. 껍데기 테스트를 고친다 ② — Tab · 재료 검사 · 제작대 레시피
  - 기준: Tab 이 더는 가방을 열지 않는다는 것을 지키는 검사가 없다. 기준의 「Tab 에서 옮겼다」 쪽을 되돌아가지 않게 막으려면 test_bag.gd 의 test_e_is_bound_to_the_inventory_action 에 한 줄을 더해라 — InputMap.action_get_events(InputActions.INVENTORY) 안에 physical_keycode == KEY_TAB 인 것이 하나도 없다는 단언. 지금 코드는 맞게 되어 있어 이번 기준은 통과지만, 누가 Tab 을 다시 넣어도 아무도 못 잡는다
  - 기준: 재료 검사가 유황광석까지 허용한다 — (막는 것은 아니다) test_tool_recipes.gd:173 이 허용 재료를 Harvest.DROPS 에서 뽑는데, 거기에는 sulfur_ore 도 들어 있다(harvest.gd:28). sulfur_ore 는 개척섬에만 나므로 부두를 놓기 전에는 못 얻는데도, 도구 레시피에 sulfur_ore 를 넣으면 이 테스트가 그대로 통과한다. 지금 네 레시피는 wood · stone · iron_ore 만 써서 실제로 어긋난 곳은 없다. 「내 섬에서 나는 것」으로 좁히려면 IslandResources 의 섬별 광물 목록(test_island_has_its_own_ores_only 이 쓰는 것)을 빼서 허용 목록을 만들어라.
  - 기준: 제작대 레시피가 없는 제작대를 가리켜도 통과한다 — test_every_station_in_the_data_file_can_be_crafted(test_station_recipes.gd:103)은 그 제작대를 output 으로 내놓는 레시피 '줄이 있는지'만 본다. 레시피의 station 칸이 stations.json 에 없는 이름이어도 통과한다. QA 가 확인했다: stations.json 에 loom 을 더하고 recipes.json 에 {key: loom, station: "nowhere", output: loom} 을 더했더니 이 테스트는 그대로 통과했다 (떨어진 것은 loom 이름이 겹친 음성 대조 테스트 하나뿐). 지금 다섯은 실전 제작까지 확인되지만 그것은 NEW_STATIONS 에 손으로 적은 넷을 도는 test_the_four_new_stations_are_made_at_a_station_and_land_in_the_bag 덕분이라, 여섯 번째 제작대를 적는 사람은 이 그물에 걸리지 않는다. test_every_station... 에 '레시피의 station 이 hand 이거나 stations.catalog 에 있는 이름이다' 한 줄을 더하면 손으로 적은 목록 없이도 막힌다.
- [x] 19. 껍데기 테스트를 고친다 ③ — 부순 제작대 · 설치물 · 버퍼 시간
  - 기준: 부순 제작대 테스트가 사람이 뒤집은 규칙을 굳힌다 — spec/05_craft/crafting-stations.md:11 · 25 에 「부수면 놓은 것이 그대로 돌아온다 (사람 결정 2026-09-22) — 재료 절반이 아니라 제작대 자체다」 와 「한 방에 부서지지 않는다 (사람 결정 2026-09-22)」 가 적혀 있는데, 새 테스트 test_pickup.gd:232 test_walking_over_what_a_broken_station_drops_picks_it_up 은 정확히 그 반대를 단언한다: 250줄이 assert_eq(int(back.get("wood", 0)), 10, "부수면 목재가 돌아온다") 로 목재 10개를 못 박고, 258~259줄은 좌클릭 **한 번** 뒤 assert_null(stations.aimed_station(), "제작대가 부서져 앞에 아무것도 없다") 로 한 방에 부서지는 것을 못 박는다. 아직 코드가 옛 규칙(stations.gd:29 RETURN_RATE := 0.5)이라 지금은 통과하지만, G-119 는 list.md:45 에서 [ ] 로 남아 있다. G-119 를 구현하는 회차가 이 테스트에 부딪히는데, 단언 문구가 「부수면 목재가 돌아온다」라서 옛 규칙을 지키는 장치처럼 읽힌다. 고칠 방향: 이 테스트가 묻는 것은 「부순 것이 걸어가면 주워지나」뿐이므로 돌아오는 것의 정체(wood·10개)를 박지 말고 stations.returns_of() 가 내주는 것을 그대로 받아 「그것이 바닥에 떨어지고 밟으면 들어온다」만 확인하게 눅여라. 부수는 것도 한 대로 끝난다고 가정하지 말고 부서질 때까지 치게 하라.
  - 기준: 상자 · 횃불은 진짜 코드가 아니라 흉내로만 확인한다 — tests/build/test_placeable.gd 의 test_a_newly_placeable_thing_gets_the_same_rule_for_free 는 테스트 파일 안에 든 _FakePlaceable(placed_item · vanish 만 갖춘 가짜)로 규칙을 본다. 상자 · 횃불은 놓는 길이 아직 없어(G-120) 이번 회차로는 이것이 최선이고 기준을 막지는 않지만, 이 검사는 앞으로 나올 진짜 상자가 Placeable.GROUP 에 들도록 강제하지 못한다. 한편 game/world/storage/chest.gd 에 이미 진짜 Chest(StaticBody3D)가 있다 — 죽은 자리 상자 · 개발용 상자가 물려받는 것이라 부수면 안 되는 것이 맞으니 지금 규칙을 붙이지 않은 것은 옳다. G-120 에서 놓는 나무 상자를 만들 때 이 가짜 검사를 진짜 상자로 갈아 끼워라
  - 기준: 「닫아 둔 동안 시간이 흘렀다」 단언이 헐겁다 — test_station_output.gd:283 의 assert_lt(station.craft_left(), left_before + 0.01) 은 여유 0.01 때문에 시간이 완전히 멈춰도(craft_left() == left_before) 통과한다. 메시지는 「시간이 흘렀다」고 말하는데 아무것도 지키지 않는다. + 0.01 을 떼고 assert_lt(station.craft_left(), left_before, ...) 로 바꿔라 — 그대로 두고 돌려 15개가 다 통과하는 것을 확인했다 (제작대가 _process 로 스스로 돌아 창이 닫혀 있어도 시간이 준다)
- [x] 20. 껍데기 테스트를 고친다 ④ — 빈 총 · 총마다 다른 탄 · 맨손 사슬
  - 기준: 빈 총 테스트가 탄창을 놓는 길을 지나지 않는다 — test_per_gun_magazine.gd:157 test_an_empty_gun_stays_empty_after_being_put_down 은 주석에 「가장 아픈 자리」라 적었지만, 도끼를 든 동안 attack.magazine() 을 한 번도 부르지 않아 「손에서 놓을 때」 도는 코드를 지나지 않는다. 실제로 magazine() 이 총을 놓을 때 탄창을 버리도록 깨 보니 이 테스트만 통과했다 (형제 테스트 test_putting_the_gun_down_keeps_its_rounds 가 잡아 주므로 기준은 막혀 있다 — 통과를 막는 것은 아니다). _hold(AXE) 뒤에 형제 테스트처럼 assert_null(attack.magazine(), "도끼에는 탄창이 없다") 한 줄을 넣어 놓는 길을 지나게 하라
  - 기준: 총마다 다른 탄을 먹는지 아무 테스트도 안 본다 — ToolCatalog.ammo_item() 이 늘 "pistol_ammo" 를 돌려주게 일부러 깨 놓고 TEST_DIR=res://tests/combat/tools_as_weapons 를 돌려 봤더니 62개가 다 통과했다. 검사들이 「제 탄」을 전부 catalog.ammo_item() 에 되물어 보기 때문에, 총 전부가 한 가지 탄을 먹게 되돌아가도 아무도 못 잡는다 (기준 자체는 막혀 있어 통과를 막는 것은 아니다). test_ammo_kinds.gd 의 test_every_gun_in_the_file_says_which_round_it_eats 에 「쏘는 도구들이 먹는 탄을 모아 보면 서로 다른 것이 둘 이상이다」를 넣어라 — _guns() 를 돌며 catalog.ammo_item(gun) 을 Dictionary 에 모아 assert_gt(seen.size(), 1, "총마다 먹는 탄이 다르다") 한 줄이면 된다. 지금 파일은 revolver=pistol_ammo · gun=rifle_ammo 라 이대로 통과한다
  - 기준: 가벼운 것 하나 — test_from_empty_hands_to_the_first_axe 의 1단계(맨손으로 나무·돌 캐기)만 실제로 치지 않고 game.inventory.add() 로 건너뛴다. 맨손 채집은 test_harvest.gd 가 따로 보고 있어 사슬 자체는 끊기지 않았지만, 「빈손에서」가 한 테스트 안에서 끝까지 이어지려면 나중에 여기서도 좌클릭으로 나무·돌을 쳐서 줍는 대목을 넣으면 더 단단하다. 이번 통과를 막는 것은 아니다
  - 기준: (앞 단계 QA) 줍기 테스트가 빈 무더기를 거르지 않는다 — test_pickup.gd 의 test_walking_over_what_a_broken_station_drops_picks_it_up 은 count := drop.count 를 받아 「가방에 count 만큼 들어왔다」를 보는데, count 가 0 이어도 (줍기 전 0 == 뒤 0) 통과한다. (막는 것은 아니다 — 개수는 test_placeable 이 1 로 지킨다.) var count := drop.count 바로 뒤에 assert_gt(count, 0, "떨어진 무더기에 무엇이 들어 있다") 한 줄을 더해라
- [x] 21. 저장에서 새는 것 — 부순 선착장 · 깎인 대수
  - 기준: 부순 선착장이 저장본에서 되살아날 수 있다 — Dock.vanish() 는 Placeable.GROUP 에서만 빠지고 queue_free() 를 부른다. 지우는 것은 프레임 끝이라 그때까지 DockBuilder 의 자식으로 남고, DockBuilder.standing()(dock_builder.gd:100 근처)은 무리가 아니라 get_children() 을 훑는다 — 부순 프레임에 섬이 저장되면 부순 선착장이 다시 적힌다. 지금은 부술 길이 없어 터지지 않지만 위 결정이 내려지면 바로 드러난다. Dock.vanish() 가 부모에서 먼저 떼어 내게 하고(CraftingStation 이 무리에서 먼저 빠지는 것과 같은 이유), 「부순 선착장은 standing() 에 남지 않는다」 테스트를 tests/world/frontier_islands/test_dock_building.gd 에 짜라
  - 기준: 섬을 떠났다 오면 깎인 대수가 사라진다 — stations.gd 의 standing() 은 {kind, at} 만 담으므로 두 대 맞은 제작대가 저장·복원을 거치면 성한 몸으로 다시 선다. 막는 것은 아니다 (기준 밖이고, 만들던 것·버퍼도 이미 같은 처지다). 그 함수 위의 「만들던 것 · 버퍼는 아직 담지 않는다 (**임시**)」 줄에 「남은 대수」도 함께 적어 두면 다음에 저장본을 건드릴 때 빠뜨리지 않는다
- [x] 22. 자잘한 고침 — 선착장 null · E 키 · 막대 폭 · 등반 장비 그물
  - 기준: 막는 것은 아니다 (기준은 다 통과했다) — 다음에 건드릴 때 같이 보면 좋을 것: TestIsland.dock_position() 은 dock 이 null 이면 터진다. 저장을 일부러 깼을 때 test_going_back_to_the_frontier_island_finds_it_as_i_left_it 이 'Invalid access to property global_position on Nil' 로 죽었다. 지금은 선착장 없이는 섬을 떠날 수 없어 닿지 않는 길이지만, 앞으로 선착장을 부수거나 옛 저장본을 읽게 되면 배에서 내리다 게임이 죽는다. dock 이 없으면 스폰 자리로 내리게 두는 편이 안전하다.
  - 기준: E 가 개발용 비행 카메라의 debug_up 과 겹친다 — project.godot 에서 inventory 와 debug_up 둘 다 physical_keycode 69 다. F1 로 비행 중에 E 를 누르면 올라가면서 가방도 같이 열린다. 구현 세션이 알고 적어 뒀고(이번 기준 밖이라 안 고쳤다) 개발용 키라 게임에는 안 나온다. 다음에 손댈 때 debug_up 을 다른 키(예: Space 나 R)로 옮기면 된다 — 사람이 정할 일이면 needs_decision 으로 올려라
  - 기준: 막대 폭이 두 곳에 적혀 있다 — health_bar.gd 의 WIDTH(240) 와 health_bar.tscn 의 자리 폭(offset_left 16 · offset_right 256 = 240) 이 같아야 하는데, 어긋나도 아무도 안 잡는다. tscn 의 offset_right 를 256→416 으로 놓아(자리 폭 400) 돌려 보니 8개가 다 통과했다 — 체력이 가득 차도 막대는 자리의 60% 만 차는데 fill_ratio() 는 그대로 1.0 이다. WIDTH 를 지우고 _fill.offset_right = size.x * ratio 처럼 제 자리 폭에서 가져오게 하거나(resized 도 받아), 막대가 자리를 꽉 채우는지 보는 테스트를 하나 넣어라. (막는 것은 아니다 — 지금 두 값은 맞다)
  - 기준: 등반 장비에는 빠뜨림을 잡는 그물이 없다 — 도구는 tools.json 을 읽어 「한 줄 더 적었는데 레시피가 없으면 떨어진다」가 걸리지만, 등반 장비는 test_tool_recipes.gd:15 의 CLIMB_GEAR 상수에 셋이 손으로 박혀 있다. 네 번째 장비가 생기면 레시피를 빠뜨려도 아무것도 안 걸린다 — 이번 단계를 만든 바로 그 병이다. 등반 장비에는 tools.json 같은 데이터 파일이 아예 없고 anchor.gd · grapple.gd · climbing.gd 의 const 로만 있어서, 고치려면 장비 목록을 한 곳(데이터 파일이든 climb_gear.gd 의 한 배열이든)에 모으고 테스트가 그것을 읽게 해야 한다. 일이 작지 않다.
  - 기준: (앞 단계 QA) standing() 단언은 고친 곳을 지키지 않는다 — test_a_broken_dock_does_not_stay_in_standing 의 첫 단언 assert_eq(builder.standing().size(), 0) 은 standing() 이 이미 무리(Placeable.GROUP)로 거르므로 vanish() 의 remove_child 를 빼도 통과한다. 실제로 지키는 것은 둘째 단언(자식에서 빠졌다)뿐이다. 막는 것은 아니다. 테스트 주석에 「standing() 은 무리로도 거르므로, 떼어 냈는지는 자식 단언이 지킨다」 한 줄을 적어 두면 뒤에 누가 자식 단언을 지우지 않는다

## [x] G-126 건축 뼈대 — 토대 · 벽 · 문 · 지붕 · 계단
- spec: spec/06_build/building.md, spec/00_core/tech.md
- 결정 (사람 결정 2026-09-22): 토대는 **땅에만** 놓는 평평한 바닥, **한 장 3×3칸**.
  재료는 **나무판자**(나무 건축물) · **석재 블록**(석재 건축물). **철거하면 그대로 돌아온다**.
  손에 들면 놓일 자리가 격자에 맞춰 미리 보인다. 실내에서 지붕을 숨기지는 않는다
- 장식 없는 회색까지만 만든다 (roadmap.md — 뼈대만 앞당겼다)
- [x] 1. 격자에 맞춰 미리 보인다
  - 기준: 건축물을 손에 들면 조준한 칸에 놓일 모습이 **격자에 스냅되어** 미리 보인다 (테스트)
  - 기준: 놓을 수 없는 자리(이미 찬 칸 · 급경사 · 물)는 **다른 색**이고, 눌러도 놓이지 않는다 (테스트)
  - 기준: 우클릭으로 놓는다 — 설치물을 드는 것과 같은 손짓이다 (spec/02_player/movement-controls.md)
  - 기준: 「널빤지」를 **「나무판자」**로 고친다 (ko · en 둘 다. 아이템 이름만 바뀐다)
- [x] 2. 토대 · 벽 · 문
  - 기준: 토대는 **땅에만** 놓이고 한 장이 3×3칸이다. 평평한 바닥이 된다 (테스트)
  - 기준: 벽은 토대 가장자리에 스냅된다. 벽을 세운 칸은 **통행이 막힌다** (테스트)
  - 기준: 문은 통행이 되고 **우클릭으로 여닫는다** (테스트)
  - 기준: 나무판자 · 석재 블록 두 재료로 각각 만들어진다. 글자는 번역 키다 (ko · en)
  - 기준: (앞 단계 QA) 테스트 주석에 「널빤지」가 남았다 — game/tests/craft/recipes/test_recipes.gd 9줄 「널빤지를 만든다」, 198줄 「널빤지는 목재 2가 든다」를 「나무판자」로 고쳐라 (막는 것은 아니다 — 게임 안 글자가 아니라 주석이다)
- [x] 3. 지붕 · 계단 · 철거
  - 기준: 지붕을 얹으면 그 칸의 **위가 막힌다** (테스트)
  - 기준: 계단으로 **위층에 오른다** (테스트)
  - 기준: 철거하면 재료가 아니라 **그 건축물이 그대로** 가방에 돌아온다 (테스트)
  - 기준: 지은 것이 저장본에 남는다 — 나갔다 들어와도 그대로다 (테스트)
  - 기준: (앞 단계 QA) 임시 벽·문 치수가 spec 미정에 없다 — WALL_THICKNESS 0.2m · DOOR_WIDTH 1.2m · DOOR_HEIGHT 2.2m · LEAF_THICKNESS 0.08m 가 build_piece.gd 에만 「임시」로 적혀 있다(막는 것은 아니다). spec/06_build/building.md 「미정」 절에 「벽 두께 · 문 크기 미정 (지금 임시 0.2m · 1.2×2.2m)」 한 줄을 적어 두어라

## [x] G-127 밭과 비료 — 농사를 되살린다
- spec: spec/04_life/farming.md, spec/04_life/mining.md
- 결정 (사람 결정 2026-09-22): **밭은 만들어서 놓는다** — 삽 개간은 없앤다. 밭 한 칸 = 1칸.
  **밭 = 비료 + 흙**, 비료는 **석회**로 만들고 **석회는 내 섬에서 나지 않는다** (개척 섬을 열어야 한다).
  흙은 **돌을 캘 때 같이** 나온다 (지형은 파지 않는다)
- [x] 1. 흙과 석회
  - 기준: 돌을 캐면 **흙이 같이** 떨어진다 (테스트)
  - 기준: 석회는 **개척 섬에만** 깔린다 — 내 섬에는 한 곳도 없다 (테스트)
  - 기준: 곡괭이로 석회를 캔다. 글자는 번역 키다 (ko · en)
- [x] 2. 비료와 밭을 만든다
  - 기준: 석회로 **비료**를 만든다 (테스트)
  - 기준: **비료 + 흙**으로 밭을 만든다 (테스트)
  - 기준: 재료 개수는 임시다 — 코드와 report 에 「임시」라고 적는다
  - 기준: (앞 단계 QA) 없는 파일을 가리키는 주석 — game/tests/life/harvest/test_harvest.gd 의 test_each_resource_drops_its_own_yield 주석이 「그것은 test_harvest_soil_lime.gd 가 본다」라고 하는데 그런 파일은 없다. 흙은 같은 파일의 test_mining_a_rock_drops_soil_along_with_the_stone 이 본다 — 주석을 그렇게 고쳐라
- [x] 3. 밭을 놓고 농사를 짓는다
  - 기준: 밭은 1칸 격자에 **스냅**되어 놓이고, 급한 경사에는 놓이지 않는다 (테스트)
  - 기준: **삽 개간이 사라졌다** — 맨땅에 삽을 우클릭해도 밭이 생기지 않는다 (테스트)
  - 기준: 놓은 밭에 심고 · 물 주고 · 수확하는 것이 그대로 된다 (테스트)
  - 기준: 놓은 밭과 자란 작물이 저장본에 남는다 (테스트)

## [x] G-133 기둥과 무너짐 — 떠 있는 건축물을 없앤다
- spec: spec/06_build/building.md
- 결정 (사람 결정 2026-09-23): **받침이 사라지면 위가 무너진다.** 기둥을 새로 넣고,
  지붕은 기둥 9장 · 벽 6장까지 뻗는다 (장 수, 임시). 무너진 것은 **바닥에 떨어진다**
- 방 판정(G-128)보다 **먼저** 한다 — 떠 있는 벽이 남아 있으면 방이 엉뚱하게 잡힌다
- [x] 1. 기둥
  - 기준: 기둥을 만들어 놓을 수 있다. **통행을 막지 않는다** (테스트)
  - 기준: 나무판자 · 석재 블록 두 재료로 만든다. 글자는 번역 키다 (ko · en)
  - 기준: 다른 건축물처럼 격자에 스냅되고 미리 보인다 (테스트)
- [x] 2. 받치는 것이 있어야 지붕이 놓인다
  - 기준: 기둥에서 지붕 **9장**(3×3), 벽에서 **6장**(3×2)까지 놓인다 (테스트)
  - 기준: 받치는 것이 없는 자리에는 **놓이지 않고**, 미리보기가 다른 색이다 (테스트)
  - 기준: 장 수는 값 한 곳에 있고 「임시」라고 적는다
  - 기준: (앞 단계 QA) 기둥 임시 수치가 spec 미정에 없다 — 기둥 굵기 0.3m 는 build_piece.gd 에 「임시」로 적혀 있으나 레시피(나무판자 2 · 석재 블록 2)는 recipes.json 에 주석을 달 수 없어 어디에도 「임시」라고 남지 않았다. spec/06_build/building.md 「미정」에 「기둥 굵기 · 레시피 미정 (지금 임시 0.3m · 재료 2개)」 한 줄을 더해라 (막는 것은 아니다)
- [x] 3. 연쇄로 무너진다
  - 기준: 토대를 부수면 그 위 벽 · 지붕 · 설치물이 **함께** 무너진다 (테스트)
  - 기준: 무너진 것은 **바닥에 떨어진다** — 가방으로 들어오지 않는다. 손 철거는 지금처럼 가방으로 (테스트)
  - 기준: **부서진 상자의 내용물이 바닥에 쏟아진다** (테스트)
  - 기준: 무너진 뒤에도 떠 있는 건축물이 하나도 남지 않는다 (테스트)

## [x] G-134 삽을 없앤다 — 들고 다닐 것을 줄인다
- spec: spec/04_life/gathering.md, spec/02_player/movement-controls.md, spec/04_life/farming.md
- 결정 (사람 결정 2026-09-23): **삽을 없앤다.** 개간이 사라져 남은 일이 채집뿐인데,
  등반 장비만 해도 챙길 것이 많다. **캐는 데 도구가 필요 없다** — 약초를 막는 것은 등반이다
- [x] 1. 도구 없이 캔다
  - 기준: 채집물에 좌클릭하면 **무엇을 들었든(맨손 포함)** 스킬체크가 시작된다 (테스트)
  - 기준: 나무 · 돌 · 광물은 지금처럼 평타로 친다 — 스킬체크가 뜨지 않는다 (테스트)
  - 기준: 놓은 밭은 **부수면 그대로 돌아온다** — 다른 설치물과 같은 규칙이다 (테스트)
- [x] 2. 삽을 걷어낸다
  - 기준: 삽이 도구 목록 · 레시피 · 번역에서 사라진다 (테스트)
  - 기준: 삽을 가리키던 테스트 · 주석이 남지 않는다 (테스트)
  - 기준: 빈손에서 도끼 · 곡괭이 · 총으로 이어지는 사슬이 그대로 돈다 (테스트)
  - 기준: (앞 단계 QA) 밭 좌클릭이 겨눈 대상을 가리지 않는다 — Farmland.hit_aimed()(game/life/farming/farmland.gd)는 aimed_ground() 의 광선이 무엇에 맞았든(몹 · 작물 · 상자 옆면 · 나무) 맞은 점의 칸에 밭이 있으면 그 밭을 친다. 밭 위에 선 몹을 평타로 세 번 치면 밭이 부서지고 작물이 뽑힌다. 고치는 법: hit_aimed 에서 ground["collider"] 가 지형(또는 흙판)일 때만 hit_field 를 부르고, 몹 · 작물 · CraftingStation · Chest 등이면 "" 를 돌려라. 테스트: 밭 위에 몸통 있는 것(몹이나 StaticBody3D)을 세우고 그것을 겨눠 HITS 번 좌클릭해도 is_tilled(cell) 가 참으로 남는지 단언하라

## [x] G-128 방 — 막히면 방이 된다
- spec: spec/06_build/rooms.md
- 결정 (사람 결정 2026-09-22): **방 종류표는 데이터 파일**이다 — 사람이 「이 방에 무엇이 몇 개」를
  말하면 한 줄 붙여 바로 생긴다. 가장 작은 방은 **토대 한 장(3×3칸)**. 문은 늘 닫힌 것으로 본다
- [x] 1. 막힌 공간을 방으로 안다
  - 기준: 사방 벽과 지붕으로 막히면 방이 생기고, 벽이나 지붕 하나를 헐면 사라진다 (테스트)
  - 기준: 문이 있어도 **닫힌 것으로** 본다 (테스트)
  - 기준: 계단으로 이어진 2층에서 위 · 아래가 **각각 따로** 방이다 (테스트)
  - 기준: 토대 한 장(3×3칸)이 가장 작은 방이다 — 그보다 작으면 방이 아니다 (테스트)
- [x] 2. 방 종류를 데이터로 정한다
  - 기준: 방 종류표가 **데이터 파일**이다 — 한 줄 적으면 코드를 안 고쳐도 새 방이 생긴다 (테스트)
  - 기준: 첫 내용은 spec 의 표다 — 농장(밭) · 제작소(가공대) · 대장간(제련로) · 연구소(연구대) ·
    주방(조리대 + 조리용 화로 둘 다) (테스트)
  - 기준: 핵심 오브젝트가 없거나 둘 이상 섞이면 **잡실**이다 (테스트)
  - 기준: 방 이름은 번역 키다 (ko · en 둘 다)
  - 기준: (앞 단계 QA) 맨땅 판 테스트가 엉뚱한 이유로 통과한다 — game/tests/build/test_rooms.gd test_less_than_one_foundation_of_floor_is_not_a_room 은 이웃 토대 넷에 지붕·바깥벽이 없어 그쪽이 새서 0개가 된다. 맨땅 판이 방으로 잡히는지는 실제로 가려지지 않는다. 또 Rooms._fill 의 `cells < MIN_CELLS` 는 넓이가 늘 9의 배수라 닿지 않는 죽은 검사다 — `cells < 0` 으로 바꿔도 6개가 다 통과했다. 고치는 법: 이웃 넷에도 바깥 변 벽과 지붕을 얹어 각자 막힌 방이 되게 한 뒤 rooms().size()==4 이고 어느 방의 plates 에도 Vector2i.ZERO 가 없는지 단언하라. MIN_CELLS 검사는 지우거나 주석에 「판 단위라 늘 참 — 방 크기의 뜻만 적는다」로 밝혀라
- [x] 3. 방-상자 연동
  - 기준: **같은 방**의 상자에 든 재료를 제작대가 쓴다 (테스트)
  - 기준: **다른 방**의 상자는 쓰지 않는다 — 거리가 아니라 방 ID 로 가른다 (테스트)

## [x] G-130 동물이 산다 — 두 갈래 · 소리에 반응 · 도망
- spec: spec/04_life/hunting.md, spec/08_combat/mob-ai.md
- 결정 (사람 결정 2026-09-23): 비적대는 소리에 **도망**, 적대는 소리 쪽으로 **달려온다**.
  체력 30% 아래면 도망가고 **도망이 아주 빠르다**
- [x] 1. 걸어 다닌다
  - 기준: 동물이 섬 위를 걸어 다닌다 — 물 · 절벽에 빠지거나 끼이지 않는다 (테스트)
  - 기준: 길찾기 수단을 하나로 정하고 spec 에 적는다 (내비메시)
  - 기준: 값(걷는 속도 · 도는 반경)은 한 곳에 있고 「임시」라고 적는다
- [x] 2. 소리에 반응한다
  - 기준: 발소리 · 피격 · 총소리를 **비적대는 피하고 적대는 쫓는다** (테스트)
  - 기준: 적대는 보이면 공격한다 (테스트)
  - 기준: 소리가 들리는 반경이 값으로 있고 「임시」다
  - 기준: (앞 단계 QA) 내비메시 비탈 · 몸 값에 「임시」 표시가 없다 — game/life/hunting/animal_nav.gd 의 MAX_SLOPE 40° · MAX_CLIMB 0.5 · AGENT_RADIUS 0.5 는 동물 목록이 미정이라 사실상 임시인데 주석에 「임시」가 없고 spec/04_life/hunting.md 「수치」에도 없다. 주석에 「임시」를 달고 수치 줄에 한 줄 더하라 (막는 것은 아니다)
- [x] 3. 도망간다
  - 기준: 체력 30% 아래면 도망간다 — 적대도 마찬가지다 (테스트)
  - 기준: 도망 속도가 평소보다 **뚜렷이 빠르다** (테스트)
  - 기준: (앞 단계 QA) 사람 몸이 걸을 때만 돈다 — game/player/movement_controls/player.gd 에서 _physics_process 끝의 `_turn_body(delta)` 가 새 함수 _footsteps 본문 맨 끝으로 딸려 들어갔다(181행). _footsteps 는 땅에 없거나 0.5 m/s 보다 느리면 일찍 return 하므로, 점프 중 · 물가 · 벽 앞에서 막혀 멈췄을 때 · 방향을 튼 직후 멈췄을 때 몸이 보는 쪽으로 돌지 않는다 (HEAD 에서는 늘 돌았다). `_turn_body(delta)` 를 _footsteps 에서 빼 _physics_process 의 `_footsteps(delta)` 다음 줄로 되돌려라. 테스트: 공중(점프 직후)에서 _facing 을 바꾸고 몇 프레임 뒤 몸(_body.basis)이 그쪽으로 돌았는지 보는 단언을 더하라
  - 기준: (앞 단계 QA) 가려진 사람도 보는 것이 테스트에 안 걸린다 — animal.gd _sees 의 광선 검사를 `return true` 로 바꿔도 tests/life/hunting 21개가 다 통과했다(QA 가 깨 보고 되돌렸다). test_hostile_does_not_bite_what_it_cannot_see 는 SIGHT 밖 거리만 본다. SIGHT 안(예: 8m)이지만 사이에 벽(StaticBody3D 상자)을 세운 사람을 적대가 CHASE 하지 않고 bit 도 없는지 보는 테스트를 더하라

## [x] G-135 웅크리기 · 배고픔 · 목마름
- spec: spec/02_player/hunger-thirst.md, spec/02_player/movement-controls.md, spec/12_ui/hud.md
- 결정 (사람 결정 2026-09-23): **달리기 키를 없앤다.** 기본이 달리기 속도고, 배고픔 · 목마름이
  바닥이면 느려진다 — 누르고 있는 달리기 키는 새끼손가락이 아프다. **굶어 죽지는 않는다**
- [x] 1. 웅크리기
  - 기준: **Ctrl 로 켜고 끈다**(토글). 웅크리면 느려진다 (테스트)
  - 기준: 웅크리면 **발소리가 나지 않아** 동물이 듣지 못한다 — 적대도 마찬가지다 (테스트)
  - 기준: **총소리는 웅크려도 난다** (테스트)
- [x] 2. 배고픔과 목마름
  - 기준: 둘 다 차 있으면 **달리기 속도**, 하나가 바닥이면 **걷기**, 둘 다면 거기서 **-30%** (테스트)
  - 기준: 바닥이어도 **죽지 않는다** (테스트)
  - 기준: 음식을 먹으면 배고픔이, 물을 마시면 목마름이 찬다 — 물은 연못 · 개울에서 마신다 (테스트)
  - 기준: **하루 세 끼 정도**로 준다 (하루 40분). 값은 한 곳에 있고 「임시」라고 적는다
  - 기준: 버프 음식은 **기본 속도 위에** 얹힌다 — 둘이 섞이지 않는다 (테스트)
  - 기준: (앞 단계 QA) test_crouch.gd 머리 주석이 없는 파일을 가리킨다 — game/tests/player/movement_controls/test_crouch.gd 3행이 발소리 · 총소리 테스트가 'tests/life/hunting/test_crouch_sound.gd' 에 있다고 적었는데, 그런 파일은 없다. 실제 테스트는 tests/life/hunting/test_animal_sound.gd 의 「웅크리기 (G-135.1)」 절에 있다. 주석의 경로를 그 파일로 고쳐라
- [x] 3. 동그란 게이지
  - 기준: 왼쪽 아래 **체력과 한자리**에 배고픔 · 목마름이 **동그란 게이지**로 보인다 (테스트)
  - 기준: **남은 양에 따라 색이 바뀐다.** 숫자는 없다 (테스트)
  - 기준: 글자가 있으면 번역 키다 (ko · en 둘 다)

## [x] G-131 부위별 사냥 — 머리 · 몸통 · 다리
- spec: spec/04_life/hunting.md
- 결정 (사람 결정 2026-09-23): 배율은 머리 1.3 · 몸통 1.0 · 다리 0.5(임시).
  **그 부위에 준 피해가 그 부위 산출을 깎는다** — 그래서 다리만 쏘면 뿔 · 가죽이 온전하다
- [x] 1. 부위를 맞힌다
  - 기준: 머리 · 몸통 · 다리가 따로 맞고, 부위마다 피해 배율이 다르다 (테스트)
  - 기준: **다리를 맞히면 느려진다** (테스트)
  - 기준: 배율은 데이터 한 곳에 있고 「임시」라고 적혀 있다
  - 기준: **조준하면** 그 동물의 **통짜 체력바와 마취 게이지**가 뜨고, 안 겨누면 사라진다 (테스트)
  - 기준: **마취가 걸리는 구간(체력 10% 아래)에서 체력바 색이 바뀐다** — 숫자 · % · 눈금은 없다 (테스트)
- [x] 2. 산출이 손상된다
  - 기준: 동물마다 부위 산출물이 데이터로 정해진다 (사슴: 머리 뿔 · 몸통 고기와 가죽 · 다리 없음) (테스트)
  - 기준: 그 부위에 준 피해만큼 **그 부위 산출이 준다** (테스트)
  - 기준: 다리만 쏴서 잡으면 머리 · 몸통 산출이 온전하다 (테스트)
- [x] 3. 도축과 점수표
  - 기준: 죽은 짐승에 다가가면 **도축 단추**가 뜨고, 누르면 산출이 나온다 (테스트)
  - 기준: 도축할 때 **부위별 몇 발 · 산출이 몇 %** 남았는지 보인다 (테스트)
  - 기준: 글자는 전부 번역 키다 (ko · en 둘 다)

## [x] G-132 마취탄과 포획
- spec: spec/04_life/hunting.md, spec/04_life/gathering.md, spec/04_life/ranching-breeding.md
- 결정 (사람 결정 2026-09-23): 마취탄은 **피해 0 · 속도를 늦춘다**. 체력 **10% 아래**에서만
  마취 게이지가 오른다. 약초 세 단(벨라도나 · 만드라고라 · 투구꽃)이 곧 마취탄 세 단이다
- [x] 1. 약초 세 종
  - 기준: 벨라도나 · 만드라고라 · 투구꽃이 난다. **벨라도나만 재배할 수 있다** (테스트)
  - 기준: 2 · 3단은 절벽의 발 디딜 틈에만 난다 (테스트)
  - 기준: 글자는 전부 번역 키다 (ko · en 둘 다)
- [x] 2. 마취탄을 만든다
  - 기준: **탄약 조합식 + 약초**로 마취탄 세 종을 만든다 (테스트)
  - 기준: 마취탄은 **아무 총에나** 들어간다. 맞아도 **피해가 0**이고 **속도가 준다** (테스트)
  - 기준: **R 을 꾹 누르면** 그 총에 맞는 탄만 뜨고 휠 · 숫자로 고른다 (테스트)
- [x] 3. 재워서 잡는다
  - 기준: 체력 **10% 위**에서는 마취 게이지가 오르지 않는다 (테스트)
  - 기준: 게이지가 다 차면 **포획된다** — 사살과 결과가 다르다 (테스트)
  - 기준: **투구꽃은 양을 넘기면 죽는다** — 포획하려다 사살이 된다 (테스트)
  - 기준: 동물마다 **재우는 데 드는 양이 다르다** (사슴 30 · 하급 마취탄 10 → 세 발) (테스트)
  - 기준: (앞 단계 QA) 탄을 바꿀 때 가방이 차면 탄이 사라진다 — Magazine.switch_to 가 남은 탄 · 쥔 탄을 bag.add 로 돌려놓는데, 가방이 가득 차 들어가지 못한 몫은 버려진다(구현 세션도 report 에 적었다). bag.add 가 돌려주는 넣은 수를 보고 못 넣은 몫이 있으면 바꾸지 않거나(false) 발밑에 떨어뜨리게 고치고, 가방을 꽉 채운 뒤 switch_to 해서 탄 총수가 줄지 않는지 단언하는 테스트를 test_tranq_ammo.gd 에 더하라
  - 기준: (앞 단계 QA) 핫바 칸에서 긴 탄 이름이 넘친다 — '벨라도나 마취탄' 같은 이름이 ItemSlot 옆 칸으로 넘친다(report 가 적은 것, '자동권총'도 같다). ItemSlot 라벨에 clip_text 나 줄임/글자 크기 맞춤을 두고, 가장 긴 ITEM_ 이름이 칸 너비를 넘지 않는지 보는 테스트를 짜라
- [x] 4. 들고 가기와 케이지
  - 기준: 재운 짐승을 **가방에 넣어 옮긴다** (테스트)
  - 기준: **마취 게이지가 계속 떨어지고**, 다 떨어지면 깨어나 도망간다 (테스트)
  - 기준: 깨는 데 걸리는 시간은 동물마다 다르다 — 값은 한 곳에 있고 「임시」다
  - 기준: **케이지**(소 · 중 · 대)를 만들어 가두면 깨어나도 도망가지 못한다 (테스트)
  - 기준: 제 덩치보다 작은 케이지에는 들어가지 않는다 (테스트)
  - 기준: (앞 단계 QA) 두 줄 이름이 칸 번호 · 개수와 겹친다 — 구현 세션이 report 에 적은 남은 틈(막는 것은 아니다). ui/hud/item_slot.gd 의 Item 라벨 상자가 칸 전체라 두 줄 이름이 왼쪽 위 Number · 오른쪽 아래 Count 글자와 겹친다. 이름 라벨의 위아래 여백을 숫자 높이만큼 두거나 숫자를 이름 밖으로 빼고, test_item_slot_fit.gd 에 Item 라벨 글자 줄 영역이 Number · Count 의 글자 영역과 겹치지 않는지 보는 단언을 더하라
  - 기준: (앞 단계 QA) item_slot.gd fit() 에 안 쓰는 변수 — fit() 안의 `var font := label.get_theme_font("font")` 가 쓰이지 않는다. 지워라

## [x] G-136 테스트가 왜 느린지 쟀다 — 고칠 것은 없었다
- **잰 것이 산출물이다** (사람 결정 2026-09-23). 「섬을 매번 새로 굽는다」는 전제로 열었는데,
  재 보니 **그런 곳이 한 곳도 없었다** — 없는 문제를 좇지 않게 여기서 닫는다
- 잰 결과 (2026-09-23):
  - 전체 **13~27분** — 같은 테스트가 맥 상태에 따라 **두 배** 흔들린다. 회차마다 도는 「바뀐 곳만」은 7~12분
  - **섬(TestIsland)을 테스트마다 다시 세우는 곳은 없다** — 134파일에서 17번, 전부 `before_all`
  - 무거운 쪽 둘: **저장본 없는 IslandShape 굽기**(한 번 **32초**, 저장본을 쓰면 0.2초)와
    **기다리기**(`wait_seconds` · 게임 시간 흐르기). 느린 열 개 중 여섯이 기다리기다
  - 가장 느린 파일: `test_island_shape` 139초(네 번 굽는다 — 그중 둘은 「같은 설계면 같은 섬」을
    확인하느라 **일부러** 두 번이다) · `test_animal_walk` 48초 · `test_tranq_ammo` 42초
- **재는 법** (다음 사람용): `TIMING=1 HARNESS_GODOT_TIMEOUT=3600 ./tools/test.sh | grep TIMING`
  — `game/tests/timing_hook.gd` 가 파일마다 걸린 초 · 섬을 몇 번 · 몇 초 세웠는지 느린 순으로 찍는다
- **왜 지금 안 고치나**: 다 고쳐야 15~20%인데 흔들림이 2배다. 기다리기를 줄이면 테스트가
  간헐적으로 실패하기 시작해 그 한 번이 아낀 것보다 비싸다
- **되살릴 조건**: 전체가 **40분**을 넘거나 회차마다 도는 검사가 **15분**을 넘으면 다시 본다.
  그때는 `TIMING=1` 로 다시 재는 것부터

## [x] G-137 저장이 빠지지 않게 — 왕복 검사
- spec: spec/01_settings/save.md
- 사람이 플레이해 보고 짚었다 (2026-09-23) — **껐다 켜면 서 있던 자리가 사라지고 탄창이 늘 가득이다.**
  의도가 아니라 spec 의 저장 목록에 아예 없었다. 오늘 하루에 들어온 건축 · 밭 · 동물 · 배고픔 중
  저장까지 챙긴 것은 절반뿐이다 — **빠뜨림이 구조적으로 생긴다**
- 결정 (사람 결정 2026-09-23): **저장은 담는 것이 기본**이고, 안 담을 것만 까닭을 적는다
- UI 묶음들보다 **먼저** 한다 — 지금도 새 기능이 계속 들어와서, 빨리 세울수록 새는 것이 적다
- [x] 1. 왕복 검사
  - 기준: 게임을 세우고 **상태를 여럿 바꾼 뒤**(움직이고 · 쏘고 · 먹고 · 짓고) 저장하고
    새로 불러오면 **값이 전부 같은지** 훑어 견주는 검사가 있다 (테스트)
  - 기준: **필드를 하나하나 적지 않는다** — 속성을 훑으므로 새 필드가 생기면 저절로 들어온다 (테스트)
  - 기준: 지금 안 담기는 것을 **목록으로 뱉는다** (고치는 것은 다음 단계)
- [x] 2. 빠진 것을 담는다
  - 기준: **어디 서 있었나**(섬 + 좌표)가 남는다 — 나갔다 들어오면 그 자리다 (테스트)
  - 기준: **총마다 남은 탄**이 남는다 — 껐다 켠다고 공짜 재장전이 되지 않는다 (테스트)
  - 기준: **배고픔 · 목마름 · 기력 · 체력**이 남는다 (테스트)
  - 기준: 단계 1의 왕복 검사가 **아무것도 못 뱉는다** — 빠진 것이 없다 (테스트)
  - 기준: (앞 단계 QA) 뱉는 목록에 값이 <없음>으로 찍히는 줄 — test_round_trip.gd 의 _at() 이 사전 키를 문자열로만 찾아서, Vector2i 키(Island/Farmland:_fields.(-397, 205))는 전·후 모두 <없음>으로 찍힌다(QA 가 섬 복원을 깨 봤을 때 드러났다 · 판정에는 영향 없다). _at 에서 키를 찾을 때 (v as Dictionary).keys() 를 돌며 str(key) == parts[i] 인 것을 고르게 하라
  - 기준: (앞 단계 QA) Island/Resources:_by_owner 가 목록에 든 까닭이 불확실하다 — 주석은 「캐릭터 가까운 칸만 짓는다」지만, 섬 복원을 끄자 이 줄이 차이에서 사라졌다(= 섬 상태와 얽혀 있다). 다음 단계에서 담을지·안 담을지 정할 때 _by_owner 의 해시가 무엇 때문에 다른지(인스턴스 id 가 섞이는지, 캔 자원이 다시 서는지) 확인하고 주석을 바로 적어라
- [x] 3. 다시 빠지지 않게
  - 기준: 일부러 안 담는 것은 **「안 담는다」 목록**에 까닭과 함께 적혀야 검사가 통과한다 (테스트)
  - 기준: 그 목록에 없는 새 상태가 안 담기면 **검사가 실패한다** — 일부러 하나 빠뜨려 확인한다 (테스트)
  - 기준: (앞 단계 QA) 죽은 채 저장하면 체력 1로 살아난다 — Health.set_left 가 clampi(value, 1, max) 로 0 을 1 로 올린다(game/combat/damage_death/health.gd). 죽음 처리 중 저장·종료되면 데스 상자 없이 체력 1로 되살아날 수 있다(막는 것은 아니다). 죽은 상태 저장을 어떻게 다룰지 확인하고(죽음이 저장 전에 늘 치러지는지), 체력 0 저장본을 불러오는 테스트를 하나 두어라
- [x] 4. (앞 단계 QA) 죽은 채 저장 결론이 spec 에 없다
  - 기준: 죽은 채 저장 결론이 spec 에 없다 — 「죽음은 take 안에서 치러져 저장본 체력은 0 이 될 수 없고, 0 이 들어오면 1 로 산다」는 결론이 health.gd 주석과 test_dead_save.gd 머리말에만 있다. spec/01_settings/save.md 의 체력 줄(31줄 「체력을 그대로 담을지…」 근처)에 한 줄로 적어 두어라 (막는 것은 아니다)

## [x] G-138 개발용 상자에 전부 들어간다
- spec: spec/01_settings/world-settings.md
- 사람이 플레이해 보고 짚었다 (2026-09-23) — **개발용 상자에 아이템이 계속 안 들어간다.**
  지금은 캐면 나오는 것(Harvest.DROPS) · 농사(Crops.CROPS) · 도구(tools.json)만 담는다.
  그래서 **제작으로만 나오는 것이 통째로 빠졌다** — 총알 네 종 · 마취탄 세 종 · 갈고리 탄 ·
  널빤지 · 석재 블록 · 철괴 · 건축물 여섯 종(나무 · 석재) · 제작대 다섯 · 케이지 셋 · 밭 · 비료 · 약초 셋
- **저장과 같은 병이다** — 「담을 것을 하나씩 적는」 방식이라 새 기능이 들어올 때마다 조용히 빠진다.
  목록을 적지 말고 **만들 수 있는 것 전부에서 끌어온다**
- [x] 1. 만들 수 있는 것이 다 들어간다
  - 기준: **레시피(recipes.json)의 모든 output** · 캐면 나오는 것 · 농사 · 도구 · 등반 장비가
    개발용 상자에 들어간다 — **목록을 손으로 적지 않는다** (테스트)
  - 기준: **하나라도 빠지면 테스트가 실패한다** — 레시피에 한 줄 더해도 저절로 들어오는지
    일부러 새 레시피를 넣어 확인한다 (테스트)
  - 기준: 상자 창이 **화면을 넘지 않는다** — 칸이 많아지면 스크롤된다 (테스트).
    찍어서 눈으로도 확인한다 (`harness/shot.sh --ui <폴더> chest`)
- [x] 2. (앞 단계 QA) spec 의 개발용 상자 줄 두 곳이 낡았다
  - 기준: spec 의 개발용 상자 줄 두 곳이 낡았다 — spec/01_settings/world-settings.md 13줄 「모든 자원 · 도구가 든 상자」와 26줄(확인 기준) 「모든 자원 · 도구가 든 상자가 선다」가 16줄의 사람 결정(2026-09-23, 만들 수 있는 것 전부)과 어긋난다. 두 줄을 「만들 수 있는 것 전부가 든 상자」로 고쳐라. 17줄에도 약초 · 레시피 재료가 담긴다는 것을 더하면 코드와 맞는다 (사람 결정 줄 자체는 지우지 말 것)
  - 기준: (앞 단계 QA) 개발용 상자 창이 조작 안내 글을 가린다 — 칸이 많으면 창이 $Center 높이를 꽉 채워 화면 맨 위(y=0)까지 올라가, 왼쪽 위 HUD 안내 「… 클릭 다시 잡기」 끝부분을 덮는다 (harness/shot.sh --ui <폴더> chest 로 보인다). 화면을 넘지는 않아 기준은 통과. chest_window.gd _fit 의 room 에 위쪽 여백(예: 안내 줄 높이)을 빼 두거나 Center 에 위 여백을 주고, test_chest_window_scroll.gd 에 창 위끝이 0 보다 아래인지 보는 단언을 더해라

## [x] G-139 데스 상자 — 한눈에 알아보고 남은 시간이 보인다
- spec: spec/08_combat/damage-death.md, spec/12_ui/hud.md
- 사람이 플레이해 보고 짚었다 (2026-09-23) — **데스 상자가 보관 상자와 똑같이 생겼다.**
  실제로 크기(0.7 · 0.6 · 0.7)도 색(0.45 · 0.31 · 0.18)도 **같은 값**이다.
  **남은 시간도 코드에만 있고**(death_chest.gd `seconds_left()`) 화면에 보여 주는 곳이 없다
- 30분이 지나면 상자와 안의 것이 **같이 사라진다** (사람 결정 2026-09-16) — 남은 시간을 모르면
  잃고 나서야 안다. 여는 동안에는 시간이 멈춘다는 것도 보여야 급하게 굴지 않는다
- [x] 1. 한눈에 다르고, 남은 시간이 보인다
  - 기준: 데스 상자가 보관 상자 · 개발용 상자와 **한눈에 구분된다** — 색이나 표시가 다르다 (테스트)
  - 기준: **조준하면 남은 시간이 보인다** (테스트)
  - 기준: 창을 열면 창에도 남은 시간이 보이고, **여는 동안 멈춘다**는 것이 드러난다 (테스트)
  - 기준: 글자는 전부 번역 키다 (ko · en 둘 다)
  - 기준: 찍어서 눈으로 확인한다 (`harness/shot.sh --ui <폴더> chest`)
  - 색은 임시다 — 사람이 보고 정한다
- [x] 2. (앞 단계 QA) 찍기 도구에 디버그 print 가 남았다
  - 기준: 찍기 도구에 디버그 print 가 남았다 — game/core/debug/ui_shots.gd 139줄 print("DBG ", player._control_locks, …) 가 남아 있고 남의 private 변수(_control_locks)까지 읽는다. 그 줄을 지워라
  - 기준: (앞 단계 QA) death_aim 자리가 세운 것을 안 치운다 — ui_shots.gd _aim_death_chest 가 ShotGround · ShotDeath · StorageChest · DevBox 를 stations 가 아니라 game 에 붙여 _reset 이 치우지 않는다. 뒤 자리(menu · ammo)를 chest 와 같이 찍으면 상자 셋과 바닥이 배경에 남는다. 자리 끝에서 free 하거나 stations 에 붙여 _reset 이 치우게 하라
  - 기준: (앞 단계 QA) 창의 '멈춰 있다' 테스트가 멈춤을 지키지 않는다 — test_chest_window_death.gd test_the_number_in_the_window_does_not_move_while_open 은 창이 _rebuild 때만 글자를 쓰므로 DeathChest.tick 이 열린 상자를 줄여도 통과한다. chest.seconds_left() 가 tick(120) 뒤에도 300 그대로인지 함께 단언하라

## [x] G-129 UI 바탕 — Theme · 재는 검사 · 찍는 폭
- **자가 피드백**: 검사가 깨끗해질 때까지 단계를 계속 붙인다 (사람 결정 2026-09-23) —
  고치고 → 다시 훑고 → 또 고친다. 맨 뒤 묶음으로 미루지 않는다
- spec: spec/12_ui/hud.md, spec/12_ui/menu.md, spec/01_settings/display.md, LOOP.md 5절
- **UI 를 고치기 전에 바탕을 세운다** (사람 결정 2026-09-23). 순서가 중요하다 —
  Theme 없이 검사를 짜면 흩어진 값에 맞춰 검사가 만들어져, Theme 을 넣을 때 검사도 다시 손봐야 한다
- 화면은 **1280×720 · 16:9 고정**이다 (project.godot · spec/01_settings/display.md 사람 결정 2026-09-17).
  해상도를 여러 개 볼 필요가 없다 — 「기준 해상도 안에 잘리지 않고 들어가나」 하나만 보면 된다
- 찍는 법: `harness/shot.sh --ui <폴더> [hud bag workbench smelter chest menu]` → **PNG 를 열어 보고** 고친다
- 나중에 사람이 ComfyUI 로 뽑은 아이콘을 끼워 넣는다 — Theme 이 서 있어야 갈아 끼워도 일관되게 보인다
- [x] 1. Theme 한 곳에 모은다
  - 기준: 색 · 여백 · 칸 크기 · 글꼴이 **Theme 리소스 한 곳**에 모인다 (지금은 Theme 을 하나도 안 쓴다)
  - 기준: 같은 값이 코드와 `.tscn` 두 곳에 적혀 있던 것이 사라진다 (막대 폭이 그랬다) (테스트)
  - 기준: 창들이 그 Theme 을 쓴다 — 글자 크기 · 칸 크기가 창마다 제각각이지 않다 (테스트)
  - 기준: 고치기 전후를 찍어 눈으로 확인한다 (bag · workbench · chest)
- [x] 2. 재는 검사
  - 기준: 열리는 창을 **전부** 열어 놓고 잰다 — ① **1280×720 안에 들어오나**
    ② 서로 **겹치나**(창이 핫바를 가린다) ③ 글자가 **칸을 넘나** (테스트)
  - 기준: **창 목록을 손으로 적지 않는다** — 새 창을 더하면 저절로 검사에 들어온다 (테스트)
  - 기준: 지금 어긋난 곳은 **목록으로 뱉기만** 한다. 고치는 것은 G-901 의 몫이다
  - 기준: (앞 단계 QA) 제작대 창이 화면 아래로 넘친다 — /tmp/g129/after/workbench.png 에서 레시피 목록이 화면 아래로 잘린다(돌격소총탄 줄이 반쯤 잘림). station_window 목록을 ScrollContainer 로 감싸거나 창 높이를 화면 안에 맞추고, 창 Rect 가 get_viewport_rect() 안에 드는지 단언하는 테스트를 이 묶음의 재는 검사 단계에 넣어라
  - 기준: (앞 단계 QA) 맨손 제작 줄이 핫바를 덮는다 — /tmp/g129/after/bag.png 에서 「횃불」 버튼이 핫바 5·6번 칸 위에 겹친다. 가방 창(bag.tscn Center/Box)의 아래 끝이 핫바 위 끝보다 위인지 재는 테스트를 짜고 배치를 고쳐라
- [x] 3. 찍는 폭
  - 기준: **한국어 · 영어 둘 다** 찍는다 — 영어가 길어 칸을 넘치는 것이 흔하다
  - 기준: **만지는 중**을 찍는다 — 칸을 끌고 있는 중 · 재료가 모자란 줄
  - 기준: **섬 위에서의 HUD** 도 찍는다 — 회색 배경이 아니라 진짜 배경 위에서 읽히는지 본다
  - 기준: (앞 단계 QA) 핫바 높이 80 이 두 곳에 적혀 있다 — 테마 Window/hotbar_room=80 과 game/ui/hud/hotbar.tscn 의 offset_top=-80.0 이 따로 산다(단계 1 이 없앤 「같은 값 두 곳」이 다시 생겼다). hotbar.gd _ready 에서 offset_top = -UiTheme.window(&"hotbar_room") 로 걸고 .tscn 값은 지우거나, 두 값이 같은지 단언하는 테스트를 tests/ui/layout 에 넣어라
  - 기준: (앞 단계 QA) 재는 검사 테스트가 고아 노드 31개를 남긴다 — test.log 의 test_station_windows_fit_the_screen 뒤에 「31 Orphans」(Button 줄들). station_window._rebuild 가 queue_free 전에 떼어낸 줄이거나 테스트가 st.free() 로 창보다 먼저 제작대를 지운 탓으로 보인다. 원인을 찾아 없애고 after_each 에서 assert_no_new_orphans 로 지켜라
- [x] 4. (앞 단계 QA) 모자란 줄이 눈으로 안 갈린다
  - 기준: 모자란 줄이 눈으로 안 갈린다 — workbench_en.png 에서 Match pistol(철괴 10 필요, 가방 6)처럼 disabled 인 줄도 다른 줄과 똑같이 흰 글자다. 레시피 글자가 Button 글자가 아니라 자식 Label 이라 disabled 색을 안 탄다(station_window.gd 레시피 줄 만드는 곳). 테마에 모자란 줄 글자색을 두고 disabled 일 때 Label 에 걸어라. 테스트: 모자란 줄의 Label 색이 고를 수 있는 줄과 다른지 단언
  - 기준: (앞 단계 QA) 영어에서 철광석·철괴 칸이 둘 다 Iron — drag_en · workbench_en 핫바/가방 칸이 'Iron' 'Iron' 으로 같아 보인다(칸 글자 줄임). 줄여도 둘이 갈리게 칸 이름 줄임 규칙이나 짧은 이름 키를 두고, 가방 칸 글자가 아이템마다 다른지 단언하는 테스트를 넣어라
  - 기준: (앞 단계 QA) 섬 위 HUD 글자가 풀밭에서 흐리다 — island_en.png 의 알림 한 줄 · Hunger/Thirst 글자가 밝은 풀 위에서 잘 안 읽힌다. 테마 Label 에 그림자(shadow_color · shadow_offset)나 바탕 판을 걸어라

## [x] G-901 UI 개선 — 창을 훑어 고친다
- spec: spec/12_ui/hud.md, spec/12_ui/menu.md, spec/01_settings/display.md
- **자가 피드백**: 검사가 깨끗해질 때까지 단계를 계속 붙인다 (사람 결정 2026-09-23) —
  고치고 → 다시 훑고 → 또 고친다. 맨 뒤 묶음으로 미루지 않는다
- **단계를 미리 적어 두지 않는다** (사람 결정 2026-09-23) — 한 회차에 다 못 고치면
  그 회차 QA 가 남긴 것이 다음 단계로 붙는다. 창이 몇 개든 깨끗해질 때까지 이어진다
- 도구는 G-129 가 세워 둔다: **재는 검사**(1280×720 안인가 · 겹치나 · 글자가 칸을 넘나)와
  `harness/shot.sh --ui <폴더> [hud bag workbench smelter chest menu]` — **찍은 PNG 를 열어 보고** 고친다
- 사람이 2026-09-22 에 찍어 본 것 (여기서 시작하면 된다):
  - 제작 창이 레시피 22줄에 위아래로 화면을 넘쳐 **출력 버퍼가 잘리고 핫바를 통째로 가린다**
  - 상자 창과 가방이 붙어 있어 어디가 어디인지 구분이 없고, 「맨손으로 만드는 것」의
    **「횃불」 단추가 핫바에 겹쳐 잘린다**
  - 칸 안에서 이름과 개수가 흩어지고, **재료가 모자란 줄이 눈에 안 띈다**
- 고치는 방향 (참고 — 그대로 할 필요는 없다):
  - 패널 높이에 상한 · 목록만 스크롤 · **남은 시간과 버퍼는 스크롤 밖 고정**
  - 창을 핫바 위쪽에 놓아 겹치지 않게 · 상자와 가방을 한 패널에 위아래로, 제목은 제 격자 바로 위
  - 칸: 이름은 위 한 줄, 개수는 오른쪽 아래 구석. 빈 칸은 테두리만, 찬 칸은 배경을 밝게
  - **색만으로 구분하지 않는다** — 모자란 줄은 색 + 표시(점 · 빗금). 색각 이상이 스무 명에 한 명이다
- [x] 1. 걸린 것을 고친다
  - 기준: **재는 검사가 아무것도 뱉지 않는다** — 화면 밖 · 겹침 · 글자 넘침이 없다 (테스트)
  - 기준: 찍어서 눈으로도 확인한다 (workbench · bag · chest · hud · menu) — 무엇을 고쳤는지 report 에 적는다
  - 기준: 한 회차에 다 못 고쳤으면 **남은 것을 QA 가 적는다** — 다음 단계로 붙는다
- [x] 2. (앞 단계 QA) 창 바탕이 비쳐 캐릭터가 보인다
  - 기준: 창 바탕이 비쳐 캐릭터가 보인다 — bag · chest · workbench 사진에서 가방 칸 뒤로 캐릭터(갈색 캡슐)가 비친다. 창 바탕 테마 알파 0.55 때문이다(report). 창 패널 StyleBox 의 bg_color 알파를 올려(예: 0.9, 임시라고 적고) 다시 찍어 캐릭터가 안 비치는지 본다. 검사로 지키려면 ui_measure 쪽에 창 패널 바탕 알파가 기준 이상인지 보는 단언을 더한다
  - 기준: (앞 단계 QA) 영어 이름이 줄바꿈되면 개수가 글자에 붙는다 — bag_en.png 에서 「Iron ingot」 · 「Iron ore」가 두 줄로 접히고 개수 6 · 12 가 둘째 줄 글자 바로 옆에 붙어 읽기 어렵다(겹침 검사엔 안 걸린다). 칸 이름 글자 크기를 줄여 한 줄에 들게 하거나 개수 라벨을 칸 오른쪽 아래 모서리에 여백을 두고 두어, ko · en 사진 모두에서 이름과 개수가 떨어져 보이게 한다
  - 기준: (앞 단계 QA) 상자 창 안내 줄이 창 가장자리에 붙는다 — chest_ko.png 의 「칸을 끌어다 놓아 가방과 주고받는다 · 우클릭으로 닫는다」가 창 폭 끝에서 끝까지 닿아 좌우 여백이 없다(데스 상자 창도 같다). 창 패널에 안쪽 여백(content_margin 또는 MarginContainer)을 두어 글자가 창 테두리에서 떨어지게 한다
- [x] 3. (앞 단계 QA) 제작대 판 뒤로 캐릭터가 아주 희미하게 남는다
  - 기준: 제작대 판 뒤로 캐릭터가 아주 희미하게 남는다 — 알파 0.96 이라 workbench_ko.png 를 확대하면 「펌프 샷건 · 반자동 샷건」 줄 오른쪽(x≈760~850, y≈480~590)에 캐릭터 윤곽이 4% 남아 보인다. 보통 크기로는 거의 안 보여 기준은 통과로 쳤다. 완전히 가리려면 game/ui/theme/naru_theme.tres 의 window_panel bg_color 알파를 1.0 으로 올리고 MIN_BACK_ALPHA 는 그대로 둔다
  - 기준: (앞 단계 QA) 가장 긴 한국어 이름은 틈 없이 맞춘다 — ItemSlot.fit 은 DIGIT_GAP 을 둔 채로 안 드는 이름(벨라도나 마취탄 · 볼트액션 저격총 · 만드라고라 마취탄)을 틈 0 으로 되돌린다. test_in_korean_names_keep_off_the_count 의 STOCK 에는 그런 이름이 없어 이 경우는 지키지 않는다. 그 이름들로 칸을 채워 찍어 보고, 개수와 붙어 읽히면 칸 이름 글자 최소 크기(MIN_FONT_SIZE)나 두 줄 배치를 손본다

## [x] G-140 건축 손보기 — 사람이 플레이해 보고 짚은 셋
- spec: spec/06_build/building.md, spec/01_settings/input.md
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- 사람이 플레이해 보고 짚었다 (2026-09-24, 사진 둘):
  토대가 **지면을 따라 들쭉날쭉**하게 깔린다 · 맞닿은 변에 **겹벽**이 선다 · 계단이 **칸에 안 맞는다**
- [x] 1. 토대가 옆에 붙는다
  - 기준: 이미 놓인 토대가 곁에 있으면 **그 변에 먼저 붙는다** — 땅보다 우선이다 (테스트)
  - 기준: **마우스 휠로 높낮이를 올리고 내린다** — 건축물을 들고 있는 동안에만 (테스트)
  - 기준: **땅에서 5m 를 넘으면 놓이지 않는다** — 옆에 붙이는 중이어도 (테스트)
  - 기준: 찍어서 눈으로 확인한다 — 토대 여럿이 **수평으로 이어진다**
- [x] 2. 겹벽이 서지 않는다
  - 기준: 토대 둘이 맞닿은 선에는 **벽이 하나만** 선다 — 양쪽에서 하나씩 놓이지 않는다 (테스트)
  - 기준: 이미 벽이 선 변에는 미리보기가 **놓을 수 없는 색**이다 (테스트)
  - 기준: (앞 단계 QA) input.md 휠 줄이 구현과 어긋난다 — spec/01_settings/input.md 19줄은 「건축물을 들고 있으면 놓을 높낮이」인데 Buildings._holding_foundation 은 토대일 때만 휠을 받는다 (building.md 14줄은 토대 항목 아래라 구현이 맞다). input.md 줄을 「토대를 들고 있으면」으로 좁혀 적고(사람 결정 줄이니 뜻은 그대로 두고 괄호로 「벽 · 기둥 등은 변 · 바닥에 스냅되어 높낮이가 없다」를 덧붙인다), test_the_wheel_does_nothing_unless_a_foundation_is_in_hand 에 벽(wood_wall)을 든 경우도 넣어 raise()==0 을 단언하라 — 지금은 재료(wood)와 빈손만 본다
  - 기준: (앞 단계 QA) shots.gd _set_up_row 에 print 가 남았다 — game/core/debug/shots.gd 의 print("ROW …") 는 확인용 출력이다. 다른 자리 설정 함수처럼 조용히 두거나, 남길 거면 까닭 주석을 달아라
- [x] 3. 계단이 한 장에 들어가고 아래가 뚫린다
  - 기준: 계단이 **토대 한 장(3×3칸)** 안에 들어간다 — 지금은 두 장을 먹는다 (테스트)
  - 기준: **계단 아래로 걸어 지나갈 수 있다** — 속이 꽉 찬 쐐기가 아니다 (테스트). 난간은 없다
  - 기준: 걸어서 위층에 오르는 것이 그대로 된다 (테스트)
  - 기준: **계단 밑을 지나다녀도 층이 새지 않는다** — 방 판정은 그대로다 (테스트)
  - 기준: 찍어서 눈으로 확인한다 — 칸 밖으로 안 삐져나오고 밑이 비어 보인다
- [x] 4. (앞 단계 QA) building.md 계단 결정 줄의 「지금은」이 낡았다
  - 기준: building.md 계단 결정 줄의 「지금은」이 낡았다 — spec/06_build/building.md 18~20줄이 아직 「지금은 두 장을 먹고 속이 꽉 찬 쐐기라 계단 밑이 죽은 공간이다」라고 말한다. 사람 결정 문장(「계단은 토대 한 장(3×3칸)에 들어가고, 아래가 뚫려 있다 (사람 결정 2026-09-24)」 · 난간 없음 · 아트 단계)은 그대로 두고, 「지금은 …」 절만 「(G-140.3 에서 한 장 · 얇은 비탈 판으로 바꿨다)」처럼 지난 일로 고쳐라
  - 기준: (앞 단계 QA) _stairs_edges 가 늘 빈 목록을 돌려준다 — game/build/buildings.gd 의 _stairs_edges 는 STAIRS_PLATES=1 이 된 뒤로 쓰이는 데가 없다(주석에 「다시 늘면 쓰인다」). 한 장 계단이 정해졌으니 함수와 부르는 곳을 지우거나, 남길 거면 테스트 하나로 한 장일 때 빈 목록임을 못박아라

## [x] G-142 저장이 새지 않게 — 갈아 끼우기 · 창 닫기 · 자동 저장
- spec: spec/01_settings/save.md
- 사람이 플레이해 보고 짚었다 (2026-09-24) — **게임을 완전히 껐다 켜면 인벤토리가 사라진다.**
  확인해 보니 저장이 **메인 화면으로 나갈 때와 「게임 끄기」를 누를 때만** 일어난다
  (`game_root.gd` `_leave_to_main_menu` · `_quit_game`). **창의 X 나 ⌘Q 는 저장 없이 꺼진다**
- **순서가 중요하다** — 3 → 1 → 2 가 아니라, **갈아 끼우기를 먼저** 한다.
  자주 저장하게 만들면 **덮어쓰다 죽을 기회도 그만큼 늘기** 때문이다
- 저장이 새면 플레이 QA 자체가 안 되므로 목록 맨 앞에 둔다
- [x] 1. 갈아 끼우듯 저장한다
  - 기준: 저장본에 **바로 덮어쓰지 않는다** — 임시 파일에 다 쓴 뒤 이름을 바꾼다 (테스트)
  - 기준: **쓰다 말고 죽어도 옛 저장본이 멀쩡하다** — 임시 파일만 남기고 일부러 끊어 확인한다 (테스트)
  - 기준: 저장에 실패하면 옛 저장본을 지우지 않는다 (테스트)
- [x] 2. 창을 닫을 때도 저장한다
  - 기준: **창의 X 로 끄면 저장된다** — 자동 종료를 끄고 닫기 알림을 직접 받는다 (테스트)
  - 기준: 저장이 끝난 뒤에 꺼진다 — 쓰다 만 채로 죽지 않는다 (테스트)
  - 기준: 저장에 실패해도 꺼진다 — 못 끄고 갇히는 것이 더 나쁘다 (테스트)
- [x] 3. 자동 저장
  - 기준: **하루가 바뀔 때 · 섬을 옮길 때 · 죽었을 때 · 5분마다** 저장한다 (테스트)
  - 기준: 매 순간 저장하지 않는다 — 주기는 값 한 곳에 있고 「임시」라고 적는다
  - 기준: 저장하는 동안 조작이 멈추지 않는다 (테스트)
  - 기준: (앞 단계 QA) save.md 의 창 닫기 줄이 낡았다 — spec/01_settings/save.md 21줄 「창을 닫을 때(X · ⌘Q) — 지금은 이 길에서 저장이 안 된다」가 G-142.2 로 틀린 말이 됐다. 이 줄은 「사람 결정 2026-09-24」 목록 안이므로 줄을 지우지 말고 「지금은 이 길에서 저장이 안 된다」 부분만 「(한다 — 게임 안에서는 자동 종료를 끄고 닫기 알림을 받아 저장 뒤 끈다 · 메인 화면은 그냥 꺼진다)」처럼 고쳐라

## [x] G-143 크기 시험 — 4×4 토대와 2×2 밭을 하나씩
- spec: spec/06_build/building.md, spec/04_life/farming.md
- 사람이 플레이해 보고 「밭이 너무 잘다」고 했다 (2026-09-24). 지금은 **토대 3×3칸 · 밭 1칸**이라
  한 장에 밭이 아홉이다. **4×4 토대에 2×2 밭이면 네 장**이라 훨씬 시원하다 — 숫자도 딱 맞는다
- **바꾸는 것이 아니라 재 보는 것이다** — 지금 것(3×3 토대 · 1칸 밭)은 **그대로 두고**,
  **임시로 하나씩만** 더해 찍어 본다. 사람이 그림을 보고 정한다 (루프는 「보기 좋은가」를 판단하지 못한다)
- 고르고 나면 이 묶음은 닫고, 정해진 크기로 바꾸는 일은 따로 올린다
- [x] 1. 하나씩 만들어 찍는다
  - 기준: **임시 4×4 토대**를 하나 놓을 수 있다 — 지금 3×3 토대는 그대로 남는다 (테스트)
  - 기준: **임시 2×2 밭**을 하나 놓을 수 있다 — 지금 1칸 밭은 그대로 남는다 (테스트)
  - 기준: 4×4 토대 위에 2×2 밭이 **정확히 네 장** 들어간다 (테스트)
  - 기준: `harness/shot.sh` 로 **나란히 찍는다** — 3×3+1칸 과 4×4+2×2 를 한눈에 견줄 수 있게.
    찍은 자리 이름을 report 에 적는다
  - 기준: 임시라고 코드에 적는다 — 사람이 고르면 하나는 지운다

## [x] G-144 지붕은 받치는 것 바로 위만
- spec: spec/06_build/building.md
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- 사람 결정 2026-09-24 — 지금은 벽 하나가 지붕 **6장**, 기둥 하나가 **9장**을 받친다. 너무 멀리 뻗는다.
  **벽은 2장(1×2, 양쪽 한 장씩) · 기둥은 제 판 1장**으로 줄인다. 넓게 덮으려면 그만큼 받쳐야 한다
- [x] 1. 장 수를 줄인다
  - 기준: **벽 하나가 받치는 지붕은 두 장** — 벽이 선 그 자리에서 양쪽으로 한 장씩 (테스트)
  - 기준: **기둥 하나가 받치는 지붕은 한 장** — 기둥이 선 제 판만 (테스트)
  - 기준: 문도 벽과 똑같다 (테스트)
  - 기준: 받침이 없어진 지붕은 그대로 무너진다 — 연쇄 붕괴가 새 장 수로도 맞는다 (테스트)
  - 기준: 방 판정이 새 장 수로도 맞는다 — 사방과 위가 막히면 방이다 (테스트)
  - 기준: 찍어서 확인한다 — 벽 한 장 · 기둥 한 개를 세우고 지붕 미리보기가 딱 그만큼만 초록이다
- [x] 2. 계단도 지붕을 받친다
  - 사람이 플레이해 보고 「계단에 지붕이 안 붙는다」고 했다 (2026-09-24).
    지금 `roof_plates()` 는 기둥 · 벽 · 문만 보고 계단은 빈 배열이라, 계단 둘레에 지붕이 안 올라간다
  - 기준: **계단이 올라가 닿는 판 한 장**에 지붕이 놓인다 — 계단이 받친다 (테스트)
  - 기준: **계단이 선 제 판 위는 뚫린 채**다 — 거기가 2층으로 올라가는 구멍이다.
    계단 판 위에 지붕을 놓으려 하면 안 놓인다 (테스트)
  - 기준: 계단을 부수면 그것이 받치던 지붕이 무너진다 (테스트)
  - 기준: 계단으로 2층에 올라가는 것이 그대로 된다 — 머리가 막히지 않는다 (테스트)
  - 기준: 찍어서 확인한다 — 계단 올라간 자리에 지붕이 덮이고 계단 위는 뚫려 있다

## [x] G-141 총을 쏘는 맛 — 연사 딜레이 · 거리 · 반동 · 무게
- spec: spec/08_combat/tools-as-weapons.md, spec/02_player/inventory-hotbar.md
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- 지금 열여섯 자루가 **탄 수와 재장전만 다르다** — 피해 · 연사 · 거리 · 퍼짐 · 반동 · 소리가 없다.
  사람이 표를 정해 spec 에 올렸다 (2026-09-24, 전부 임시)
- [x] 1. 연사 딜레이와 자동
  - 기준: 좌클릭을 아무리 빨리 눌러도 **총마다 정해진 간격**보다 빨리 안 나간다 (테스트)
  - 기준: **돌격소총 3 · 4단만** 꾹 누르면 이어 나간다. 나머지는 눌러야 한 발이다 (테스트)
  - 기준: 값은 데이터 한 곳(tools.json)에 있고 「임시」라고 적는다
- [x] 2. 피해 · 거리 · 퍼짐 · 반동
  - 기준: **총마다 피해가 다르고** 부위 배율이 곱해진다 (테스트)
  - 기준: **유효 거리 밖에서 피해가 줄고**, 산탄총은 급하게 준다 (테스트)
  - 기준: 산탄총은 **알이 여럿** 나간다 (테스트)
  - 기준: 퍼짐이 **조준 절반 · 걸으며 1.5배 · 웅크리면 0.6배** (테스트)
  - 기준: **반동**으로 총구가 올라가고 안 쏘면 돌아온다. 연사는 발마다 쌓인다 (테스트)
  - 기준: 저격총 탄속만 400m/s 다 (테스트)
  - 기준: (앞 단계 QA) 좌클릭 도우미가 여섯 파일에 복사됐다 — _release_click() 과 「ready_in() 이 0 이 될 때까지 기다림」이 test_magazine · test_per_gun_magazine · test_attack · test_bullet_trace · test_ammo_label · test_ammo_label_by_gun 에 똑같이 붙었다. 다음에 좌클릭 규칙(반동 등)이 바뀌면 여섯 곳을 고쳐야 한다. game/tests/ 아래 공용 도우미(예: tests/combat/tools_as_weapons/click_helper.gd 의 static func click(tree, attack))로 모아 여섯 파일이 부르게 하라 (막는 것은 아니다)
- [x] 3. 한 발씩 장전
  - 기준: 「한 발씩」인 총은 **아무 때나 끊고 쏠 수 있다** — 두 발만 넣고 쏘는 것이 된다 (테스트)
  - 기준: 「통째로」인 총은 다 찰 때까지 못 쏜다 (테스트)
  - 기준: **총은 닳지 않는다** — 내구도가 없다 (테스트)
  - 기준: (앞 단계 QA) spec 「미정」 줄이 낡았다 — spec/08_combat/tools-as-weapons.md:101 「재장전 시간 · 조준 배율 · 흩어짐 · 탄착 남는 시간 미정」인데 조준 배율(0.5) · 흩어짐(총마다 퍼짐)은 2026-09-24 표로 정해졌다. 그 둘을 빼고, 대신 이번에 지어낸 반동 되돌림 값(Attack.RECOIL_HOLD 0.15초 · RECOIL_RETURN 20°/초 · RECOIL_MAX 15°)과 Projectile.max_range(유효 거리×2, 최소 60m)가 미정이라고 한 줄 적어라. 사람 결정 줄은 건드리지 마라
  - 기준: (앞 단계 QA) 기다림 루프가 도우미 밖에 두 곳 더 있다 — game/tests/combat/tools_as_weapons/test_aiming.gd:122 이 「ready_in() > 0 or recoil_degrees() > 0」을 따로 돌고, game/tests/settings/save/test_round_trip.gd:309 는 ready_in() 만 기다린다(반동은 안 기다림). 둘 다 click_helper.gd 의 Click.click 을 부르게 하거나, 기다림만 떼어 click_helper 에 static settle(tree, attack) 로 두고 부르게 하라
- [x] 4. 무게가 속도를 바꾼다
  - 기준: **모든 아이템에 무게**가 있다 — 데이터에 없으면 테스트가 실패한다 (테스트)
  - 기준: 가진 무게가 기준을 넘으면 **1kg 마다 -1%, 최대 -40%** 로 느려진다 (테스트)
  - 기준: **배고픔 · 목마름이 정한 속도에 곱해진다** — 둘이 섞이지 않는다 (테스트)
  - 기준: **칸 제한은 그대로다** — 무게로 막지 않는다 (테스트)
  - 기준: 기준 무게와 비율은 임시다. 한 곳에 있고 「임시」라고 적는다
  - 기준: (앞 단계 QA) spec 「재장전 중에는 쏘지 못한다」 줄이 낡았다 — spec/08_combat/tools-as-weapons.md:15 「R 로 재장전한다. 재장전 중에는 쏘지 못한다」는 이제 「통째로」 총에만 맞는다. 사람 결정 줄(2026-09-22 묶음) 안의 문장이니 지우지 말고, 뒤에 「(「한 발씩」인 총은 넣는 중에도 쏠 수 있다 — 아래 표 「장전」)」를 덧붙여라
  - 기준: (앞 단계 QA) spec 미정의 「재장전 시간 미정」이 낡았다 — spec/08_combat/tools-as-weapons.md:101 은 「재장전 시간 · 탄착 남는 시간 미정」이라고 적었지만, 재장전 시간은 이제 2026-09-24 표의 「한 발당 · 가득」 칸에 (임시로) 있다. 「탄착 남는 시간 미정」만 남기고 재장전 시간은 「위 표, 임시」로 옮겨 적어라

## [x] G-902 칸 옮기기가 편하다 — 다른 게임에 있는 것들
- **자가 피드백**: 검사가 깨끗해질 때까지 단계를 계속 붙인다 (사람 결정 2026-09-23) —
  고치고 → 다시 훑고 → 또 고친다. 맨 뒤 묶음으로 미루지 않는다
- spec: spec/06_build/storage.md, spec/02_player/inventory-hotbar.md
- **G-901 뒤에 한다** — 지금은 한 칸씩 끌어다 놓는 것뿐이라 불편하다.
  코어 키퍼 · 스타듀 · 마인크래프트에 다 있는 손버릇을 들여온다
- [x] 1. Shift + 클릭 — 통째로 건너간다
  - 기준: 상자가 열려 있을 때 가방 칸을 Shift+클릭하면 그 칸이 **통째로 상자로** 간다 (테스트)
  - 기준: 상자 칸을 Shift+클릭하면 통째로 가방으로 온다. 자리가 모자라면 들어간 만큼만 간다 (테스트)
  - 기준: 창이 닫혀 있으면 아무 일도 없다 (테스트)
- [x] 2. 우클릭 — 반만 집고, 한 개씩 놓는다
  - 기준: 칸을 우클릭하면 **반만** 집힌다 (홀수면 많은 쪽을 집는다) (테스트)
  - 기준: 집은 것을 칸에 우클릭하면 **한 개씩** 놓인다 (테스트)
  - 기준: 창 바깥 우클릭은 지금처럼 창을 닫는다 — 규칙이 부딪히지 않는다 (테스트)
  - 기준: (앞 단계 QA) spec 에 Shift+클릭이 안 적혔다 — spec/06_build/storage.md 와 spec/02_player/inventory-hotbar.md 어디에도 Shift+클릭(통째로 건너감 · 같은 것 칸부터 · 모자라면 들어간 만큼만 · 창이 닫혀 있으면 없음 · 잡은 짐승 칸은 빈 칸 하나로만)이 없다. 코드가 규칙이 되지 않게 storage.md 의 상자 칸 옮기기 줄 옆에 한 단락으로 적어라 (사람 결정 줄은 건드리지 말 것)
- [x] 3. 창 밖에 놓으면 버린다
  - 기준: 칸을 **창 밖으로 끌어다 놓으면** 그것이 **캐릭터 앞 바닥에 떨어진다** (테스트)
  - 기준: 떨어진 것은 **다시 주울 수 있다** — 밟으면 줍는다 (spec/02_player/pickup.md) (테스트)
  - 기준: 우클릭으로 **반만 집어** 밖에 놓으면 반만 버려진다 (테스트)
  - 기준: 버린 것은 저장본에 남는다 — 나갔다 들어와도 그 자리에 있다 (테스트)
  - 실수로 버려도 되돌릴 수 있어야 한다 — 없어지는 것이 아니라 **바닥에 놓이는 것**이다
    (무너진 건축물이 바닥에 떨어지는 길을 그대로 쓴다, spec/06_build/building.md)
  - 기준: (앞 단계 QA) 낡은 테스트 경로 주석 — game/player/inventory_hotbar/slot_hand.gd 의 머리 주석이 tests/player/inventory_hotbar/test_slot_hand.gd 를 가리키는데 그 파일은 없다. 실제 테스트인 tests/world/storage/test_chest_right_click.gd 로 고쳐라
  - 기준: (앞 단계 QA) 집어 든 것이 화면에 안 보인다 — 우클릭으로 집으면 칸 개수만 줄고 든 것(아이콘 · 개수)이 어디에도 보이지 않아, 사람은 무엇을 몇 개 들었는지 모른다. 든 것을 보여 주는 Control(mouse_filter IGNORE)을 창에 붙여라 — 커서 위치가 필요하면 LOOP.md 2절대로 Pointer 를 거쳐야 한다(커서를 직접 읽지 말 것). 들면 보이고 다 놓으면 숨는지 테스트로 확인하라
- [x] 4. 모으기 · 정렬 · 빠른 채우기
  - 기준: 같은 아이템 칸을 **더블클릭**하면 흩어진 것이 한 칸으로 모인다 (테스트)
  - 기준: 상자에 **정렬** 단추가 있다 — 누르면 같은 것끼리 모이고 이름순으로 선다 (테스트)
  - 기준: **빠른 채우기** 단추 — 상자에 이미 있는 종류만 가방에서 밀어 넣는다 (테스트)
  - 기준: 단추 글자는 번역 키다 (ko · en 둘 다). 찍은 그림으로 자리를 확인한다

## [x] G-903 한 바퀴가 이어지는가 — 빈손에서 끝까지
- spec: spec/00_core/roadmap.md (프로토타입 수용 기준 — 한 회차를 끊김 없이 돈다)
- **QA 가 못 잡는 것을 잡는 묶음이다.** 단계마다의 QA 는 「그 기준을 지키나」를 보지만,
  **길이 이어지는가**는 못 본다 — 제작 창이 며칠 동안 게임에서 열 길이 없었던 것이 그 예다
- 이미 `game/tests/craft/test_from_empty_hands.gd` 가 **맨손 → 나무 · 돌 → 제작대 →
  도끼 · 곡괭이 → 철광석 → 제련로 → 철괴**까지 실제로 친다. 거기서 이어 간다
- **중간에 아이템을 한 개도 넣어 주지 않는다** — 그 파일의 규칙을 그대로 지킨다
- [x] 1. 총과 탄까지 이어진다
  - 기준: 철괴에서 **총 · 탄약**을 만들어 실제로 쏜다 — 중간에 아이템을 넣어 주지 않는다 (테스트)
  - 기준: R 로 재장전하고, 탄이 없으면 안 채워진다 (테스트)
- [x] 2. 밭과 음식까지 이어진다
  - 기준: 돌을 캐 **흙**을 얻고, 석회로 **비료**를 만들어 **밭**을 놓는다 (테스트)
  - 기준: 심고 · 물 주고 · 수확해 **먹는다** — 배고픔이 찬다 (테스트)
  - 기준: (앞 단계 QA) 유황을 캐러 섬을 건너는 길은 치지 않는다 — 유황은 개척 섬에서 난다(roadmap 「자원」). 그런데 test_from_empty_hands.gd 는 유황 광석을 내 섬의 평평한 줄에 놓아 캤다. 연구대 → 해금 아이템 → 선착장 → 배로 건너가는 길은 이 한 바퀴 테스트가 치지 않는다. 이번 기준 밖이니 G-903 단계 4 「한 바퀴가 한 번도 끊기지 않는다」나 G-900 에서, 개척 섬으로 건너가 유황을 캐는 데까지 실제로 치는 테스트를 이어 붙여라
- [x] 3. 사냥과 포획까지 이어진다
  - 기준: 동물을 찾아 **부위를 맞혀** 잡고 **도축**한다 (테스트)
  - 기준: 약초로 **마취탄**을 만들어 체력 10% 아래에서 **재워 잡는다** (테스트)
  - 기준: (앞 단계 QA) 섬 건너 유황·석회 캐는 길을 단계 4에서 쳐라 — test_from_empty_hands.gd 는 개척 섬에서만 나는 유황과 석회를 둘 다 내 섬의 평평한 줄(LINE 의 "sulfur", "lime")에 놓고 캔다. G-903 단계 4에서는 연구대 → sulfur_dock_key → 선착장 → 배로 개척 섬에 건너가 유황과 석회를 캐는 데까지 실제로 치고, LINE 에서 두 줄을 빼라
## [x] G-145 건축을 다시 짠다 — 도면 · 등급 · 이어 붙이는 개수
- 차선: 3d-start (대화 세션이 나눴다 2026-09-24 — 3d-start 는 건축 쪽, 3d-lane2 는 겹치지 않는 것)
- 결정: **턱은 0.3m 까지 걸어서 오른다** (사람 결정 2026-09-24, spec/02_player/movement-controls.md).
  세션이 「캐릭터가 0.2m 토대 위로 걸어 오르지 못한다」고 물어 온 것에 대한 답이다.
  **다만 근거는 토대 두께가 아니다** (사람이 바로잡음 2026-09-24) — 토대 높이는 휠로 정하고,
  그것을 오르는 것은 **계단이 할 일**이다. 턱 0.3m 는 **지형의 작은 턱 · 돌부리**를 위한 값이다 —
  테스트에서 빼거나 토대를 땅에 묻지 말고, **턱 오르는 높이를 게임 규칙으로 넣어라**.
  이것부터 하면 HEAD 에서 떨어지던 test_from_empty_hands.gd 의 건축 부분이 함께 풀린다.
  과녁이 길을 막는 것은 테스트만 고치면 된다
- spec: spec/06_build/building.md, spec/04_life/farming.md, spec/05_craft/recipes.md
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- 사람이 플레이해 보고 「건축은 전체적으로 다시 손봐야 한다」고 했다 (2026-09-24).
  뿌리는 **「한 장이 몇 장을 받친다」(ROOF_SPAN · 장 수)** 였다 — 받침이 범위를 뿌리니
  처마가 멋대로 생기고, 기둥은 판 한가운데라 쓸모가 없고, 미리보기가 짚은 자리와 어긋났다.
  러스트 · 발하임처럼 **소켓 + 이어 붙이는 개수**로 바꾼다
- **먼저 개수, 그다음 도면, 그다음 크기** 순서다 — 크기를 먼저 바꾸면 어긋난 것이 더 커진다
- [x] 1. 장 수를 버리고 이어 붙인 개수로 잰다
  - 기준: `ROOF_SPAN` 과 「받치는 장 수」가 **코드와 spec 어디에도 없다** (테스트)
  - **이름 규칙**: 「걸음」을 쓰지 않는다 — 코드에서 이미 **진짜 걸음**(동물 · 플레이어 이동)에 쓰인다.
    `step` 도 쓰지 않는다 — 루프의 **단계**와 헷갈린다. 「이어 붙인 개수」가 드러나는 이름을 쓴다
  - 기준: 땅에 닿은 토대가 **0**, 거기 붙은 것이 1, 그 옆이 2 다 — **받침에서 이어 붙인 개수**다 (테스트)
  - 기준: **제 등급의 개수를 넘으면 놓이지 않는다** — 나무 3개 · 석재 4개 · 철 5개 (임시) (테스트)
  - 기준: **기둥이 선 자리는 다시 0** 이 된다 — 거기서 다시 뻗을 수 있다 (테스트)
  - 기준: 받침을 부숴 개수가 넘어가면 **무너진다** — 연쇄로 (테스트)
  - 기준: 미리보기가 초록 · 빨강으로 갈린다. 찍어서 확인한다 — 벽 한 장에서 뻗어 나간 지붕이
    세 장째까지 초록, 네 장째부터 빨강이다
- [x] 2. 붙을 자리를 정한다 (소켓)
  - 기준: 벽 · 문 · 계단은 판의 **변**, 지붕은 판 **위**, 기둥은 격자의 **모서리**(네 판이 만나는 자리)에
    붙는다 (테스트). 기둥이 판 한가운데에만 서던 것을 푼다
  - 기준: 붙을 자리가 없는 허공에는 **미리보기가 뜨지 않는다** (테스트)
  - 기준: **계단이 토대에 붙는다** (사람 결정 2026-09-24) — **토대를 짚으면 그 변에서 계단이
    뻗어 내려간다**. 땅을 짚어 올리는 것이 아니다 — 붙는 쪽은 늘 받침이 있는 쪽이다 (테스트)
  - 기준: 지금 `plan_stairs_at` 은 **제 판 안에서 한 층을 오르는 것**뿐이라, 휠로 올린 토대에
    걸어 올라갈 길이 없다. 토대 밖으로 내려가는 계단이 놓여야 한다 (테스트)
  - 기준: **땅에 박혀도 놓인다** (사람 결정 2026-09-24, 팰월드 그림을 봤다) — 땅에 딱 닿는지
    따지지 않는다. 비탈이든 평지든 늘 놓인다. 「땅에 안 닿아서 못 놓는다」를 두지 않는다 (테스트)
  - 기준: 더 높으면 계단을 **이어 붙여** 내려갈 수 있다 (테스트)
  - 기준: **미리보기와 놓인 것의 상자(AABB)가 같다** — 여섯 가지 전부, 크기도 자리도 (테스트).
    사람이 「오버레이랑 실제 크기가 계속 다르다」고 했다. 어긋나면 불합격이다
  - 기준: 찍어서 확인한다 — 토대 한 장 네 모서리에 기둥이 선 그림
  - 기준: (앞 단계 QA) 빈손 테스트에 TMPSTEP 디버그 줄이 남았다 — game/tests/craft/test_from_empty_hands.gd 에 gut.p("TMPSTEP …") 가 25줄 남아 로그를 어지럽힌다(이번 회차에 TMPDBG 두 줄만 지웠다). 전부 지워라
  - 기준: (앞 단계 QA) 0.3m 턱 테스트가 0.29m 로 잰다 — test_step_up.gd test_walks_up_a_0_3m_ledge 는 _walk_into_ledge(0.29) 를 쓴다. 규칙은 「0.3m 까지」라 경계값 0.3 자체가 오르는지 보지 않는다. 0.3 으로 올리고 안 되면 _step_up 의 들어 올리는 높이에 작은 여유를 더해 0.3 이 정확히 오르게 하라(0.4 가 막히는 단언은 그대로 둔다)
- [x] 3. 도면 하나로 짓는다
  - 기준: **도면을 들면** 지을 것 여섯이 뜬다 — 토대 · 벽 · 문 · 지붕 · 계단 · 기둥 (테스트)
  - 기준: 놓으면 **가방의 재료가 그 자리에서 빠진다**. 모자라면 못 놓는다 (테스트)
  - 기준: **건축물 레시피를 없앤다** — `craft/recipes/recipes.json` 에서 열두 개가 사라지고,
    가방에 건축물 아이템이 들어갈 길이 없다 (테스트)
  - 기준: **저장본에 남은 건축물 아이템은 재료로 바꿔 돌려준다** — 옛 저장을 열어도 잃지 않는다 (테스트)
  - 기준: 철거하면 **들어간 재료가 전부** 돌아온다. 회전 · 철거에 시간 제한이 없다 (테스트)
  - 기준: (앞 단계 QA) stairs_down 그림이 계단을 옆에서만 본다 — .loop/out/stairs_down.png 는 올린 토대를 옆에서 찍어 계단이 얇은 선으로만 보이고 토대 변에 붙은 자리가 잘 안 보인다. game/core/debug/shots.gd 의 stairs_down 카메라를 계단 정면 비스듬히(남서 위) 로 옮기면 사람이 한눈에 확인할 수 있다 (막는 것은 아니다)
- [x] 4. 토대 4×4칸 · 밭 2×2칸
  - **등급보다 먼저 한다** (사람 지적 2026-09-24) — 나중에 하면 단계 3·4 에서 짠 테스트를 또 고친다
  - 사람이 G-143 사진을 보고 골랐다 (2026-09-24)
  - 기준: 토대 한 변이 **4칸(4m)** 이다 — 벽 · 문 · 지붕 · 계단도 4m 다 (테스트)
  - 기준: 밭 한 변이 **2칸(2m)** 이고, 토대 한 장에 **정확히 네 장** 들어간다 (테스트)
  - 기준: 임시 시험 코드를 **지운다** — `build/size_trial.gd` · 그 테스트 · `shots.gd` 의
    `size_trial` · `size_trial_top`. 남은 곳이 없다 (테스트)
  - 기준: (앞 단계 QA) test_blueprint 에 고아 노드가 남는다 — test_what_was_spent_is_saved_and_an_old_save_counts_the_piece_price 가 restore 를 두 번 불러 BuildPiece 6개가 고아로 잡힌다(test.log). restore 뒤 await wait_process_frames(1) 을 넣거나 끝에 남은 조각을 free 해 고아가 0 이 되게 하라
  - 기준: (앞 단계 QA) 시간 제한 테스트가 10초만 기다린다 — test_rotating_and_breaking_have_no_time_limit 는 600 물리 프레임(약 10초)만 보낸다. 지금은 잠금 코드가 아예 없어 문제없지만, 나중에 누가 분 단위 잠금을 넣으면 못 잡는다. BuildPiece 에 놓은 시각을 두지 않는다는 것을 직접 보거나(예: 놓인 조각에 placed_at 같은 메타가 없다) 시계를 몇 분 앞당겨 보는 단언으로 바꿔라
- [x] 5. 등급 셋 — 나무 · 석재 · 철
  - 기준: 같은 건축물을 **나무 · 석재 · 철** 세 등급으로 짓는다 (테스트)
  - 기준: **도면으로 그 자리에서 등급을 올린다** — 망치 같은 도구를 새로 두지 않는다 (테스트)
  - 기준: 등급을 올리면 **이을 수 있는 개수도 늘어난다** (테스트)
  - 기준: 올린 것을 철거하면 **올리며 쓴 재료까지 전부** 돌아온다 (테스트)
  - 기준: (앞 단계 QA) 옛 테스트가 1m 칸을 밭 판으로 넘긴다 — tests/settings/save/test_round_trip.gd:330 과 tests/world/day_night/test_day_in_world.gd:40 이 Grid.world_to_cell(...) 로 구한 1m 칸을 farmland.till · crops.plant 에 그대로 넘긴다. 이제 그 인자는 2m 밭 판 좌표라 밭이 뜻한 자리의 두 배 먼 곳에 서고, 높이도 엉뚱한 자리(Grid.cell_to_world(cell))에서 잰다. 지금은 우연히 통과한다. Farmland.plate_of(pos) 로 판을 구하고 높이는 Farmland.center_of(plate) 자리에서 재도록 고쳐라
  - 기준: (앞 단계 QA) 시각 이름 검사의 'age' 가 엉뚱한 것을 잡는다 — test_blueprint.gd _time_marks 는 부분 문자열로 찾아서 damage · stage · storage · image 같은 변수가 BuildPiece · Buildings 에 생기면 시각이 아닌데도 깨진다. 이름을 '_' 로 쪼갠 낱말이 정확히 age · time · lock 등과 같은지로 보거나, placed_at · placed_time · lock_time 같은 정확한 이름 목록으로 바꿔라
- [x] 6. 휠로 올려도 옆에 붙는다
  - 「토대의 높이를 휠로 올렸을 경우 옆에 스냅이 안 붙는다」 — `plan_at` 이 이웃 윗면에
    휠 값(`_raise`)을 **또 더한다**. `_raise` 는 손에서 내려놓을 때만 0 이라 이어 붙일수록
    계단처럼 올라가고 곧 5m(`MAX_HEIGHT`)에 걸려 빨개진다
  - 기준: **옆에 붙을 때는 이웃 윗면에 딱 맞춘다** — 휠 값을 더하지 않는다 (테스트)
  - 기준: **한 장 놓을 때마다 휠 값이 0 으로 돌아간다** (테스트)
  - 기준: 이웃을 고를 때 **올린 높이** 기준으로 고른다 (테스트)
  - 기준: 휠로 이웃과 **다른 높이**로 놓는 것은 그대로 된다. 5m 제한도 그대로 (테스트)
  - 기준: (앞 단계 QA) spec 의 「등급을 내린다」를 만들 길이 없다 — spec/06_build/building.md 수용 기준(80줄)은 「등급을 올리고 내릴 수 있고」인데 이번 단계는 올리기만 만들었다. 이 묶음 뒤 단계나 G-900 에서 도면으로 한 등급 내리는 손짓(임시 키)과 그때 돌려줄 재료 규칙(철거처럼 올린 몫을 그대로 돌려주나)을 만들고, 내린 뒤 LINK_LIMIT 가 줄어 넘치는 것이 무너지는지 보는 테스트를 짜라. 규칙이 spec 에 없으면 「미정」에 한 줄 적어라
  - 기준: (앞 단계 QA) Buildings._grade 가 이제 거의 쓰이지 않는다 — buildings.gd:113 의 _grade 는 손으로 놓는 것이 늘 나무가 된 뒤 pick() 으로만 바뀐다. 테스트 편의로만 남았으면 주석에 그렇게 적거나, 필요 없으면 걷어내라

## [x] G-149 계단 위에는 아무것도 못 짓는다 — 플레이하고 찾은 것
- 차선: 3d-start (건축이라 차선 1)
- spec: spec/06_build/building.md
- 사람이 플레이해 보고 찾았다 (2026-09-25): **계단 위에 토대를 지을 수 있다.**
  「건축은 아무것도 없어야 한다」 — 계단이 선 판에는 어떤 건축물도 놓이면 안 된다
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- [x] 1. 계단이 선 판에는 놓이지 않는다
  - 기준: 계단이 선 판에 **토대 · 벽 · 문 · 지붕 · 계단 · 기둥** 어느 것도 놓이지 않는다 — 휠로 높이를 올려도,
    옆 토대에 붙여도 마찬가지다. 미리보기가 빨갛다 (테스트 — 여섯 가지 전부)
  - 기준: 계단 **위 공간**(계단이 오르는 한 층 높이 안)에도 놓이지 않는다 — 계단 구멍을 막는 지붕 · 2층 바닥이 생기지 않는다
    (spec 「계단이 선 제 판 위는 뚫린 채로 둔다」) (테스트)
  - 기준: 계단 위에 **설치물**(제작대 · 상자 · 횃불 · 밭)도 놓이지 않는다 (테스트)
  - 기준: 계단 **옆 변**에 벽을 세우거나 옆 판에 토대를 붙이는 것은 그대로 된다 — 막는 것은 계단이 선 판 하나다 (테스트)
  - 기준: `spec/06_build/building.md` 에 사람 결정 줄을 적는다 — 「**계단이 선 판에는 아무것도 짓지 못한다** (사람 결정 2026-09-25)」
  - 기준: 찍어서 확인한다 — 계단 위를 겨눈 토대 미리보기가 빨갛다
- [x] 2. (앞 단계 QA) 횃불을 놓게 되면 계단 판도 막아야 한다
  - 기준: 횃불을 놓게 되면 계단 판도 막아야 한다 — 지금은 횃불을 놓는 길이 아예 없다 (stations.catalog 에 torch 가 없다). 그래서 이번 기준은 통과지만, 나중에 횃불을 놓는 길을 만들 때 BuildPiece.stairs_in(self, BuildPiece.plate_of(spot), spot.y, spot.y) 확인을 넣어야 한다. test_building_stairs_plate.gd 의 assert_false(stations.catalog.has("torch")) 도 그때 '횃불 aimed_spot 이 null' 단언으로 바꿔라
  - 기준: (앞 단계 QA) stairs_blocked 그림이 남지 않았다 — 구현 세션이 찍었다고 한 stairs_blocked.png 가 .loop/out 에도 없고 다른 곳에서도 찾지 못했다. 앞으로 그림은 .loop/out/ 에 저장해 QA 가 볼 수 있게 하라 (harness/shot.sh .loop/out stairs_blocked)

## [x] G-148 한 바퀴 마무리 — 새 건축으로 집까지
- 차선: 3d-start (대화 세션이 나눴다 2026-09-24 — 3d-start 는 건축 쪽, 3d-lane2 는 겹치지 않는 것)
- spec: spec/00_core/roadmap.md, spec/06_build/building.md
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- G-903 단계 4 에서 **건축만 떼어 온 것**이다 (사람 결정 2026-09-24) — 그때는 건축을 다시 짜는
  중이라 옛 건축으로 도는 것이 버리는 일이었다. **G-145 가 선 뒤에** 새 건축으로 친다
- 결정: **한 바퀴 테스트의 집 짓기 꼬리(22~25)를 이 묶음 전까지 뺀다** (사람 결정 2026-09-24) —
  G-147 · G-910 의 마지막 전체 검사가 옛 건축 꼬리에 늘 걸렸다. `test_from_empty_hands.gd` 의
  `HOUSE_UNTIL_G148` 로 pending 처리했다 (3d-lane2). **이 묶음에서 새 건축으로 되살리고 그 표시를 지운다**
- [x] 1. 빈손에서 집까지 끊기지 않는다
  - 기준: `HOUSE_UNTIL_G148` pending 이 **없다** — 집 짓기 꼬리가 다시 돈다 (테스트)
  - 기준: 한 바퀴 테스트가 **도면으로** 토대 · 벽 · 지붕을 세워 **방**이 생기는 데까지 친다 (테스트)
  - 기준: 재료를 캐서 도면으로 짓는 길이 **한 번도 끊기지 않는다** — 막히면 그 자리를 report 에 적는다
  - 기준: 지은 것이 **저장하고 새로 불러와도 그대로**다 — 등급까지 (테스트)
  - 기준: 철거하면 들어간 재료가 전부 돌아오고, 그것으로 다시 지을 수 있다 (테스트)
- [x] 2. 저장까지 이어진다 — G-903 에서 옮겨 왔다
  - G-903 단계 4 를 통째로 옮긴 것이다 (사람 결정 2026-09-24) — 건축을 다시 짜는 중에
    옛 건축으로 한 바퀴를 도는 것이 버리는 일이라 묶음째 건너뛰었다
  - 기준: 저장하고 새로 불러와도 **지은 것 · 가진 것 · 서 있던 자리**가 그대로다 (테스트)
  - 기준: 한 바퀴가 **한 번도 끊기지 않는다** — 어디서 막히면 그 자리를 report 에 적는다
  - 기준: (앞 단계 QA) **섬을 건너가 캔다** — 연구대 → sulfur_dock_key → 선착장 → 배로
    개척 섬에 건너가 **유황 넷과 석회 하나**를 캐는 데까지 test_from_empty_hands.gd 가 실제로 치고,
    LINE 에서 "sulfur" · "lime" 줄을 뺀다 (테스트). 지금 LINE 의 유황은 넷이다 (권총탄 3 · 마취탄 1)
  - 기준: (앞 단계 QA · 이미 들어갔다 65fb024) 잡아 비운 사슴 집은 저장하고 불러와도 다음 날까지 비어 있다 — `island_animals.gd` 가 빈 집 · 비운 날을 담는다. 한 바퀴 테스트 25단계 끝의 단언이 **다시 돌면서** 지키는지만 본다 (테스트)
- [x] 3. (앞 단계 QA) 배 건너기 순서가 테스트에 복사돼 있다
  - 기준: 배 건너기 순서가 테스트에 복사돼 있다 — test_from_empty_hands.gd 의 _on_boarded · _on_key_inserted · _island_open 이 core/game_root.gd 의 sail_to · insert_key · island_open 을 손으로 베낀 것이라, GameRoot 쪽이 바뀌면(예: 로딩 · 캐릭터 몸 상태 넘기기 차례) 한 바퀴 테스트는 모른 채 통과한다. 지금은 같은 차례임을 확인했다(막는 것은 아니다). 베낀 함수 머리 주석에 'GameRoot.sail_to 를 바꾸면 여기도 맞춘다'를 적거나, IslandState · PlayerState 담기/되돌리기를 GameRoot 와 테스트가 함께 부르는 정적 함수 하나로 모아라
  - 기준: (앞 단계 QA) 개척 섬 캔 자리 단언이 빈 값끼리도 통과한다 — test_from_empty_hands.gd 25단계의 assert_eq(sulfur_now.get("gone"), sulfur_left.get("gone")) 는 둘 다 비어 있어도 참이다. 그 앞에 assert_eq((sulfur_left.get("gone", PackedStringArray()) as PackedStringArray).size(), SULFUR_LINE.size(), "개척 섬에서 캔 다섯 자리가 담겼다") 를 넣어라
- [x] 4. (앞 단계 QA) GameRoot.island_open · insert_key 머리에 베낌 표시가 없다
  - 기준: GameRoot.island_open · insert_key 머리에 베낌 표시가 없다 — sail_to 머리(game_root.gd 287줄)에만 '한 바퀴 테스트가 베껴 쓴다'가 있고 island_open(226줄) · insert_key(240줄) 머리에는 없다. 고치는 쪽에서 보이도록 두 함수 머리에도 'tests/craft/test_from_empty_hands.gd 의 _island_open / _on_key_inserted 가 베껴 쓴다 — 바꾸면 거기도 맞춘다' 한 줄씩 적어라 (막는 것은 아니다)
  - 기준: (앞 단계 QA) 한 바퀴 테스트가 옆 차선과 겹쳐 돌면 흔들린다 — report 에 따르면 naru-lane2 가 godot 6개를 돌리는 동안 test_from_empty_hands.gd 가 10단계(밭 놓기) · 5단계(걷기)에서 떨어졌고 혼자 돌리면 통과했다. 걷기 · 조준을 프레임 수가 아니라 도착 여부(거리 조건 + 넉넉한 상한)로 기다리게 바꾸거나, 떨어진 단계에서 무엇이 모자랐는지 단언 메시지에 위치 · 남은 거리를 찍어 원인을 가려라
- [x] 5. (앞 단계 QA) _put_down 은 조준이 맞기 전에 놓을 수 있다
  - 기준: _put_down 은 조준이 맞기 전에 놓을 수 있다 — test_from_empty_hands.gd 의 _put_down(700줄 근처)은 _look 뒤 곧바로 _right_click 하고 stations.aimed_station() 을 한 번만 읽는다. 조준 대기(_until_aims_ground 로 땅을 짚을 때까지 기다린 뒤 우클릭)를 넣고 assert_not_null 메시지에 _where() 를 붙여라 — 이번 기준(5 · 10단계)은 풀렸지만 같은 흔들림이 제련로 · 연구대 놓기에서 날 수 있다

## [x] G-146 플레이하고 짚은 것 — 밤 · 횃불 · 오버레이 · 탄 고르기
- 차선: 3d-start (대화 세션이 나눴다 2026-09-24 — 3d-start 는 건축 쪽, 3d-lane2 는 겹치지 않는 것)
- spec: spec/03_world/lighting.md, spec/06_build/building.md, spec/08_combat/tools-as-weapons.md
- 설치물 오버레이(옛 4번)는 G-150 으로 옮겼다 — 놓기 코드를 G-150 과 같이 만져 차선이 갈리면 부딪힌다 (2026-09-26)
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- 사람이 플레이해 보고 짚었다 (2026-09-24). 넷 다 「있는데 안 된다」쪽이다
- [x] 1. 밤이 가장 어둡다
  - 「낮→저녁 되는 노을에 어둠이 엄청 어두운데 밤은 엄청 밝다」 — 지금은 순서가 뒤집혀 있다
  - 기준: 밝기가 **낮 → 노을 → 밤 → 새벽 → 낮** 으로 이어지고 **밤이 가장 어둡다** (테스트)
  - 기준: 노을 · 새벽이 밤보다 어둡지 않다 (테스트)
  - 기준: 하루를 네 때로 나눠 찍어 나란히 본다 — 눈으로도 밤이 가장 어둡다
- [x] 2. 노을부터 새벽까지 내내 어둡다 — 한밤이 밝지 않다
  - 사람이 다시 짚었다 (2026-09-26): 「18~19시는 아예 어두운데 20시쯤은 엄청 밝다. 노을 → 밤이 어둡다가 밤이 밝아 어색하다」
  - 결정: **밤은 내내 어둡다** (사람 결정 2026-09-26) — 노을 · 한밤 · 새벽 모두 노을 때처럼 어둡다.
    초반엔 횃불, 나중엔 연구로 야간투시경 (spec/03_world/lighting.md)
  - 기준: 해가 진 뒤부터 뜨기 전까지 **어느 시각에도** 한밤이 노을보다 밝지 않다 — 18 · 19 · 20 · 22 · 0 · 3 · 5시를 재서 견준다 (테스트)
  - 기준: 밤 밝기가 광원 없이 「못 나갈 만큼」은 아니다 — 가까운 땅의 윤곽은 보인다 (day-night.md) (테스트: 최소 밝기 문턱)
  - 기준: spec/03_world/lighting.md · day-night.md 의 「밤이 가장 어둡다」 줄을 「밤은 내내 어둡다 (사람 결정 2026-09-26)」로 바꾼다
  - 기준: 하루를 18 · 20 · 22 · 3 · 5시로 찍어 나란히 본다 — 눈으로도 밤 내내 어둡다
- [x] 3. 횃불이 제 둘레를 밝힌다
  - 「횃불이 횃불 역할을 안 한다」 — 들어도 놓아도 둘레가 밝아지지 않는다
  - 기준: 횃불을 **놓으면** 그 둘레가 밝아진다 — 반경 밖은 그대로다 (spec/03_world/lighting.md) (테스트)
  - 기준: 횃불을 **손에 들어도** 둘레가 밝아진다 (테스트)
  - 기준: 밤에 횃불 하나를 놓고 찍는다 — 둘레만 밝고 섬 반대편은 그대로다
  - 기준: (앞 단계 QA) SKY_SHARE 에 「임시」 표시가 없다 — game/world/day_night/day_light.gd 의 const SKY_SHARE := 0.7 주석에 **임시** 가 빠졌다. report.json 의 temporary 에는 올라 있다. DAY_FILL · NIGHT_BELOW 처럼 주석에 **임시** 를 붙여라
  - 기준: (앞 단계 QA) 테스트의 땅 빛에 하늘 복사광이 빠졌다 — DayLight.ground_light 는 햇빛+달빛+평평한 주변광만 더하고 주변광의 70%(하늘 몫)는 뺀다. 지금은 사진으로 순서가 맞음을 확인했지만, Sky3D 가 밤하늘을 밝게 바꾸면 테스트는 못 잡는다. shots.gd 가 이미 재는 땅 밝기(_brightness(shot, GROUND))로 time_* 네 장의 순서를 단언하는 가벼운 검사를 더하거나, ground_light 주석에 이 빈틈을 적어 두어라
- [x] 4. R 꾹 — 없는 탄은 안 보인다
  - 「R 꾹 눌렀을 때, 있지 않은 탄의 종류는 표시되지 않는다」 — 지금은 0 개인 것도 다 뜬다
  - 기준: 탄 고르기에 **가방에 있는 탄만** 뜬다 (테스트)
  - 기준: 들고 있는 총이 쓰는 계통의 탄만 뜬다 — 지금 규칙 그대로다 (테스트)
  - 기준: 쓸 탄이 하나도 없으면 고르기가 뜨지 않는다 (테스트)  - 기준: (앞 단계 QA) shots.gd 의 밤 판정이 단언이 아니라 출력뿐이다 — game/core/debug/shots.gd 의 TIME_ORDER · TORCH_NIGHT 는 「틀렸다」를 print 만 하고 종료 코드는 그대로다. 사진을 찍는 세션이 줄을 읽지 않으면 놓친다. 틀렸을 때 push_error 로 남기거나 quit(1) 로 끝내 harness/shot.sh 가 실패로 돌려주게 하라
  - 기준: (앞 단계 QA) test_torch.gd 머리 주석의 단계 번호가 틀렸다 — game/tests/world/lighting/test_torch.gd 1줄 「G-146.2」 는 이번 단계(G-146.3)다. shots.gd 의 torch_night 주석(「(G-146.2, spec/03_world/lighting.md)」)도 같다. G-146.3 으로 고쳐라
- [x] 5. (앞 단계 QA) ammo_picker.gd 머리 주석 한 줄이 너무 길다
  - 기준: ammo_picker.gd 머리 주석 한 줄이 너무 길다 — game/ui/hud/ammo_picker.gd 7줄에 「가방에 없는 탄도 뜨지 않는다 (Attack.usable_rounds).」 를 앞줄에 이어 붙여 다른 줄보다 훨씬 길어졌다. 옆 줄들처럼 두 줄로 나눠라

## [x] G-147 지도에서 자리를 찾는다 — 좌표 읽기 · 좌표로 찾기
- 차선: 3d-lane2 (대화 세션이 나눴다 2026-09-24 — 3d-start 는 건축 쪽, 3d-lane2 는 겹치지 않는 것)
- spec: spec/12_ui/hud.md, spec/01_settings/input.md
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- 결정: 마지막 전체 검사를 막던 한 바퀴 테스트의 건축 꼬리는 **G-148 까지 뺐다** (사람 결정 2026-09-24, (a)).
  G-147 은 기준을 다 만족했으니 전체 검사만 다시 돌면 된다
- 사람이 청했다 (2026-09-24) — 지도(M)는 이미 밝히기와 「내 자리」까지 되어 있다.
  **어디가 어디인지 읽을 길**과 **좌표로 찾아가는 길**만 없다
- **마우스는 Pointer 로만 읽는다** (LOOP.md 2절) — `map_window.gd` 머리에도 적혀 있다.
  커서를 직접 읽으면 하네스 검사가 떨어진다
- [x] 1. 마우스 올린 자리의 좌표가 보인다
  - 기준: 지도 위에 마우스를 올리면 **그 자리의 세계 좌표**가 보인다 (테스트)
  - 기준: 마우스가 지도 밖으로 나가면 사라진다 (테스트)
  - 기준: 좌표는 **`game/core/input/` 의 Pointer 를 거쳐** 읽는다 — 커서를 직접 읽지 않는다 (테스트)
  - 기준: 지도를 닫았다 열어도 어긋나지 않는다 — 지도 네모와 세계 좌표가 늘 같은 잣대다 (테스트)
  - 기준: 찍어서 확인한다 — 글자가 지도 밖으로 잘리지 않고 다른 것을 덮지 않는다
- [x] 2. 좌표를 넣으면 그 자리에 표가 뜬다
  - 기준: 지도 **위쪽에 X · Y 칸**이 있다. 넣으면 그 자리에 표가 뜬다 (테스트)
  - 기준: **칸을 지우면 표도 사라진다** — 잠깐 보는 것이라 남지 않는다 (테스트)
  - 기준: 지도를 닫으면 표도 사라진다. **저장본에 담지 않는다** (테스트)
  - 기준: 지도 밖 좌표를 넣으면 표가 뜨지 않는다 — 빨갛게든 비어서든 알려 준다 (테스트)
  - 기준: 숫자가 아닌 것을 넣어도 터지지 않는다 (테스트)
  - 기준: 칸 이름은 번역 키다 (ko · en 둘 다)
  - 기준: 찍어서 확인한다 — 표가 어디에 떴는지 눈으로 보인다
- 표시를 **남겨 두는 마커**(아이콘 · 이름 · 저장)는 이 묶음에 넣지 않는다 —
  아이콘이 나온 뒤에 따로 한다 (사람 결정 2026-09-24)
  - 기준: (앞 단계 QA) 밝힌 칸이 지도 네모 밖으로 삐져나온다 — .loop/shots/map/map_ko.png 오른쪽 아래를 보면 (200,200) 언저리 밝힌 칸이 지도 테두리(아래·오른쪽) 바깥까지 그려진다. 이번 단계(좌표 글자) 밖의, 원래 있던 _draw 흠이다. game/ui/hud/map_window.gd _draw 에서 밝힌 칸 Rect 를 map_rect() 로 잘라(Rect2.intersection) 그리고, tests/ui/hud/test_map_window.gd 에 「섬 가장자리 칸을 밝혀도 그린 칸이 map_rect 를 넘지 않는다」 단언을 더하라

## [ ] G-150 건축 손보기 — 사람이 플레이하고 짚은 것 (2차)
- 차선: 3d-lane2 (사람 결정 2026-09-26 — 건축은 Fable 이 맡는다)
- spec: spec/06_build/building.md, spec/06_build/rooms.md, spec/06_build/storage.md, spec/04_life/farming.md
- 사람이 플레이해 보고 짚었다 (2026-09-26)
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- [x] 1. 토대를 부수면 그 위 설치물도 무너진다
  - 「토대 위에 밭을 설치하고 토대를 부수면 밭이 공중부양한다 — 다른 것들도 이런지 다 확인하고 다 부서져야 한다」
  - 기준: 토대(와 그 위 지붕 · 2층 바닥)를 부수면 그 위에 놓인 **모든 설치물**(밭 · 제작대 계열 전부 · 상자 · 횃불 · 앞으로 생길 것)이
    같이 무너져 바닥에 떨어진다 — **놓이는 것 전부에서 끌어와** 검사한다. 하나라도 떠 있으면 실패 (테스트)
  - 기준: 밭에 심긴 작물도 같이 사라지거나 떨어진다 — 떠 있는 작물이 없다 (테스트)
  - 기준: 찍어서 확인한다 — 토대를 부순 뒤 공중에 남은 것이 없다
- [x] 2. 계단은 토대에만 붙고, 토대 위에도 놓인다 — Tab 으로 스냅을 바꾼다
  - 「계단은 맨 땅에 설치하는 게 아니다. 스냅이 토대에 붙는 것일 뿐」 · 「토대 위에 계단 설치가 안 된다 — 스냅이 토대 아래로 잡힌다」
  - 기준: 계단은 **맨땅에 놓이지 않는다** — 토대(또는 2층 바닥)의 변에 붙을 때만 놓인다 (테스트)
  - 기준: 토대 변에서 **아래로 내려가는 계단**과 **토대 위에서 위층으로 올라가는 계단** 둘 다 놓인다 (테스트)
  - 기준: **Tab** 으로 붙는 자리(위로 · 아래로)를 바꾼다 — 미리보기가 바로 바뀐다. 입력은 InputMap 액션,
    spec/01_settings/input.md 표에 한 줄 (사람 결정 2026-09-26) (테스트)
  - 기준: 계단이 선 판에는 아무것도 못 짓는다(G-149)는 그대로다 (테스트)
  - 기준: (앞 단계 QA) spec 무너짐 줄에 밭이 빠져 있다 — spec/06_build/building.md 60줄 「그 위에 놓인 설치물(제작대 · 상자 · 횃불)까지 연쇄로 내려앉는다」에 밭(과 그 작물이 바닥에 쏟아진다)을 한 단어 더해라. 코드(Buildings.everything_placed)와 테스트는 밭까지 무너뜨리는데 spec 문장만 옛것이다
- [x] 3. 지붕은 하늘을 보고 놓는다
  - 「지붕은 하늘 보고 건축을 하는데 땅을 봐야 설치가 된다」
  - 기준: 지붕을 들고 **위를 보면** 조준선이 닿는 벽 윗면 · 기둥 위 자리에 미리보기가 뜬다 — 땅을 보지 않아도 놓인다 (테스트)
  - 기준: 땅을 보고 놓던 길도 그대로 된다 (테스트)
- [ ] 4. 설치물은 1칸 단위로 자유롭게 놓인다
  - 「밭은 2×2 인데, 토대 두 개 사이에 걸치거나 한 토대 가운데에 놓을 수 있어야 한다. 지금은 네 사분면에만 딱딱 들어맞는다」
  - 기준: 설치물(밭 · 제작대 · 상자 · 횃불 …)은 **1칸(1m) 격자**에 스냅된다 — 토대의 사분면 · 토대 경계에 묶이지 않는다 (테스트)
  - 기준: 밭 2×2 가 **토대 두 장에 걸쳐** 놓이고, **한 토대의 가운데**에도 놓인다 (테스트)
  - 기준: 겹쳐 놓이지는 않는다 — 이미 놓인 것과 칸이 겹치면 빨갛다 (테스트)
  - 기준: `spec/06_build/building.md` 또는 farming.md 에 「설치물은 1칸 격자 (사람 결정 2026-09-26)」를 적는다
  - 기준: (앞 단계 QA) 벽 윗면 테스트가 새 길을 지나지 않는다 — test_building_roof_skyward.gd 의 test_looking_up_at_the_wall_top_… 은 25° 로 벽 **옆면**에 광선이 닿아(BuildPiece 를 짚음) 고친 것 없이도 통과한다(roof 분기를 꺼도 통과했다). 벽 **위 하늘**을 보는 경우(Aim.at 이 비는 각도로 올리거나 벽에서 더 떨어져 서서)를 하나 더 두어 _roof_level_crossing 이 벽 꼭대기 자리를 짚는지 assert_true(sky.is_empty()) 대조와 함께 단언하라
- [ ] 5. 설치물도 놓을 자리가 보인다 (G-146 에서 옮겼다)
  - 「모든 설치물들은 오버레이를 둘 것. 밭 · 연구대 · 상자 · 조리대 다」 — 사람이 다시 짚었다 (2026-09-26: 「해 달라고 했는데 안 했다」)
  - 기준: **놓을 수 있는 것 전부**가 손에 들면 놓일 자리 미리보기를 띄운다 — 밭 · 상자 ·
    제작대(연구대 · 조리대 · 화로 …) · 횃불. **하나라도 빠지면 검사가 실패한다** (테스트).
    「목록에 적어 둔 것만」이 아니라 **놓이는 것 전부에서 끌어온다**
  - 기준: 놓을 수 있으면 초록 · 없으면 빨강이다 — 건축물과 같은 색 규칙 (테스트)
  - 기준: **미리보기 크기가 놓인 것과 같다** (테스트) — G-145.1 과 같은 잣대다
  - 기준: 찍어서 확인한다
- [ ] 6. 건축 전체 QA — 한 바퀴 훑어 흠을 찾는다 (G-153 을 옮겼다 2026-09-26)
  - 사람이 플레이할 때마다 건축에서 새로 걸렸다 (G-140 · G-145 · G-149 · G-150). **사람보다 먼저 찾는다**
  - 보는 법: **실제 입력(도면 들기 · 휠 · Tab · 우클릭 · 좌클릭)으로만** 짓고, 그림으로 찍어 본다. 함수를 직접 불러 맞추지 않는다
  - 기준: 아래를 **전부** 실제 입력으로 해 보고, 되는 것 · 안 되는 것을 report 에 표로 적는다 —
    토대 · 벽 · 문 · 지붕 · 계단 · 기둥 여섯 × 나무 · 석재 · 철 세 등급 놓기 / 등급 올리기 · 내리기 / 회전 / 철거(재료가 전부 돌아오나) ·
    옆에 붙이기 · 휠로 높이기(5m 한도) · 계단 위 · 아래(Tab) · 지붕을 하늘 보고 놓기 · 이어 붙인 개수를 넘기면 빨강 ·
    받침을 부수면 연쇄로 무너지고 **위의 설치물까지** 떨어지나 · 방이 생기고 없어지나 · 2층 · 저장하고 불러오면 그대로인가 (등급까지)
  - 기준: 찾은 흠 중 **그 자리에서 고칠 수 있는 것**은 고치고 테스트를 단다 (테스트)
  - 기준: 나머지는 QA 가 적어 다음 단계로 붙인다
  - 기준: 찍어서 확인한다 — 여섯 가지가 선 집 한 채 · 무너진 뒤 · 불러온 뒤

## [ ] G-151 카메라 · 장비칸 — 사람이 플레이하고 짚은 것
- 차선: 3d-lane2 (건축과 안 겹친다)
- spec: spec/02_player/movement-controls.md, spec/01_settings/display.md, spec/02_player/equipment.md, spec/12_ui/hud.md
- 사람이 플레이해 보고 짚었다 (2026-09-26)
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- [ ] 1. 캐릭터를 화면 왼쪽 아래로 — 평소에도 조준할 때도
  - 「총을 조준할 때 캐릭터가 가운데 있어서 표적이 안 보인다. 오른손잡이라 생각하고 캐릭터를 왼쪽 아래로」 ·
    「플레이어가 너무 가운데 있어 부자연스럽다. 왼쪽 아래로 조금」
  - 기준: 평소 카메라에서 캐릭터가 화면 가운데보다 **왼쪽 아래**에 선다 — 조준점(화면 가운데)을 가리지 않는다 (테스트 — 화면 좌표로 잰다)
  - 기준: 우클릭 조준 때도 캐릭터가 조준점을 가리지 않는다 (테스트)
  - 기준: 보이는 범위는 누구에게나 같다(display.md) · 벽에 막히면 당겨진다는 규칙은 그대로다 (테스트)
  - 기준: spec 에 「캐릭터는 왼쪽 아래 — 오른손잡이 어깨 너머 (사람 결정 2026-09-26)」를 적는다
  - 기준: 찍어서 확인한다 — 평소 · 조준 두 장
- [ ] 2. 인벤토리는 핫바를 포함해 20칸 (2줄)
  - 「기본 인벤토리 2줄(20칸)인데 왜 3줄이지」 — **핫바 10 + 가방 한 줄 10 = 20칸** (사람 결정 2026-09-26, 지금은 30칸)
  - 기준: 새 캐릭터의 인벤토리가 핫바 포함 20칸이다. 가방 창에 두 줄이 보인다 (테스트)
  - 기준: **옛 저장본의 21~30칸에 든 물건을 잃지 않는다** — 빈 칸으로 옮기고, 자리가 없으면 캐릭터 발밑에 떨어뜨린다 (테스트)
  - 기준: 무게 규칙 · 줍기 · 칸 옮기기 · 상자 Shift+클릭이 20칸에서 그대로 된다 (테스트)
  - 기준: spec/02_player/inventory-hotbar.md 수치 「가방 30칸」을 「20칸 (핫바 포함, 사람 결정 2026-09-26)」으로
  - 기준: 찍어서 확인한다 — 가방 창이 두 줄이다
- [ ] 3. 장비칸
  - 「인벤토리 칸 위에 있고, 왼쪽에 캐릭터가 보이고 그 주변으로 장비칸이 있는 느낌」
  - 기준: 가방 창의 **인벤토리 칸 위**에 장비 영역이 있다 — **왼쪽에 캐릭터 모습**, 그 둘레에 장비칸 (테스트)
  - 기준: 장비칸은 **신발 · 하의 · 상의 · 모자 · 귀걸이 · 목걸이 · 반지 · 가방** 여덟 (사람 결정 2026-09-26) (테스트)
  - 기준: 그 부위에 맞는 것만 들어간다 — 스파이크 신발은 신발칸 (테스트). 장비칸은 저장본에 담긴다 (테스트)
  - 기준: 칸 이름은 번역 키 (ko · en)
  - 기준: **가방칸에 가방을 끼우면 인벤토리 칸이 는다** (사람 결정 2026-09-26) — 늘어나는 수 · 가방 등급은 임시.
    가방을 빼려는데 늘어난 칸에 물건이 있으면 빠지지 않는다 (잃지 않게) (테스트)
  - 기준: `spec/02_player/equipment.md` 에 여덟 칸 · 가방칸 규칙을 사람 결정으로 적는다. 장비마다의 스탯은 「미정」
  - 기준: 찍어서 확인한다 — 창이 잘리지 않고 1280×720 안에 들어간다

## [ ] G-152 농사가 된다 — 물 주기 · 비료
- 차선: 3d-start (밭은 건축과 같은 놓기 코드를 쓴다)
- spec: spec/04_life/farming.md
- 사람이 플레이해 보고 짚었다 (2026-09-26): 「밭에 물을 어떻게 뿌리는 건지, 비료도 안 되고 되는 게 없다」
- **자가 피드백**: 깨끗해질 때까지 단계를 계속 붙인다
- [ ] 1. 물 주기 · 비료가 게임 안에서 실제로 된다
  - 기준: **빈손에서 시작해** 밭을 놓고 → 심고 → **물을 주고** → 비료를 주고 → 자라 → 수확하는 길을 **실제 입력(클릭 · 키)만으로** 친다 —
    중간에 함수를 직접 부르지 않는다 (테스트)
  - 기준: 물은 어디서 어떻게 얻고 어떻게 뿌리는지 게임 안에서 알 수 있다 — 물을 들고 밭을 겨누면 안내 한 줄이 뜬다 (번역 키) (테스트)
  - 기준: 비료를 주면 무엇이 달라지는지 눈에 보인다 (자라는 속도 · 표시) (테스트)
  - 기준: 안 되는 까닭(물이 없다 · 이미 줬다 · 심지 않았다)을 한 줄로 띄운다 — 「아무 일도 안 일어남」이 없다 (테스트)
  - 기준: 찍어서 확인한다 — 물 준 밭 · 안 준 밭이 달라 보인다

## [ ] G-910 루프가 찾은 것 — 스스로 갚는다 (2차)
- 차선: 3d-lane2 (대화 세션이 나눴다 2026-09-24 — 3d-start 는 건축 쪽, 3d-lane2 는 겹치지 않는 것)
- QA 가 통과시키면서 찾은 것이다. **물어볼 것이 아니면 여기로 온다** (사람 결정 2026-09-22).
  루프가 제 손으로 갚는다 — 사람은 순서를 바꾸고 싶을 때만 손댄다
- 기능을 더하지 않는다. 지키는 것이 없던 자리에 지키는 것을 넣는 일이다
- **차선 2(Fable)가 맡는다** (사람 결정 2026-09-24) — 차선 1(Opus)의 G-145 와 겹치는 것은 G-911 로 뺐다.
  건축(`build/`) · 가방 · 도면 · `player.tscn` · `world/storage/chests.gd` 는 **건드리지 않는다**
- [x] 1. 다쳐서 도망간 뒤 진정하지 않는다 (G-130 단계 3)
  - 기준: 다쳐서 도망간 뒤 진정하지 않는다 — spec/04_life/hunting.md 22행 「한동안 뒤 진정한다」가 아직 없다. panicked() 는 체력만 보므로 30% 아래인 짐승은 영원히 쫓지도 물지도 않고 소리마다 9 m/s 로 달아난다(체력이 차오르는 길도 없다). animal.gd 에 도망 시작 시각을 두고 CALM_AFTER(임시 값, spec 수치 줄에도 「임시」로)가 지나면 panicked() 가 false 가 되게 하라. 테스트: 25% 로 다친 적대가 CALM_AFTER 뒤에 보이는 사람을 다시 CHASE 하는지, 그 전에는 안 하는지 단언하라
- [x] 2. spec 「미정」 줄이 낡았다 (G-130 단계 3)
  - 기준: spec 「미정」 줄이 낡았다 — spec/04_life/hunting.md 68행이 「도망 속도 … 미정」인데 55행에 임시 값 9 m/s 가 섰다. 「도망 속도 (지금 9 m/s 임시)」처럼 고쳐 두 줄이 어긋나지 않게 하라 (막는 것은 아니다)
- [x] 3. 총을 들면 단추의 「(우클릭)」이 틀린다 (G-131 단계 3)
  - 기준: 총을 들면 단추의 「(우클릭)」이 틀린다 — 막는 문제는 아니다. HUNT_BUTCHER 가 「도축 (우클릭)」/「Butcher (Right-click)」인데, 총을 들었을 때 우클릭은 조준이다(사람 결정 2026-09-22, test_right_click_with_a_gun_aims_and_the_button_still_butchers). ButcherPanel._refresh 에서 손에 총이 있으면 「(우클릭)」이 없는 키(예: HUNT_BUTCHER_PLAIN, ko·en 둘 다)를 쓰든지 안내 글자를 없애라. 총을 든 채 패널을 띄웠을 때 단추 글자에 우클릭 안내가 없는지 보는 단언을 test_butchery.gd 에 더하라
- [x] 4. 도축하지 않은 주검이 영원히 남는다 (G-131 단계 3)
  - 기준: 도축하지 않은 주검이 영원히 남는다 — 막는 문제는 아니다. Animal._on_died 가 queue_free 를 하지 않으니 도축하지 않은 사슴(그리고 적대 동물)은 CARCASSES 무리에 쌓이고, Butchery._nearest 는 매 프레임 그 무리를 다 돈다. spec/04_life/hunting.md 「미정」에 「주검이 사라지는 시간」 한 줄을 적어 두고, 임시 값(예: 하루)과 그것을 확인하는 테스트를 넣어라
- [x] 5. 상자에 넣은 짐승은 영영 안 깬다 (G-132 단계 4)
  - 기준: 상자에 넣은 짐승은 영영 안 깬다 — Captives._process 는 가방(player.inventory) 칸만 돌며 게이지를 깎는다. 그런데 world/storage/chest.gd 는 SlotMove.drop 으로 칸을 통째로(kind · sedation · cage 까지) 상자에 옮기므로, 잡은 짐승을 상자에 넣어 두면 게이지가 멈춰 케이지 없이도 영영 가둘 수 있다. 상자에 captive_ 칸을 못 넣게 하거나(Chest 넣기에서 Captives.is_captive 면 거절) 상자 칸도 깎게 하고, test_carry_cage.gd 에 '잡은 짐승을 상자에 넣고 시간이 가도 게이지가 멈추지 않는다(또는 넣을 수 없다)' 단언을 더하라
- [x] 6. 케이지 제작을 실제로 해 보는 테스트가 없다 (G-132 단계 4)
  - 기준: 케이지 제작을 실제로 해 보는 테스트가 없다 — test_three_cages_are_crafted 는 레시피가 있는지만 본다(막는 것은 아니다). 제작대 레시피 경로로 목재 · 철괴를 넣어 cage_small 이 가방에 들어오는지 한 번 보는 단언을 더하라
- [x] 7. 테스트의 안내 줄 아래끝 40 이 박힌 값이다 (G-138 단계 2)
  - 기준: 테스트의 안내 줄 아래끝 40 이 박힌 값이다 — test_chest_window_scroll.gd 의 assert_gte(panel.position.y, 40.0) 와 chest_window.gd TOP_MARGIN 주석이 player.tscn HUD/Hint 의 offset_bottom(40)을 숫자로 베껴 두었다. 안내 줄이 옮겨지거나 두 줄이 되면 테스트는 통과한 채 다시 덮는다. player.tscn 을 불러 HUD/Hint 의 offset_bottom 을 읽어 비교하거나, 적어도 test_ 쪽에 그 값의 출처를 상수로 두고 Hint 의 offset_bottom 과 같은지 보는 단언을 더해라
- [x] 8. chest 찍기에 제작대 창이 남아 겹친다 (G-129 단계 1)
  - 기준: chest 찍기에 제작대 창이 남아 겹친다 — /tmp/g129/after/chest.png 에 앞 자리의 제작대 창이 그대로 깔린다. ui_shots 가 제작대를 먼저 치워 StationWindow._refresh 가 풀린 제작대로 can_start 를 부르는 SCRIPT ERROR 가 난다(보고서 기준, 고치기 전에도 났다). 자리를 바꿀 때 창을 먼저 닫거나 _refresh 에서 is_instance_valid 로 막고, 찍은 로그에 SCRIPT ERROR 가 없는지 보라
- [x] 9. 조준점 겹침은 창이 뜨면 해가 없을 수 있다 (G-129 단계 2)
  - 기준: 조준점 겹침은 창이 뜨면 해가 없을 수 있다 — UIMEASURE 목록 4곳 중 3곳이 Crosshair/H 를 가린다는 줄이다. 창이 열리면 조준점을 숨기는지(게임 쪽) 아니면 재는 검사가 Crosshair 를 가려도 되는 쪽으로 빼야 하는지 G-901 에서 정하고, 어느 쪽이든 목록이 진짜 흠만 뱉게 하라
- [x] 10. 제작대 목록 휠 스크롤이 확인되지 않았다 (G-129 단계 2)
  - 기준: 제작대 목록 휠 스크롤이 확인되지 않았다 — 구현 세션이 headless push_input 휠로 스크롤을 못 움직였다고 적었다. Scroll 이 PASS 라 휠을 받는지, scroll_vertical 을 직접 바꿔 아래 줄이 보이는 자리로 오는지 단언하는 테스트를 test_station_window.gd 에 넣어라
- [x] 11. ui_shots 의 _reset 이 제작대 창을 못 닫는다 (G-129 단계 2)
  - 기준: ui_shots 의 _reset 이 제작대 창을 못 닫는다 — stations.open(null) 은 무시되어 chest 사진에 앞 제련로 창이 남고 can_start SCRIPT ERROR 가 난다(구현 세션 보고). stations.close() 로 바꾸고 찍는 폭 단계에서 chest.png 를 열어 확인하라
- [x] 12. 섬 사진 테스트가 얕다 (G-129 단계 3)
  - 기준: 섬 사진 테스트가 얕다 — test_island_shot_builds_the_real_island 는 island_scene 이 null 이 아닌지만 본다. 세운 뒤 game.island()(세운 섬)가 있고 HUD(hotbar)가 보이는지까지 단언하거나, 이름대로 '섬을 세운다'를 확인하게 고쳐라
- [x] 13. 녹이는 곳 창 바닥이 넓게 비어 있다 (G-901 단계 1)
  - 기준: 녹이는 곳 창 바닥이 넓게 비어 있다 — report 가 남긴 것: 레시피가 둘뿐인데 창이 크게 잡혀 아래가 빈다. 창 높이를 레시피 수에 맞춰 줄이고(제작대 창이 핫바 위에 머무는 규칙은 지킨다) smelter 사진으로 확인한다
- [x] 14. 테스트가 GameRoot 의 밑줄 함수를 직접 부른다 (G-901 단계 1)
  - 기준: 테스트가 GameRoot 의 밑줄 함수를 직접 부른다 — test_window_layout.gd 의 _open · _close_all 과 core/debug/ui_shots.gd 가 game._on_chest_open_changed(...) 를 부른다. 시그널 받는 쪽 함수라 이름이 바뀌면 조용히 깨진다. GameRoot 에 open_chest_window(chest)(null 이면 닫기) 같은 드러난 함수를 두고 셋 다 그것을 부르게 한다
- [x] 15. 낡은 Godot 함수 경고의 출처를 적어 둔다 — `instance_reset_physics_interpolation()` 은 deprecated 다
  - 확인함 (2026-09-24 대화 세션): **우리 GDScript 는 이 함수를 부르지 않는다.** `game/addons/terrain_3d/bin/` 의
    Terrain3D 1.0.2 바이너리 안에서 부른다 — `_build_terrain` 이 Terrain3D 를 만들 때 경고가 뜨는 까닭이다
  - 기준: `game/` 에서 애드온을 뺀 곳에 이 함수가 없다는 것을 검사로 지킨다 (테스트 — 소스를 읽어 본다)
  - 기준: `THIRD_PARTY.md` 의 Terrain3D 줄에 「1.0.2 는 deprecated 함수를 불러 경고가 뜬다 — 새 판으로 올릴 때 사라진다」를 적는다
  - 애드온을 새 판으로 올리는 것은 이 단계가 아니다 (사람이 정한다)
- [x] 16. 갈고리총이 3발이다 — 사람 결정은 4발이다 (2026-09-25 대화 세션 점검)
  - `spec/08_combat/tools-as-weapons.md` 수치 「갈고리총 **4발** (사람 결정 2026-09-22)」인데 `game/life/climbing/grapple.gd:30` 은 `magazine := 3` 이다.
    테스트가 탄창을 상대값으로만 견줘 못 잡았다
  - 기준: 갈고리총에 **4발**이 들어간다 — 숫자 4 를 단언하는 테스트가 있다 (테스트)
  - 기준: `grapple.gd` 의 「임시」 표시를 지운다 — 사람이 정한 값이다. `spec/04_life/climbing.md` 수치 절의 「탄창은 grapple.gd」 줄도 「4발 (사람 결정)」으로 맞춘다
- [x] 14. test.log 합계 한 줄이 어긋난다 (G-910 단계 3)
  - 기준: test.log 합계 한 줄이 어긋난다 — 전체 결과가 Tests 1430 · Passing 1429 · Failing 0 · Pending 0 이라 하나가 어느 쪽에도 안 든다. 단언 없는(GUT 의 risky) 테스트가 하나 있을 것이다. 이번 단계와 무관하다 (test_butchery 는 10개 다 통과·단언 110). test.sh 가 남기는 파일별 로그에서 'risky' 를 찾아 그 테스트에 진짜 단언을 넣어라
- [x] 13. 죽음 상자 안에서는 풀린 짐승의 게이지가 멈춘다 (G-910 단계 5)
  - 기준: 죽음 상자 안에서는 풀린 짐승의 게이지가 멈춘다 — combat/damage_death/death_chest.gd:43 은 가방을 _items 에 통째로 옮기므로 accepts 를 거치지 않는다. 30분 뒤 상자가 사라지니 「영영」은 아니지만(사람 결정 2026-09-16), 열어 두면 상자 시간도 멈추므로 그동안 게이지가 얼어 있다. spec/04_life/hunting.md 「미정」에 「죽었을 때 풀린 짐승 — 죽음 상자에 얼린 채 두나, 그 자리에 놓아 도망가게 하나」 한 줄을 적고, 지금 행동(얼린 채 죽음 상자에 간다)을 test_death_chest.gd 에 단언 하나로 못 박아라
- [ ] 14. 전체 합계에서 테스트 하나가 통과도 실패도 아니다 (G-910 단계 5)
  - 기준: 전체 합계에서 테스트 하나가 통과도 실패도 아니다 — test.log 합친 결과가 Tests 1440 · Passing 1439 · Failing 0 · Pending 0 이다. GUT 의 risky(단언 없는) 테스트가 하나 있는 것으로 보이는데 tools/test.sh 가 임시 폴더를 지워 어느 파일인지 남지 않는다. test.sh 의 합치는 awk 에 Risky 줄도 더하고, Tests 와 Passing+Failing+Pending 이 안 맞으면 그 파일 이름을 맨 뒤에 찍게 하라
- [ ] 12. 줄 · 버퍼 칸 누르기에는 지킴이가 없다 (G-910 단계 8)
  - 기준: 줄 · 버퍼 칸 누르기에는 지킴이가 없다 — station_window.gd 의 _press 와 _collect 는 _station == null 만 보고 _drop_freed() 를 안 부른다. 제작대가 풀린 그 프레임 안(_process 의 _refresh 가 돌기 전)에 줄이나 버퍼 칸이 눌리면 풀린 객체로 start_craft · collect 를 불러 같은 SCRIPT ERROR 가 난다. _press · _collect 첫머리에 _drop_freed() 를 넣고, test_station_window.gd 의 test_a_station_freed_while_the_window_is_open_is_not_asked_anything 에서 station.free() 직후 wait_process_frames 없이 row(AXE).pressed.emit() · buffer_slot(0).pressed.emit() 을 먼저 한 번 더 눌러 조용한지 단언하라 (지금은 station_kind() 가 먼저 불려 null 이 된 뒤에만 누른다)
- [ ] 11. station_window.gd 머리말의 줄 수가 낡았다 (G-910 단계 10)
  - 기준: station_window.gd 머리말의 줄 수가 낡았다 — 25행 「제작대 레시피가 스물 몇 줄이라 화면 아래로 넘쳤다」인데 recipes.json 의 가공대 레시피는 44줄이다(이번 테스트 주석은 「마흔 몇 줄」로 맞다). 「마흔 몇 줄」로 고쳐라 (막는 것은 아니다)
- [ ] 7. test_from_empty_hands 가 회차마다 흔들린다 (G-910 단계 15)
  - 기준: test_from_empty_hands 가 회차마다 흔들린다 — 앞 회차 전체 돌림에서 tests/craft/test_from_empty_hands.gd 가 「wood_foundation 놓을 자리가 water」로 떨어졌다가(줄 905) 이번 회차 전체 돌림에서는 같은 코드로 통과했다. 시드 0 으로 결정적이어야 할 섬 모양이 6개 godot 동시 실행 때 달라지는지, 아니면 토대 자리 짚기가 물리 프레임 타이밍에 걸리는지 원인을 찾아 고정해라 (건축 쪽이라 차선 1 몫이면 G-911 로). 재현: 전체를 두세 번 돌려 그 줄의 why 값을 모아 본다
- [ ] 7. 탄창 주석이 spec 에 없는 말을 한다 (G-910 단계 16)
  - 기준: 탄창 주석이 spec 에 없는 말을 한다 — game/life/climbing/grapple.gd:29 「등급이 생기면 등급표가 덮는다」는 spec/04_life/climbing.md 에 없다. 등급마다 다른 것은 **최대 거리**(사람 결정 2026-09-17)뿐이고 탄창은 4발로 정해졌다. 그 문장을 지워라 (test_the_magazine_is_not_marked_temporary 는 「임시」·「사람 결정」만 보니 지워도 통과한다)
- [ ] 7. test.sh 합계의 Pending 이 늘 0 으로 찍힌다 (G-910 단계 14)
  - 기준: test.sh 합계의 Pending 이 늘 0 으로 찍힌다 — tools/test.sh 끝의 awk 가 '^Pending +[0-9]' 를 찾는데 GUT(addons/gut/summary.gd:64) 는 그 줄을 'Risky/Pending N' 으로 찍고 0 이면 아예 안 찍는다. 그래서 pending·risky 가 있어도 합계에 안 보이고 Tests 와 Passing 만 어긋나 보인다 — 이번 기준의 「하나가 어느 쪽에도 안 든다」가 바로 그것이었다. awk 패턴을 '^(Risky\/)?Pending +[0-9]' 로 바꾸고 $NF 를 더하라. 테스트: pending() 하나만 있는 임시 테스트 파일로 test.sh 를 돌려 합계의 Pending 이 1 로 찍히는지 보는 셸 테스트(tests/ 아래 GD 로 어렵다면 harness/ 의 python 테스트)를 짜라
- [ ] 8. test.sh 가 파일별 로그를 남기지 않는다 (G-910 단계 14)
  - 기준: test.sh 가 파일별 로그를 남기지 않는다 — 기준이 「test.sh 가 남기는 파일별 로그에서 risky 를 찾아라」고 했지만 tools/test.sh 는 mktemp 폴더에 두고 trap 으로 지운다. 구현 세션이 찾을 수 없어 파일마다 godot 을 따로 띄워 되짚었다. 떨어졌을 때만이 아니라 늘 .loop/out/test_files/ 같은 곳에 파일별 로그를 복사해 두거나(하네스 쪽이면 [결정] 아님 — 세션이 tools/test.sh 를 고칠 수 있다), 아니면 위 awk 고침으로 합계에 Risky/Pending 이 보이게 해서 로그 없이도 찾게 하라
- [ ] 9. 지키는 테스트 머리말이 실제 검사보다 세게 말한다 (G-910 단계 14)
  - 기준: 지키는 테스트 머리말이 실제 검사보다 세게 말한다 — test_from_empty_hands_asserts_to_the_end.gd 머리말·단언문은 「중간에 return 으로 빠져 뒤가 비지 않는다」고 하지만 검사는 글자 줄 수만 센다. '# 25.' 바로 아래에 `return` 을 넣어도 통과했다(일부러 깨 봄). 몸통에 들여쓴 `return` 줄이 없는지도 같이 단언하거나(_body_of 결과에서 strip_edges()=='return' 줄 0개), 머리말을 「25번 아래에 단언 글줄이 있다」로 낮춰 적어라
- [ ] 9. 옛 시각 상수가 테스트에 남았다 (G-146 단계 2)
  - 기준: 옛 시각 상수가 테스트에 남았다 — test_day_light.gd 에 DUSK_AT 18.5 · DAWN_AT 5.5 가 새 SUNSET_AT 18.0 과 같이 있다. 앞 테스트(test_brightness_runs_…)가 아직 쓰고 있어서 틀린 것은 아니다. 다만 「노을」이 두 시각이라 읽기가 헷갈린다. 주석에 둘이 무엇이 다른지 한 줄 적거나 하나로 합쳐라
- [ ] 10. Buildings 기본 물 판정이 땅 높이 0 에서 흔들린다 (G-146 단계 2)
  - 기준: Buildings 기본 물 판정이 땅 높이 0 에서 흔들린다 — test_from_empty_hands 는 is_water 를 넣어서 피했다. 그러나 Buildings 의 기본 물음(y < 0)은 윗면이 정확히 0 인 땅에서 광선 오차(-0.000001)로 「water」를 낸다. 기본 판정에 작은 여유(예: y < -0.01)를 두거나, is_water 를 반드시 넣게 하는 편이 낫다. 넣고 나면 평평한 땅(y=0)에서 토대가 water 로 거부되지 않는지 단언하는 테스트를 붙여라

## [ ] G-911 G-910 에서 뺀 것 — G-145 뒤에 한다
- 차선: 3d-lane2 (사람 결정 2026-09-25 — Fable 이 G-910 다음에 하고 멈춘다)
- 건축과 겹치는 것(무너짐 연쇄 테스트 · 밭 거르기 · spec 토대 3×3)은 G-912 로 뺐다 — 차선 1 몫 (사람 결정 2026-09-25)
- G-910 을 차선 2 가 맡으면서 차선 1(G-145 건축)과 겹치는 것을 뺐다 (사람 결정 2026-09-24).
  G-145 가 합쳐진 뒤에 한다. shot.sh 둘은 하네스라 **사람이** 고친다
- [x] 1. shot.sh 기본 해상도가 1280x720 이 아니다 — 대화 세션이 고쳤다 (2026-09-24) (G-129 단계 1)
  - 뺀 까닭: harness/shot.sh — 세션은 하네스를 못 고친다
  - 기준: shot.sh 기본 해상도가 1280x720 이 아니다 — 찍힌 PNG 가 1600x900 이다. 화면은 1280×720 고정(spec/01_settings/display.md)이라 찍는 폭도 그에 맞춰라 (이 묶음 「찍는 폭」 단계의 몫)
- [x] 2. shot.sh 쓰임 줄이 낡았다 — 대화 세션이 고쳤다 (2026-09-24) (G-129 단계 3)
  - 뺀 까닭: harness/shot.sh — 세션은 하네스를 못 고친다
  - 기준: shot.sh 쓰임 줄이 낡았다 — harness/shot.sh 5줄의 자리 목록(hud · bag · workbench · smelter · chest · menu)에 drag · ammo · island 가 없고 _ko/_en 두 장이라는 말도 없다. ui_shots_kit.gd PLACES 를 가리키게 고쳐라
- [ ] 3. 창이 떠 있어도 위 안내 줄이 걷기 안내다 (G-901 단계 1)
  - 뺀 까닭: player.tscn HUD 안내 줄 — G-145 가 player.tscn · 입력 안내를 고치는 중
  - 기준: 창이 떠 있어도 위 안내 줄이 걷기 안내다 — 모든 창 사진 맨 위에 「WASD 이동 · … · Esc 마우스 풀기 · 클릭 다시 잡기」가 그대로 떠 있다. 창이 떠 있을 때는 이 줄을 숨기거나 창 조작 안내로 바꿀지 spec/12_ui/hud.md 를 보고 맞춘다 — spec 에 없으면 「미정」에 한 줄 적어 둔다
- [ ] 4. 테스트가 임시 폴더를 안 지운다 (2026-09-24 대화 세션 점검)
  - $TMPDIR 에 naru_locked_* 155 · naru_key_* 154 · naru_island_animals_* 22 개가 쌓였다 — 돌 때마다 는다
  - 까닭 (확인함): 지우는 코드는 있는데 `_erase` 가 **파일만 지우고 하위 폴더(worlds/)를 못 지운다** — 그래서
    마지막 `remove_absolute(폴더)` 도 실패해 통째로 남는다 (test_locked_island.gd:261 · test_island_key.gd:302)
  - 기준: 임시 폴더를 **하위 폴더까지** 지운다 — 한 곳에 재귀로 지우는 함수를 두고 테스트들이 그것을 쓴다 (테스트: 지운 뒤 폴더가 없다)
  - 기준: 테스트 폴더 전체에서 `OS.get_temp_dir()` 아래 만든 것을 안 지우는 곳이 없다 — 찾아서 같이 고친다
- [ ] 5. 섬 저장본(island_cache)이 옛 판을 안 지운다 (2026-09-24 대화 세션 점검)
  - user://island_cache 에 24 개 · 379MB. 굽는 코드가 바뀔 때마다 새 이름으로 하나씩 는다 (VERSION · SOURCES 해시)
  - 기준: 새로 구워 저장할 때 **같은 섬의 옛 판**을 지운다 — 섬마다 최신 하나만 남는다 (테스트)
  - 기준: 다른 섬(개척 섬 · 시험 섬)의 저장본은 지우지 않는다 (테스트)
  - 기준: 여러 godot 이 한꺼번에 돌 때(tools/test.sh) 남이 쓰는 중인 파일을 지워 터지지 않는다 — 없으면 다시 굽는 것으로 족하다

## [ ] G-912 G-911 에서 뺀 건축 쪽 — 차선 1
- 차선: 3d-start (사람 결정 2026-09-25 — 건축 파일을 만지는 것은 차선 1 한 곳에서)
- G-911 에 있던 셋을 옮겼다. 차선 1 의 G-149 · G-146(설치물 미리보기)과 같은 파일을 만져 차선 2 가 하면 부딪힌다
- [ ] 1. 연쇄 되풀이를 지키는 테스트가 없다 (G-133 단계 3)
  - 뺀 까닭: buildings.gd collapse — G-145 가 건축을 다시 짜는 중
  - 기준: 연쇄 되풀이를 지키는 테스트가 없다 — buildings.gd collapse() 의 while 루프에서 `more = true` 를 지워 한 번만 훑게 해도 tests/build 53개가 다 통과했다. 지금 테스트는 받치는 것이 늘 받쳐지는 것보다 먼저 놓여(무리 순서가 유리해) 한 번 훑기로도 잡힌다. 받침이 나중에 놓인 경우를 짜라: 토대 A · 벽 W1(A) · 지붕 R1 · R1 위 기둥 P · 지붕 R2 를 놓은 뒤, 옆 토대 C 와 R1 을 받치는 벽 W2(C) 를 나중에 놓고 W1 을 손으로 부순다. 그다음 C 를 부수면 W2 · R1 · P · R2 가 전부 무너지는지 단언하라 (한 번 훑기면 R1 · P · R2 가 떠서 남는다)
- [ ] 2. 밭 거르기가 지형 확인이 아닌 제외 목록이다 (G-134 단계 2)
  - 뺀 까닭: 밭 거르기 — G-145 단계 4 가 밭 크기를 바꾼다
  - 기준: 밭 거르기가 지형 확인이 아닌 제외 목록이다 — 앞 단계 QA 는 「collider 가 지형(또는 흙판)일 때만」 치라고 했는데, is_field_ground 는 몸통 · Placeable · 절벽 법선 · 높이(GROUND_TOLERANCE 0.5m 임시)로 걸러낸다. 테스트 땅과 장애물이 둘 다 맨 StaticBody3D 라는 까닭은 이해되나, 윗면이 0.5m 아래인 낮은 몸통(바위 · 작은 자원 노드)이 밭 칸에 걸쳐 있으면 그 윗면을 쳐도 밭이 깎인다. 막는 것은 아니다. 섬 지형·자원 노드에 그룹이나 메타를 달아 받아들일 것을 지형으로 좁히거나, 낮은 StaticBody3D(높이 0.3m)를 밭 위에 세우고 HITS 번 쳐도 is_tilled 가 참인지 보는 테스트를 더하라
- [ ] 3. spec 에 토대 3×3 이 남았다 (2026-09-24 md 점검)
  - 뺀 까닭: G-145 가 같은 spec 을 고치는 중
  - 기준: `spec/04_life/farming.md` 「토대 한 장(3×3칸) 위에 아홉 칸」을 4×4 · 네 장으로 고치고, 「미정」에 들어간 사람 결정(밭 2×2)을 규칙 절로 옮긴다
  - 기준: `spec/06_build/rooms.md` 「가장 작은 방은 토대 한 장(3×3칸)」을 4×4 로 고친다 — 사람 결정 줄이므로 날짜를 붙여 「3×3 에서 키웠다」로 남긴다
  - 기준: `spec/06_build/building.md` 의 옛 줄 「건축물 = 벽 · 문 · 지붕 · 계단」을 지운다 — 위에 여섯 가지가 이미 있다
  - 기준: spec 에 「3×3」이 토대 크기로 남은 곳이 없다 (grep)

## [ ] G-990 점검 — 한 바퀴 돌아보고 빠진 것을 찾는다
- 차선: 3d-start (대화 세션이 나눴다 2026-09-24 — 3d-start 는 건축 쪽, 3d-lane2 는 겹치지 않는 것)
- **자가 피드백**: 찾은 것을 단계로 계속 붙인다 (사람 결정 2026-09-23)
- **목록이 비었을 때 도는 자리다.** 기능을 새로 만들지 않는다 — **끊긴 곳 · 빠진 것을 찾아 잇는다**
- 보는 법 셋: ① 한 바퀴 테스트(G-903)를 돌려 어디서 막히는지 ②`harness/shot.sh --ui` 로 창을 찍어
  눈으로 ③ spec 의 「수용 기준」을 훑어 **적혀 있는데 없는 것**을 찾는다
- 사람에게: 루프가 「할 일을 모두 처리했다」로 끝나면 **이 묶음을 다시 `[ ]` 로 열면** 또 한 바퀴 돈다
- [ ] 1. 한 바퀴 돌아본다
  - 기준: 위 셋으로 훑고, **빠진 것 · 끊긴 곳을 목록으로** 뱉는다 (report 에 적는다)
  - 기준: 그중 **그 자리에서 고칠 수 있는 것**은 고친다 (테스트)
  - 기준: 나머지는 QA 가 적어 다음 단계로 붙인다 — 깨끗해질 때까지

## 다음 — 위가 끝난 뒤 대화로 적는다
- **사람이 직접 플레이해 보는 자리다** — 루프가 할 일이 아니다 (2026-09-21).
  로드맵 한 바퀴: 생활 → 보급 → 배 → 새 자원 → 더 나은 생활
- 사람이 봐 둔 것 (2026-09-21): **치는 티가 안 난다** — 맨손 20대 · 도끼 4대를 치는 동안
  흔들림 · 소리 · 내구도(균열) 표시가 없다 (`struck` 신호를 듣는 곳이 없다). 디자인 단계에서 같이 본다
- 선착장: **내 섬 것은 플레이어가 짓고, 개척 섬 것은 맵에 박혀 있다** (spec/03_world/frontier-islands.md)
- **나아가는 순서** (사람 결정 2026-09-24, spec/00_core/roadmap.md) — **메인섬 → 옆섬 무역 개통 → 원정섬(맨 마지막)**
  - 1단계에 남은 것: **낚시** · **동물 세분화**(동물 목록은 사람이 정리해 준다 — G-148 뒤)
  - **NPC 가 기계(자동화)보다 먼저다** — 이벤트로 하나씩 들어오는 일손 (spec/07_automation/npc-villagers.md)
  - 2단계 「무역」은 spec 에 아직 없다 — 사람이 정해 준 뒤에 묶음으로 올린다
  - 섬 모양은 사람과 같이 다시 빚는다
- **멀티플레이를 할 때 같이**: 데스 상자에 주인이 없다 — `spec/08_combat/damage-death.md` 의
  「죽은 본인만 열고 꺼낼 수 있다」가 코드에 없다. 지금은 혼자뿐이라 드러나지 않는다 (루프가 찾음 2026-09-21)
- 그 밖: 광산 · 목장 · 펫 · 도감 · 날씨 · 멀티 · 경제 (roadmap.md 「빼는 것」)
