# 苍纹牌阵

一个 Godot 4 角色成长战棋原型：在棋盘上移动、从合适的位置攻击、通过战后领悟扩展角色技能，并在章节营地里整备队伍。

方向是“剧情驱动的角色战棋 + 少量技能装备 + 日式油画幻想 UI”。当前正式规划强调角色记忆点、阵型协同、可预判风险和章节叙事。角色、技能名、设定和素材都是原创占位内容。

## 运行方式

1. 用 Godot 4.6 打开这个文件夹。
2. 运行项目。
3. 点击卡牌，再点击棋盘上的发光格子。

## 当前循环

- 10x8 战术棋盘，已支持第 1 章、第 2 章，以及第 3 章最小可运行闭环数据。
- 当前可用角色包括阿斯特拉、莉奥拉、凯尔；第 2 章可招募伊芙琳，第 3 章可在 `chapter3_1` 胜利后正式招募赛琳，并在后续状态中按正式队员处理。
- 每名角色拥有独立技能栏；底部只显示当前角色的技能牌，随右侧角色切换或棋盘选人自动切换。
- 已实现角色个人技能、技能领悟、胜利、战败、营地整备、招募、转职和重开。
- 当前规则采用经典死亡：阿斯特拉倒下直接战败；其他同伴倒下后会永久离队，不再进入后续战斗和营地。
- 已接入生成素材：战场背景、单位头像和卡牌插画。
- UI 已中文化，并整理了顶部状态、右侧战斗面板和底部手牌区。

## 当前正式规划

- 游戏定位：剧情驱动的角色战棋，不走重 deckbuilding。
- 前三章固定为每章 2 战，按“教学 -> 扩队 -> 阵型成型”推进；第 3 章当前已补到“guest 出场 -> 正式入队 -> 后续战斗视为正式队员”的最小闭环。
- 首版战斗特色优先围绕“阵型协同 + 可预判风险”展开。
- 首版风险系统目标为：反击、破绽、护卫。
- 棋盘底层继续使用正交规则，视觉表现向 2.5D 靠拢。
- 设计与实现前的主要依据见：
  - `docs/game_direction.md`
  - `docs/chapters_1_3_bible.md`
  - `docs/combat_identity.md`
  - `docs/ai_workflow.md`
  - `docs/concept_art_briefs.md`

## 当前架构

- `scenes/Main.tscn` 现在提供了明确的场景分层：棋盘/VFX 绘制层 + `UiCanvas` 节点化 UI 层。
- `scenes/UiPreview.tscn` 是专门的 UI 预览场景，可在编辑器里切换 `preview_phase` 直接调整战斗 HUD、对白、奖励、转职、章节地图和章节完成界面。
- `scenes/LevelPreview.tscn` 是编辑器里的关卡预览场景，可切换 `encounter_id` 查看地形和出生点。
- `scripts/Main.gd` 负责回合推进、输入转发和各层协作，不再承载全部战斗逻辑。
- `scripts/core/BattleState.gd` 集中管理战斗状态、牌组循环、单位行动和结算。
- `scripts/core/BattleContent.gd` 负责卡牌库、单位原型和关卡数据读取，后续扩卡、扩怪时优先改这里。
- `assets/data/levels/chapter1_battles.json` 负责章节对白、营地事件、遭遇单位、地形格子和战斗顺序；当前已支持第 1 章、第 2 章和第 3 章骨架数据。
- `assets/data/levels/chapter1_battles.json` 也可给战斗配置 `tutorial_steps`，用于章节内教学提示和关注格高亮。
- `assets/data/levels/chapter1_battles.json` 的 `chapter.camp_events` 负责营地事件文本、图标 key、加成类型和数值。
- 战斗奖励领取后会进入战间营地阶段，显示已完成节点、当前节点、Boss 节点和幸存队伍摘要；点击角色卡可查看营地技能池、调整出战技能、训练或选择剧情羁绊事件，再点击当前节点进入下一战。
- 每名角色初始只装备 1 个技能，战后可领悟新技能；营地最多设置 2 个出战技能，底部战斗技能条只显示当前装备技能。
- 地图底部会汇总下一战待生效的营地加成，章节完成面板会记录本章营地行动。
- 第 1 章完成转职后，可从章节完成面板进入第 2 章开场。
- 第 2 章第 1 战已接入首个可加入角色：伊芙琳存活到胜利后加入队伍，后续战斗会自动补入已招募队员。
- 第 3 章第 1 战中赛琳会先以 guest 友军参战；战斗胜利后她会正式加入队伍，并可在章节地图中调入后续出战名单。
- 队伍扩张后默认每战最多 3 人出战；第 3 章部署上限提升为 4，营地详情里可把角色设为出战或候补。
- `assets/data/art_assets.json` 负责战场、棋盘头像、立绘、卡图、UI、VFX 和动作表等美术资源映射，新增或替换素材时优先改这里。
- `scripts/core/SkillEffects.gd` 负责技能目标规则和效果执行，新增技能时优先在这里扩展。
- `scripts/core/BattleLayout.gd` 负责棋盘、侧栏和手牌区的响应式布局。
- `scripts/ui/BattleHudRoot.gd`、`scripts/ui/BattleOverlayRoot.gd`、`scripts/ui/ChapterFlowRoot.gd` 负责正式节点化 UI，同步战斗与章节流程状态。
- `scripts/core/BattleAssets.gd` 统一负责贴图加载，方便后续换皮或接资源表。
- `scripts/views/` 下的各个视图脚本现在主要承担棋盘、单位、地形和少量演出绘制；HUD 与章节流程 UI 已开始迁入正式节点场景。
- `assets/art/vfx/` 存放序列帧特效图，目前已接入攻击、治疗和护盾三类 VFX。
- `assets/art/unit_sheets/` 可放角色动作表。约定为 4 列 x 6 行：idle、move、attack、skill、hit、defeat。
- `assets/data/art_assets.json` 集中记录美术资源 key 到图片路径的映射，其中 `unit_action_sheets` 记录 4 列 x 6 行动作表。
- `shaders/` 存放后续节点化 Sprite/Tile 高亮可复用的 CanvasItem shader。
- `docs/level_authoring.md` 记录关卡 JSON 的坐标、地形、单位 ID 和校验命令。
- `docs/ui_authoring_workflow.md` 记录 Hastur Editor Executor + UI 预览场景的日常工作流。
- `tools/validate_project_data.gd` 可用 Godot headless 校验关卡和角色技能池数据。
- `tools/run_state_checks.gd` 可用 Godot headless 做关键战斗状态回归检查。
- `tools/check_all.ps1` 会串起数据校验、状态回归和 headless 启动检查。

## 第 3 章当前闭环

- 第 3 章主题为“阵型协同试炼”，已接入两场 battle：`chapter3_1` 与 `chapter3_2`。
- `scenes/maps/chapter3_1_tilemap.tscn`、`scenes/maps/chapter3_2_tilemap.tscn` 目前是最小地形占位场景，供 JSON 和运行时地形读取。
- 赛琳已在 `BattleContent.gd` 中补入正式角色/职业/被动与技能池数据，并在 `chapter3_1` 先以内置 guest 友军形式出场。
- `chapter3_1` 胜利后会触发赛琳正式入队；在章节地图与 `chapter3_2` 中，她会被视为正式队员，可参与部署、技能和后续状态判断。
- 赛琳当前仍复用占位肖像与动作表资源；本次目标先保证正式入队链路、章节推进与回归检查稳定。

## 美术素材

- `assets/art/battlefield-academy-courtyard-1280x720.jpg`
- `assets/art/tokens/astra-hero.png`
- `assets/art/tokens/blade-acolyte.png`
- `assets/art/tokens/rune-flare.png`
- `assets/art/tokens/shield-vow.png`
- `assets/art/cards/quick-slash.png`
- `assets/art/cards/radiant-lance.png`
- `assets/art/cards/step-command.png`
- `assets/art/cards/guard-bloom.png`
- `assets/art/cards/engage-crest.png`
- `assets/art/cards/mend-light.png`
- `assets/art/ui/status-panel-frame.png`
- `assets/art/ui/hand-dock-frame.png`
- `assets/art/vfx/fire-slash-sheet.png`
- `assets/art/vfx/heal-sigil-sheet.png`
- `assets/art/vfx/guard-shield-sheet.png`
- 可选 Tile 图集路径：`assets/art/tilesets/academy-courtyard-tiles.png`，按 4x2、每格 64px 排列：floor、wall、pillar、gate、high、holy、fire、marker。

## 后续适合添加

- 战斗后的奖励选牌。
- 职业和被动技能。
- 地形效果，比如掩体、荆棘、治疗格和危险格。
- 路线地图和多场遭遇。
- 更完整的原创角色立绘、动作特效和音效。
