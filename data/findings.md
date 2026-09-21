# 루프가 찾은 것

QA 가 **통과시키면서** 남긴 지적이다 — 기준은 만족했지만 눈에 걸린 것들.
사람이 읽고 필요한 것만 `list.md` 로 옮긴 뒤 **그 줄을 지운다.** 남은 줄 = 아직 안 본 것.
루프는 이 파일을 읽지 않는다 (세션이 앞질러 가지 않게).

- `09-22 05:13` **G-117.2** 제작대 레시피가 없는 제작대를 가리켜도 통과한다 ‖ 제작대 레시피가 없는 제작대를 가리켜도 통과한다 — test_every_station_in_the_data_file_can_be_crafted(test_station_recipes.gd:103)은 그 제작대를 output 으로 내놓는 레시피 '줄이 있는지'만 본다. 레시피의 station 칸이 stations.json 에 없는 이름이어도 통과한다. QA 가 확인했다: stations.json 에 loom 을 더하고 recipes.json 에 {key: loom, station: "nowhere", output: loom} 을 더했더니 이 테스트는 그대로 통과했다 (떨어진 것은 loom 이름이 겹친 음성 대조 테스트 하나뿐). 지금 다섯은 실전 제작까지 확인되지만 그것은 NEW_STATIONS 에 손으로 적은 넷을 도는 test_the_four_new_stations_are_made_at_a_station_and_land_in_the_bag 덕분이라, 여섯 번째 제작대를 적는 사람은 이 그물에 걸리지 않는다. test_every_station... 에 '레시피의 station 이 hand 이거나 stations.catalog 에 있는 이름이다' 한 줄을 더하면 손으로 적은 목록 없이도 막힌다.
- `09-22 04:46` **G-117.1** 등반 장비에는 빠뜨림을 잡는 그물이 없다 ‖ 등반 장비에는 빠뜨림을 잡는 그물이 없다 — 도구는 tools.json 을 읽어 「한 줄 더 적었는데 레시피가 없으면 떨어진다」가 걸리지만, 등반 장비는 test_tool_recipes.gd:15 의 CLIMB_GEAR 상수에 셋이 손으로 박혀 있다. 네 번째 장비가 생기면 레시피를 빠뜨려도 아무것도 안 걸린다 — 이번 단계를 만든 바로 그 병이다. 등반 장비에는 tools.json 같은 데이터 파일이 아예 없고 anchor.gd · grapple.gd · climbing.gd 의 const 로만 있어서, 고치려면 장비 목록을 한 곳(데이터 파일이든 climb_gear.gd 의 한 배열이든)에 모으고 테스트가 그것을 읽게 해야 한다. 일이 작지 않다.
