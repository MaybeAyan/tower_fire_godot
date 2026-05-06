# TileMap 地图绘制说明

现在战斗地形已经支持 Godot 原生 `TileMapLayer`。推荐用地图场景来画，不要直接改运行时主场景里的 TileMap。

## 去哪里画

每场战斗都有一张独立地图：

- `scenes/maps/chapter1_1_tilemap.tscn`
- `scenes/maps/chapter1_2_tilemap.tscn`
- `scenes/maps/chapter1_3_tilemap.tscn`
- `scenes/maps/chapter2_1_tilemap.tscn`
- `scenes/maps/chapter2_2_tilemap.tscn`
- `scenes/maps/chapter2_3_tilemap.tscn`

打开对应场景，选中里面的 `Terrain` 节点，就可以用 Godot 的 TileMap 画笔刷格子。

## 图块含义

TileSet 使用 `assets/tile_sets/forest_tactical_tileset.tres`，来源图是 `assets/art/tilesets/forest-tactical-tiles-v2-8x6.png`。

图集现在是 `8 列 x 6 行`，每格 `64 x 64`。战斗逻辑只读取下面这些基础格，其它图块可以先当装饰或地图美术变体使用：

```text
第 1 行前 4 格：floor / wall / pillar / gate
第 2 行前 4 格：high  / holy / fire   / marker
```

地形逻辑：

- `floor`: 普通地面。
- `wall`: 墙，不可通行。
- `pillar`: 柱体，不可通行。
- `gate`: 门，可通行。
- `high`: 高台，移动成本较高，攻击范围 +1。
- `holy`: 治疗格，回合开始恢复。
- `fire`: 火焰格，回合开始受伤。
- `marker`: 标记格，可通行。

扩展图块也已经映射到地形逻辑：墙体/树木/路障会按 `wall` 或 `pillar` 阻挡，陷阱和燃烧符文按 `fire`，圣辉圆阵和小圣坛按 `holy`，旗帜/路牌按 `marker`，道路/草地/石板按 `floor`。

## 运行时怎么生效

战斗配置在 `assets/data/levels/chapter1_battles.json` 里通过 `tilemap_scene` 指向地图场景。游戏开始战斗时会直接读取这个 TileMap 场景：战斗逻辑从图块坐标推导地形，运行时视觉也复制该场景的 TileMap 数据。JSON 里的 `terrain_preset` / `terrain` 只作为旧配置和缺少地图场景时的回退。

保存地图场景后直接运行游戏即可，不需要手动导出。

注意：`scenes/Main.tscn` 里的 `TerrainTileMapLayer` 是运行时显示层，会根据当前战斗自动重建。不要在这里刷正式地图，否则运行时会被战斗数据覆盖。

## 尺寸限制

当前棋盘是 `10 x 8`：

- 左上角是 `(0, 0)`
- 右下角是 `(9, 7)`

超出这个范围的格子不会参与战斗逻辑。

## 生成或重建地图场景

如果你改了 JSON 地形并想重新生成地图场景，可以运行：

```powershell
& 'E:\迅雷下载\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe' --headless --path 'E:\godotPro\tower_fire_godot' --script 'res://tools/create_level_tilemap_scenes.gd'
```

重建会覆盖 `scenes/maps/*_tilemap.tscn`，所以手动画过的地图不要随便执行这条。

重建后再跑校验：

```powershell
.\tools\check_all.ps1
```

## 改图块美术

只改画风时，直接替换 `assets/art/tilesets/forest-tactical-tiles-v2-8x6.png`，保持 `8 x 6`、每格 `64px`，并且不要改动前两行前四格的含义。

改完后运行：

```powershell
.\tools\check_all.ps1
```
