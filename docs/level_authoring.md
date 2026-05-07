# 关卡编辑说明

当前推荐的工作流是“场景编辑优先，JSON 管逻辑”。

- 地图布局、地块摆放：优先直接改 `scenes/maps/*_tilemap.tscn`
- 单位出生、目标、教学、招募：改 `assets/data/levels/chapter1_battles.json`
- 运行时战斗：会把当前场景里的 `TileMapLayer` 读回到 `BattleState`

这样你在编辑器里看着不对，可以直接刷地块、拖资源、改节点，不用先回 JSON 猜结果。

## 你最常改的地方

1. 改战斗顺序：
   `chapter.encounters` 或 `chapters[*].encounters`
2. 改单位出生：
   `battles[*].units`
3. 改地图地形：
   `scenes/maps/*_tilemap.tscn`
4. 改关卡目标：
   `objective_type`、`objective_title`、`reach_tiles`
5. 改教学高亮：
   `tutorial_steps[*].focus`

## 数据结构

- `chapter`: 章节标题、地点、敌军描述、战斗顺序和开场对白。
- `terrain_presets`: 可复用地形模板。
- `battles`: 每场战斗的单位出生点、地形模板引用、教学、目标和招募配置。

## 坐标规则

棋盘是 `10 x 8`，坐标从左上角开始：

- 左上角是 `[0, 0]`
- 右下角是 `[9, 7]`
- 单位出生点写成 `{"unit": "enemy_sword", "pos": [7, 3]}`

说明：

- `x` 向右增加。
- `y` 向下增加。
- 目前战斗逻辑、预览工具、校验工具都仍然按 `10 x 8` 处理。
- 这轮虽然已经把战斗显示区域放大了，但“真正扩大地图格子数”还需要同步改 `BattleState.GRID_W / GRID_H`、校验脚本和预览脚本，不能只改一处。

## 地形类型

- `floor`: 普通地面，默认值，不需要显式写。
- `wall`: 墙，不可通行。
- `pillar`: 柱子，不可通行。
- `gate`: 圣门，可通行。
- `high`: 高台，可通行，移动成本较高，攻击范围 +1。
- `holy`: 治疗格，可通行，停留后恢复生命。
- `fire`: 危险格，可通行，停留后受伤。
- `marker`: 标记格，可通行。

## 单位 ID

玩家单位：

- `hero_astra`
- `hero_liora`
- `hero_kael`

敌方单位：

- `enemy_sword`
- `enemy_mage`
- `enemy_guard`
- `enemy_boss`

## 推荐配置方式

推荐按这套顺序配图：

1. 先打开对应的 `scenes/maps/*_tilemap.tscn`
2. 直接在 `TileMapLayer` 上刷格子、调障碍、改出口
3. 再去 JSON 改 `battles[*].units`
4. 最后补 `objective_type`、`tutorial_steps`、`recruitment`

这样做的好处：

- 你在 Godot 里看到的，就是实际要打的地图
- 美术资源可以直接拖拽挂到场景或节点上
- 单位和规则还保留在 JSON，后续批量调平衡也方便

示例：

```json
{
  "terrain_preset": "academy_courtyard",
  "terrain": {
    "high": [[4, 3], [5, 3]],
    "fire": [[6, 3], [7, 4]],
    "gate": [[8, 4]]
  },
  "units": [
    {"unit": "hero_astra", "pos": [1, 4]},
    {"unit": "enemy_boss", "pos": [7, 3]}
  ]
}
```

## TileMap 场景怎么用

`battles[*].tilemap_scene` 现在建议这样理解：

- 它就是你在编辑器里直接改的地图场景
- 运行时会把这个 `TileMapLayer` 的格子读回状态
- 所以场景里的 tilemap 调整会直接影响战斗

如果你想根据 JSON 自动生成一版 `TileMapLayer` 预览场景，可以运行：

```powershell
$env:GODOT_BIN='C:\Users\admin\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $env:GODOT_BIN --headless --path 'E:\godot\paa' --script 'res://tools/create_level_tilemap_scenes.gd'
```

这个脚本会根据 `terrain_preset / terrain` 重新生成 `scenes/maps/*_tilemap.tscn`。

如果你已经手工把场景改好了，就不要随手再跑一次，不然会把手调结果覆盖掉。

## 为什么之前地图会乱

这次排查下来，核心不是单纯“某张图尺寸不对”，而是两个问题叠加：

1. 运行时曾经同时存在 `BoardLayer` 自绘地形 和 `TerrainTileMapLayer`。
2. 棋盘显示区域太小，技能栏和右栏又太重，视觉上会更拥挤。

现在已经调整为：

- 运行时优先吃 JSON 地形。
- 棋盘区域比之前更大。
- UI 面板更轻。

如果后面你要继续扩图，建议优先保证：

- 地形图集每格尺寸一致。
- `terrain_tile_regions` 和图集实际切片完全对齐。
- 不要再让两套运行时地形来源同时参与最终绘制。

## 校验命令

改完关卡或角色技能池后运行：

```powershell
$env:GODOT_BIN='C:\Users\admin\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64_console.exe'
& $env:GODOT_BIN --headless --path 'E:\godot\paa' --script 'res://tools/validate_project_data.gd'
```

校验会检查：

- 章节引用的战斗是否存在。
- 战斗 ID 是否重复。
- 单位 ID 是否有效。
- 出生点是否越界、重叠或刷在阻挡地形上。
- 地形类型是否有效。
- 角色技能池是否引用了不存在或无法执行的卡。
- 教学步骤的动作类型、角色 ID、技能 ID 和关注格是否合法。

## 可视化预览

打开 `scenes/LevelPreview.tscn` 可以在 Godot 编辑器里查看关卡格子、地形和出生单位。

预览节点有两个常用导出字段：

- `encounter_id`: 切换要看的战斗，例如 `chapter1_1`、`chapter1_2`、`chapter1_3`。
- `tile_size`: 调整预览格子的显示尺寸。

预览会用金色框标出 `tutorial_steps[*].focus` 关注格，并在右侧列出教学步骤标题、动作类型、限定角色和限定技能。

## 扩大地图时要一起改的地方

如果后面要把战场从 `10 x 8` 扩成更大的格子数，不要只改 JSON。至少要一起动这些位置：

- `scripts/core/BattleState.gd`
  这里有 `GRID_W / GRID_H`
- `scripts/tools/LevelPreview.gd`
  预览面板尺寸和循环范围
- `tools/create_level_tilemap_scenes.gd`
  自动生成 tilemap scene 的循环范围
- `tools/validate_project_data.gd`
  越界校验范围
- `tools/run_state_checks.gd`
  有一些固定坐标测试

这也是为什么这轮我先做了“棋盘显示区域变大”，而没有直接把底层格子数一次性放开。

## 美术资源表

美术资源路径在 `assets/data/art_assets.json` 中维护。新增角色、敌人、卡图、UI 图或替换动作表时，优先改这个资源表，不需要改 `BattleAssets.gd`。

```json
{
  "battlefield": "res://assets/art/battlefield-academy-courtyard-1280x720.jpg",
  "terrain_tileset": "res://assets/art/tilesets/academy-courtyard-tiles.png",
  "tokens": {
    "hero": "res://assets/art/tokens/astra-hero.png",
    "faith": "res://assets/art/tokens/liora-saint.png"
  },
  "portraits": {
    "astra": "res://assets/art/portraits/astra.png"
  },
  "unit_action_sheets": {
    "astra": "res://assets/art/unit_sheets/astra-actions.png",
    "sword": "res://assets/art/unit_sheets/enemy-sword-actions.png"
  },
  "cards": {
    "strike": "res://assets/art/cards/quick-slash.png"
  },
  "ui": {
    "status_panel": "res://assets/art/ui/status-panel-frame.png"
  },
  "vfx": {
    "slash": "res://assets/art/vfx/sword-slash-sheet.png"
  }
}
```

当前固定资源段：

- `battlefield`: 主战场背景，必填。
- `terrain_tileset`: 可选地形图集，存在时会按 4x2、每格 64px 切分。
- `tokens`: 棋盘和侧栏小头像，必需 key 为 `hero`、`faith`、`sword`、`mage`、`guard`。
- `portraits`: 角色立绘，必需 key 为 `astra`、`liora`、`kael`。
- `cards`: 技能卡插画，必需 key 为 `strike`、`lance`、`dash`、`guard`、`engage`、`heal`。
- `ui`: 界面面板图，必需 key 为 `status_panel`、`hand_dock`、`sidebar_inner`、`reward_panel`。
- `vfx`: 序列帧特效图，必需 key 为 `hit`、`slash`、`magic`、`heal`、`guard`、`death`。
- `unit_action_sheets`: 单位动作表，允许额外添加单位 ID 专属 key。

所有路径都必须使用 `res://`，并且文件需要真实存在。`tools/validate_project_data.gd` 会在检查流程里验证这些路径。

当前动作表 key 规则：

- 玩家角色使用 `character_id`：`astra`、`liora`、`kael`。
- 敌人默认使用单位 `role`：`sword`、`mage`、`guard`。
- 如果资源表里存在单位 ID 专属 key，例如 `enemy_boss`，会优先使用单位专属动作表，再 fallback 到 role。

动作表格式固定为 4 列 x 6 行：

- 第 1 行：idle
- 第 2 行：move
- 第 3 行：attack
- 第 4 行：skill
- 第 5 行：hit
- 第 6 行：defeat

## 教学步骤

战斗可以配置 `tutorial_steps`，用于主战斗界面的教学面板和关注格高亮。

```json
{
  "title": "选择单位",
  "body": "点击阿斯特拉，先确认本回合要行动的角色。",
  "action": "select_unit",
  "character_id": "astra",
  "required_skill_id": "",
  "focus": [[1, 4]]
}
```

字段说明：

- `title`: 教学面板标题，必填。
- `body`: 教学面板正文，必填。
- `action`: 推进条件，必填。
- `character_id`: 可选，限制这一步必须由指定角色完成。
- `required_skill_id`: 可选，限制 `attack_or_skill` 步骤必须使用指定技能。
- `focus`: 可选，棋盘关注格数组，会在战斗和关卡预览中高亮。

当前支持的 `action`：

- `select_unit`: 选择单位后推进；可用 `character_id` 限定角色。
- `move_or_wait`: 移动或点击自身格进入指令阶段后推进。
- `attack_or_skill`: 普通攻击或技能结算后推进。
- `end_turn`: 结束我方行动后推进。

`focus` 是一组棋盘坐标，用来提示玩家当前应关注的格子。

示例：要求凯尔使用守护绽放。

```json
{
  "title": "使用格挡技能",
  "body": "选择底部的守护绽放，给凯尔叠加格挡。",
  "action": "attack_or_skill",
  "character_id": "kael",
  "required_skill_id": "guard_bloom",
  "focus": [[1, 3], [2, 3], [3, 3]]
}
```
