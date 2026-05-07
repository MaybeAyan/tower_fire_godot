# 首批概念图提示词与交付说明

## 1. 用途

本文件用于《苍纹牌阵》第一批正式概念图出图，服务两类内容：

- 战斗 HUD
- 2D 正交棋盘 / 伪 2.5D 棋盘表现

这些提示词用于 AI 出图、外部美术首轮方向确认，或作为后续人工细化的共同起点。

## 2. 通用出图原则

### 目标

- 先找方向，不追求一张成稿
- 先看信息层级和氛围，再看细节
- 先确认“像不像这款游戏”，再确认“够不够精”
- 优先生成适合 Godot 2D 项目继续拆分和二次加工的画面参考

### 通用正向关键词

- story-driven tactical RPG
- Japanese fantasy oil painting
- bright sacred courtyard
- elegant parchment UI
- warm gold ornament
- readable tactical interface
- orthographic board readability
- 2D tactical game presentation
- pseudo 2.5D depth illusion
- calm but tense atmosphere
- high clarity game mockup

### 通用负向关键词

- generic mobile gacha UI
- dark grim dungeon
- photorealistic
- sci-fi
- cyberpunk
- purple neon fantasy
- thick medieval black-gold frame
- messy text-heavy layout
- low readability
- card game board
- heavy 3D scene
- strong perspective convergence
- true isometric diamond grid

### 批次建议

- 每个主题首轮先出 4 张
- 每张只换一个重点变量
- 不要首轮同时混改 UI、镜头、地形和色调

建议首轮变量：

- 构图比例
- UI 边框材质
- 棋盘镜头高度
- 油画程度

## 2.1 用途分轨

后续所有提示词默认分为两类：

- `氛围概念图 prompt`
- `生产级 2D 资产 prompt`

前者用于定气质，后者用于生成更接近 Godot 可落地的 2D 素材参考。不要混用。

## 3. 战斗 HUD 概念图

### 图 1：标准战斗 HUD

#### Prompt

```text
苍纹牌阵, story-driven tactical RPG battle HUD concept, Japanese fantasy oil painting interface, bright sacred academy courtyard battlefield, orthographic tactical board with subtle 2.5D depth, large readable central battle area, elegant parchment-and-brushed-paper UI panels with restrained warm gold trim, translucent tactical glass overlays only for move/attack range, top objective banner, top turn header, right-side tactical status panel divided into unit, target, battle status, action sections, bottom horizontal skill bar with compact illustrated skill slots, top-left tutorial card floating like a tactical note, overall clean readable Chinese fantasy strategy game mockup, emotional but clear, ceremonial yet lightweight, polished concept art, high-detail game UI presentation
```

#### Negative Prompt

```text
generic gacha UI, card battler layout, thick black gold medieval frame, dark gothic dungeon, overdecorated interface, cluttered center screen, purple neon, sci-fi HUD, unreadable tiny text, photorealistic, low contrast muddy board
```

#### 用途

- 定主 HUD 的信息层级
- 看右侧面板和底部技能栏的压迫感是否合适

### 图 2：更强叙事感 HUD

#### Prompt

```text
苍纹牌阵, tactical RPG battle HUD with stronger narrative mood, Japanese oil-painted fantasy UI, bright sanctuary under attack, parchment interface with hand-painted brush textures, delicate gold corner ornaments, central tactical board kept spacious and readable, tutorial and objective cards feel like floating commander notes, right panel feels like a field command dossier, bottom skill bar sleek and restrained, battle atmosphere tense but luminous, character-driven strategy game mockup, elegant, emotional, readable, premium concept art
```

#### Negative Prompt

```text
MMO hotbar, esports overlay, heavy medieval stone frame, too many icons, over-busy mini panels, dark fantasy horror, low readability, cartoon mobile style
```

#### 用途

- 看“剧情驱动感”能否融进战斗界面
- 测试更强纸本与笔触材质是否仍然可读

### 图 3：更轻的信息层版本

#### Prompt

```text
苍纹牌阵, minimalist but elegant tactical RPG HUD concept, Japanese fantasy oil painting with restrained interface, bright courtyard battlefield, large unobstructed board view, slim top status strips, refined right-side tactical cards, compact bottom action bar, subtle warm paper texture, thin gold details, light glass tactical markers, highly readable strategy interface, premium indie tactics game, calm, sharp, cinematic, clean information hierarchy
```

#### Negative Prompt

```text
empty bland UI, generic fantasy menu, sci-fi minimalism, no atmosphere, purple gradients, giant buttons, mobile idle game layout, noisy textures
```

#### 用途

- 找更适合长期战斗游玩的轻 HUD 基准
- 检查是否还能保住世界观气质

## 4. 2D 正交棋盘 / 伪 2.5D 棋盘表现概念图

### 图 1：圣庭庭院战场

#### Prompt

```text
苍纹牌阵, 2D tactical battlefield concept, orthographic square board, pseudo 2.5D depth illusion, Japanese fantasy oil painting environment, bright sacred courtyard under attack, layered stone walkways, raised platforms, holy healing tile, dangerous fire tile, narrow defensive choke points, luminous but readable battlefield, clear flat tile logic, top-down tactical readability first, elegant fantasy war tableau, polished 2D strategy game concept art
```

#### Negative Prompt

```text
hard isometric diamond grid, strong camera perspective, unreadable convergence, dark muddy colors, realistic ruins, low visibility terrain, random clutter, sci-fi battlefield, cartoon toy look, heavy 3D render
```

#### 用途

- 确认“正交规则 + 2D 可实现伪 2.5D 表现”的主方向
- 看高台、治疗格、火焰格是否能一眼读懂

### 图 2：回廊追击战场

#### Prompt

```text
苍纹牌阵, 2D corridor pursuit tactical board concept, orthographic square battlefield, pseudo 2.5D spatial layering, Japanese oil-painted fantasy architecture, luminous sacred hallway battlefield, narrow passages, pillars creating route pressure, side flanking lanes, elevated firing spots, a glowing exit gate, readable danger tiles and healing tiles, flat rule clarity with rich 2D presentation, elegant high-clarity strategy game environment art, story-driven battlefield with tension and direction
```

#### Negative Prompt

```text
maze-like confusion, black dungeon, gothic horror, exaggerated perspective distortion, cluttered props hiding movement lanes, overly dark shadows, abstract board game look, true 3D corridor render
```

#### 用途

- 看回廊战是否能自然呈现路线压力
- 为第 2 章地图视觉找模板

### 图 3：阵型协同章战场

#### Prompt

```text
苍纹牌阵, formation-focused 2D tactical battlefield concept, orthographic square tiles, pseudo 2.5D layering, Japanese fantasy oil painting, bright ceremonial battleground with layered platforms and open lanes, environment designed to encourage adjacency, flanking, formation anchors, rally points, readable tactical geometry, sacred banners and restrained magical motifs, premium indie strategy game art, clear, elegant, coordinated, tactical
```

#### Negative Prompt

```text
chaotic terrain, no lane structure, random decoration, giant empty floor, MMO raid arena, sci-fi holograms, heavy black-gold cathedral excess, unreadable board
```

#### 用途

- 预演第 3 章“阵型协同”舞台应该长什么样
- 让环境本身服务相邻、夹击和共鸣

## 4.1 生产级 2D TileSet / 地编素材 Prompt

### 场景地块总表

#### Prompt

```text
苍纹牌阵, 2D tactical RPG tileset production sheet, strict orthographic view, uniform tile size, grid-aligned square modules, Japanese fantasy sacred architecture, bright ivory stone, soft gold trim, clean tactical readability, modular environment pieces for Godot 2D, floor tile, wall tile, pillar tile, gate tile, raised tile, healing tile, fire hazard tile, marker tile, no perspective distortion, no camera convergence, no heavy 3D render, premium hand-painted 2D game asset sheet
```

#### Negative Prompt

```text
isometric diamond grid, perspective view, dramatic camera angle, inconsistent tile scale, painterly full scene illustration, photorealistic render, cluttered decorative overlap, unreadable tile boundaries, heavy 3D lighting
```

### 楼梯 / 平台 / 栏杆模块

#### Prompt

```text
苍纹牌阵, modular 2D tactical environment pieces, strict orthographic, grid-aligned square proportions, pseudo 2.5D depth only through layered stairs and platform edges, Japanese fantasy sacred stone stairs, platform border modules, railings, pillar bases, clean separable props for Godot 2D tactics game, consistent scale, readable silhouettes, hand-painted but production-friendly
```

#### Negative Prompt

```text
true 3D staircase render, perspective foreshortening, scene illustration, inconsistent module size, clutter, cinematic angle, dark dungeon, isometric asset pack
```

### 回廊地编模块

#### Prompt

```text
苍纹牌阵, modular sacred corridor 2D asset sheet, strict orthographic, square grid alignment, corridor floor tiles, side lane tiles, narrow choke point modules, pillar segments, balcony edges, gate marker, healing tile, fire tile, elegant ivory and blue fantasy palette, designed for Godot 2D tactical RPG level editing, clean tile boundaries, consistent scale
```

#### Negative Prompt

```text
deep perspective hallway, vanishing point camera, realistic cathedral render, inconsistent tile size, giant full-scene concept art, unreadable edges, heavy 3D shading
```

## 5. 出图批次建议

### 第一批

- `首批图 01`：圣庭战斗主界面
  - 对应命名：`hud-battle-standard-v1`
  - 评审重点：中央信息区是否够开阔；右侧面板和底栏是否压画面；UI 是否和世界观统一
- `首批图 02`：战火中的叙事战斗界面
  - 对应命名：`hud-battle-narrative-v1`
  - 评审重点：叙事感是否明显增强；纸本笔触是否提升气质而不损失可读性；是否比标准版更像本项目
- `首批图 03`：圣庭庭院 2D 正交棋盘 / 伪 2.5D 战场
  - 对应命名：`board-courtyard-ortho2d-v1`
  - 评审重点：高低差是否一眼可读；治疗格和火焰格是否清晰；是否能在 Godot 2D 中靠贴图和分层实现
- `首批图 04`：回廊追击 2D 正交棋盘 / 伪 2.5D 战场
  - 对应命名：`board-corridor-ortho2d-v1`
  - 评审重点：路线压力和追击感是否成立；通道/侧翼/出口是否读得快；是否能直接作为章节战场模板

目标：

- 先确认 UI 和棋盘是不是同一款游戏
- 先确认读图是否清晰

### 第二批

- HUD 轻量版本
- 阵型协同章战场图
- 章节地图 / 营地流程图

目标：

- 收敛长期使用的 UI 复杂度
- 为第 3 章建立空间语言

## 6. 交付格式建议

- 每批 4 张图
- 每张保留 prompt、negative prompt、用途说明
- 文件命名建议：
  - `hud-battle-standard-v1`
  - `hud-battle-narrative-v1`
  - `board-courtyard-ortho2d-v1`
  - `board-corridor-ortho2d-v1`
- 每张图落库时建议额外记录 3 个标签：
  - `主题`
  - `可读性结论`
  - `是否可作为实现锚点`

- 每批结束后记录三条结论：
  - 哪张最接近项目气质
  - 哪张可读性最好
  - 哪张最适合作为后续 UI / 棋盘实现锚点
