# 할 일 목록

사람과 Claude 가 대화로 채운다. 루프가 위에서부터 **순서대로** 처리하고 체크한다.
루프 세션은 이 파일을 읽지 않는다 — 루프가 지금 할 단계만 `current.md` 로 뽑아 준다.

## 형식

- `## [ ] ID 제목` — 묶음. 한 묶음 = 브랜치 하나. 단계가 전부 통과해야 main 에 합친다
- `- [ ] 1. 단계 제목` — 단계. 한 단계 = 루프 한 회차
- `  - 기준: ...` — 수용 기준 (QA 채점표). 단계 밑에 들여 쓴다
- `  - ...` — 기준이 아닌 참고
- 묶음 제목 바로 밑 `- spec: ...` · `- 결정: ...` — 묶음 전체에 붙는 정보
- 표시: `[ ]` 할 일 · `[x]` 끝남 · `[>]` 결정 대기로 넘어감 (`decisions.md`)
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

## [ ] G-125 선착장 — 기둥을 겨눈다 · 개척 섬은 부서진 채로 시작한다
- spec: spec/03_world/frontier-islands.md, spec/06_build/building.md
- 결정: 기둥을 겨눠 부순다 · 개척 섬 선착장은 부서진 채로 시작하고 **연구대 해금 아이템**으로 연다
  (사람 결정 2026-09-22 — 처음부터 배로 오가는 것을 막는다)
- [ ] 1. 기둥을 겨눈다
  - 기준: 내가 지은 선착장은 물가 쪽 기둥을 겨눠 부순다. 부수면 선착장이 그대로 돌아온다 (테스트)
  - 기준: 널판에는 몸통이 없다 — 배에서 내린 캐릭터가 끼이지 않는다 (테스트)
  - 기준: 맵에 박힌 선착장은 부술 수 없다 (테스트)
- [ ] 2. 개척 섬은 부서진 채로 시작한다
  - 기준: 새 월드에서 개척 섬 선착장은 기둥만 서 있다 (테스트)
  - 기준: 잠긴 섬으로는 배가 가지 않는다 — 내 섬 선착장에서 타도 안 간다 (테스트)
  - 기준: 글자는 전부 번역 키다 (ko · en 둘 다)
- [ ] 3. 연구대 열쇠로 연다
  - 기준: 해금 아이템은 **연구대에서만** 만들어진다 — 다른 제작대에서는 나오지 않는다 (테스트)
  - 기준: 그것을 선착장에 넣으면 널판이 깔리고 배가 간다 (테스트)
  - 기준: 열린 것이 저장본에 남는다 — 나갔다 들어와도 열려 있다 (테스트)
  - 해금 아이템의 재료는 임시다 (spec 미정)

## [ ] G-900 루프가 찾은 것 — 스스로 갚는다
- QA 가 통과시키면서 찾은 것이다. **물어볼 것이 아니면 여기로 온다** (사람 결정 2026-09-22).
  루프가 제 손으로 갚는다 — 사람은 순서를 바꾸고 싶을 때만 손댄다
- 기능을 더하지 않는다. 지키는 것이 없던 자리에 지키는 것을 넣는 일이다
- [ ] 1. test_enter_game.gd:109 test_the_other_world_did_not_get_t… (G-102 단계 3)
  - 기준: test_enter_game.gd:109 test_the_other_world_did_not_get_the_items 는 늘 참인 테스트다 — WorldData.to_dict() 는 {name, seed, created_at} 리터럴을 돌려주므로 'inventory' in w.to_dict() 는 어떤 코드에서도 false 다. 기준 3 은 다른 테스트가 제대로 막고 있어 통과지만, 이 테스트는 아무것도 지키지 않는다. 인벤토리가 캐릭터에만 붙는다는 것을 정말 보려면 '월드 A 에서 넣고 저장한 뒤 다른 캐릭터로 같은 월드 A 에 들어가면 인벤토리가 비어 있다'를 확인하게 고쳐라
- [ ] 2. 「비우면 무작위」를 UI 를 거쳐 확인하는 테스트가 없다 (G-102 단계 3)
  - 기준: 「비우면 무작위」를 UI 를 거쳐 확인하는 테스트가 없다. test_empty_seed_is_random 은 WorldCreate.seed_from('') 를 직접 부르고, test_empty_seed_still_saves_the_world 는 이름과 오류 표시만 볼 뿐 저장된 world_seed 를 보지 않는다. _on_create_pressed 가 w.world_seed 넣는 줄을 빠뜨려도 두 테스트 다 통과한다. test_empty_seed_still_saves_the_world 에 '시드 칸을 비우고 만든 월드 둘을 저장본에서 읽으면 world_seed 가 서로 다르다'를 더해라
- [ ] 3. Player._ready() 가 조건 없이 Pointer.set_captured(true) 를 한다 (G-103 단계 5)
  - 기준: (기준은 통과했다 — 다음 단계에서 터질 것들이다) Player._ready() 가 조건 없이 Pointer.set_captured(true) 를 한다. 설정 창이 떠 있는 동안 플레이어가 씬에 들어오면 커서를 도로 뺏는다. 지금은 GameRoot 안에 플레이어가 없어 드러나지 않지만, 섬·플레이어를 GameRoot 에 붙이는 단계에서 「창이 떴는데 커서가 사라진다」로 나온다. 붙일 때 GameRoot 가 창 상태를 보고 커서를 정하게 하고, 그 경우를 보는 테스트를 같이 짜라.
- [ ] 4. GameRoot.set_menu_open(false) 이 씬 안 모든 Player 의 controls_… (G-103 단계 5)
  - 기준: GameRoot.set_menu_open(false) 이 씬 안 모든 Player 의 controls_enabled 를 무조건 true 로 되돌린다. debug_tools.gd:65 도 같은 값을 쓰므로, 디버그 비행 카메라를 켠 채 ESC 를 열었다 닫으면 꺼 뒀던 조작이 되살아난다. 지금은 디버그 도구가 시험 섬에만 있어 부딪히지 않는다 — 두 곳이 한 씬에 모이는 단계에서 「누가 껐나」를 세는 방식(이유별 잠금)으로 바꾸고 테스트를 붙여라.
- [ ] 5. 클릭 차단은 창이 실제로 삼키는 것을 확인하지 못했다 (G-103 단계 5)
  - 기준: 클릭 차단은 창이 실제로 삼키는 것을 확인하지 못했다. headless 에는 커서가 없어 Godot GUI 판정이 안 돌기 때문에, 지금 테스트는 「좌클릭의 유일한 효과인 커서 재잡기가 안 일어난다」로 대신 본다. G-105 에서 좌클릭이 평타가 되면 이 확인이 비어 버린다 — 평타를 넣을 때 「창이 떠 있으면 평타가 안 나간다」를 직접 보는 테스트를 같이 짜라.
- [ ] 6. 막 색 Color(0,0,0,0.55) 가 pause_menu.tscn 안에 있어 「임시」 표시를 달… (G-103 단계 5)
  - 기준: 막 색 Color(0,0,0,0.55) 가 pause_menu.tscn 안에 있어 「임시」 표시를 달 수 없다. report.json 에만 적혀 있어 다음 사람이 보기 어렵다 — pause_menu.gd 머리말에 「막 색은 임시, 디자인은 사람이 나중에」 한 줄을 남겨라.
- [ ] 7. bag.tscn 안의 수치 두 개에 「임시」 표시가 없다 (G-105 단계 2)
  - 기준: 막는 것은 아니다. bag.tscn 안의 수치 두 개에 「임시」 표시가 없다 — Dim 의 알파 0.55 와 Window CanvasLayer 의 layer = 5 다. report.json 의 temporary 에는 적혀 있지만 .tscn 을 여는 사람은 그걸 못 본다. bag.gd 머리글 주석에 덮개 색과 레이어 값이 임시라는 줄을 한 줄 보태라 (SLOT_SIZE 는 이미 잘 적혀 있다).
- [ ] 8. 제작대 이름 다섯(ITEM_workbench · smelter · cook_table · cook_st… (G-106 단계 1)
  - 기준: 제작대 이름 다섯(ITEM_workbench · smelter · cook_table · cook_stove · research_bench)이 ko.po · en.po 에 있는지 보는 테스트가 없다. 지금 두 파일에 다 들어 있어 게임 글자는 맞지만, stations.json 은 「한 줄 더 적으면 코드를 안 고쳐도 나타난다」가 설계다 — 다음에 한 줄 더 적으면 화면에 번역 안 된 ITEM_xxx 날글자가 그대로 뜨고 아무도 안 잡는다. 도구 쪽에는 이미 그 테스트가 있다 (game/tests/combat/tools_as_weapons/test_tools.gd:90-94 — 카탈로그를 훑어 po 두 개에 ITEM_<이름> 이 있는지 본다). 같은 모양으로 StationCatalog.load_from().keys() 를 훑어 ko.po · en.po 둘 다에 ITEM_<key> 가 있는지 보는 테스트를 test_stations.gd 에 하나 더 짜라.
- [ ] 9. 레시피 결과물의 번역 키를 지켜 주는 테스트가 없다 (G-106 단계 2)
  - 기준: 레시피 결과물의 번역 키를 지켜 주는 테스트가 없다. recipes.json 에 줄을 하나 더 적으면(이번 기준이 바로 그것이다) ITEM_<output> 이 ko.po · en.po 에 없어도 아무도 안 잡고, 화면에는 번역 키가 그대로 뜬다. game/tests/combat/tools_as_weapons/test_tools.gd:94 가 하는 방식대로 recipes.json 의 output 마다 두 po 파일에 키가 있는지 보는 테스트를 짜라. (지금 있는 네 개 plank · stone_block · iron_ingot · sulfur 는 한국어 · 영어 둘 다 들어 있다.)
- [ ] 10. CraftingStation.craft_progress() 와 craft_recipe() 는 부르는 곳… (G-106 단계 2)
  - 기준: CraftingStation.craft_progress() 와 craft_recipe() 는 부르는 곳도 테스트도 없다 (craft_progress 는 쓰는 곳 0). 제작 창을 만들 때 쓸 것이면 그때 테스트와 함께 살리고, 안 쓸 것이면 지워라.
- [ ] 11. 절벽 기울기 45° (Farmland.MAX_SLOPE_DEG, game/life/farming/far… (G-107 단계 1)
  - 기준: 절벽 기울기 45° (Farmland.MAX_SLOPE_DEG, game/life/farming/farmland.gd:28-30) 가 report.json 에는 임시 수치로 적혀 있는데 코드 주석에는 「임시」가 없다. REACH · 흙판 두께 · 설치물 한 칸 주석은 전부 「임시 — … 미정이다」 꼴로 적혀 있으니(stations.gd:24 · harvest.gd:31 과 같은 투) 같은 꼴로 고쳐라: spec/04_life/farming.md 에 절벽 수치가 없다는 것과, 걸어 오르지 못하는 기울기(IslandShape.is_step_walkable)에 맞춰 둔 값이라는 것을 주석에 적으면 된다. 값 자체는 바꿀 것 없다.
- [ ] 12. 진짜 섬에서 물 자리가 막히는지 보는 테스트가 없다 (G-107 단계 1)
  - 기준: 진짜 섬에서 물 자리가 막히는지 보는 테스트가 없다. 물 판정은 두 조각으로 나뉘어 각각만 확인된다 — Farmland 쪽은 가짜 is_water 를 꽂아서(test_water_cannot_be_tilled), 섬 쪽은 Farmland 없이(test_island_shape.test_water_spots_are_under_water). 둘을 잇는 줄(game/world/terrain/test_island.gd:181 의 is_water 람다)은 어느 테스트도 지나가지 않는다 — 좌표를 잘못 넘기거나(Vector2(pos.x, pos.z)) 배선을 빠뜨려도 286개가 다 통과한다. test_island_walk 에 한 줄짜리 테스트를 더해라: 연못 한가운데 섬 좌표를 골라 island.farmland.is_water.call(Vector3(c.x, 아무 높이, c.z)) 가 참이고 스폰 자리는 거짓인지 본다. 다음 단계(심기 · 물 주기)가 이 배선 위에 얹히므로 지금 박아 두는 편이 싸다.
- [ ] 13. 「물은 하루치다 (G-107 단계 2)
  - 기준: 「물은 하루치다 — 준 다음 날 다시 마른다」가 임시라고 코드에 적혀 있지 않다. spec/04_life/farming.md 미정 줄이 「물 마름 규칙 미정」이라고 적고 있고 report.json 도 임시로 꼽았는데, crops.gd:133~134 의 next_day() 주석은 그냥 규칙처럼 적혀 있다. 같은 파일의 count(31줄) · 크기와 색(37줄)처럼 「임시다 — 물 마름 규칙 미정 (spec/04_life/farming.md)」 한 줄을 next_day() 주석에 넣어라. 코드 동작은 고치지 않는다.
- [ ] 14. 작물 아이템의 번역을 지키는 테스트가 없다 (G-107 단계 2)
  - 기준: 작물 아이템의 번역을 지키는 테스트가 없다. ko.po · en.po 에 ITEM_wheat · ITEM_wheat_seed 가 둘 다 들어 있지만(확인함), 도구 쪽은 test_tools.gd:94 가 tools.json 의 모든 key 에 대해 ko·en 둘 다 있는지 세는 반면 작물 쪽은 아무도 안 본다. test_crops.gd 에 Crops.CROPS 의 작물 이름과 씨앗 이름마다 ITEM_<이름> 이 두 po 에 다 있는지 세는 테스트를 하나 더해라 — 작물을 늘릴 때 번역 빠진 것이 그때 잡힌다.
- [ ] 15. 막는 것은 아니지만 다음에 메우면 좋다 (G-108 단계 2)
  - 기준: 막는 것은 아니지만 다음에 메우면 좋다 — 섬 배선을 지키는 테스트가 없다. test_island.gd 의 _build_food() 가 하는 두 가지(player.buffs = buffs 로 걸음에 버프를 잇는 것, Food 를 밭 · 제작대보다 뒤에 붙여 먹은 우클릭이 작물까지 가지 않게 하는 것)를 어떤 테스트도 보지 않는다. test_food.gd 의 ClickWatcher 는 제 손으로 지은 나무에서만 순서를 확인하므로, 누가 _build_food() 를 _build_crops() 앞으로 옮기거나 player.buffs 줄을 지워도 326개가 전부 통과한다(report.json 의 「그 순서가 깨지면 걸리도록 테스트를 뒀다」는 섬까지는 덮지 못한다). 고치는 법: test_island_walk.gd 에 G-107.1 의 test_tilling_bare_ground_on_the_real_terrain 과 같은 꼴로 한 개를 더한다 — 스폰 앞 밭에 다 자란 밀을 하나 두고, 빵을 손에 든 채 우클릭해서 (가) 빵이 한 개 줄고 island.player.speed_multiplier() 가 파일 값이 되고 (나) 그 작물은 그대로 남아 있는지 본다.
- [ ] 16. game/world/terrain/island_shape.gd 의 marks() 앞 주석이 아직 「굽는… (G-109 단계 2)
  - 기준: (막는 문제 아님 · 낡은 줄) game/world/terrain/island_shape.gd 의 marks() 앞 주석이 아직 「굽는 동안 쓰는 표시」라고 적혀 있다. 바로 위 _raw · _beach · _wet 필드 주석은 「땅을 읽는 표시 … 저장본에도 담는다」로 고쳐졌으니 둘이 어긋난다. marks() 주석도 「자원을 다시 깔 때 쓰는 표시」로 맞춰라
- [ ] 17. 진짜 섬의 배선(world/terrain/test_island.gd 의 _build_death)을 보는… (G-110 단계 2)
  - 기준: 진짜 섬의 배선(world/terrain/test_island.gd 의 _build_death)을 보는 테스트가 하나도 없다. death.player 와 death.spawn = spawn_position() 이 거기서만 정해지는데, 그 두 줄이 틀려도(예: spawn 을 안 넣어 Vector3.ZERO 로 남아 바다 한가운데서 살아나도) 415개가 전부 통과한다. tests/world/terrain/test_island_in_game.gd 에 섬을 세운 채 죽여서 상자가 떨어지고 섬의 spawn_position() 자리에 다시 서는지 보는 검사를 하나 붙여라
- [ ] 18. GameRoot 가 붙이는 death.respawned → _apply_input_block(창을 열어… (G-110 단계 2)
  - 기준: GameRoot 가 붙이는 death.respawned → _apply_input_block(창을 열어 둔 채 죽었다 살아나면 조작을 도로 막는다)을 확인하는 테스트가 없다. 설정 창을 연 채 죽이고 살아난 뒤 player.controls_enabled 가 false 인지 보는 검사를 tests/settings/test_world_settings_in_game.gd 또는 test_island_in_game.gd 에 붙여라
- [ ] 19. 게임 기준과 별개로 껍데기 테스트가 하나 있다 (G-111 단계 1)
  - 기준: 게임 기준과 별개로 껍데기 테스트가 하나 있다 — game/tests/life/climbing/test_climbing.gd:87 test_a_walkable_slope_is_not_a_cliff 는 비탈에 닿지도 못한다. before_each(13줄)가 z=-3 에 80m 높이 벽(x -20..20, 앞면 z=-2)을 이미 세워 두는데, 이 테스트는 그 벽을 그대로 둔 채 30° 비탈을 z=-22 에 놓고 플레이어를 (20, 0.3, 0) 에 세워 1.0초만 앞(-z)으로 걷게 한다. 비탈은 기울어 파묻혀 있어 땅 위로 드러나는 곳이 z≈-20 부터인데, move_speed 6.0 으로 1.0초면 최대 6m 라 z≈-6 까지밖에 못 가고 그마저 z=-2 의 벽이 막는다. 즉 assert_false 는 비탈과 아무 상관 없이 참이다. 그래서 climbing.gd _wall_ahead 의 「n.angle_to(Vector3.UP) < floor_max_angle_deg 면 절벽이 아니다」 걸러내기를 확인하는 테스트가 하나도 없다 — 그 줄을 지워도 433개가 전부 통과한다. 고칠 것: 앞을 막는 벽이 없는 자리에 비탈을 두고(또는 플레이어를 비탈이 땅 위로 드러난 발치에 바로 세우고) 걸어 붙어 보게 하라. 짠 뒤에는 _wall_ahead 의 각도 검사 줄을 잠깐 지워서 그 테스트가 실제로 실패하는지 확인해 껍데기가 아님을 보여라. 플레이어를 x=20 — 벽의 정확히 모서리 — 에 세우는 것도 걷어라, 붙고 안 붙고가 광선이 모서리를 스치느냐에 달려 있어 흔들린다.
- [ ] 20. 땅에서 기력이 차는 규칙이 spec 에 없다 (G-111 단계 1)
  - 기준: 땅에서 기력이 차는 규칙이 spec 에 없다. stamina.gd recover_per_second = 20/초 로 땅을 딛고 있으면 기력이 차게 해 두었고 코드에는 임시라 적혀 있지만, spec/04_life/climbing.md 는 회복을 앵커로만 적고 「미정」에도 땅 회복이 없다. spec/04_life/climbing.md 의 「미정」에 한 줄을 넣어라 — 예: 「땅에서도 기력이 차나 (임시: 찬다 — 안 그러면 한 번 지친 뒤 영영 못 오른다)」.
- [ ] 21. test_my_island_grows_twenty_herbs:30 도 test_ledges_are_ca… (G-112 단계 1)
  - 기준: 작은 것 · 다음 단계를 막지는 않는다: 「20」이라는 사람 결정 수를 어느 테스트도 못 박지 않는다. test_my_island_grows_twenty_herbs:30 도 test_ledges_are_carved_into_cliffs:123 도 blueprint.herb_spot_count 와 견줄 뿐이라, 누가 island_blueprint.gd:83 을 12 로 바꿔도 테스트가 다 통과한다 — spec/04_life/gathering.md:11 의 「내 섬에 20곳 (사람 결정 2026-09-19)」이 소리 없이 무너질 수 있다. 고치는 법: test_herbs.gd 나 test_project_setup 류에 assert_eq(IslandBlueprint.new().herb_spot_count, 20, "사람 결정 2026-09-19") 한 줄을 넣어 숫자 자체를 못 박아라. (이 저장소에 이미 있던 관례라 이번 단계에서 새로 생긴 흠은 아니다.)
- [ ] 22. player.gd 의 주석 두 줄이 어긋났다 (G-112 단계 2)
  - 기준: (통과를 막는 문제는 아니다 — 다음에 이 파일을 건드릴 때 같이 고치면 된다) player.gd 의 주석 두 줄이 어긋났다. 첫째, 「## 이 캐릭터의 절벽 등반 (spec/04_life/climbing.md) — 붙어 있나 · 기력이 얼마나 남았나.」는 원래 climbing() 의 설명인데 새 skill_check_ring() 위로 밀려 올라갔다. 지금 climbing() 은 설명이 없고, skill_check_ring() 은 절벽 등반 설명을 달고 있다. 등반 줄을 climbing() 바로 위로 되돌려라 (player.gd:179 · 186). 둘째, skill_check_ring() 에 남은 「무엇을 들여다볼지는 섬이 이어 준다 (world/terrain/test_island.gd 의 _build_gathering)」는 사실과 다르다 — _build_gathering 은 gathering.player 만 넣고 watch() 를 부르지 않으며, 이어 붙이는 것은 Gathering._ready 다 (gathering.gd:42~43). gathering.gd:40~41 이 「이어 주는 일을 섬에 맡기면 섬 밖에서 세울 때마다 빠뜨린다」고 일부러 적어 둔 것과 정면으로 어긋나, 이 주석을 믿고 섬에 watch() 를 넣으려 드는 다음 세션을 함정에 빠뜨린다. 「채집(life/gathering/gathering.gd)이 제 _ready 에서 스스로 이어 붙는다」로 고쳐라.
- [ ] 23. 유황 섬 설계 값 game/world/frontier_islands/sulfur_island_bluep… (G-113 단계 1)
  - 기준: 막는 것은 아니다 — 유황 섬 설계 값 game/world/frontier_islands/sulfur_island_blueprint.tres 가 「회색 초안」이라는 표시가 파일 쪽 어디에도 없다. report.json 에만 적혀 있는데 report 는 다음 회차에 지워진다. islands.json 의 _temporary 줄에 「sulfur 설계 값은 전부 임시 — 섬 모양은 사람이 같이 빚는다 (list.md G-113)」를 한 줄 더 적어라. 다른 임시 수치(Dock.REACH 7m · PLANK · dock_angle_deg · 제작대가 만들던 것을 안 담는다)는 코드와 islands.json 에 「임시」로 적혀 있어 문제없다.
- [ ] 24. test_cliffs_ring_the_volcano 는 절벽 띠 설정에 둔하다 (G-113 단계 2)
  - 기준: (막는 것 아님) test_cliffs_ring_the_volcano 는 절벽 띠 설정에 둔하다 — cliff_coverage 를 0.9→0 으로 놓아 절벽 띠를 통째로 꺼도 11개가 그대로 통과했다 (335/360). 가파른 원뿔 비탈만으로도 45°+ 8m 벽면이 서기 때문이라 기준(둘레에 절벽) 자체는 지켜지지만, cliff_step · cliff_coverage 가 사라져도 아무도 못 알아챈다. 화산 모양을 다시 만질 때 「걸어 오를 수 없는 벽면이 단으로 끊겨 있다」를 보는 잣대(예: walk_reach 로 산비탈 대부분이 스폰에서 닿지 않는다)를 하나 더하면 좋다.
- [ ] 25. 임시 표시가 분화구 값에만 붙어 있다 (G-113 단계 2)
  - 기준: (막는 것 아님) 임시 표시가 분화구 값에만 붙어 있다. island_blueprint.gd 의 crater_* 에는 「임시」가 적혀 있지만 화산 몸통(mountain_height 170 · mountain_radius 200 · mountain_profile 1.0 · ridge_strength 0.35)과 둘레 절벽(cliff_step 32 · cliff_coverage 0.9 · path_angle_deg 20)은 어디에도 임시라고 적혀 있지 않다. spec/03_world/frontier-islands.md 의 「분화구 크기 · 깊이는 임시」를 「설계 값은 모두 임시 — 사람이 같이 다듬는다」로 넓혀라.
- [ ] 26. test_from_empty_hands_to_the_first_axe 의 1단계(맨손으로 나무·돌 캐기… (G-114 단계 1)
  - 기준: 가벼운 것 하나 — test_from_empty_hands_to_the_first_axe 의 1단계(맨손으로 나무·돌 캐기)만 실제로 치지 않고 game.inventory.add() 로 건너뛴다. 맨손 채집은 test_harvest.gd 가 따로 보고 있어 사슬 자체는 끊기지 않았지만, 「빈손에서」가 한 테스트 안에서 끝까지 이어지려면 나중에 여기서도 좌클릭으로 나무·돌을 쳐서 줍는 대목을 넣으면 더 단단하다. 이번 통과를 막는 것은 아니다
- [ ] 27. 다음에 건드릴 때 같이 보면 좋을 것: TestIsland.dock_position() 은 dock 이… (G-114 단계 3)
  - 기준: 막는 것은 아니다 (기준은 다 통과했다) — 다음에 건드릴 때 같이 보면 좋을 것: TestIsland.dock_position() 은 dock 이 null 이면 터진다. 저장을 일부러 깼을 때 test_going_back_to_the_frontier_island_finds_it_as_i_left_it 이 'Invalid access to property global_position on Nil' 로 죽었다. 지금은 선착장 없이는 섬을 떠날 수 없어 닿지 않는 길이지만, 앞으로 선착장을 부수거나 옛 저장본을 읽게 되면 배에서 내리다 게임이 죽는다. dock 이 없으면 스폰 자리로 내리게 두는 편이 안전하다.
- [ ] 28. 쓰레기 파일이 남았다 (G-115 단계 1)
  - 기준: 쓰레기 파일이 남았다 — game/tests/ui/hud/test_zz_probe.gd.uid 가 짝이 되는 .gd 없이 혼자 남아 있다. 구현 중에 헤드리스 마우스를 떠보던 검사를 지우면서 .uid 만 안 지운 것이다. 그대로 두면 다음 커밋에 쓸모없는 파일이 섞여 들어간다 — rm game/tests/ui/hud/test_zz_probe.gd.uid 로 지워라
- [ ] 29. E 가 개발용 비행 카메라의 debug_up 과 겹친다 (G-115 단계 1)
  - 기준: E 가 개발용 비행 카메라의 debug_up 과 겹친다 — project.godot 에서 inventory 와 debug_up 둘 다 physical_keycode 69 다. F1 로 비행 중에 E 를 누르면 올라가면서 가방도 같이 열린다. 구현 세션이 알고 적어 뒀고(이번 기준 밖이라 안 고쳤다) 개발용 키라 게임에는 안 나온다. 다음에 손댈 때 debug_up 을 다른 키(예: Space 나 R)로 옮기면 된다 — 사람이 정할 일이면 needs_decision 으로 올려라
- [ ] 30. Tab 이 더는 가방을 열지 않는다는 것을 지키는 검사가 없다 (G-115 단계 1)
  - 기준: Tab 이 더는 가방을 열지 않는다는 것을 지키는 검사가 없다. 기준의 「Tab 에서 옮겼다」 쪽을 되돌아가지 않게 막으려면 test_bag.gd 의 test_e_is_bound_to_the_inventory_action 에 한 줄을 더해라 — InputMap.action_get_events(InputActions.INVENTORY) 안에 physical_keycode == KEY_TAB 인 것이 하나도 없다는 단언. 지금 코드는 맞게 되어 있어 이번 기준은 통과지만, 누가 Tab 을 다시 넣어도 아무도 못 잡는다
- [ ] 31. 막대 폭이 두 곳에 적혀 있다 (G-115 단계 2)
  - 기준: 막대 폭이 두 곳에 적혀 있다 — health_bar.gd 의 WIDTH(240) 와 health_bar.tscn 의 자리 폭(offset_left 16 · offset_right 256 = 240) 이 같아야 하는데, 어긋나도 아무도 안 잡는다. tscn 의 offset_right 를 256→416 으로 놓아(자리 폭 400) 돌려 보니 8개가 다 통과했다 — 체력이 가득 차도 막대는 자리의 60% 만 차는데 fill_ratio() 는 그대로 1.0 이다. WIDTH 를 지우고 _fill.offset_right = size.x * ratio 처럼 제 자리 폭에서 가져오게 하거나(resized 도 받아), 막대가 자리를 꽉 채우는지 보는 테스트를 하나 넣어라. (막는 것은 아니다 — 지금 두 값은 맞다)
- [ ] 32. 쓰는 곳이 없는 clock() 접근자 (G-115 단계 2)
  - 기준: 쓰는 곳이 없는 clock() 접근자 — game_root.gd:226 에 func clock() -> GameClock 을 새로 냈는데 게임에도 테스트에도 부르는 곳이 한 곳도 없다 (clock_label() 은 테스트가 쓴다). 다음 단계에서 쓸 자리가 확실치 않으면 지워라.
- [ ] 33. 키 표에 M 이 없다 (G-115 단계 3)
  - 기준: 키 표에 M 이 없다 — spec/01_settings/input.md 의 키 표에 E 줄은 있는데 M 줄이 없다. 「맵은 M」은 spec/12_ui/hud.md 에만 있다. input.md 는 「키 배치의 기본값」을 맡는 곳이라, 다음 세션이 이 표만 보고 M 을 딴 데 묶을 수 있다. E 줄 아래에 「| **M** | 지도 열기 · 닫기 (사람 결정 2026-09-21, 12_ui/hud.md) |」를 한 줄 더해라
- [ ] 34. 잔손질한 spec 한 줄에 「설계 값은」이 두 번 (G-115 단계 3)
  - 기준: 잔손질한 spec 한 줄에 「설계 값은」이 두 번 — spec/03_world/frontier-islands.md:18 이 「설계 값은 `world/frontier_islands/sulfur_island_blueprint.tres` — 설계 값은 모두 임시 — 사람이 같이 다듬는다」가 됐다. 뜻은 맞지만 같은 말이 겹쳤다. 「설계 값은 `world/frontier_islands/sulfur_island_blueprint.tres` — 전부 임시다, 사람이 같이 다듬는다」로 줄여라
- [ ] 35. 두 섬 크기가 같아지면 지도 테스트가 헛되게 깨진다 (막는 것은 아니다) (G-115 단계 3)
  - 기준: 두 섬 크기가 같아지면 지도 테스트가 헛되게 깨진다 (막는 것은 아니다) — test_voyage.gd 의 `assert_ne(_sulfur_map.size(), _home_map.size())`(157줄 무렵)와 `assert_ne(int(home_map.get("cells")), int(sulfur_map.get("cells")))`(218줄 무렵)는 「섬마다 제 크기의 지도다」를 두 섬의 크기가 **다르다**는 데 기대어 본다. 그런데 유황 섬 설계 값은 이제 spec 에 「전부 임시 — 사람이 같이 다듬는다」로 적혀 있어, 사람이 size 를 내 섬과 같게 고르면 섬 갈림이 멀쩡한데도 이 두 줄이 실패한다. 섬마다 갈라 담기는 것은 같은 시험의 gone · stations · map 비교가 이미 확인하므로, 이 두 줄은 빼거나 「크기가 다를 때만 견준다」로 눅여라
- [ ] 36. 재료 검사가 유황광석까지 허용한다 (G-117 단계 1)
  - 기준: 재료 검사가 유황광석까지 허용한다 — (막는 것은 아니다) test_tool_recipes.gd:173 이 허용 재료를 Harvest.DROPS 에서 뽑는데, 거기에는 sulfur_ore 도 들어 있다(harvest.gd:28). sulfur_ore 는 개척섬에만 나므로 부두를 놓기 전에는 못 얻는데도, 도구 레시피에 sulfur_ore 를 넣으면 이 테스트가 그대로 통과한다. 지금 네 레시피는 wood · stone · iron_ore 만 써서 실제로 어긋난 곳은 없다. 「내 섬에서 나는 것」으로 좁히려면 IslandResources 의 섬별 광물 목록(test_island_has_its_own_ores_only 이 쓰는 것)을 빼서 허용 목록을 만들어라.
- [ ] 37. bag.gd 의 임시 표시가 SLOT_SIZE 설명에 붙었다 (G-117 단계 1)
  - 기준: bag.gd 의 임시 표시가 SLOT_SIZE 설명에 붙었다 — current.md 는 「bag.gd 머리글 주석에 한 줄 보태라」고 했는데, 덮개 알파 · 레이어 세 줄이 bag.gd:19~22 의 `## 칸 크기. 임시 …` 와 `const SLOT_SIZE` 사이에 들어가 버려 GDScript 가 이것을 SLOT_SIZE 의 doc 주석으로 읽는다. 칸 크기 설명과 창 모양 설명이 한 덩어리가 되어 어긋난다. 세 줄을 위쪽 머리글 블록(bag.gd:17 의 `## 모양은 아직 …` 다음, 빈 줄 앞)으로 옮겨라. 내용 자체는 맞다 — layer = 5 가 bag.tscn 이 아니라 core/game_root.tscn:22~23 의 Window CanvasLayer 에 있다는 report 의 정정도 확인했다.
- [ ] 38. 등반 장비에는 빠뜨림을 잡는 그물이 없다 (G-117 단계 1)
  - 기준: 등반 장비에는 빠뜨림을 잡는 그물이 없다 — 도구는 tools.json 을 읽어 「한 줄 더 적었는데 레시피가 없으면 떨어진다」가 걸리지만, 등반 장비는 test_tool_recipes.gd:15 의 CLIMB_GEAR 상수에 셋이 손으로 박혀 있다. 네 번째 장비가 생기면 레시피를 빠뜨려도 아무것도 안 걸린다 — 이번 단계를 만든 바로 그 병이다. 등반 장비에는 tools.json 같은 데이터 파일이 아예 없고 anchor.gd · grapple.gd · climbing.gd 의 const 로만 있어서, 고치려면 장비 목록을 한 곳(데이터 파일이든 climb_gear.gd 의 한 배열이든)에 모으고 테스트가 그것을 읽게 해야 한다. 일이 작지 않다.
- [ ] 39. 제작대가 전부 workbench 인 것이 임시인데 데이터 파일에 안 적혀 있다 (G-117 단계 1)
  - 기준: 제작대가 전부 workbench 인 것이 임시인데 데이터 파일에 안 적혀 있다 — 새 레시피 일곱이 모두 station=workbench 다. 제작대 계통 수 · 단계 수가 미정이라(F-16) 도끼 자리에 같이 둔 것이고, 단계가 정해지면 금속 도구는 위 단계로 옮겨야 한다. 이 말이 report.json 에만 있어 다음 사람이 recipes.json 만 보면 확정된 값으로 읽는다. recipes.json 의 _temporary 에 「제작대는 전부 임시로 workbench 다 — 제작대 단계가 정해지면 금속 도구는 위 단계로 옮긴다 (F-16)」 한 줄을 더해라.
- [ ] 40. 제작대 레시피가 없는 제작대를 가리켜도 통과한다 (G-117 단계 2)
  - 기준: 제작대 레시피가 없는 제작대를 가리켜도 통과한다 — test_every_station_in_the_data_file_can_be_crafted(test_station_recipes.gd:103)은 그 제작대를 output 으로 내놓는 레시피 '줄이 있는지'만 본다. 레시피의 station 칸이 stations.json 에 없는 이름이어도 통과한다. QA 가 확인했다: stations.json 에 loom 을 더하고 recipes.json 에 {key: loom, station: "nowhere", output: loom} 을 더했더니 이 테스트는 그대로 통과했다 (떨어진 것은 loom 이름이 겹친 음성 대조 테스트 하나뿐). 지금 다섯은 실전 제작까지 확인되지만 그것은 NEW_STATIONS 에 손으로 적은 넷을 도는 test_the_four_new_stations_are_made_at_a_station_and_land_in_the_bag 덕분이라, 여섯 번째 제작대를 적는 사람은 이 그물에 걸리지 않는다. test_every_station... 에 '레시피의 station 이 hand 이거나 stations.catalog 에 있는 이름이다' 한 줄을 더하면 손으로 적은 목록 없이도 막힌다.
- [ ] 41. 음성 대조 테스트가 loom 이라는 이름에 매여 있다 (G-117 단계 2)
  - 기준: 음성 대조 테스트가 loom 이라는 이름에 매여 있다 — test_a_station_added_to_the_file_without_a_recipe_is_caught(test_station_recipes.gd:111~123)이 assert_eq(missing, ["loom"]) 으로 정확히 한 이름만 나오기를 바란다. 사람이 언젠가 진짜 베틀(loom)을 stations.json 에 적으면 검사 장치가 멀쩡한데도 이 줄이 실패한다. 실제로 위 확인 중에 이 이름이 겹쳐 엉뚱한 이유로 떨어졌다. 이름을 실제로 쓰일 리 없는 것(예: __qa_no_recipe__)으로 바꾸거나, assert_true("loom" in missing) 으로 눅여라.
- [ ] 42. 원자재에서 몇 단계인지 세는 코드가 테스트 두 곳에 따로 있다 (G-117 단계 2)
  - 기준: 원자재에서 몇 단계인지 세는 코드가 테스트 두 곳에 따로 있다 — test_station_recipes.gd:71 _steps_of() 는 되돌아가며 재귀로 세고, test_recipes.gd:292~313 은 더 정해지지 않을 때까지 되돌아 훑는 방식으로 센다. 같은 spec 수치(MAX_STEPS=3)를 두 알고리즘이 따로 지키고 있어, 한쪽만 고치면 둘이 어긋나도 아무도 모른다. 제작대만 보는 쪽은 모든 아이템을 보는 test_recipes.gd 쪽에 이미 포함되므로, 깊이 세는 함수를 한 곳(예: tests 공용 헬퍼)으로 모으거나 제작대 쪽 검사를 지워도 기준은 그대로 지켜진다.
- [ ] 43. 부순 제작대 테스트가 사람이 뒤집은 규칙을 굳힌다 (G-117 단계 3)
  - 기준: 부순 제작대 테스트가 사람이 뒤집은 규칙을 굳힌다 — spec/05_craft/crafting-stations.md:11 · 25 에 「부수면 놓은 것이 그대로 돌아온다 (사람 결정 2026-09-22) — 재료 절반이 아니라 제작대 자체다」 와 「한 방에 부서지지 않는다 (사람 결정 2026-09-22)」 가 적혀 있는데, 새 테스트 test_pickup.gd:232 test_walking_over_what_a_broken_station_drops_picks_it_up 은 정확히 그 반대를 단언한다: 250줄이 assert_eq(int(back.get("wood", 0)), 10, "부수면 목재가 돌아온다") 로 목재 10개를 못 박고, 258~259줄은 좌클릭 **한 번** 뒤 assert_null(stations.aimed_station(), "제작대가 부서져 앞에 아무것도 없다") 로 한 방에 부서지는 것을 못 박는다. 아직 코드가 옛 규칙(stations.gd:29 RETURN_RATE := 0.5)이라 지금은 통과하지만, G-119 는 list.md:45 에서 [ ] 로 남아 있다. G-119 를 구현하는 회차가 이 테스트에 부딪히는데, 단언 문구가 「부수면 목재가 돌아온다」라서 옛 규칙을 지키는 장치처럼 읽힌다. 고칠 방향: 이 테스트가 묻는 것은 「부순 것이 걸어가면 주워지나」뿐이므로 돌아오는 것의 정체(wood·10개)를 박지 말고 stations.returns_of() 가 내주는 것을 그대로 받아 「그것이 바닥에 떨어지고 밟으면 들어온다」만 확인하게 눅여라. 부수는 것도 한 대로 끝난다고 가정하지 말고 부서질 때까지 치게 하라.
- [ ] 44. 곡괭이가 광물을 막는다는 말을 아무도 확인하지 않는다 (G-117 단계 3)
  - 기준: 곡괭이가 광물을 막는다는 말을 아무도 확인하지 않는다 — test_from_empty_hands.gd:281 주석이 「곡괭이를 들고 돌 일곱 · 철광석을 캔다 — 곡괭이가 없으면 여기서 막힌다」라고 하고 묶음의 머리말(current.md:6)도 「곡괭이가 없어 광물을 못 캔다」에서 출발하는데, 실제 코드에는 도구 관문이 없다. game/life/harvest/harvest.gd:91 은 맞는 도구면 GOOD_HIT, 아니면(맨손 포함) POOR_HIT 로 **빠르기만** 다르고 못 캐게 막지 않는다. 위에서 곡괭이를 못 만들게 막고 돌려 보니 철광석·돌 관련 단언은 하나도 떨어지지 않았다 — 도끼를 든 채 MAX_SWINGS=60 안에 철광석까지 다 캤다. 즉 이 테스트는 곡괭이를 **만들 수 있다**는 것만 보이고 곡괭이가 무엇을 열어 준다는 것은 보이지 않는다. 고칠 방향: 주석을 사실대로(맞는 도구는 빠를 뿐이다) 고치거나, 같은 광물을 맨손·도끼·곡괭이로 칠 때 드는 대수를 비교해 곡괭이가 확실히 적게 드는 것을 단언으로 남겨라.
- [ ] 45. 부순 선착장이 저장본에서 되살아날 수 있다 (G-119 단계 1)
  - 기준: 부순 선착장이 저장본에서 되살아날 수 있다 — Dock.vanish() 는 Placeable.GROUP 에서만 빠지고 queue_free() 를 부른다. 지우는 것은 프레임 끝이라 그때까지 DockBuilder 의 자식으로 남고, DockBuilder.standing()(dock_builder.gd:100 근처)은 무리가 아니라 get_children() 을 훑는다 — 부순 프레임에 섬이 저장되면 부순 선착장이 다시 적힌다. 지금은 부술 길이 없어 터지지 않지만 위 결정이 내려지면 바로 드러난다. Dock.vanish() 가 부모에서 먼저 떼어 내게 하고(CraftingStation 이 무리에서 먼저 빠지는 것과 같은 이유), 「부순 선착장은 standing() 에 남지 않는다」 테스트를 tests/world/frontier_islands/test_dock_building.gd 에 짜라
- [ ] 46. 상자 · 횃불은 진짜 코드가 아니라 흉내로만 확인한다 (G-119 단계 1)
  - 기준: 상자 · 횃불은 진짜 코드가 아니라 흉내로만 확인한다 — tests/build/test_placeable.gd 의 test_a_newly_placeable_thing_gets_the_same_rule_for_free 는 테스트 파일 안에 든 _FakePlaceable(placed_item · vanish 만 갖춘 가짜)로 규칙을 본다. 상자 · 횃불은 놓는 길이 아직 없어(G-120) 이번 회차로는 이것이 최선이고 기준을 막지는 않지만, 이 검사는 앞으로 나올 진짜 상자가 Placeable.GROUP 에 들도록 강제하지 못한다. 한편 game/world/storage/chest.gd 에 이미 진짜 Chest(StaticBody3D)가 있다 — 죽은 자리 상자 · 개발용 상자가 물려받는 것이라 부수면 안 되는 것이 맞으니 지금 규칙을 붙이지 않은 것은 옳다. G-120 에서 놓는 나무 상자를 만들 때 이 가짜 검사를 진짜 상자로 갈아 끼워라
- [ ] 47. 섬을 떠났다 오면 깎인 대수가 사라진다 (G-119 단계 2)
  - 기준: 섬을 떠났다 오면 깎인 대수가 사라진다 — stations.gd 의 standing() 은 {kind, at} 만 담으므로 두 대 맞은 제작대가 저장·복원을 거치면 성한 몸으로 다시 선다. 막는 것은 아니다 (기준 밖이고, 만들던 것·버퍼도 이미 같은 처지다). 그 함수 위의 「만들던 것 · 버퍼는 아직 담지 않는다 (**임시**)」 줄에 「남은 대수」도 함께 적어 두면 다음에 저장본을 건드릴 때 빠뜨리지 않는다
- [ ] 48. Chests.REACH 에 「임시」 표시가 없다 (G-120 단계 1)
  - 기준: Chests.REACH 에 「임시」 표시가 없다 — report.json 은 놓는 거리(4m)를 임시로 꼽았는데 chests.gd:19 주석은 「제작대를 놓는 거리와 같은 값으로 뒀다」까지만 적혀 있다. 값이 미정이라는 말이 코드에 없으면 다음 사람이 정해진 값으로 읽는다. 「임시 — 도달 거리 값은 미정이다」 한 마디를 붙여라. stations.gd:26 의 REACH 도 같은 처지다(Harvest.REACH 와 같게 뒀다는 말만 있다)
- [ ] 49. 제작대·상자가 칸을 나눠 갖는 검사가 on_cell 을 지나지 않는다 (G-120 단계 1)
  - 기준: 제작대·상자가 칸을 나눠 갖는 검사가 on_cell 을 지나지 않는다 — test_chest_place.gd/test_a_station_and_a_chest_do_not_share_a_cell 는 주석에 「(Placeable.on_cell)」이라 적었지만, 제작대 몸통에 광선이 걸려 aimed_spot 의 앞쪽 종류 거르기에서 이미 막힌다. on_cell 을 무력화한 채 돌려도 이 검사는 통과했다. 막는 것은 아니다 — 그 길은 tests/build/test_placeable.gd 가 따로 본다. 주석의 「(Placeable.on_cell)」을 「광선이 제작대를 짚는 길」로 고치거나, 제작대 옆 칸 가장자리 땅을 겨누는 꼴로 바꿔라
- [ ] 50. 섬의 붙이는 차례를 지키는 테스트가 없다 (G-118 단계 2)
  - 기준: 섬의 붙이는 차례를 지키는 테스트가 없다 — 「총이면 우클릭이 상호작용으로 안 간다」는 Aiming 이 우클릭을 받는 아홉(stations·chests·farmland·crops·food·climb_gear·death·dock_builder·dock)보다 **뒤에 붙는다**는 것에만 기대어 있다. test_aiming.gd 는 그 차례를 손으로 다시 세워 검사할 뿐 test_island.gd 의 진짜 차례를 읽지 않는다. 누가 _build_aiming() 을 앞으로 옮기거나 우클릭 받는 노드를 뒤에 새로 붙이면 테스트는 전부 통과한 채 게임에서 총 우클릭이 상자를 연다. 진짜 섬을 세우고 Aiming 이 INTERACT 를 받는 자식들 가운데 맨 뒤인지 보는 구조 테스트를 하나 짜라 (또는 _build_aiming 을 맨 뒤로 옮기고 그것을 검사하라)
- [ ] 51. 섬에 붙인 자리가 테스트에 안 잡힌다 (G-118 단계 3)
  - 기준: 섬에 붙인 자리가 테스트에 안 잡힌다 — test_island.gd:256 _build_bullet_trace() 가 예광탄을 진짜 게임에 이어 주는 유일한 줄인데 이것을 확인하는 테스트가 없다. test_bullet_trace.gd 는 before_each 에서 BulletTrace 를 손으로 만들어 붙이므로, 섬 쪽 줄을 통째로 지워도 47개가 다 통과한다. 막는 것은 아니다 — 앞 단계의 _build_aiming 도 같은 처지고 섬 하위 계통은 원래 테스트가 없다. 고치려면 tests/world/terrain/test_island_in_game.gd 에 island.bullet_trace 가 서 있고 그 attack 이 island.attack 인지 보는 단언 두 줄이면 된다
- [ ] 52. 쓰지 않는 station() 접근자가 남았다 (G-121 단계 1)
  - 기준: 쓰지 않는 station() 접근자가 남았다 — 막는 것은 아니다. ui/hud/station_window.gd 에 새로 들어온 `func station() -> CraftingStation` 를 부르는 곳이 코드에도 테스트에도 하나도 없다 (game/ 전체 grep 결과 0건). 같은 자리의 station_kind() 는 세 테스트가 쓰고 있다. station() 를 지워라.
- [ ] 53. 막대 크기와 소수 자릿수에 「임시」 표시가 없다 (G-121 단계 2)
  - 기준: 막대 크기와 소수 자릿수에 「임시」 표시가 없다 — station_window.tscn:37 의 ProgressBar custom_minimum_size = Vector2(400, 16) 과 station_window.gd:183 의 "%.1f" (남은 초를 소수 첫째 자리까지) 가 사람이 나중에 정할 값인데 코드에는 「임시」가 한 줄도 없다. report.json 의 temporary 에만 적혀 있어 .tscn 을 여는 사람은 못 본다 — G-900 6·7번과 똑같은 자리다. station_window.gd 머리글의 ROW_SIZE·BUFFER_SLOT_SIZE 주석과 같은 투로 「남은 시간 막대 크기(tscn)와 적는 소수 자릿수는 임시 — 사람이 보고 정한다」 한 줄을 보태라. 값은 바꿀 것 없다
- [ ] 54. 「닫아 둔 동안 시간이 흘렀다」 단언이 헐겁다 (G-121 단계 2)
  - 기준: 「닫아 둔 동안 시간이 흘렀다」 단언이 헐겁다 — test_station_output.gd:283 의 assert_lt(station.craft_left(), left_before + 0.01) 은 여유 0.01 때문에 시간이 완전히 멈춰도(craft_left() == left_before) 통과한다. 메시지는 「시간이 흘렀다」고 말하는데 아무것도 지키지 않는다. + 0.01 을 떼고 assert_lt(station.craft_left(), left_before, ...) 로 바꿔라 — 그대로 두고 돌려 15개가 다 통과하는 것을 확인했다 (제작대가 _process 로 스스로 돌아 창이 닫혀 있어도 시간이 준다)
- [ ] 55. 칸 하나를 눌러도 버퍼째로 가져오는 것이 spec 에 없다 (G-121 단계 2)
  - 기준: 칸 하나를 눌러도 버퍼째로 가져오는 것이 spec 에 없다 — station_window.gd 의 _collect 은 어느 칸을 눌러도 Stations.collect 로 버퍼 전체를 가져온다 (코드 주석에는 까닭이 적혀 있다). 가방이 모자랄 때 2번 칸을 눌렀는데 0번 칸 것만 들어오는 일이 생긴다. 지금 기준을 막지는 않는다 — spec/05_craft/crafting-stations.md 의 「미정」에 「칸마다 따로 수령하나, 버퍼째로 가져오나 (지금은 버퍼째)」 한 줄을 적어 두어라
- [ ] 56. spec 미정 줄이 낡았다 (G-122 단계 2)
  - 기준: spec 미정 줄이 낡았다 — spec/04_life/climbing.md:51 「갈고리총 탄창을 어디서 채우나 (제작 · 줍기 · 자동)」 은 이번 단계에서 정해졌다 (제작대에서 만들고 R 로 채운다, 사람 결정 2026-09-22). 그 줄을 지우고, 대신 아직 안 정해진 「갈고리총 재장전에 걸리는 시간 (지금은 임시로 0초 — 총은 2초)」 을 미정에 한 줄 적어라
- [ ] 57. 갈고리총이 가득 찬 채 손에 들어오는 것이 임시라고 안 적혀 있다 (G-122 단계 2)
  - 기준: 갈고리총이 가득 찬 채 손에 들어오는 것이 임시라고 안 적혀 있다 — grapple.gd 의 `_init()` 이 `_left = magazine` 으로 첫 탄창을 공짜로 준다. 같은 임시 규칙을 쓰는 총은 magazine.gd:27 에 「총은 가득 찬 채로 손에 들어온다 — 임시다」 라고 적어 두었다. grapple.gd 의 `_init` 위에 같은 뜻의 한 줄을 적어라
- [ ] 58. tools.json 의 gun 30발이 spec 표에 없는 총이다 (G-124 단계 1)
  - 기준: tools.json 의 gun 30발이 spec 표에 없는 총이다 — tools.json 의 _temporary 는 「탄창 크기는 spec 표의 값이고 권총 9발만 사람이 정했다」고 적었는데, gun 은 그 표(권총·산탄총·돌격소총·저격총 4계통 16자루) 어디에도 없는 예전 총이다. 30발도 표에서 온 값이 아니라 전에 코드에 박혀 있던 값을 옮긴 것이다. 단계 3 「열여섯 자루와 사다리」에서 이것을 지워야 할지 남겨야 할지가 지금 파일만 봐서는 안 보인다. tools.json 의 _temporary 에 「gun 은 표에 없는 예전 총이고 30발은 표가 아니라 옛 코드에서 온 값이다 — 계통이 붙으면 없어질 자리」를 한 줄 더 적어라
- [ ] 59. 빈 총 테스트가 탄창을 놓는 길을 지나지 않는다 (G-124 단계 1)
  - 기준: 빈 총 테스트가 탄창을 놓는 길을 지나지 않는다 — test_per_gun_magazine.gd:157 test_an_empty_gun_stays_empty_after_being_put_down 은 주석에 「가장 아픈 자리」라 적었지만, 도끼를 든 동안 attack.magazine() 을 한 번도 부르지 않아 「손에서 놓을 때」 도는 코드를 지나지 않는다. 실제로 magazine() 이 총을 놓을 때 탄창을 버리도록 깨 보니 이 테스트만 통과했다 (형제 테스트 test_putting_the_gun_down_keeps_its_rounds 가 잡아 주므로 기준은 막혀 있다 — 통과를 막는 것은 아니다). _hold(AXE) 뒤에 형제 테스트처럼 assert_null(attack.magazine(), "도끼에는 탄창이 없다") 한 줄을 넣어 놓는 길을 지나게 하라
- [ ] 60. 총마다 다른 탄을 먹는지 아무 테스트도 안 본다 (G-124 단계 2)
  - 기준: 총마다 다른 탄을 먹는지 아무 테스트도 안 본다 — ToolCatalog.ammo_item() 이 늘 "pistol_ammo" 를 돌려주게 일부러 깨 놓고 TEST_DIR=res://tests/combat/tools_as_weapons 를 돌려 봤더니 62개가 다 통과했다. 검사들이 「제 탄」을 전부 catalog.ammo_item() 에 되물어 보기 때문에, 총 전부가 한 가지 탄을 먹게 되돌아가도 아무도 못 잡는다 (기준 자체는 막혀 있어 통과를 막는 것은 아니다). test_ammo_kinds.gd 의 test_every_gun_in_the_file_says_which_round_it_eats 에 「쏘는 도구들이 먹는 탄을 모아 보면 서로 다른 것이 둘 이상이다」를 넣어라 — _guns() 를 돌며 catalog.ammo_item(gun) 을 Dictionary 에 모아 assert_gt(seen.size(), 1, "총마다 먹는 탄이 다르다") 한 줄이면 된다. 지금 파일은 revolver=pistol_ammo · gun=rifle_ammo 라 이대로 통과한다
- [ ] 61. 갈고리총 주석이 없어진 상수를 가리킨다 (G-124 단계 2)
  - 기준: 갈고리총 주석이 없어진 상수를 가리킨다 — game/life/climbing/grapple.gd:14 가 「총알(Magazine.AMMO_ITEM)로는 채워지지 않는다」고 적었는데 Magazine.AMMO_ITEM 은 이번 단계에서 없어졌다. 읽는 사람이 없는 것을 찾게 된다. 그 줄을 「총알(탄 네 종, tools.json 의 ammo_kinds)로는 채워지지 않는다」로 고쳐라
- [ ] 62. list.md 가 216줄이다 (G-124 단계 2)
  - 기준: list.md 가 216줄이다 — 세션이 읽는 md 는 150줄 이하라는 줄(LOOP.md 9행)을 넘긴 지 오래다 (HEAD~12 에 143줄 → 지금 216줄). 늘어난 몫은 대부분 G-900 의 단계마다 붙은 긴 「기준:」 줄이다. 이번 단계가 만든 문제는 아니지만 정리 묶음이 아직 없다. 끝난 묶음의 단계 줄을 접거나 지워 150줄 안으로 줄여라
- [ ] 63. 같은 파일에 낡은 주석이 하나 더 남았다 (G-123 단계 1)
  - 기준: 같은 파일에 낡은 주석이 하나 더 남았다 — game/settings/save/world_data.gd:23 의 `var islands` 주석이 아직 `{gone(캔 자리), taken(캔 날), stations(지은 것), map(밝힌 지도)}` 넷만 센다. 두 줄 위에서 새로 고친 주석(상자 · 선착장도 담긴다)과 바로 어긋난다. island_state.gd 의 of() 가 담는 여섯 키(gone · taken · stations · chests · docks · map)를 그대로 적어라. 단계는 통과시켰다 — 기준이 6번 줄만 짚었다
- [ ] 64. 쓰이지 않는 gun_at() 이 남았다 (G-124 단계 3)
  - 기준: 쓰이지 않는 gun_at() 이 남았다 — game/combat/tools_as_weapons/tool_catalog.gd:170 의 gun_at(계통, 단) 을 부르는 곳이 게임 코드에도 테스트에도 없다 (grep 결과 정의 한 줄뿐). guns_of() · tier() 만으로 사다리가 다 읽힌다. 그 함수를 지워라 — 쓸 곳이 생기면 그때 다시 붙이면 된다

## [ ] G-901 창이 화면을 넘지 않는다 — 찍어 보고 고친다
- spec: spec/12_ui/hud.md, spec/12_ui/menu.md
- **G-900 이 다 끝난 뒤에 한다** (사람 결정 2026-09-22) — 목록이 비어도 루프가 UI 를 다듬게 남겨 둔 자리다
- 찍는 법: `harness/shot.sh --ui <폴더> workbench bag chest hud menu` → **PNG 를 열어 보고** 고친다.
  사람이 2026-09-22 에 찍어 본 것: 제작 창이 위아래로 화면을 넘쳐 **출력 버퍼가 잘리고 핫바를 가린다**
- [ ] 1. 제작 창이 화면 안에 들어온다
  - 기준: 레시피가 몇 개든 창 전체가 화면 안이다 — 패널 rect 가 뷰포트 rect 안에 있다 (테스트)
  - 기준: 레시피 목록이 길면 **스크롤**된다. 남은 시간 · 출력 버퍼는 늘 보인다 (테스트)
  - 기준: 창이 **핫바를 가리지 않는다** — 두 rect 가 겹치지 않는다 (테스트)
  - 기준: 찍은 그림(workbench)에서 버퍼 칸 셋이 다 보인다
- [ ] 2. 상자 · 가방이 한 덩어리로 보인다
  - 기준: 상자 창과 가방이 서로 겹치지 않고, 제목이 제 칸 바로 위에 붙는다 (테스트)
  - 기준: 「맨손으로 만드는 것」 단추가 핫바를 가리지 않는다 (테스트)
  - 기준: 열리는 창은 전부 화면 안이다 — 가방 · 상자 · 제작 창 · 지도 · ESC (테스트 하나로 훑는다)
  - 기준: 찍은 그림(chest · bag)으로 확인한다
- [ ] 3. 칸과 줄이 읽힌다
  - 기준: 칸 안에서 이름과 개수가 겹치지 않는다 — 글자 rect 가 칸 안이다 (테스트)
  - 기준: 재료가 모자란 레시피 줄은 **눈에 띄게** 다르다 (색이 다르고, 테스트가 그 차이를 본다)
  - 기준: 빈 칸과 찬 칸이 구분된다. 찍은 그림으로 확인한다

## [ ] G-902 칸 옮기기가 편하다 — 다른 게임에 있는 것들
- spec: spec/06_build/storage.md, spec/02_player/inventory-hotbar.md
- **G-901 뒤에 한다** (사람 결정 2026-09-22) — 지금은 한 칸씩 끌어다 놓는 것뿐이라 불편하다.
  코어 키퍼 · 스타듀 · 마인크래프트에 다 있는 손버릇을 들여온다
- [ ] 1. Shift + 클릭 — 통째로 건너간다
  - 기준: 상자가 열려 있을 때 가방 칸을 Shift+클릭하면 그 칸이 **통째로 상자로** 간다 (테스트)
  - 기준: 상자 칸을 Shift+클릭하면 통째로 가방으로 온다. 자리가 모자라면 들어간 만큼만 간다 (테스트)
  - 기준: 창이 닫혀 있으면 아무 일도 없다 (테스트)
- [ ] 2. 우클릭 — 반만 집고, 한 개씩 놓는다
  - 기준: 칸을 우클릭하면 **반만** 집힌다 (홀수면 많은 쪽을 집는다) (테스트)
  - 기준: 집은 것을 칸에 우클릭하면 **한 개씩** 놓인다 (테스트)
  - 기준: 창 바깥 우클릭은 지금처럼 창을 닫는다 — 규칙이 부딪히지 않는다 (테스트)
- [ ] 3. 모으기 · 정렬 · 빠른 채우기
  - 기준: 같은 아이템 칸을 **더블클릭**하면 흩어진 것이 한 칸으로 모인다 (테스트)
  - 기준: 상자에 **정렬** 단추가 있다 — 누르면 같은 것끼리 모이고 이름순으로 선다 (테스트)
  - 기준: **빠른 채우기** 단추 — 상자에 이미 있는 종류만 가방에서 밀어 넣는다 (테스트)
  - 기준: 단추 글자는 번역 키다 (ko · en 둘 다). 찍은 그림으로 자리를 확인한다

## 다음 — 위가 끝난 뒤 대화로 적는다
- **사람이 직접 플레이해 보는 자리다** — 루프가 할 일이 아니다 (2026-09-21).
  로드맵 한 바퀴: 생활 → 보급 → 배 → 새 자원 → 더 나은 생활
- 사람이 봐 둔 것 (2026-09-21): **치는 티가 안 난다** — 맨손 20대 · 도끼 4대를 치는 동안
  흔들림 · 소리 · 내구도(균열) 표시가 없다 (`struck` 신호를 듣는 곳이 없다). 디자인 단계에서 같이 본다
- 확인해 둔 것: **선착장은 맵에 박혀 있다** (건설이 아니다, world/frontier_islands/dock.gd)
- 그 다음 순서: 섬을 사람과 같이 다시 빚기 → 자동화 → 개별 스탯 · 무기 · 농사 넓히기 · 사냥(동물)
  → **그 다음에 원정 섬** (탑승 · 티켓 · 침몰한 마을 · 몰려오는 적 · 상위 금속 → 더 좋은 도구)
- **멀티플레이를 할 때 같이**: 데스 상자에 주인이 없다 — `spec/08_combat/damage-death.md` 의
  「죽은 본인만 열고 꺼낼 수 있다」가 코드에 없다. 지금은 혼자뿐이라 드러나지 않는다 (루프가 찾음 2026-09-21)
- 그 밖: 건축 · 방 · 광산 · 낚시 · 목장 · 펫 · 도감 · 날씨 · 멀티 · 경제 (roadmap.md 「빼는 것」)
